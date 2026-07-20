`timescale 1ns / 1ps
`include "para.sv"

// 取指级只做一件事：维护当前 PC，并在顺序执行、暂停、重定向之间切换。
// 这里的 valid 固定为 1，意味着是否真正接纳指令由后级 ready 和控制面的 flush/stall 共同决定。
module IFU (
    input               clock,
    input               reset,
    input       [31:0]  dnpc,
    input               dnpc_flag,
    input       [31:0]  irom_data,
    input               stall,

    output      [31:0]  snpc,
    output logic [31:0] pc,
    output      [31:0]  inst,

    input               ready,
    output logic        valid
);

    localparam ResetValue = 32'h0;

    assign valid = 1'b1;
    assign snpc  = pc + 4;
    assign inst  = irom_data;

    // PC 更新优先级体现了前端协同关系：
    // reset > stall 保持 > dnpc 重定向 > 顺序加 4。
    always_ff @(posedge clock) begin
        if (reset) 
            pc <= ResetValue;
        else if (stall & valid & ready) 
            pc <= pc;
        else if (dnpc_flag & valid & ready) 
            pc <= dnpc;
        else if (valid & ready) 
            pc <= snpc;
    end

endmodule
