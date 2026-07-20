`include "para.sv"

// v2 将 ALU 单独拆出，标志着数据通路从“顶层直接写表达式”
// 演进为“控制选择 + 功能模块”的组织方式。
// 从接口语义看:
// - `d1` / `d2` 是两个操作数输入；
// - `choice` 指定本次应执行的运算；
// - `res` 是统一的执行结果输出。
module ALU #(
    parameter BW = 32
) (
    input  [BW-1:0]       d1,
    input  [BW-1:0]       d2,
    input  [3:0]          choice,
    output logic [BW-1:0] res
);

  logic choose_add_sub;
  logic [BW-1:0] add_result;
  logic [BW-1:0] d2_inv;
  logic [BW-1:0] d1_inv;

  // 为了复用同一个加法器实现加法/减法，先准备按位取反结果。
  assign d2_inv = ~d2;
  assign d1_inv = ~d1;

  always_comb begin
    choose_add_sub = 1'b0;
    res = '0;
    unique case (choice)
      `alu_signed_comparator: begin
        // 有符号比较可转化为减法结果符号位的分析。
        choose_add_sub = 1'b1;
        res[0] = (d1[BW-1] != d2[BW-1]) ? d1[BW-1] : add_result[BW-1];
      end
      `alu_unsigned_comparator: begin
        // 无符号比较直接按无符号数值比较。
        res[0] = (d1 < d2);
      end
      `alu_add: begin
        res = add_result;
      end
      `alu_sub: begin
        // 选择减法时，底层 add 模块会执行 d1 + (~d2) + 1。
        choose_add_sub = 1'b1;
        res = add_result;
      end
      `alu_and: begin
        res = d1 & d2;
      end
      `alu_or: begin
        res = d1 | d2;
      end
      `alu_xor: begin
        // 这里手写了异或逻辑，便于教学中观察布尔代数展开形式。
        res = (d1 & d2_inv) | (d1_inv & d2);
      end
      `alu_equal: begin
        res[0] = (d1 != d2);
      end
      `alu_sll: begin
        res = d1 << d2[4:0];
      end
      `alu_srl: begin
        res = d1 >> d2[4:0];
      end
      `alu_sra: begin
        res = $signed(d1) >>> d2[4:0];
      end
      default: begin
        res = '0;
      end
    endcase
  end

  add #(
      .BW(BW)
  ) add_inst0 (
      // add 子模块是 ALU 中最核心的算术单元，
      // 比较、加法、减法都会通过它复用部分硬件。
      .choose_add_sub(choose_add_sub),
      .add_1(d1),
      .add_2(d2),
      .add_2_inv(d2_inv),
      .result(add_result)
  );

endmodule
