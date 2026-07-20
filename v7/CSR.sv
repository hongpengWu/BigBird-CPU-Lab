// 教学注释: CSR 模块集中保存机器态演示所需的几个寄存器，如 `mepc/mcause/mstatus/mtvec`。
// 这里体现了 v6/v7 相比 v5 的重要新增路径: ecall/mret 不再只是“结束仿真”，而是进入真正的 CSR 控制流。
// `ecall_flag` 会强制改写 `mepc/mcause`，随后 Control 再利用 `mtvec/mepc` 把 PC 重定向到异常入口或返回点。
module CSR #(
    parameter CSR_WIDTH = 32,
    parameter RESET_VAL = 0
)
(
    input clock,
    input reset,
    input [31: 0] pc,
    input ecall_flag,
    input [31: 0] csrd,
    input [3: 0] csr_wen,

    output [31: 0] mvendorid_out,
    output [31: 0] marchid_out,
    output [31: 0] mepc_out,
    output [31: 0] mcause_out,
    output [31: 0] mstatus_out,
    output [31: 0] mtvec_out
);

    logic [31: 0] mepc_in;
    logic [31: 0] mcause_in;
    logic [31: 0] mstatus_in;
    logic [31: 0] mtvec_in;

    // ecall 发生时，mepc/mcause 不是来自普通 CSR 写数据，而是由异常现场自动生成。
    assign mepc_in = (ecall_flag)? pc : csrd;
    assign mcause_in = (ecall_flag)? 11 : csrd;
    assign mstatus_in = csrd;
    assign mtvec_in = csrd;
    assign mvendorid_out = 32'h79737978;
    assign marchid_out = 32'h16FBCBD;

// 每个 CSR 都用独立寄存器保存，便于教学时单独观察写使能条件。
Reg #(
    .WIDTH(CSR_WIDTH),
    .RESET_VAL(RESET_VAL)
) CSR_MEPC(
    .clock(clock),
    .reset(reset),
    .din(mepc_in),
    .dout(mepc_out),
    .wen(csr_wen[0] | ecall_flag)
);

Reg #(
    .WIDTH(CSR_WIDTH),
    .RESET_VAL(RESET_VAL)
) CSR_MCAUSE(
    .clock(clock),
    .reset(reset),
    .din(mcause_in),
    .dout(mcause_out),
    .wen(csr_wen[1] | ecall_flag)
);

Reg #(
    .WIDTH(CSR_WIDTH),
    .RESET_VAL(32'h1800)
) CSR_MSTATUS(
    .clock(clock),
    .reset(reset),
    .din(mstatus_in),
    .dout(mstatus_out),
    .wen(csr_wen[2])
);

Reg #(
    .WIDTH(CSR_WIDTH),
    .RESET_VAL(RESET_VAL)
) CSR_MTVEC(
    .clock(clock),
    .reset(reset),
    .din(mtvec_in),
    .dout(mtvec_out),
    .wen(csr_wen[3])
);

endmodule //CSR
