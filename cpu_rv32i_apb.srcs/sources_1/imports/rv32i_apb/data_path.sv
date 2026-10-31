module datapath
  import rv32_pkg::*;
(
  input  logic               clk,
  input  logic               rst_n,

  // Control
  input  logic               pc_en,
  input  logic               rf_we,
  input  logic               alusrc_sel,
  input  logic               branch,
  input  logic               jal,
  input  logic               jalr,
  input  alu_control_e       alu_control,
  input  writeback_select_e  rf_srcsel,

  // Data
  input  logic [31:0]        instr_code,
  input  logic [31:0]        bus_rdata,

  // Data outputs
  output logic [31:0]        instr_addr,
  output logic [31:0]        bus_addr,
  output logic [31:0]        bus_wdata
);

  logic [31:0] wRfRd1;
  logic [31:0] wRfRd2;
  logic [31:0] wImmExt;
  logic [31:0] wAluSrc2;
  logic [31:0] wAluResult;
  logic        wBTaken;
  logic [31:0] wWbData;

  logic [31:0] rIdExRs1;
  logic [31:0] rIdExRs2;
  logic [31:0] rIdExImm;
  logic [31:0] rExMemAlu;
  logic [31:0] rExMemRs2;
  logic [31:0] rMemWbRData;

  logic [31:0] rPc;
  logic [31:0] wPcNext;
  logic [31:0] wPcPlus4;
  logic [31:0] wPcBase;
  logic [31:0] wPcTarget;
  logic        wPcTargetSel;

  // ===== FETCH: program counter =====
  assign instr_addr   = rPc;
  assign wPcPlus4     = rPc + 32'd4;
  assign wPcTargetSel = (wBTaken & branch) | jal | jalr;
  assign wPcBase      = jalr ? rIdExRs1 : rPc;
  assign wPcTarget    = wPcBase + rIdExImm;
  assign wPcNext      = wPcTargetSel ? wPcTarget : wPcPlus4;

  always_ff @(posedge clk) begin
    if (!rst_n)
      rPc <= 32'd0;
    else if (pc_en)
      rPc <= wPcNext;
  end

  // ===== DECODE: register file and immediate generation =====
  reg_file u_reg_file (
    .clk   (clk),
    .rst_n (rst_n),
    .ra1   (instr_code[19:15]),
    .ra2   (instr_code[24:20]),
    .wa    (instr_code[11:7]),
    .wd    (wWbData),
    .we    (rf_we),
    .rd1   (wRfRd1),
    .rd2   (wRfRd2)
  );

  imm_extend u_imm_extend (
    .instr_code (instr_code),
    .imm_extend (wImmExt)
  );

  // ===== ID -> EX: pipeline registers =====
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rIdExRs1 <= 32'd0;
      rIdExRs2 <= 32'd0;
      rIdExImm <= 32'd0;
    end else begin
      rIdExRs1 <= wRfRd1;
      rIdExRs2 <= wRfRd2;
      rIdExImm <= wImmExt;
    end
  end

  // ===== EXECUTE: ALU source selection and calculation =====
  assign wAluSrc2 = alusrc_sel ? rIdExImm : rIdExRs2;

  alu u_alu (
    .rs1         (rIdExRs1),
    .rs2         (wAluSrc2),
    .b_taken     (wBTaken),
    .alu_control (alu_control),
    .alu_result  (wAluResult)
  );

  // ===== EX -> MEM: pipeline registers =====
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rExMemAlu <= 32'd0;
      rExMemRs2 <= 32'd0;
    end else begin
      rExMemAlu <= wAluResult;
      rExMemRs2 <= rIdExRs2;
    end
  end

  // ===== MEMORY: APB bus interface =====
  assign bus_addr  = rExMemAlu;
  assign bus_wdata = rExMemRs2;

  // ===== MEM -> WB: pipeline register =====
  always_ff @(posedge clk) begin
    if (!rst_n)
      rMemWbRData <= 32'd0;
    else
      rMemWbRData <= bus_rdata;
  end

  // ===== WRITEBACK: writeback-data selection =====
  always_comb begin
    wWbData = wAluResult;
    case (rf_srcsel)
      WB_ALU_RESULT: wWbData = wAluResult;
      WB_MEM_RDATA : wWbData = rMemWbRData;
      WB_IMMEDIATE : wWbData = rIdExImm;
      WB_PC_IMM    : wWbData = wPcTarget;
      WB_PC_PLUS4  : wWbData = wPcPlus4;
      default      : wWbData = wAluResult;
    endcase
  end

