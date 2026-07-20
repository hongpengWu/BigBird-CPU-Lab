// 教学注释: Reg 是通用触发器模板，可复用于 CSR 等需要“带写使能寄存”的场景。
// 在流水线教学里，它对应最基础的时序单元: 组合逻辑结果在时钟边沿被锁存，形成跨拍状态。
// 触发器模板
module Reg #(WIDTH = 1, RESET_VAL = 0) (
    input clock,
    input reset,
    input [WIDTH-1: 0]din,
    output reg [WIDTH-1: 0]dout,
    input wen                         
);
    always @(posedge clock) begin
        if (reset) 
            dout <= RESET_VAL;
        else if (wen) 
            dout <= din;  
        end
endmodule

