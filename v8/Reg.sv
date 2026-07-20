// 通用可写寄存器模板。
// 在本工程里既可作为普通流水寄存器，也可作为 CSR 存储单元。
module Reg #(WIDTH = 1, RESET_VAL = 0) (
    input               clock,
    input               reset,
    input      [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    input               wen
);
always_ff @(posedge clock) begin
    if (reset) 
        dout <= RESET_VAL;
    else if (wen) 
        dout <= din;
end
endmodule