endmodule


module reg_file (
  input  logic        clk,
  input  logic        rst_n,

  // Address and data
  input  logic [4:0]  ra1,
  input  logic [4:0]  ra2,
  input  logic [4:0]  wa,
  input  logic [31:0] wd,
  input  logic        we,

  // Read data
  output logic [31:0] rd1,
  output logic [31:0] rd2
);

  logic [31:0] rRegisterFile [1:31];

  always_ff @(posedge clk) begin
    if (we && (wa != 5'd0))
      rRegisterFile[wa] <= wd;
  end

  assign rd1 = (ra1 != 5'd0) ? rRegisterFile[ra1] : 32'd0;
  assign rd2 = (ra2 != 5'd0) ? rRegisterFile[ra2] : 32'd0;

endmodule


module alu
  import rv32_pkg::*;
(
  input  logic [31:0]  rs1,
  input  logic [31:0]  rs2,
  input  alu_control_e alu_control,

  output logic [31:0]  alu_result,
  output logic         b_taken
);

  always_comb begin
    alu_result = 32'd0;
    case (alu_control)
      ALU_ADD : alu_result = rs1 + rs2;
      ALU_SUB : alu_result = rs1 - rs2;
      ALU_SLL : alu_result = rs1 << rs2;
      ALU_SLT : alu_result = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;
      ALU_SLTU: alu_result = (rs1 < rs2) ? 32'd1 : 32'd0;
      ALU_XOR : alu_result = rs1 ^ rs2;
      ALU_SRL : alu_result = rs1 >> rs2;
      ALU_SRA : alu_result = $signed(rs1) >>> rs2;
      ALU_OR  : alu_result = rs1 | rs2;
      ALU_AND : alu_result = rs1 & rs2;
      default : alu_result = 32'd0;
    endcase
  end

  always_comb begin
    b_taken = 1'b0;
    case (alu_control)
      alu_control_e'(BRANCH_EQ) : b_taken = ($signed(rs1) == $signed(rs2));
      alu_control_e'(BRANCH_NE) : b_taken = ($signed(rs1) != $signed(rs2));
      alu_control_e'(BRANCH_LT) : b_taken = ($signed(rs1) <  $signed(rs2));
      alu_control_e'(BRANCH_GE) : b_taken = ($signed(rs1) >= $signed(rs2));
      alu_control_e'(BRANCH_LTU): b_taken = (rs1 < rs2);
      alu_control_e'(BRANCH_GEU): b_taken = (rs1 >= rs2);
      default   : b_taken = 1'b0;
    endcase
  end

endmodule


module imm_extend
  import rv32_pkg::*;
(
  input  logic [31:0] instr_code,

  output logic [31:0] imm_extend
);

  opcode_e wOpcode;

  assign wOpcode = opcode_e'(instr_code[6:0]);

  always_comb begin
    case (wOpcode)
      OP_STYPE              : imm_extend = {{20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]};
      OP_ITYPE, OP_ILTYPE,
      OP_JRTYPE             : imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
      OP_BTYPE              : imm_extend = {{20{instr_code[31]}}, instr_code[31], instr_code[7], instr_code[30:25], instr_code[11:8], 1'b0};
      OP_ULTYPE, OP_UATYPE  : imm_extend = {instr_code[31:12], 12'b0};
      OP_JTYPE              : imm_extend = {{12{instr_code[31]}}, instr_code[19:12], instr_code[20], instr_code[30:21], 1'b0};
      default               : imm_extend = 32'd0;
    endcase
  end

endmodule

