// 教学说明：寄存器堆位于译码与执行之间，负责提供源操作数并接收写回结果。
// 观察它的读写接口，有助于理解单周期 CPU 如何把“上一条指令的提交”
// 和“当前指令的取数”串接起来。
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

  // 时钟上升沿完成写回；x0 始终保持为 0，因此写地址为 0 时直接忽略。
  always_ff @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
        rf[i] <= '0;
      end
    end else if (wen && (waddr != '0)) begin
      rf[waddr] <= wdata;
    end
  end

  // 组合读端口让译码阶段可以立即拿到源寄存器的值。
  assign rs1_value = (rs1_addr == '0) ? '0 : rf[rs1_addr];
  assign rs2_value = (rs2_addr == '0) ? '0 : rf[rs2_addr];
  assign a0_value  = rf[10];

endmodule
