// 通用符号扩展模块。
// 它把较窄位宽的数据扩展到更宽位宽，并复制最高位作为符号位。
// 在 CPU 数据通路里，这类模块常用于:
// - 立即数扩展；
// - load 指令读回后的字节/半字符号扩展。
module sext #(
    parameter DATA_WIDTH = 1,
    parameter OUT_WIDTH = 2
) (
    input  [DATA_WIDTH-1:0] data,
    output [OUT_WIDTH-1:0]  sext_data
);

  // 复制输入最高位到高位区间，保持补码数值语义不变。
  assign sext_data = {{(OUT_WIDTH - DATA_WIDTH){data[DATA_WIDTH-1]}}, data};

endmodule
