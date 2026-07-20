
// v1/v2 共用的基础参数定义文件。
// 教学上可以把它理解为“控制编码字典”:
// 1. opcode 宏用于快速完成主译码；
// 2. alu_* 宏用于在数据通路里描述 ALU 要执行的具体操作。
// 这些宏本身不产生硬件逻辑，只是让上层连线和 case 选择更清晰。

// __opcode__
// 不同指令大类在指令[6:0]上的编码。

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

// alu
// ALU 控制码。v1 还没把 ALU 模块独立出来，但从 v2 起会正式使用这组编码。
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
