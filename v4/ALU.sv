`include "para.sv"

// 教学说明：ALU 是 v3-v5 里最核心的执行单元。
// v3 主要依赖它完成算术、逻辑和分支比较；
// v4 在此基础上把“基址 + 偏移”用于访存地址；
// v5 又继续复用加法结果支持 jalr 等控制流跳转目标的生成。
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

  assign d2_inv = ~d2;
  assign d1_inv = ~d1;

  // 组合逻辑根据 `choice` 选择运算类型；大多数操作最终都围绕加法器或位运算展开。
  always_comb begin
    choose_add_sub = 1'b0;
    res = '0;
    unique case (choice)
      // 有符号比较通过“做减法后看符号位”实现，是分支判断的重要基础。
      `alu_signed_comparator: begin
        choose_add_sub = 1'b1;
        res[0] = (d1[BW-1] != d2[BW-1]) ? d1[BW-1] : add_result[BW-1];
      end
      `alu_unsigned_comparator: begin
        res[0] = (d1 < d2);
      end
      `alu_add: begin
        res = add_result;
      end
      `alu_sub: begin
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

  // 底层加法器被复用给 add/sub 以及比较类运算，体现了硬件里“共享数据通路”的思路。
  add #(
      .BW(BW)
  ) add_inst0 (
      .choose_add_sub(choose_add_sub),
      .add_1(d1),
      .add_2(d2),
      .add_2_inv(d2_inv),
      .result(add_result)
  );

endmodule
