`include "para.sv"

// 教学注释: EXU 是执行级，同时承担 ID/EX 级间寄存器的角色。
// 进入 EXU 的控制位与操作数会先被寄存，再由 ALU 计算得到 `EX_result`，最后继续送往 LSU。
// `EXU_inst_clr` 对应流水线 flush: 当前级若遇到跳转/分支改道，需要把本拍已经进入 EXU 的无效控制位清零。
module EXU (
    input clock,
    input reset,

    input EXU_inst_clr,
    input [3:0] csr_wen,
    input R_wen,
    input mem_wen,
    input mem_ren,
    input [4:0] rd,
    input [2:0] funct3,
    input [31:0] pc,

    input [3:0] alu_opcode,
    input inv_flag,
    input jump_flag,
    input branch_flag,
    input fetch_i_flag,

    input [31:0] branch_pc,
    input [31:0] rs2_value,
    input [31:0] add1,
    input [31:0] add2,
    input [31:0] rd_value,

    output [31:0] branch_pc_next,
    output [31:0] rd_value_next,
    output fetch_i_flag_next,
    output branch_flag_next,
    output jump_flag_next,
    output [2:0] funct3_next,
    output [31:0] rs2_value_next,
    output [4:0] rd_next,
    output [3:0] csr_wen_next,
    output R_wen_next,
    output mem_wen_next,
    output mem_ren_next,
    output [31:0] EX_result,
    output logic [31:0] pc_out,

    input valid_last,
    output ready_last,

    input ready_next,
    output logic valid_next
);

    logic [31:0] branch_pc_reg;
    logic [3:0] csr_wen_reg;
    logic R_wen_reg;
    logic mem_wen_reg;
    logic mem_ren_reg;
    logic [4:0] rd_reg;
    logic [2:0] funct3_reg;

    logic [3:0] alu_opcode_reg;
    logic inv_flag_reg;
    logic jump_flag_reg;
    logic branch_flag_reg;

    logic [31:0] rs2_value_reg;

    logic [31:0] add1_reg;
    logic [31:0] add2_reg;

    logic [31:0] rd_value_reg;
    logic fetch_i_reg;

    // valid_next 描述当前拍是否真的有一条有效指令进入执行级。
    always @(posedge clock) begin
        if(reset)
            valid_next <= 1'b0;
        else if(ready_last & valid_last & EXU_inst_clr)
            valid_next <= 1'b0;
        else if(ready_last & valid_last)
            valid_next <= 1'b1;
        else
            valid_next <= 1'b0;
    end

    // 这一组寄存器保存数据面信息，对应 ID/EX 级间寄存器。
    always @(posedge clock) begin
        if(reset)begin
            funct3_reg <= 0;
            rd_reg <= 0;
            alu_opcode_reg <= 0;
            inv_flag_reg <= 0;
            rs2_value_reg <= 0;
            add1_reg <= 0;
            add2_reg <= 0;
            rd_value_reg <= 0;
            branch_pc_reg <= 0;
            pc_out <= 0;
        end
        else if(valid_last & ready_next)
        begin
            funct3_reg <= funct3;
            rd_reg <= rd;
            alu_opcode_reg <= alu_opcode;
            inv_flag_reg <= inv_flag;
            rs2_value_reg <= rs2_value;
            add1_reg <= add1;
            add2_reg <= add2;
            rd_value_reg <= rd_value;
            branch_pc_reg <= branch_pc;
            pc_out <= pc;
        end
    end

    // 这一组寄存器保存控制面信息；flush 时会被清零，避免错误路径继续提交。
    always @(posedge clock) begin
        if(reset)begin
            mem_ren_reg <= 0;
            csr_wen_reg <= 0;
            R_wen_reg <= 0;
            mem_wen_reg <= 0;
            jump_flag_reg <= 0;
            branch_flag_reg <= 0;
            fetch_i_reg <= 0;
        end
        else if(valid_last & ready_next& EXU_inst_clr)begin
            mem_ren_reg <= 0;
            csr_wen_reg <= 0;
            R_wen_reg <= 0;
            mem_wen_reg <= 0;
            jump_flag_reg <= 0;
            branch_flag_reg <= 0;
            fetch_i_reg <= 0;
        end
        else if(valid_last & ready_next) begin
            mem_ren_reg <= mem_ren;
            csr_wen_reg <= csr_wen;
            R_wen_reg <= R_wen;
            mem_wen_reg <= mem_wen;
            jump_flag_reg <= jump_flag;
            branch_flag_reg <= branch_flag;
            fetch_i_reg <= fetch_i_flag;
        end
    end

    logic [31:0] alu_res;

    assign jump_flag_next = jump_flag_reg;
    assign funct3_next = funct3_reg;
    assign rd_next = rd_reg;
    assign rd_value_next = rd_value_reg;
    assign csr_wen_next = csr_wen_reg;
    assign R_wen_next = R_wen_reg;
    assign mem_wen_next = mem_wen_reg;
    assign mem_ren_next = mem_ren_reg;
    // 某些分支比较通过对最低位取反来复用 ALU 结果，因此这里统一在输出端做一次修正。
    assign EX_result = alu_res ^{31'd0,inv_flag_reg};
    assign rs2_value_next = rs2_value_reg;
    assign branch_flag_next = branch_flag_reg;
    assign ready_last = ready_next;
    assign fetch_i_flag_next = fetch_i_reg;
    assign branch_pc_next = branch_pc_reg;

ALU #(
    .BW(32)
) ALU_i0
(
    .d1(add1_reg),
    .d2(add2_reg),
    .choice(alu_opcode_reg),
    .res(alu_res)
);

endmodule


