`include "para.sv"

// v2 在 v1 的最小可运行 CPU 基础上，开始把数据通路拆成可复用部件:
// 1. 新增独立 ALU、RegisterFile、sext 模块，结构上更接近“真实 CPU 设计”。
// 2. 指令支持从 addi/jal 扩展到 lui/auipc/branch/R 型 add，并为 load/store/jalr 预留接口。
// 3. 顶层接口保持不变，因此可以直接复用同一套测试平台观察版本演进。
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
  // v2 仍然是单周期风格，但已经明确按 IF/ID/EX/MEM/WB 的教学分层来组织信号。
  logic [31:0] pc;

  // ==================== IF/ID: Instruction Fields ==============
  // 指令字段拆解是控制通路的起点，后续所有控制选择都由这些字段派生。
  wire [31:0] inst = irom_data;
  wire [31:0] snpc = pc + 32'd4;

  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];
  wire [4:0] rs1 = inst[19:15];
  wire [4:0] rs2 = inst[24:20];
  wire [4:0] rd = inst[11:7];

  // 各类立即数在译码阶段一次性展开，方便执行级复用。
  // 这里已经覆盖 I/S/B/U/J 五种常见格式，体现出 v2 比 v1 更完整的 ISA 视角。
  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  wire [31:0] imm_u = {inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

  // ==================== ID: Decode Result ======================
  // 这些布尔量就是“控制通路”的核心输出。
  // 注意: v2 中 load/store/jalr 端口已经留好，但当前版本仍将其钉死为 0，表示结构先行、功能后补。
  wire is_load   = 1'b0;
  wire is_op_imm = (opcode == `I1_opcode);
  wire is_jalr   = 1'b0;
  wire is_store  = 1'b0;
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
  // 与 v1 直接在顶层维护寄存器数组不同，v2 把寄存器堆独立成子模块。
  // 这样更容易看清“地址/数据/写使能”这些接口语义。
  wire [31:0] rs1_value;
  wire [31:0] rs2_value;
  wire [31:0] a0_value_unused;

  // ==================== EX: ALU Path ===========================
  // 执行级的核心思想:
  // 先把“本条指令需要什么操作数”和“ALU 应执行什么运算”编码出来，
  // 再统一交给 ALU 计算，减少散落在各处的算术逻辑。
  logic [31:0] alu_in1;
  logic [31:0] alu_in2;
  logic [3:0]  alu_choice;
  wire [31:0]  alu_res;

  // ==================== EX/WB: Control Result ==================
  // `next_pc`、`reg_write_en`、`rd_value_next` 可以视为本条指令在提交前的“决议结果”。
  logic [31:0] next_pc;
  logic        reg_write_en;
  logic [31:0] rd_value_next;
  logic        branch_taken;

  // ==================== MEM: Reserved Load Path ================
  // 虽然 v2 尚未真正打开 load 功能，但已经把字节/半字的符号扩展通路准备好。
  // 这让学生能提前看到“访存读回数据 -> 扩展 -> 写回寄存器”的完整路径形状。
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
  // 分支比较结果单独计算，强调“比较是否成立”和“下一条 PC 选哪里”是两个相关但不同的步骤。
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
  // 这段逻辑是 v2 的关键教学点:
  // 不同指令虽然语义不同，但都可以转化为“给 ALU 选输入 + 给 ALU 选操作”。
  always_comb begin
    alu_in1 = rs1_value;
    alu_in2 = rs2_value;
    alu_choice = `alu_add;

    if (is_lui) begin
      // lui 本质上是把高 20 位立即数直接送入 rd，这里用 0 + imm_u 统一到 ALU 通路。
      alu_in1 = 32'd0;
      alu_in2 = imm_u;
      alu_choice = `alu_add;
    end else if (is_auipc) begin
      // auipc 的语义是 PC 相对加法，体现“控制流地址也能进入普通算术通路”。
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
      // branch 的跳转目标靠 PC + imm_b 生成，但比较操作仍复用 ALU/操作数选择思路。
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
      alu_choice = `alu_add;
    end else if (is_op) begin
      alu_in1 = rs1_value;
      alu_in2 = rs2_value;
      alu_choice = `alu_add;
    end
  end

  // ==================== MEM/WB: Commit Select ==================
  // 这里统一决定三件事:
  // 1. 访存接口该输出什么；
  // 2. 下一条 PC 是顺序执行还是跳转目标；
  // 3. rd 最终写回什么数据。
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
      // jal 的写回数据和跳转目标来自两条不同支路，是控制流指令的典型双输出语义。
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
      // load 的接口语义:
      // `perip_addr` 给出地址，`perip_mask` 描述访问粒度，
      // 读回后根据 funct3 决定是否做符号/零扩展。
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
      // store 不写回 rd，而是把 rs2_value 沿外设写数据通路送出去。
      perip_addr = alu_res;
      perip_wen = 1'b1;
      perip_mask = funct3[1:0];
      perip_wdata = rs2_value;
    end else if (is_op_imm && (funct3 == 3'b000)) begin
      reg_write_en = 1'b1;
      rd_value_next = alu_res;
    end else if (is_op && (funct3 == 3'b000) && (funct7[5] == 1'b0)) begin
      reg_write_en = 1'b1;
      rd_value_next = alu_res;
    end else if (is_system && is_ecall) begin
      reg_write_en = 1'b0;
    end
  end

  // 真正写寄存器时仍然屏蔽 x0，保证接口行为符合 RISC-V 架构约束。
  assign rf_wen = reg_write_en && (rd != 5'd0);
  assign rf_wdata = rd_value_next;
  assign irom_addr = pc;

  // ==================== WB: Architectural Commit ===============
  // v2 依旧在单个时钟边沿提交体系结构状态；
  // 与 v1 相比，区别主要在于组合逻辑阶段已经提前把提交结果整理好了。
  always_ff @(posedge cpu_clk) begin
    if (cpu_rst) begin
      pc <= RESET_PC;
      debug_wb_have_inst <= 1'b0;
      debug_wb_pc <= 32'd0;
      debug_wb_ena <= 1'b0;
      debug_wb_reg <= 5'd0;
      debug_wb_value <= 32'd0;
    end else begin
      // debug 接口继续描述“这一拍提交的指令及其写回效果”，便于版本间对拍。
      pc <= next_pc;
      debug_wb_have_inst <= 1'b1;
      debug_wb_pc <= pc;
      debug_wb_ena <= reg_write_en;
      debug_wb_reg <= rd;
      debug_wb_value <= rd_value_next;
    end
  end

endmodule
