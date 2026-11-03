module instruction_rom (
  input  logic [31:0] instr_addr,

  output logic [31:0] instr_code
);

  logic [31:0] instr_rom [0:127];

`ifdef SIMULATION_TEST
  initial begin
    instr_rom[0] = 32'h0041_82b3;   // add x5, x3, x4
    instr_rom[1] = 32'h0053_2323;   // sw x6, 6(x6)
    instr_rom[2] = 32'h0023_8413;   // addi x8, x7, 2
    instr_rom[3] = 32'h0063_2503;   // lw x10, 6(x6)
    instr_rom[4] = 32'hfe62_8ce3;   // beq x5, x6, -8
    instr_rom[5] = 32'hfe62_9ce3;   // bne x5, x6, -8
  end
 `endif


  initial
 // $readmemh(" ./rtl/rom_code.mem", instr_rom,0,18);

  $readmemh("rom_code_apb_gpio.mem", instr_rom,0,127);


 // initial begin
   // instr_rom[0]  = 32'h0032_00b3;   //add, rd = 1, rs1 = 4, rs2 = 3
   // instr_rom[1]  = 32'h4032_0133;   //sub, rd = 2, rs1 = 4, rs2 = 3
   // instr_rom[2]  = 32'h0032_11b3;   //sll, rd = 3, rs1 = 4, rs2 = 3
   // instr_rom[3]  = 32'h0032_2233;   //slt, rd = 4, rs1 = 4, rs2 = 3
   // instr_rom[4]  = 32'h0032_32b3;   //sltu,rd = 5, rs1 = 4, rs2 = 3
   // instr_rom[5]  = 32'h0032_4333;   //xor, rd = 6, rs1 = 4, rs2 = 3
   // instr_rom[6]  = 32'h0032_53b3;   //srl, rd = 7, rs1 = 4, rs2 = 3
   // instr_rom[7]  = 32'h4032_5433;   //sra, rd = 8, rs1 = 4, rs2 = 3
   // instr_rom[8]  = 32'h0032_64b3;   //or,  rd = 9, rs1 = 4, rs2 = 3
   // instr_rom[9]  = 32'h0032_7533;  //and, rd = 10, rs1 = 4, rs2 = 3
   // instr_rom[10]  = 32'h0032_02a3;  //imm = 5, rs1 = 4, rs2 = 3, funct3 = 000, SB
   // instr_rom[11]  = 32'h0032_12a3; //imm = 5, rs1 = 4, rs2 = 3, funct3 = 001, SH
   // instr_rom[12]  = 32'h0032_22a3; //imm = 5, rs1 = 4, rs2 = 3, funct3 = 010, SW
 // end

  assign instr_code = instr_rom[instr_addr[31:2]];

  endmodule

