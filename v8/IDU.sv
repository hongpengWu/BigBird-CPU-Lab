`include "para.sv"

// 译码级负责把原始指令翻译成三类信息：
// 1. 数据通路控制：ALU 操作数、写回使能、访存读写。
// 2. 控制通路信息：branch/jump/ecall/mret/fence.i 等重定向事件。
// 3. 系统路径入口：CSR 地址与 CSR 写使能，用于把异常/返回并入统一控制流。
module IDU(
    input clock,
    input reset,

    input [31:0] inst_in,
    input [31:0] snpc_in,
    input [31:0] pc_in,

    input flush,
    input stall,

    input [31:0] rd_value,
    input [31:0] csrd,
    input [4:0] rd,
    input R_wen,
    input [3:0] csr_wen,

    input [31:0] EXU_rs1_in,
    input [31:0] EXU_rs2_in,

    output [4:0] rd_next,
    output [2:0] funct3,
    output mret_flag,
    output ecall_flag,
    output fence_i_flag,

    output [31:0] branch_pc,
    output [31:0] rs1_value,
    output [31:0] rs2_value,
    
    output [31:0] add1_value,
    output [31:0] add2_value,
    output [3:0] csr_wen_next,
    output R_wen_next,
    output [31:0] rd_value_next,

    output        mem_wen,
    output        mem_ren,
    output        inv_flag,
    output        branch_flag,
    output        jump_flag,

    output [3:0] alu_opcode,

    output [4:0] rs1,
    output [4:0] rs2,
    output [31:0] a0_value,
    output [31:0] mepc_out,
    output [31:0] mtvec_out,
    output [31:0] pc_out,


    input        valid_last,
    output       ready_last,

    input        ready_next,
    output logic valid_next
);

    logic [31:0] inst;
    logic [31:0] snpc;
    logic [31:0] pc;
    logic        valid;

    logic [31:0] inst_d;
    logic [31:0] snpc_d;
    logic [31:0] pc_d;
    logic        valid_d;

    assign ready_last = ready_next && !stall;
    assign valid_next = valid_d;

    // 第一级流水寄存：从 IFU 接住原始指令。flush 时主动灌入 NOP。
    always_ff @(posedge clock) begin
        if (reset || flush) begin
            inst  <= 32'h00000013;
            snpc  <= 0;
            pc    <= 0;
            valid <= 0;
        end else if (ready_next && !stall) begin
            inst  <= inst_in;
            snpc  <= snpc_in;
            pc    <= pc_in;
            valid <= valid_last;
        end
    end

    // 第二级译码寄存：把译码看到的 inst/snps/pc 再稳定一个拍，便于后续组合译码和前递选择。
    always_ff @(posedge clock) begin
        if (reset || flush) begin
            inst_d  <= 32'h00000013;
            snpc_d  <= 0;
            pc_d    <= 0;
            valid_d <= 0;
        end else if (ready_next && !stall) begin
            inst_d  <= inst;
            snpc_d  <= snpc;
            pc_d    <= pc;
            valid_d <= valid;
        end
    end

    logic [31:0] csr_addr;
    logic [6:0] oprand;
    logic [6:0] opcode;

    logic [31:0] imm_I;
    logic [31:0] imm_U;
    logic [31:0] imm_R;
    logic [31:0] imm_S;
    logic [31:0] imm_B;
    logic [31:0] imm_J;
    logic [31:0] csrs;
    logic [31:0] imm;

    assign oprand                      = inst_d[31:25];
    assign opcode                      = inst_d[6:0];
    assign rs1                         = inst_d[19:15];
    assign rs2                         = inst_d[24:20];
    assign funct3                      = inst_d[14:12];
    assign rd_next                     = inst_d[11:7];

    // 三条特殊系统路径都在译码级尽早识别，后续统一交给 Control 决定是否重定向 PC。
    assign ecall_flag                  = (inst_d == 32'b00000000000000000000000001110011);
    assign mret_flag                   = (inst_d == 32'b00110000001000000000000001110011);
    assign fence_i_flag                = (inst_d == 32'b00000000000000000001000000001111);
 
    assign csr_wen_next[0]             = (opcode == `M_opcode && imm == 32'h341);
    assign csr_wen_next[1]             = (opcode == `M_opcode && imm == 32'h342);
    assign csr_wen_next[2]             = (opcode == `M_opcode && imm == 32'h300);
    assign csr_wen_next[3]             = (opcode == `M_opcode && imm == 32'h305);

    logic is_S;
    logic is_I0;
    logic is_U0;
    logic is_U1;
    logic is_J;
    logic is_I2;
    logic is_I1;
    logic is_R;
    logic is_B;
    logic is_M;
    assign is_S  = (opcode == `S_opcode);
    assign is_I0 = (opcode == `I0_opcode);
    assign is_U0 = (opcode == `U0_opcode);
    assign is_U1 = (opcode == `U1_opcode);
    assign is_J  = (opcode == `J_opcode);
    assign is_I2 = (opcode == `I2_opcode);
    assign is_I1 = (opcode == `I1_opcode);
    assign is_R  = (opcode == `R_opcode);
    assign is_B  = (opcode == `B_opcode);
    assign is_M  = (opcode == `M_opcode);

    assign R_wen_next                  = (is_S || is_B || opcode == 0)? 1'b0:1'b1;
    assign mem_wen                     = is_S;
    assign mem_ren                     = is_I0;

    assign jump_flag                   = (is_I2 || is_J)? 1'b1:1'b0;

    assign inv_flag                    = (is_B && (funct3 == 3'b101 || funct3 == 3'b111 || funct3 == 3'b000 ))? 1'b1:1'b0;
    assign branch_flag                 = is_B;
 
    assign csr_addr                    = imm;

    // rd_value_next 代表“无需再经过 ALU/访存加工即可写回”的结果：
    // 跳转类返回 snpc，CSR 指令直接返回读出的旧 CSR 值。
    assign rd_value_next               = jump_flag ? snpc_d :
                                         (|csr_wen_next) ? csrs :
                                         0;
    assign branch_pc                   = pc_d + imm;
    assign pc_out  = pc_d;

    logic [31:0] add_src1;
    logic [31:0] add_src2;

    // add_src1/add_src2 把不同指令族统一映射为 ALU 双输入，便于执行级只关心运算而不再关心指令格式。
    assign add_src1 = is_U0 ? 32'd0 :
                      (is_J || is_U1) ? pc_d :
                      EXU_rs1_in;

    assign add_src2 = (is_R || is_B) ? EXU_rs2_in :
                      (is_M && funct3 == 3'b010) ? rd_value_next :
                      (is_M && funct3 == 3'b001) ? 32'd0 : imm;

    assign add1_value = add_src1;
    assign add2_value = add_src2;
 

    logic cond_add;
    logic cond_signed_cmp;
    logic cond_unsigned_cmp;
    logic cond_xor;
    logic cond_or;
    logic cond_and;
    logic cond_sll;
    logic cond_srl;
    logic cond_sra;
    logic cond_sub;
    logic cond_equal;
    assign cond_add = is_S || is_I0 || is_U0 || is_U1 || is_J || is_I2
                 || (is_I1 && funct3 == 3'b000)
                 || (is_R  && funct3 == 3'b000 && oprand[5] == 1'b0)
                 || (is_B  && funct3[2:1] == 2'b01);
    assign cond_signed_cmp = (is_I1 && funct3 == 3'b010)
                        || (is_R  && funct3 == 3'b010)
                        || (is_B  && (funct3 == 3'b101 || funct3 == 3'b100));
    assign cond_unsigned_cmp = (is_B  && (funct3 == 3'b110 || funct3 == 3'b111))
                          || (is_I1 && funct3 == 3'b011)
                          || (is_R  && funct3 == 3'b011);
    assign cond_xor = (is_I1 && funct3 == 3'b100)
                 || (is_R  && funct3 == 3'b100);
    assign cond_or = (is_I1 && funct3 == 3'b110)
                || (is_R  && funct3 == 3'b110)
                || (is_M  && funct3 == 3'b010);
    assign cond_and = (is_I1 && funct3 == 3'b111)
                 || (is_R  && funct3 == 3'b111);
    assign cond_sll = (is_I1 && funct3 == 3'b001)
                 || (is_R  && funct3 == 3'b001);
    assign cond_srl = (is_I1 && funct3 == 3'b101 && oprand[5] == 1'b0)
                 || (is_R  && funct3 == 3'b101 && oprand[5] == 1'b0);
    assign cond_sra = (is_I1 && funct3 == 3'b101 && oprand[5] == 1'b1)
                 || (is_R  && funct3 == 3'b101 && oprand[5] == 1'b1);
    assign cond_sub = (is_R  && funct3 == 3'b000 && oprand[5] == 1'b1);
    assign cond_equal = (is_B && funct3[2:1] == 2'b00);

    // 分支比较与普通算术共用同一套 ALU 编码，后续由 EXU 取最低位作为条件判定结果。
    assign alu_opcode = cond_add ? `alu_add :
                        cond_signed_cmp ? `alu_signed_comparator :
                        cond_unsigned_cmp ? `alu_unsigned_comparator :
                        cond_xor ? `alu_xor :
                        cond_or ? `alu_or  :
                        cond_and ? `alu_and :
                        cond_sll ? `alu_sll :
                        cond_srl ? `alu_srl :
                        cond_sra ? `alu_sra :
                        cond_sub ? `alu_sub :
                        cond_equal ? `alu_equal : `alu_add;


    assign imm_I                       = {{20{inst_d[31]}},inst_d[31:20]};
    assign imm_U                       = {inst_d[31:12],12'd0};
    assign imm_R                       = {25'd0,inst_d[31:25]};
    assign imm_S                       = {{20{inst_d[31]}},inst_d[31:25],inst_d[11:7]};
    assign imm_B                       = {imm_S[31:11],imm_S[0],imm_S[10:1]}<<1;
    assign imm_J                       = {{11{inst_d[31]}},inst_d[31],inst_d[19:12],inst_d[20],inst_d[30:21]}<<1;
/* verilator lint_off IMPLICIT */

    assign imm = (opcode == `I0_opcode || opcode == `I1_opcode || opcode == `I2_opcode || opcode == `M_opcode)? imm_I:
                 (opcode == `U0_opcode || opcode == `U1_opcode)? imm_U:
                 (opcode == `J_opcode)? imm_J:
                 (opcode == `B_opcode)? imm_B:
                 (opcode == `S_opcode)? imm_S: 
                 (opcode == `S_opcode)? imm_R :
                  0;

// Reg_Stack 把通用寄存器堆和 CSR 空间并排组织，译码级在这里同时拿到整数寄存器值与系统寄存器值。
Reg_Stack Reg_Stack_inst0(
    .reset (reset),
    .clock (clock),
    .pc (pc),
    .ecall_flag (ecall_flag),

    .rs1 (rs1),
    .rs2 (rs2),
    .rd (rd),
    .rd_value (rd_value),

    .csr_addr (csr_addr),
    .R_wen (R_wen),
    .csr_wen (csr_wen),
    .csrd (csrd),

    .rs1_value (rs1_value),
    .rs2_value (rs2_value),
    .a0_value (a0_value),
    .csrs (csrs),
    .mepc_out (mepc_out),
    .mtvec_out (mtvec_out) 
);





endmodule
