`define SIMULATION

module datapath(
  input   logic         clk,
  input   logic         rstn,
  input   logic         branch,
  input   logic         rf_we,
  input   logic         rfsrc_sel,
  input   logic         alusrc_sel,
  input   logic [3:0]   alu_control,
  input   logic [31:0]  drdata,
  input   logic [31:0]  instr_code,
  output  logic [31:0]  instr_addr,
  output  logic [31:0]  daddr,
  output  logic [31:0]  dwdata
);

  logic [31:0] alu_result, rf_rd1, rf_rd2,pc;
  logic [31:0] imm_extend, alusrc_muxout, wb_muxout;
  logic b_taken;

  assign daddr  = alu_result;
  assign dwdata = rf_rd2;

  mux_2x1 u_wb_mux(
    .sel(rfsrc_sel),
    .in0(alu_result),
    .in1(drdata),
    .mux_out(wb_muxout)
  );

  reg_file u_reg_file(
    .clk(clk),
    .rstn(rstn),
    .ra1(instr_code[19:15]),
    .ra2(instr_code[24:20]),
    .wa(instr_code[11:7]),
    .wd(wb_muxout),
    .we(rf_we),
    .rd1(rf_rd1),
    .rd2(rf_rd2)
  );

  imm_extend u_imm_extend(
    .instr_code(instr_code),
    .imm_extend(imm_extend)
  );


  mux_2x1 u_alusrc_mux(
    .sel(alusrc_sel),
    .in0(rf_rd2),
    .in1(imm_extend),
    .mux_out(alusrc_muxout)
  );

  alu u_alu(
    .rs1(rf_rd1),
    .rs2(alusrc_muxout),
    .alu_control(alu_control),
    .alu_result(alu_result),
    .b_taken(b_taken)
  );

  program_counter u_pc(
    .clk(clk),
    .rstn(rstn),
    .branch(branch),
    .b_taken(b_taken),
    .imm_extend(imm_extend),
    .pc(instr_addr)
  );

endmodule

module mux_2x1(
  input   logic         sel,
  input   logic [31:0]  in0,
  input   logic [31:0]  in1,
  output  logic [31:0]  mux_out
);
  
  assign mux_out = (sel) ? in1 : in0;
  
endmodule

module reg_file(
  input   logic         clk,
  input   logic         rstn,
  input   logic         we,
  input   logic [4:0]   ra1,
  input   logic [4:0]   ra2,
  input   logic [4:0]   wa,
  input   logic [31:0]  wd,
  output  logic [31:0]  rd1,
  output  logic [31:0]  rd2
);

  logic [31:0] reg_file [1:31];
  

  //write
  always_ff @(posedge clk) begin
    if(!rstn) begin
    `ifdef SIMULATION
      for(int i = 1; i < 32; i++)
        reg_file[i] <= i;
    `else
      for(int i = 1; i < 32; i++)
        reg_file[i] <= 0;
    `endif
    end
    if(we) begin
     reg_file[wa] <= wd; 
    end
  end

  //read
  assign rd1 = (ra1 != 0) ? reg_file[ra1] : 32'd0;
  assign rd2 = (ra2 != 0) ? reg_file[ra2] : 32'd0;

endmodule

module alu(
  input   logic [31:0] rs1,
  input   logic [31:0] rs2,
  input   logic [ 3:0] alu_control,
  output  logic [31:0] alu_result,
  output  logic        b_taken
);

  always_comb begin
    alu_result = 32'h0000_0000;
    case(alu_control)
      {1'b0,3'h0} : begin // ADD
        alu_result = rs1 + rs2;
      end

      {1'b1,3'h0} : begin // SUB
        alu_result = rs1 - rs2;
      end

      {1'b0,3'h4} : begin // XOR
        alu_result = rs1 ^ rs2;
      end

      {1'b0,3'h6} : begin // OR
        alu_result = rs1 | rs2;
      end
      
      {1'b0,3'h7} : begin // AND
        alu_result = rs1 & rs2;
      end

      {1'b0,3'h1} : begin // Shift left logical
        alu_result = rs1 << rs2;
      end

      {1'b0,3'h5} : begin // Shift right logical
        alu_result = rs1 >> rs2;
      end
      
      {1'b1,3'h5} : begin // Shift right arith
        alu_result = $signed(rs1) >>> rs2;
      end

      {1'b0,3'h2} : begin // Set Less than
        alu_result = $signed(rs1) < $signed(rs2) ? 32'd1:32'd0;
      end

      {1'b0,3'h3} : begin // Set Less than(U)
        alu_result = (rs1 < rs2) ? 32'd1 : 32'd0;
      end
    endcase
  end

  always_comb begin
    b_taken = 1'b0;
    case(alu_control[2:0])
      3'b000 : 
        if (rs1 == rs2) //BEQ
          b_taken = 1'b1;
        else 
          b_taken = 1'b0;
      3'b001 :
        if (rs1 != rs2) // BNE
          b_taken = 1'b1;
        else
          b_taken = 1'b0;
      3'b100 :
        if ($signed(rs1) < $signed(rs2)) //BLT
          b_taken = 1'b1;
        else
          b_taken = 1'b0;
      3'b101 : 
        if ($signed(rs1) >= $signed(rs2)) //BGE
          b_taken = 1'b1;
        else
          b_taken = 1'b0;
      3'b110 :
        if (rs1 < rs2) //BLTU
          b_taken = 1'b1;
        else
          b_taken = 1'b0;
      3'b111 :
        if (rs1 >= rs2) //BGEU
          b_taken = 1'b1;
        else
          b_taken = 1'b0;
    endcase
  end
endmodule

// imm extender
module imm_extend
  import rv32i_pkg::*; // pkg import
(
  input   logic [31:0] instr_code,
  output  logic [31:0] imm_extend
);

  opcode_e  opcode;

//  assign opcode = instr_code[6:0];
  assign opcode = opcode_e'(instr_code[6:0]); // opcode_e' : casting operator

  always_comb begin
    case(opcode)
      OP_STYPE : begin // S-type
        imm_extend = {{20{instr_code[31]}}, {instr_code[31:25],instr_code[11:7]}};
      end
      OP_ITYPE : begin // I-type
        imm_extend = {{20{instr_code[31]}}, {instr_code[31:20]}};
      end
      OP_ILTYPE : begin // IL-type
        if(instr_code[14] == 1)
          imm_extend = {{20{instr_code[31]}},{instr_code[31:20]}};
        else
          imm_extend = {{20{1'b0}},{instr_code[31:20]}};
      end
      OP_BTYPE  : begin // B-type
        imm_extend ={{20{instr_code[31]}},instr_code[7],instr_code[30:25],instr_code[11:8],1'b0};//20bit+1bit+6bit+4bit+1bit
      end
      default : imm_extend = 32'h0000_0000;
    endcase
  end
  
  

endmodule

module program_counter(
  input   logic   clk,
  input   logic   rstn,
  input   logic   branch,
  input   logic   b_taken,
  input   logic [31:0] imm_extend,
  output  logic [31:0] pc
);

  logic [31:0] register_pc, branch_muxout;
  logic b_on;

  assign b_on = branch & b_taken;

  always_ff @(posedge clk) begin
    if(!rstn) 
      register_pc <= 32'd0;
    else
      register_pc <= register_pc + branch_muxout;
  end

  assign pc = register_pc;


  mux_2x1 branch_mux(
    .sel(b_on),
    .in0(4),
    .in1(imm_extend),
    .mux_out(branch_muxout)
  );

endmodule
