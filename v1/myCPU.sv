`include "para.sv"

module myCPU (
    input cpu_clk,
    input cpu_rst,

    output [31:0] irom_addr,
    input  [31:0] irom_data,

    output [31:0] perip_addr,
    output        perip_wen,
    output [ 1:0] perip_mask,
    output [31:0] perip_wdata,
    input  [31:0] perip_rdata,

    output logic        debug_wb_have_inst,
    output logic [31:0] debug_wb_pc,
    output logic        debug_wb_ena,
    output logic [ 4:0] debug_wb_reg,
    output logic [31:0] debug_wb_value
);

  // For `cdp-tests`, the instruction image is indexed from PC=0.
  localparam RESET_PC = 32'h0000_0000;

  // ==================== IF: Program Counter ====================
  logic [31:0] pc;

  // ==================== ID: Register State =====================
  logic [31:0] rf[0:31];
  integer i;

  // ==================== IF/ID: Instruction Fields ==============
  wire [31:0] inst = irom_data;
  wire [31:0] snpc = pc + 32'd4;

  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [4:0] rs1 = inst[19:15];
  wire [4:0] rd = inst[11:7];

  wire [31:0] rs1_value = (rs1 == 5'd0) ? 32'd0 : rf[rs1];
  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

  // ==================== ID: Decode Result ======================
  wire is_addi = (opcode == `I1_opcode) && (funct3 == 3'b000);
  wire is_jal = (opcode == `J_opcode);
  wire is_ecall = (inst == 32'h0000_0073);

  wire will_write_rd = is_addi || is_jal;

  // ==================== EX: Execute / Next PC ==================
  logic [31:0] rd_value;
  logic [31:0] dnpc;

  always @(*) begin
    rd_value = 32'd0;
    dnpc = snpc;

    if (is_addi) begin
      rd_value = rs1_value + imm_i;
    end else if (is_jal) begin
      rd_value = snpc;
      dnpc = pc + imm_j;
    end
  end

  // ==================== MEM: External Memory ===================
  assign irom_addr = pc;

  assign perip_addr = 32'd0;
  assign perip_wen = 1'b0;
  assign perip_mask = 2'b00;
  assign perip_wdata = 32'd0;

  // ==================== WB: Commit / Debug =====================
  always @(posedge cpu_clk) begin
    if (cpu_rst) begin
      pc <= RESET_PC;
      debug_wb_have_inst <= 1'b0;
      debug_wb_pc <= 32'd0;
      debug_wb_ena <= 1'b0;
      debug_wb_reg <= 5'd0;
      debug_wb_value <= 32'd0;
      for (i = 0; i < 32; i = i + 1) begin
        rf[i] <= 32'd0;
      end
    end else begin
      debug_wb_have_inst <= 1'b1;
      debug_wb_pc <= pc;
      debug_wb_ena <= will_write_rd;
      debug_wb_reg <= rd;
      debug_wb_value <= rd_value;

      if (will_write_rd && (rd != 5'd0)) begin
        rf[rd] <= rd_value;
      end

      pc <= dnpc;
    end
  end

endmodule
