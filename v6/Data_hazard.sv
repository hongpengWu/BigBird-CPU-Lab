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

  assign IDU_rs1_choice = 2'b00;
  assign IDU_rs2_choice = 2'b00;

endmodule


