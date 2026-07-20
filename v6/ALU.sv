`include "para.sv"
`timescale 1ns / 1ps

// 教学注释: ALU 负责执行算术、逻辑、比较和移位等操作，是 EXU 的核心组合逻辑。
// 与 v5 相比，ALU 本体功能变化不大，真正的变化在于它现在被放进流水线执行级，并受前后级控制信号驱动。
module ALU #(
    parameter BW = 32
)
(
    input clock,
    input [BW-1: 0] d1,
    input [BW-1: 0] d2,
    input [3: 0] choice,
    output logic [BW-1: 0] res
);

    logic choose_add_sub;
    logic [BW-1: 0] result;
    logic [BW-1: 0] d2_inv;
    logic [BW-1: 0] d1_inv;
    assign d2_inv = ~d2;
    assign d1_inv = ~d1;

// choice 来自 IDU 译码后的 ALU 操作码，EXU 只需把操作数与操作类型送进来。
always@(*)
    begin
    res = 0;
    case(choice)
    `alu_signed_comparator:begin                      // 比较大小
            choose_add_sub = 1'b1;
            if(d1[BW-1] != d2[BW-1])
                begin
                    if(d1[BW-1] == 1'b1)
                        res[0] = 1;
                    else
                        res[0] = 0;
                end
            else
                begin
                    if(result[BW-1] == 1'b1)
                        res[0] = 1;
                    else
                        res[0] = 0;
                end
            end
    `alu_unsigned_comparator:begin
                choose_add_sub = 1'b0;
                if(d1 < d2)
                    res[0] = 1;
                else
                    res[0] = 0;
            end
    `alu_add: begin                                   //加法
            choose_add_sub = 1'b0;
            res = result;
            end
    `alu_sub: begin                                   //减法
            choose_add_sub = 1'b1;
            res = result;
            end
    `alu_and: begin                                   //�?
            res = d1 & d2;
            choose_add_sub = 1'b0;
            end
    `alu_or: begin                                    //�?
            res = d1 | d2;
            choose_add_sub = 1'b0;
            end
    `alu_xor: begin                                   //异或
            res = (d1 & d2_inv) | (d1_inv & d2);
            choose_add_sub = 1'b0;
            end
    `alu_equal:begin                                  //是否相等
            choose_add_sub = 1'b0;
            if(d1 != d2)
                res[0] = 1;
            else
                res[0] = 0;
            end
    `alu_sll:begin                                    //逻辑左移
            choose_add_sub = 1'b0;
            res = d1<<d2[4:0];
    end
    `alu_srl:begin                                    //逻辑右移
            choose_add_sub = 1'b0;
            res = {{{BW{1'b0}},d1}>>d2[4:0]};                       //[31:0];
    end
    `alu_sra:begin                                    //算术右移
            choose_add_sub = 1'b0;
            res = {{{BW{d1[BW-1]}},d1}>>d2[4:0]};                   //[31:0];
    end
    default:begin
            choose_add_sub = 1'b0;
            res = 0;
    end
    endcase
    
end

// add 子模块统一承担加/减法底层实现，比较类操作也会间接复用它的结果。
add
#(
    .BW(BW)
)add_inst0
(
    .choose_add_sub(choose_add_sub),
    .add_1(d1),
    .add_2(d2),
    .add_2_inv(d2_inv),
    .result(result)
);


endmodule

