// 教学说明：这是 ALU 内部复用的加/减法器。
// 当 `choose_add_sub=0` 时执行加法，可用于普通运算、PC+4、访存地址生成；
// 当 `choose_add_sub=1` 时通过补码形式执行减法，为比较和分支判断提供基础。
module add #(
    parameter BW = 32
) (
    input              choose_add_sub,
    input  [BW-1:0]    add_1,
    input  [BW-1:0]    add_2,
    input  [BW-1:0]    add_2_inv,
    output [BW-1:0]    result
);

  // 二选一地送入原操作数或按位取反后的操作数，再补上进位 1，即可共用一套加法器。
  assign result = add_1 + (choose_add_sub ? add_2_inv : add_2) + choose_add_sub;

endmodule
