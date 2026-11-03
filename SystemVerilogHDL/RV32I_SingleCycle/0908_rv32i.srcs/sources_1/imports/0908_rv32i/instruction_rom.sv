module instruction_rom(
  input   logic [31:0] instr_addr,
  output  logic [31:0] instr_code
);

  logic [31:0] instr_rom [0:15];

  //initial begin
  //  instr_rom[0] = 32'h0041_82b3;
  //  instr_rom[1] = 32'h0053_2323;
  //  instr_rom[2] = 32'h0023_8413;
  //end

  initial begin
    instr_rom[0] = 32'h0041_82b3; // add  x5, x3, x4 // R-type start
    instr_rom[1] = 32'h4032_0333; // sub  x6, x4, x3
    instr_rom[2] = 32'h0041_c3b3; // xor  x7, x3, x4
    instr_rom[3] = 32'h0041_e433; // or   x8, x3, x4
    instr_rom[4] = 32'h0041_f4b3; // and  x9, x3, x4
    instr_rom[5] = 32'h0041_9533; // sll  x10, x3, x4
    instr_rom[6] = 32'h0041_d5b3; // srl  x11, x3, x4
    instr_rom[7] = 32'h4041_d633; // sra  x12, x3, x4
    instr_rom[8] = 32'h0041_a6b3; // slt  x13, x3, x4
    instr_rom[9] = 32'h0041_b733; // sltu x14, x3, x4 // R-type end
    instr_rom[10] = 32'h0051_8023; // sb x5,0(x3) // S-type start 
    instr_rom[11] = 32'h0051_8223; // sb x6,4(x3)  
    instr_rom[12] = 32'h0051_8423; // sb x7,8(x3) // S-type send
  end

  assign instr_code = instr_rom[instr_addr[5:2]];

endmodule
