// v2 把寄存器堆从顶层拆出来，方便学生单独理解“状态存储”这件事。
// 接口语义:
// - `wen/waddr/wdata` 描述写回端口；
// - `rs1_addr/rs2_addr` 描述两个读端口；
// - `a0_value` 额外导出 x10，方便测试或调试观察函数返回值寄存器。
module RegisterFile #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
) (
    input                    clock,
    input                    reset,
    input                    wen,
    input  [ADDR_WIDTH-1:0]  waddr,
    input  [DATA_WIDTH-1:0]  wdata,
    input  [ADDR_WIDTH-1:0]  rs1_addr,
    input  [ADDR_WIDTH-1:0]  rs2_addr,
    output [DATA_WIDTH-1:0]  rs1_value,
    output [DATA_WIDTH-1:0]  rs2_value,
    output [DATA_WIDTH-1:0]  a0_value
);

  logic [DATA_WIDTH-1:0] rf[0:(1<<ADDR_WIDTH)-1];
  integer i;

  always_ff @(posedge clock) begin
    if (reset) begin
      // 复位时清空全部通用寄存器，形成确定的初始体系结构状态。
      for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
        rf[i] <= '0;
      end
    end else if (wen && (waddr != '0)) begin
      // x0 不可写，因此显式屏蔽地址 0。
      rf[waddr] <= wdata;
    end
  end

  // 读端口采用组合读:
  // 当前拍给出地址，当前拍就能看到寄存器内容，适合单周期数据通路。
  assign rs1_value = (rs1_addr == '0) ? '0 : rf[rs1_addr];
  assign rs2_value = (rs2_addr == '0) ? '0 : rf[rs2_addr];
  assign a0_value  = rf[10];

endmodule
