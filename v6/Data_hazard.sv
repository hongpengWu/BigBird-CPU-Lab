// 教学注释: Data_hazard 预留了数据相关仲裁接口，但 v6 版尚未实现真正的选择逻辑。
// 两个输出恒为 `00`，等价于“总是直接使用寄存器堆读值”，因此本版主要用于说明接口形状。
// 到 v7 时，这里会真正决定 rs1/rs2 该从 EXU 结果、MEM 结果还是寄存器堆取值。
module Data_hazard(
    input [4:0] IDU_rs1,
    input [4:0] IDU_rs2,
    input [4:0] EXU_rd,
    input [4:0] MEM_rd,
    input IDU_valid,
    input EXU_valid,
    input MEM_valid,
    input MEM_mem_ren,
    input EXU_R_Wen,
    input MEM_R_Wen,
    output [1:0] IDU_rs1_choice,
    output [1:0] IDU_rs2_choice
);

  // `00` 表示直接使用寄存器堆读值；v6 暂不做 EX/MEM 旁路。
  assign IDU_rs1_choice = 2'b00;
  assign IDU_rs2_choice = 2'b00;

endmodule


