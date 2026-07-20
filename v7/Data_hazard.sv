// 教学注释: Data_hazard 根据 rd/rs 相关关系给出旁路选择，是 v7 相比 v6 的核心增强。
// 若命中 EXU，则优先前递最新的 `Ex_result`；若命中 MEM，则再区分取 `MEM_Ex_result` 还是 load 返回值 `MEM_Rdata`。
// 这使得多数 RAW 相关无需停顿，只有典型 load-use 还需要 Control 再额外插入 stall。
/* Deal with the Data hazard */

module Data_hazard(
    input [4: 0] IDU_rs1,
    input [4: 0] IDU_rs2,

    input [4: 0] EXU_rd,
    input [4: 0] MEM_rd,

    input IDU_valid,
    input EXU_valid,
    input MEM_valid,

    input MEM_mem_ren,
    input EXU_R_Wen,
    input MEM_R_Wen,

    output [1: 0] IDU_rs1_choice,
    output [1: 0] IDU_rs2_choice
);

// 编码约定: 01=EXU 前递, 10=MEM 中的 ALU 结果, 11=MEM 中的 load 返回值, 00=寄存器堆原值。
assign IDU_rs1_choice = (EXU_R_Wen && (EXU_rd == IDU_rs1 && EXU_rd != 0))?
                        2'b01:(MEM_R_Wen && (MEM_rd == IDU_rs1) && (MEM_rd!=0))?
                        (MEM_mem_ren? 2'b011:2'b10):2'b000;

assign IDU_rs2_choice = (EXU_R_Wen && (EXU_rd == IDU_rs2 && EXU_rd != 0))?
                        2'b01:(MEM_R_Wen && (MEM_rd == IDU_rs2) && (MEM_rd!=0))?
                        (MEM_mem_ren? 2'b011:2'b10):2'b000;

endmodule //Aribter



