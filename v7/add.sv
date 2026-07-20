// 教学注释: add 是 ALU 内部复用的加/减法器，通过 `choose_add_sub` 选择执行加法还是补码减法。
// 单独拆出该模块有助于教学时说明“复杂 ALU 也可以由更小的功能块拼起来”。
module add
#(
    parameter BW=4
)
(
   input choose_add_sub,
   input [BW-1:0]add_1,
   input [BW-1:0]add_2,
   input [BW-1:0]add_2_inv,
   output [BW-1:0]result
);
// choose_add_sub=1 表示执行 add_1 - add_2，否则执行普通加法。

wire [BW-1:0]add_3;

assign add_3 = (choose_add_sub == 1'b0)? add_2:(add_2_inv + 1'b1);

assign result = add_1 + add_3;










endmodule


