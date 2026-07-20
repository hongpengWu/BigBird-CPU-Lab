// 教学注释: Reg_Stack 把整数寄存器堆和 CSR 堆封装在一起，形成 IDU 看到的“读状态中心”。
// 从路径上看，普通寄存器写回走 `rd/rd_value/R_wen`，CSR 写回走 `csr_wen/csrd`，异常信息则走 `pc/ecall_flag`。
// 这也是 v6/v7 相比 v5 的一个明显教学点: 架构状态已经分成 GPR 路径和 CSR 路径两条线。
module Reg_Stack(
    input reset,
    input clock,
    input [31:0] pc,
    input ecall_flag,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] rd_value,

    input [31:0] csr_addr,
    input R_wen,
    input [3:0] csr_wen,
    input [31:0] csrd,

    output [31:0] rs1_value,
    output [31:0] rs2_value,
    output [31:0] a0_value,
    output [31:0] csrs,
    output [31:0] mepc_out,
    output [31:0] mtvec_out
);

    logic [31:0] wdata;

    logic [31:0] mcause_out;
    logic [31:0] mstatus_out;
    logic [31:0] mvendorid_out;
    logic [31:0] marchid_out;

    // x0 语义在写回入口被处理: 若目标寄存器为 0，则强制写入 0。
    assign wdata = (rd == 4'd0) ? 32'd0 : rd_value;

    // 读 CSR 时在这里做地址译码，译码级随后把读出的 csrs 作为普通操作数使用。
    assign csrs = (csr_addr == 32'h341) ? mepc_out :
                  (csr_addr == 32'h342) ? mcause_out :
                  (csr_addr == 32'h300) ? mstatus_out :
                  (csr_addr == 32'h305) ? mtvec_out :
                  (csr_addr == 32'hf11) ? mvendorid_out :
                  (csr_addr == 32'hf12) ? marchid_out : 32'd0;

    // CSR 子模块维护异常入口/返回地址等机器态状态。
    CSR #(32,0) CSR_inst(
        .clock(clock),
        .reset(reset),
        .pc(pc),
        .ecall_flag(ecall_flag),
        .csrd(csrd),
        .csr_wen(csr_wen),
        .mvendorid_out(mvendorid_out),
        .marchid_out(marchid_out),
        .mepc_out(mepc_out),
        .mcause_out(mcause_out),
        .mstatus_out(mstatus_out),
        .mtvec_out(mtvec_out)
    );

    // 普通整数寄存器堆与 CSR 并列存在，共同组成译码阶段可见的架构状态。
    RegisterFile #(5, 32) Reg_inst(
        .clock(clock),
        .wdata(wdata),
        .waddr(rd),
        .wen(R_wen),
        .reset(reset),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rs1_value(rs1_value),
        .rs2_value(rs2_value),
        .a0_value(a0_value)
    );

endmodule

