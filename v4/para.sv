
// 教学说明：这里统一定义 RV32I 的主要指令类别编码。
// `myCPU.sv` 里的译码只判断这些宏，因此版本演进时可以把注意力放在
// ALU、访存和控制流本身，而不是反复追踪裸常量。
// __opcode__

`define R_opcode  7'b0110011
`define I0_opcode 7'b0000011
`define I1_opcode 7'b0010011
`define I2_opcode 7'b1100111
`define S_opcode  7'b0100011
`define B_opcode  7'b1100011
`define U0_opcode 7'b0110111
`define U1_opcode 7'b0010111
`define J_opcode  7'b1101111
`define M_opcode  7'b1110011

// 教学说明：ALU 控制码把“译码结果”翻译成“执行动作”。
// v3 先依赖这些控制码完成算术/比较，v4 在此基础上扩展访存地址计算，
// v5 则继续复用加法结果支持 jalr 等控制流跳转。
// alu
`define alu_add                   4'b0000
`define alu_sub                   4'b0001
`define alu_or                    4'b0010
`define alu_and                   4'b0011
`define alu_xor                   4'b0100
`define alu_signed_comparator     4'b0101
`define alu_unsigned_comparator   4'b0110
`define alu_equal                 4'b0111
`define alu_sll                   4'b1000
`define alu_srl                   4'b1001
`define alu_sra                   4'b1010
