`include "para.sv"
// 通用整数寄存器堆：两个读口、一个写口。
// 这里保持最朴素的实现，便于教学时把注意力放在流水协同而不是寄存器堆优化上。
module RegisterFile #(ADDR_WIDTH = 32, DATA_WIDTH = 5) (
    input                          clock,
    input      [DATA_WIDTH-1:0]    wdata,
    input      [ADDR_WIDTH-1:0]    waddr,
    input                          wen,
    input                          reset,
    input      [ADDR_WIDTH-1:0]    rs1_addr,
    input      [ADDR_WIDTH-1:0]    rs2_addr,

    output     [DATA_WIDTH-1:0]    rs1_value,
    output     [DATA_WIDTH-1:0]    rs2_value,
    output     [DATA_WIDTH-1:0]    a0_value
);
    logic [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];

    // 写回在时钟上升沿生效，读口保持组合直读。
    always_ff @(posedge clock) begin
        if (wen) rf[waddr] <= wdata;
    end

    assign rs1_value = rf[rs1_addr];
    assign rs2_value = rf[rs2_addr];
    assign a0_value  = rf[10];

endmodule
