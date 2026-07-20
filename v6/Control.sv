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

  wire branch_taken = branch_flag & Ex_result[0];

  assign IFU_stall = 1'b0;
  assign EXU_rs1_in = IDU_rs1_value;
  assign EXU_rs2_in = IDU_rs2_value;
  assign icache_clr = 1'b0;
  assign dnpc_flag = branch_taken | jump_flag | fence_i_flag | mret_flag | ecall_flag;
  assign EXU_inst_clear = branch_taken | jump_flag | fence_i_flag;
  assign dnpc = jump_flag ? Ex_result :
                branch_flag ? branch_pc :
                mret_flag ? mepc_out : mtvec_out;

endmodule


