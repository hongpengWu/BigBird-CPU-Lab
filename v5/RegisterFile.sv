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
      for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1) begin
        rf[i] <= '0;
      end
    end else if (wen && (waddr != '0)) begin
      rf[waddr] <= wdata;
    end
  end

  assign rs1_value = (rs1_addr == '0) ? '0 : rf[rs1_addr];
  assign rs2_value = (rs2_addr == '0) ? '0 : rf[rs2_addr];
  assign a0_value  = rf[10];

endmodule
