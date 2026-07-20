`include "para.sv"
// 教学注释: RegisterFile 是整数寄存器堆本体，只负责存储与读写端口，不直接理解流水线。
// x0 恒为 0 的语义并不是在这里强制实现，而是由上层在写回数据路径中避免写入有效非零值。
// 教学上可把它看成被 IDU 和 WBU 共同访问的共享状态单元。
module RegisterFile #(ADDR_WIDTH = 32, DATA_WIDTH = 5) (
    input clock,
    input [DATA_WIDTH-1:0] wdata,
    input [ADDR_WIDTH-1:0] waddr,
    input wen,
    input reset,
    input [ADDR_WIDTH-1:0] rs1_addr,
    input [ADDR_WIDTH-1:0] rs2_addr,

    output [DATA_WIDTH-1:0] rs1_value,
    output [DATA_WIDTH-1:0] rs2_value,
    output [DATA_WIDTH-1:0] a0_value
);
    logic [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
    
    // 写端口在时钟边沿生效，两个读端口保持组合读。
    always @(posedge clock) begin
        if (wen)
            rf[waddr] <= wdata;
    end

    assign rs1_value = rf[rs1_addr];
    assign rs2_value = rf[rs2_addr];
    assign a0_value = rf[10];

endmodule

