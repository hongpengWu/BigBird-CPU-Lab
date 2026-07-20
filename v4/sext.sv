// 教学说明：符号扩展模块把较窄的数据扩展到 32 位。
// 在 v4/v5 中它既服务于立即数/访存读数据的解释，也帮助学生理解
// “位宽变化不改数值含义”的硬件实现方式。
module sext #(
    parameter DATA_WIDTH = 1,
    parameter OUT_WIDTH = 2
) (
    input  [DATA_WIDTH-1:0] data,
    output [OUT_WIDTH-1:0]  sext_data
);

  // 复制最高位到高位空缺处，保持补码语义不变。
  assign sext_data = {{(OUT_WIDTH - DATA_WIDTH){data[DATA_WIDTH-1]}}, data};

endmodule
