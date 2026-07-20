// 教学注释: Control 是 v7 的关键升级点，负责 PC 重定向、flush，以及 load-use 停顿与旁路选择。
// `EXU_rs1_in/EXU_rs2_in` 就是送入执行级的最终操作数，它们可能来自 IDU 原值，也可能来自 EXU/MEM 级前递。
// 相比 v5 的直接数据通路，这里体现了流水线 CPU 为解决数据相关而新增的控制复杂度。
module Control (
    input clock,
    input reset,

    input [31: 0] mtvec_out,
    input [31: 0] mepc_out,

    input [31: 0] branch_pc,
    input [31: 0] Ex_result,
    input [31: 0] MEM_Ex_result,

    input [31: 0] MEM_Rdata,
    input [31: 0] IDU_rs1_value,
    input [31: 0] IDU_rs2_value,

    input branch_flag,
    input jump_flag,
    input mret_flag,
    input ecall_flag,
    input MEM_mem_ren,
    input fence_i_flag,

    input [4: 0] IDU_rs1,
    input [4: 0] IDU_rs2,

    input IDU_valid,
    input EXU_valid,
    input MEM_valid,

    input [4: 0] EXU_rd,
    input [4: 0] MEM_rd,

    input EXU_mem_ren,
    input EXU_R_Wen,
    input MEM_R_Wen,

    output IFU_stall,
    output [31: 0] EXU_rs1_in,
    output [31: 0] EXU_rs2_in,

    output icache_clr,
    output EXU_inst_clear,
    output [31: 0] dnpc,
    output dnpc_flag
);

    // choice 编码来自 Data_hazard，用于选择 IDU 原值还是旁路值。
    logic [1: 0] IDU_rs1_choice;
    logic [1: 0] IDU_rs2_choice;

    // 分支命中、跳转、fence.i、mret、ecall 都会触发 PC 重定向。
    assign dnpc_flag = (branch_flag&Ex_result[0])? 1'b1:(((jump_flag|fence_i_flag)) | (mret_flag|ecall_flag));
    // flush 会把已经错误进入 EXU 的指令清空；load-use 停顿时也借此阻断错误推进。
    assign EXU_inst_clear = (branch_flag&Ex_result[0])? 1'b1: jump_flag|fence_i_flag|IFU_stall;
    // 典型 load-use hazard: EXU 这拍还没拿到 load 数据，只能让前级先停一拍。
    assign IFU_stall = EXU_mem_ren && (((EXU_rd == IDU_rs1) || (EXU_rd == IDU_rs2)) && (EXU_rd!=0));

    assign icache_clr = fence_i_flag&EXU_valid;

    assign dnpc = (jump_flag? Ex_result : branch_flag? branch_pc: mret_flag? mepc_out:mtvec_out);

    // rs1 旁路优先取 EXU，若命中 MEM 再区分是访存读回还是普通 ALU 结果。
    assign EXU_rs1_in = (IDU_rs1_choice == 2'b01)? Ex_result:
                        (IDU_rs1_choice == 2'b11)? MEM_Rdata:
                        (IDU_rs1_choice == 2'b10)? MEM_Ex_result:
                        IDU_rs1_value;

    // rs2 的选择逻辑与 rs1 对称，对 store/branch 等依赖第二源操作数的指令同样重要。
    assign EXU_rs2_in = (IDU_rs2_choice == 2'b01)? Ex_result:
                        (IDU_rs2_choice == 2'b11)? MEM_Rdata:
                        (IDU_rs2_choice == 2'b10)? MEM_Ex_result:
                        IDU_rs2_value;

// Data_hazard 只负责“该选哪一路”，真正的停顿策略仍由 Control 决定。
Data_hazard Data_hazard_inst(
    .IDU_rs1(IDU_rs1),
    .IDU_rs2(IDU_rs2),

    .EXU_rd(EXU_rd),
    .MEM_rd(MEM_rd),

    .MEM_valid(MEM_valid),
    .EXU_valid(EXU_valid),
    .IDU_valid(IDU_valid),

    .MEM_mem_ren(MEM_mem_ren),
    .EXU_R_Wen(EXU_R_Wen),
    .MEM_R_Wen(MEM_R_Wen),

    .IDU_rs1_choice(IDU_rs1_choice),
    .IDU_rs2_choice(IDU_rs2_choice)
);

endmodule //PC_Control



