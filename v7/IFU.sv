`timescale 1ns / 1ps
`include "para.sv"

// 教学注释: IFU 负责维护 PC，并把 `pc/snpc/inst` 作为取指级输出送往后续级。
// 在 v6/v7 中，IFU 不直接判断分支是否成立，而是等待 Control 给出 `dnpc` 与 `dnpc_flag`。
// 这也是流水线设计与 v5 的关键差异: PC 更新已经从“本地组合决定”改成“跨级反馈控制”。
module IFU
(
    input clock,
    input reset,
    input [31:0] dnpc,
    input dnpc_flag,
    input [31:0] irom_data,
    input stall,

    output [31:0] snpc,
    output logic [31:0] pc,
    output [31:0] inst,

    input ready,
    output logic valid
);

    localparam ResetValue = 32'h0000_0000;

    assign valid = 1'b1;
    assign snpc = pc + 4;   // 顺序执行时的 next PC
    assign inst = irom_data; // 这里默认指令存储器可在同拍返回数据

    // PC 更新优先级: reset > stall 保持 > dnpc 重定向 > 顺序加 4。
    always @(posedge clock) begin
        if(reset)
            pc <= ResetValue;
        else if (stall & valid &ready)
            pc <= pc;
        else if(dnpc_flag&valid&ready)
            pc <= dnpc;
        else if(valid & ready)
            pc <= snpc;
    end

endmodule
