// 这个模块专门承接“加法器”角色。
// `choose_add_sub` 为 0 时执行加法，为 1 时执行减法的二补数形式:
// add_1 + (~add_2) + 1。
// 把它独立出来后，ALU 可以把多种功能复用到同一条基础算术数据通路上。
module add #(
    parameter BW = 32
) (
    input              choose_add_sub,
    input  [BW-1:0]    add_1,
    input  [BW-1:0]    add_2,
    input  [BW-1:0]    add_2_inv,
    output [BW-1:0]    result
);

  // 一行表达式对应标准二补数加/减法器。
  assign result = add_1 + (choose_add_sub ? add_2_inv : add_2) + choose_add_sub;

endmodule
