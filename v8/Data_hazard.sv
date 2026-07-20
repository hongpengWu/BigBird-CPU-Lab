/* Deal with the Data hazard */

// 前递仲裁器只负责回答一个问题：
// IDU 当前看到的 rs1/rs2，应该优先从哪个流水级取最新值。
// 编码本身不搬运数据，真正的数据多路选择在 Control 中完成。
module Data_hazard(
    input [4:0] IDU_rs1,
    input [4:0] IDU_rs2,

    input [4:0] EXU_rd,
    input [4:0] MEM_rd,
    input [4:0] MEM_PIPE_rd,
    input [4:0] MEM2_rd,
    input [4:0] WB_rd,

    input        IDU_valid,
    input        EXU_valid,
    input        MEM_valid,
    input        MEM_PIPE_valid,
    input        MEM2_valid,
    input        WB_valid,

    input        MEM_mem_ren,
    input        EXU_R_Wen,
    input        MEM_R_Wen,
    input        MEM_PIPE_R_Wen,
    input        MEM2_R_Wen,
    input        WB_R_Wen,

    output [2:0] IDU_rs1_choice,
    output [2:0] IDU_rs2_choice
);

logic exu_hit_rs1;
logic mem_hit_rs1;
logic pipe_hit_rs1;
logic mem2_hit_rs1;
logic wb_hit_rs1;
assign exu_hit_rs1 = EXU_R_Wen && (EXU_rd == IDU_rs1) && (EXU_rd != 0);
assign mem_hit_rs1 = MEM_R_Wen && (MEM_rd == IDU_rs1) && (MEM_rd != 0);
assign pipe_hit_rs1 = MEM_PIPE_R_Wen && MEM_PIPE_valid && (MEM_PIPE_rd == IDU_rs1) && (MEM_PIPE_rd != 0);
assign mem2_hit_rs1 = MEM2_R_Wen && MEM2_valid && (MEM2_rd == IDU_rs1) && (MEM2_rd != 0);
assign wb_hit_rs1  = WB_R_Wen  && (WB_rd  == IDU_rs1) && (WB_rd  != 0);
// rs1 优先级从近到远：EXU > MEM > MEM_PIPE > MEM2 > WB。
// 其中 MEM 若是 load，则当前拍数据还未真正可用，因此返回 000 交给上层做停顿处理。
assign IDU_rs1_choice = exu_hit_rs1 ? 3'b001 :
                        mem_hit_rs1 ? (MEM_mem_ren ? 3'b000 : 3'b010) :
                        pipe_hit_rs1 ? 3'b101 :
                        mem2_hit_rs1 ? 3'b011 :
                        wb_hit_rs1  ? 3'b100 : 3'b000;

logic exu_hit_rs2;
logic mem_hit_rs2;
logic pipe_hit_rs2;
logic mem2_hit_rs2;
logic wb_hit_rs2;
assign exu_hit_rs2 = EXU_R_Wen && (EXU_rd == IDU_rs2) && (EXU_rd != 0);
assign mem_hit_rs2 = MEM_R_Wen && (MEM_rd == IDU_rs2) && (MEM_rd != 0);
assign pipe_hit_rs2 = MEM_PIPE_R_Wen && MEM_PIPE_valid && (MEM_PIPE_rd == IDU_rs2) && (MEM_PIPE_rd != 0);
assign mem2_hit_rs2 = MEM2_R_Wen && MEM2_valid && (MEM2_rd == IDU_rs2) && (MEM2_rd != 0);
assign wb_hit_rs2  = WB_R_Wen  && (WB_rd  == IDU_rs2) && (WB_rd  != 0);
// rs2 采用同样的优先级编码，保证双源操作数的前递规则一致。
assign IDU_rs2_choice = exu_hit_rs2 ? 3'b001 :
                        mem_hit_rs2 ? (MEM_mem_ren ? 3'b000 : 3'b010) :
                        pipe_hit_rs2 ? 3'b101 :
                        mem2_hit_rs2 ? 3'b011 :
                        wb_hit_rs2  ? 3'b100 : 3'b000;

endmodule                                                           //Aribter
