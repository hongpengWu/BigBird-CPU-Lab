// 教学注释: WBU 是流水线提交点，负责决定真正写回寄存器堆的值。
// 这里把三类结果汇总: `Ex_result`(普通 ALU)、`MEM_Rdata`(load)、`rd_value`(jal/jalr/CSR 特殊返回值)。
// 因此从教学上可以把 WBU 看成“最后一级多路选择器 + 调试接口来源”。
/* verilator lint_off UNUSEDSIGNAL */
// signal not use
`include "para.sv"
module WBU (
    input clock,
    input reset,

    input [31:0] MEM_Rdata,
    input [31:0] Ex_result,
    input [31:0] rd_value,
    input [ 4:0] rd,
    input [ 3:0] csr_wen,
    input        R_wen,
    input        mem_ren,
    input        jump_flag,
    input [31:0] pc,

    input  valid,
    output ready,

    output        valid_next,
    output        R_wen_next,
    output [ 3:0] csr_wen_next,
    output [31:0] csrd,

    output logic [31:0] pc_out,
    output       [31:0] rd_value_next,
    output       [ 4:0] rd_next
);

  assign pc_out = pc;


  // WBU 在本实现中总是 ready，因此 valid 直接透传到调试/提交侧。
  assign valid_next    = valid;
  // 写回值三选一: jal/jalr/CSR 走 rd_value，load 走 MEM_Rdata，其余普通指令走 Ex_result。
  assign rd_value_next = (jump_flag | (|csr_wen)) ? rd_value : (mem_ren) ? MEM_Rdata : Ex_result;
  // CSR 写数据复用 EXU 的结果通路，因此 Control/IDU 只需关注写使能与地址。
  assign csrd          = Ex_result;
  assign csr_wen_next  = csr_wen;
  assign R_wen_next    = R_wen & valid;
  assign rd_next       = rd;
  assign ready         = 1'b1;

endmodule  //WBU
