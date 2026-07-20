`include "para.sv"

module myCPU (
    input cpu_clk,
    input cpu_rst,

    output [31:0] irom_addr,
    input  [31:0] irom_data,

    output logic [31:0] perip_addr,
    output logic        perip_wen,
    output logic [ 1:0] perip_mask,
    output logic [31:0] perip_wdata,
    input  [31:0] perip_rdata,

    output logic        debug_wb_have_inst,
    output logic [31:0] debug_wb_pc,
    output logic        debug_wb_ena,
    output logic [ 4:0] debug_wb_reg,
    output logic [31:0] debug_wb_value
);

  localparam RESET_PC = 32'h0000_0000;

  // ==================== IF: Program Counter ====================
  logic [31:0] pc;

  // ==================== IF/ID: Instruction Fields ==============
  wire [31:0] inst = irom_data;
  wire [31:0] snpc = pc + 32'd4;

  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];
  wire [4:0] rs1 = inst[19:15];
  wire [4:0] rs2 = inst[24:20];
  wire [4:0] rd = inst[11:7];

  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  wire [31:0] imm_u = {inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

  // ==================== ID: Decode Result ======================
  wire is_load   = (opcode == `I0_opcode);
  wire is_op_imm = (opcode == `I1_opcode);
  wire is_jalr   = 1'b0;
  wire is_store  = (opcode == `S_opcode);
  wire is_branch = (opcode == `B_opcode);
  wire is_lui    = (opcode == `U0_opcode);
  wire is_auipc  = (opcode == `U1_opcode);
  wire is_jal    = (opcode == `J_opcode);
  wire is_op     = (opcode == `R_opcode);
  wire is_system = (opcode == `M_opcode);
  wire is_ecall  = (inst == 32'h0000_0073);

  logic        rf_wen;
  logic [31:0] rf_wdata;

  // ==================== ID: Register File ======================
  wire [31:0] rs1_value;
  wire [31:0] rs2_value;
  wire [31:0] a0_value_unused;

  // ==================== EX: ALU Path ===========================
  logic [31:0] alu_in1;
  logic [31:0] alu_in2;
  logic [3:0]  alu_choice;
  wire [31:0]  alu_res;

  // ==================== EX/WB: Control Result ==================
  logic [31:0] next_pc;
  logic        reg_write_en;
  logic [31:0] rd_value_next;
  logic        branch_taken;

  // ==================== MEM: Load Extension ====================
  wire [31:0] load_i8;
  wire [31:0] load_i16;

  sext #(
      .DATA_WIDTH(8),
      .OUT_WIDTH(32)
  ) sext_i8 (
      .data(perip_rdata[7:0]),
      .sext_data(load_i8)
  );

  sext #(
      .DATA_WIDTH(16),
      .OUT_WIDTH(32)
  ) sext_i16 (
      .data(perip_rdata[15:0]),
      .sext_data(load_i16)
  );

  RegisterFile #(
      .ADDR_WIDTH(5),
      .DATA_WIDTH(32)
  ) regfile_inst (
      .clock(cpu_clk),
      .reset(cpu_rst),
      .wen(rf_wen),
      .waddr(rd),
      .wdata(rf_wdata),
      .rs1_addr(rs1),
      .rs2_addr(rs2),
      .rs1_value(rs1_value),
      .rs2_value(rs2_value),
      .a0_value(a0_value_unused)
  );

  ALU #(
      .BW(32)
  ) alu_inst (
      .d1(alu_in1),
      .d2(alu_in2),
      .choice(alu_choice),
      .res(alu_res)
  );

  // ==================== EX: Branch Decision ====================
  always_comb begin
    branch_taken = 1'b0;
    unique case (funct3)
      3'b000:  branch_taken = (rs1_value == rs2_value);                    // beq
      3'b001:  branch_taken = (rs1_value != rs2_value);                    // bne
      3'b100:  branch_taken = ($signed(rs1_value) < $signed(rs2_value));   // blt
      3'b101:  branch_taken = ($signed(rs1_value) >= $signed(rs2_value));  // bge
      3'b110:  branch_taken = (rs1_value < rs2_value);                     // bltu
      3'b111:  branch_taken = (rs1_value >= rs2_value);                    // bgeu
      default: branch_taken = 1'b0;
    endcase
  end

  // ==================== EX: ALU Input Select ===================
  always_comb begin
    alu_in1 = rs1_value;
    alu_in2 = rs2_value;
    alu_choice = `alu_add;

    if (is_lui) begin
      alu_in1 = 32'd0;
      alu_in2 = imm_u;
      alu_choice = `alu_add;
    end else if (is_auipc) begin
      alu_in1 = pc;
      alu_in2 = imm_u;
      alu_choice = `alu_add;
    end else if (is_jal) begin
      alu_in1 = pc;
      alu_in2 = imm_j;
      alu_choice = `alu_add;
    end else if (is_jalr) begin
      alu_in1 = rs1_value;
      alu_in2 = imm_i;
      alu_choice = `alu_add;
    end else if (is_branch) begin
      alu_in1 = rs1_value;
      alu_in2 = rs2_value;
      alu_choice = `alu_sub;
    end else if (is_load) begin
      alu_in1 = rs1_value;
      alu_in2 = imm_i;
      alu_choice = `alu_add;
    end else if (is_store) begin
      alu_in1 = rs1_value;
      alu_in2 = imm_s;
      alu_choice = `alu_add;
    end else if (is_op_imm) begin
      alu_in1 = rs1_value;
      alu_in2 = imm_i;
      unique case (funct3)
        3'b000: alu_choice = `alu_add;
        3'b010: alu_choice = `alu_signed_comparator;
        3'b011: alu_choice = `alu_unsigned_comparator;
        3'b100: alu_choice = `alu_xor;
        3'b110: alu_choice = `alu_or;
        3'b111: alu_choice = `alu_and;
        3'b001: begin
          alu_in2 = {27'd0, rs2};
          alu_choice = `alu_sll;
        end
        3'b101: begin
          alu_in2 = {27'd0, rs2};
          alu_choice = funct7[5] ? `alu_sra : `alu_srl;
        end
        default: alu_choice = `alu_add;
      endcase
    end else if (is_op) begin
      alu_in1 = rs1_value;
      alu_in2 = rs2_value;
      unique case (funct3)
        3'b000: alu_choice = funct7[5] ? `alu_sub : `alu_add;
        3'b001: alu_choice = `alu_sll;
        3'b010: alu_choice = `alu_signed_comparator;
        3'b011: alu_choice = `alu_unsigned_comparator;
        3'b100: alu_choice = `alu_xor;
        3'b101: alu_choice = funct7[5] ? `alu_sra : `alu_srl;
        3'b110: alu_choice = `alu_or;
        3'b111: alu_choice = `alu_and;
        default: alu_choice = `alu_add;
      endcase
    end
  end

  // ==================== MEM/WB: Commit Select ==================
  always_comb begin
    perip_addr = 32'd0;
    perip_wen = 1'b0;
    perip_mask = 2'b10;
    perip_wdata = rs2_value;

    next_pc = snpc;
    reg_write_en = 1'b0;
    rd_value_next = 32'd0;

    if (is_lui) begin
      reg_write_en = 1'b1;
      rd_value_next = imm_u;
    end else if (is_auipc) begin
      reg_write_en = 1'b1;
      rd_value_next = alu_res;
    end else if (is_jal) begin
      reg_write_en = 1'b1;
      rd_value_next = snpc;
      next_pc = pc + imm_j;
    end else if (is_jalr) begin
      reg_write_en = 1'b1;
      rd_value_next = snpc;
      next_pc = {alu_res[31:1], 1'b0};
    end else if (is_branch) begin
      if (branch_taken) begin
        next_pc = pc + imm_b;
      end
    end else if (is_load) begin
      reg_write_en = 1'b1;
      perip_addr = alu_res;
      perip_mask = funct3[1:0];
      unique case (funct3)
        3'b000: rd_value_next = load_i8;
        3'b001: rd_value_next = load_i16;
        3'b010: rd_value_next = perip_rdata;
        3'b100: rd_value_next = {24'd0, perip_rdata[7:0]};
        3'b101: rd_value_next = {16'd0, perip_rdata[15:0]};
        default: rd_value_next = 32'd0;
      endcase
    end else if (is_store) begin
      perip_addr = alu_res;
      perip_wen = 1'b1;
      perip_mask = funct3[1:0];
      perip_wdata = rs2_value;
    end else if (is_op_imm || is_op) begin
      reg_write_en = 1'b1;
      rd_value_next = alu_res;
    end else if (is_system && is_ecall) begin
      reg_write_en = 1'b0;
    end
  end

  assign rf_wen = reg_write_en && (rd != 5'd0);
  assign rf_wdata = rd_value_next;
  assign irom_addr = pc;

  // ==================== WB: Architectural Commit ===============
  always_ff @(posedge cpu_clk) begin
    if (cpu_rst) begin
      pc <= RESET_PC;
      debug_wb_have_inst <= 1'b0;
      debug_wb_pc <= 32'd0;
      debug_wb_ena <= 1'b0;
      debug_wb_reg <= 5'd0;
      debug_wb_value <= 32'd0;
    end else begin
      pc <= next_pc;
      debug_wb_have_inst <= 1'b1;
      debug_wb_pc <= pc;
      debug_wb_ena <= reg_write_en;
      debug_wb_reg <= rd;
      debug_wb_value <= rd_value_next;
    end
  end

endmodule
