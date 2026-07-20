module add #(
    parameter BW = 32
) (
    input              choose_add_sub,
    input  [BW-1:0]    add_1,
    input  [BW-1:0]    add_2,
    input  [BW-1:0]    add_2_inv,
    output [BW-1:0]    result
);

  assign result = add_1 + (choose_add_sub ? add_2_inv : add_2) + choose_add_sub;

endmodule
