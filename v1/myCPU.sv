`include "para.sv"

// v1 是最小可运行 CPU:
// 1. 数据通路全部收在一个顶层模块里，没有拆分出独立 ALU/寄存器堆子模块。
// 2. 仅支持 addi、jal、ecall，便于先建立 "取指 -> 译码 -> 执行 -> 写回" 的基本认知。
// 3. 对外接口已经与后续版本保持一致，方便测试平台和后续版本平滑衔接。
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

  // `cdp-tests` 的指令镜像从 PC=0 开始取值，因此复位地址固定为 0。
  localparam RESET_PC = 32'h0000_0000;

  // ==================== IF: Program Counter ====================
  // v1 的取指级只有一个核心状态: pc。
  // 它既是当前指令地址，也是整条数据通路向前推进的起点。
  logic [31:0] pc;

  // ==================== ID: Register State =====================
  // 这里直接在顶层维护 32 个通用寄存器。
  // 到 v2 开始，这部分会被抽象成独立的 RegisterFile 模块。
  logic [31:0] rf[0:31];
  integer i;

  // ==================== IF/ID: Instruction Fields ==============
  // `inst` 是从指令存储器读回的 32 位指令。
  // `snpc` 表示顺序执行时的下一条 PC（static next pc）。
  wire [31:0] inst = irom_data;
  wire [31:0] snpc = pc + 32'd4;

  // 先切出常用字段，后面译码和数据选择都围绕这些字段展开。
  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [4:0] rs1 = inst[19:15];
  wire [4:0] rd = inst[11:7];

  // v1 只需要读 rs1，所以寄存器读端口也非常简化。
  // x0 按 RISC-V 约定恒为 0，不从寄存器数组里真正取值。
  wire [31:0] rs1_value = (rs1 == 5'd0) ? 32'd0 : rf[rs1];
  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

  // ==================== ID: Decode Result ======================
  // 译码结果直接变成布尔控制信号，驱动后面的执行与写回选择。
  wire is_addi = (opcode == `I1_opcode) && (funct3 == 3'b000);
  wire is_jal = (opcode == `J_opcode);
  wire is_ecall = (inst == 32'h0000_0073);

  // v1 中只有 addi / jal 会向 rd 写回结果。
  wire will_write_rd = is_addi || is_jal;

  // ==================== EX: Execute / Next PC ==================
  // `rd_value` 是本条指令最终要写回寄存器堆的数据。
  // `dnpc` 是 dynamic next pc，即真正生效的下一条 PC。
  logic [31:0] rd_value;
  logic [31:0] dnpc;

  always @(*) begin
    rd_value = 32'd0;
    dnpc = snpc;

    if (is_addi) begin
      // addi 的数据通路: rs1_value + imm_i -> rd_value
      rd_value = rs1_value + imm_i;
    end else if (is_jal) begin
      // jal 同时完成两件事:
      // 1. 把返回地址 snpc 写回 rd；
      // 2. 把 pc 跳到目标地址 pc + imm_j。
      rd_value = snpc;
      dnpc = pc + imm_j;
    end
  end

  // ==================== MEM: External Memory ===================
  // v1 尚未接入真正的数据存储器访问，外设侧接口全部拉成空操作。
  // 但端口语义已经固定下来，后续版本会在不改顶层接口的前提下逐步启用。
  assign irom_addr = pc;

  assign perip_addr = 32'd0;
  assign perip_wen = 1'b0;
  assign perip_mask = 2'b00;
  assign perip_wdata = 32'd0;

  // ==================== WB: Commit / Debug =====================
  // 时钟上升沿完成体系结构状态提交:
  // 1. 更新 pc；
  // 2. 条件写回寄存器堆；
  // 3. 输出调试端口，供测试框架观测提交结果。
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
      // debug_* 端口的语义是“这一拍提交了什么”。
      // 后续版本虽然内部结构更复杂，但提交口保持一致。
      debug_wb_have_inst <= 1'b1;
      debug_wb_pc <= pc;
      debug_wb_ena <= will_write_rd;
      debug_wb_reg <= rd;
      debug_wb_value <= rd_value;

      if (will_write_rd && (rd != 5'd0)) begin
        // x0 仍然不可写，这里保证和 RISC-V 架构语义一致。
        rf[rd] <= rd_value;
      end

      pc <= dnpc;
    end
  end

endmodule
