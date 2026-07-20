`timescale 1ns / 1ps

// 教学注释: LSU 负责把 EXU 产生的地址与访存控制映射到外设总线，同时完成 load 数据扩展。
// 从教学角度看，LSU 也是 EX/MEM 级间寄存器: 地址、rd、csr_wen、jump_flag 等都会在这里锁存一拍。
// v5 中访存与写回选择混在一起；v6/v7 则把“发起访存”和“选择写回值”明确拆到了 LSU/WBU 两级。
module LSU (
    input clock,
    input reset,

    input mem_ren,
    input mem_wen,
    input R_wen,
    input [3:0] csr_wen,
    input [31:0] Ex_result,
    input [4:0] rd,
    input [2:0] funct3,
    input [31:0] rs2_value,
    input jump_flag,
    input [31:0] rd_value,
    input [31:0] pc,

    output [31:0] rd_value_next,
    output R_wen_next,
    output logic [31:0] LSU_Rdata,
    output [3:0] csr_wen_next,
    output [31:0] Ex_result_next,
    output [4:0] rd_next,
    output mem_ren_next,
    output jump_flag_next,

    output logic [31:0] pc_out,
    output [31:0] addr,
    output wen,
    output [31:0] wdata,
    output [1:0] mask,
    input [31:0] rdata,

    input valid_last,
    output logic ready_last,

    input ready_next,
    output logic valid_next
);

    logic [31:0] rdata_8i;
    logic [31:0] rdata_16i;
    logic [31:0] rdata_8u;
    logic [31:0] rdata_16u;

    logic [4:0] rdata_b_choice;

    logic [31:0] rdata_ex;
    logic mem_ren_reg;
    logic mem_wen_reg;
    logic R_wen_reg;
    logic [3:0] csr_wen_reg;
    logic [31:0] Ex_result_reg;
    logic [31:0] rd_value_reg;
    logic [4:0] rd_reg;
    logic [2:0] funct3_reg;
    logic [31:0] rs2_value_reg;
    logic jump_flag_reg;
    logic valid_last_reg;

    // LSU 把 EXU 的有效位再延后一拍，对应 EX/MEM -> MEM/WB 之间的流动。
    always @(posedge clock) begin
        if (reset) valid_next <= 1'b0;
        else valid_next <= valid_last;
    end
    
    always @(posedge clock) begin
        if (reset) pc_out <= 0;
        else if (ready_last & valid_last) pc_out <= pc;
    end

    always @(posedge clock) begin
        if (reset) begin
            mem_ren_reg <= 0;
            mem_wen_reg <= 0;
            R_wen_reg <= 0;
            csr_wen_reg <= 0;
            Ex_result_reg <= 0;
            rd_value_reg <= 0;
            rd_reg <= 0;
            funct3_reg <= 0;
            rs2_value_reg <= 0;
            jump_flag_reg <= 0;
        end else if (valid_last & ready_last) begin
            mem_ren_reg <= mem_ren;
            mem_wen_reg <= mem_wen;
            R_wen_reg <= R_wen;
            csr_wen_reg <= csr_wen;
            Ex_result_reg <= Ex_result;
            rd_value_reg <= rd_value;
            rd_reg <= rd;
            funct3_reg <= funct3;
            rs2_value_reg <= rs2_value;
            jump_flag_reg <= jump_flag;
        end
    end

    assign ready_last = ready_next;
    // 对外总线地址来自 EXU 计算出的有效地址。
    assign addr = Ex_result_reg;
    assign wdata = rs2_value_reg;
    assign LSU_Rdata = rdata_ex;
    assign wen = mem_wen_reg;

    // store/load 的字节宽度直接复用 funct3 低两位。
    assign mask = funct3_reg[1:0];

    assign Ex_result_next = Ex_result_reg;
    assign rd_value_next = rd_value_reg;
    assign rd_next = rd_reg;
    assign mem_ren_next = mem_ren_reg;

    assign R_wen_next = R_wen_reg;
    assign jump_flag_next = jump_flag_reg;
    assign csr_wen_next = csr_wen_reg;

    // load 指令在这里完成字节/半字的符号或零扩展。
    always @(*) begin
        case (funct3_reg)
            3'b000: rdata_ex = rdata_8i;  // lb
            3'b001: rdata_ex = rdata_16i;  // lh
            3'b010: rdata_ex = rdata;  // lw
            3'b100: rdata_ex = rdata_8u;  // lbu
            3'b101: rdata_ex = rdata_16u;  // lhu
            default: rdata_ex = 0;
        endcase
    end

    assign rdata_8u = {24'd0, rdata[7:0]};
    assign rdata_16u = {16'd0, rdata[15:0]};

/* verilator lint_off PINMISSING */
    sext #(
        .DATA_WIDTH(8),
        .OUT_WIDTH(32)
    ) sext_i8 (
        .data(rdata[0+:8]),
        .sext_data(rdata_8i)
    );

    sext #(
        .DATA_WIDTH(16),
        .OUT_WIDTH(32)
    ) sext_i16 (
        .data(rdata[0+:16]),
        .sext_data(rdata_16i)
    );

endmodule  //MEM

