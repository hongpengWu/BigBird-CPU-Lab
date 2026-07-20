// 教学注释: Control 汇总跨级控制信息，决定是否改写 PC、是否清空 EXU 中的错误路径指令。
// v6 版已经具备 dnpc/flush/CSR 重定向框架，但数据相关处理仍是最简形式: 不停顿，也不真正前递。
// 因而它更像是从 v5 走向完整流水线控制的“过渡版控制器”。
module Control (
    input clock,
    input reset,

    input [31:0] mtvec_out,
    input [31:0] mepc_out,

    input [31:0] branch_pc,
    input [31:0] Ex_result,
    input [31:0] MEM_Ex_result,

    input [31:0] MEM_Rdata,
    input [31:0] IDU_rs1_value,
    input [31:0] IDU_rs2_value,

    input branch_flag,
    input jump_flag,
    input mret_flag,
    input ecall_flag,
    input MEM_mem_ren,
    input fence_i_flag,

    input [4:0] IDU_rs1,
    input [4:0] IDU_rs2,

    input IDU_valid,
    input EXU_valid,
    input MEM_valid,

    input [4:0] EXU_rd,
    input [4:0] MEM_rd,

    input EXU_mem_ren,
    input EXU_R_Wen,
    input MEM_R_Wen,

    output IFU_stall,
    output [31:0] EXU_rs1_in,
    output [31:0] EXU_rs2_in,

    output icache_clr,
    output EXU_inst_clear,
    output [31:0] dnpc,
    output dnpc_flag
);

  // EXU 用最低位给出分支条件真假，Control 再据此决定是否改写 PC。
  wire branch_taken = branch_flag & Ex_result[0];

  // v6 还没有真正的 load-use 停顿机制，因此这里恒为 0。
  assign IFU_stall = 1'b0;
  // v6 也没有真正前递，因此执行级直接消费译码级读出的寄存器值。
  assign EXU_rs1_in = IDU_rs1_value;
  assign EXU_rs2_in = IDU_rs2_value;
  assign icache_clr = 1'b0;
  // 只要发生控制流改道或异常返回，就需要告诉 IFU 使用 dnpc 而不是 snpc。
  assign dnpc_flag = branch_taken | jump_flag | fence_i_flag | mret_flag | ecall_flag;
  assign EXU_inst_clear = branch_taken | jump_flag | fence_i_flag;
  // 优先级体现了控制流来源: 普通跳转/分支来自 EXU，mret 返回 mepc，ecall 进入 mtvec。
  assign dnpc = jump_flag ? Ex_result :
                branch_flag ? branch_pc :
                mret_flag ? mepc_out : mtvec_out;

endmodule


