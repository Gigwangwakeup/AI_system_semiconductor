`include "rv32i_pkg.sv"

module control_unit 
  import rv32i_pkg::*;
(
  input   logic [31:0]  instr_code,
  output  logic         rf_we,
  output  logic         rfsrc_sel,
  output  logic         alusrc_sel,
  output  logic [ 3:0]  alu_control,
  output  logic         dwe,
  output  logic         branch,
  output  logic [ 2:0]  itype // instr_type : funct3
);

  opcode_e opcode;
  logic [2:0] funct3;

  assign opcode = opcode_e'(instr_code[6:0]);

  assign funct3 = instr_code[14:12];

  always_comb begin
    rf_we       = 1'b0;
    rfsrc_sel   = 1'b0;
    alusrc_sel  = 1'b0;
    alu_control = 4'b0000;
    dwe         = 1'b0;
    branch      = 1'b0;
    itype       = 3'b010; // Store Word(SW),LW
    case(opcode)
      OP_RTYPE : begin // R-type
        rf_we       = 1'b1;
        rfsrc_sel   = 1'b0;
        alusrc_sel  = 1'b0;
        alu_control = {instr_code[30],funct3};
        dwe         = 1'b0;
        branch      = 1'b0;
        itype       = 3'b000; // SW,LW
      end
      OP_STYPE : begin // S-type
        rf_we       = 1'b0;
        rfsrc_sel   = 1'b0;
        alusrc_sel  = 1'b1;
        alu_control = 4'd0;
        dwe         = 1'b1;
        branch      = 1'b0;
        itype       = funct3; //SW,LW
      end
      OP_ITYPE : begin // I-type
        rf_we       = 1'b1;
        rfsrc_sel   = 1'b0;
        alusrc_sel  = 1'b1;
        if(funct3 == 3'b101)
          alu_control = {instr_code[30],funct3};
        else
          alu_control = {1'b0,funct3};
        dwe         = 1'b0;
        branch      = 1'b0;
        itype       = 3'b111; // for : data_mem
      end
      OP_ILTYPE : begin // IL-type
        rf_we       = 1'b1;
        rfsrc_sel   = 1'b1;
        alusrc_sel  = 1'b1;
        alu_control = {1'b0,funct3};
        dwe         = 1'b0;
        branch      = 1'b0;
        itype       = funct3; //SW,LW
      end
      OP_BTYPE : begin // B-type
        branch      = 1'b1;
      end
    endcase
  end
endmodule
