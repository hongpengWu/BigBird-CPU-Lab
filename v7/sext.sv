// 教学注释: sext 是通用符号扩展器，常用于 load 的字节/半字扩展。
// 它本身与流水线无关，但在 LSU 中承担把外设读回值恢复成 RV32 语义的工作。
module sext#
(
    parameter DATA_WIDTH=1,
    parameter OUT_WIDTH=2
)
(
    input [DATA_WIDTH-1:0]data,
    output [OUT_WIDTH-1:0]sext_data
);

// 把输入最高位复制到高位，得到标准的符号扩展结果。
assign sext_data = {{(OUT_WIDTH-DATA_WIDTH){data[DATA_WIDTH-1]}},data};

endmodule

