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
  input  logic               exmem_en,   // [FIX-7] EX->MEM 레지스터 enable (EXECUTE 상태에서만 1)
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
  logic [31:0] wLoadData;   // [FIX-6] 부호/0 확장된 로드 데이터

  logic [31:0] rPc;
  logic [31:0] wPcNext;
  logic [31:0] wPcPlus4;
  logic [31:0] wPcBase;
  logic [31:0] wPcSum;      // [FIX-2] 덧셈 결과를 따로 둠
  logic [31:0] wPcTarget;
  logic        wPcTargetSel;

  // ===== FETCH: program counter =====
  assign instr_addr   = rPc;
  assign wPcPlus4     = rPc + 32'd4;
  assign wPcTargetSel = (wBTaken & branch) | jal | jalr;
  assign wPcBase      = jalr ? rIdExRs1 : rPc;
  assign wPcSum       = wPcBase + rIdExImm;
  // [FIX-2] RISC-V 명세: JALR 목표 주소는 (rs1 + imm)의 최하위 비트를 0으로 만든 값
  assign wPcTarget    = jalr ? {wPcSum[31:1], 1'b0} : wPcSum;
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
    end else if (exmem_en) begin
      // [FIX-7] EXECUTE에서 계산한 주소와 쓰기 데이터를 MEMORY/WRITEBACK 동안 유지
      //         이전에는 매 클럭 갱신되어 MEMORY 상태에서 rs1+rs2(잘못된 값)로 바뀌었고,
      //         APB 요청기가 IDLE에서 먼저 래치해 준 덕분에 우연히 동작하고 있었음
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

  // ===== [FIX-6] LOAD EXTEND: funct3와 주소 하위 2비트로 바이트/하프워드 선택 후 확장 =====
  // RISC-V 명세: LB, LH는 부호 확장, LBU, LHU는 0 확장, 리틀 엔디언
  // instr_code는 PC가 바뀌기 전까지 그대로이므로 WRITEBACK에서도 funct3를 그대로 쓸 수 있음
  load_extend u_load_extend (
    .funct3   (instr_code[14:12]),
    .byte_off (rExMemAlu[1:0]),
    .rdata    (rMemWbRData),
    .ldata    (wLoadData)
  );

  // ===== WRITEBACK: writeback-data selection =====
  always_comb begin
    wWbData = wAluResult;
    case (rf_srcsel)
      WB_ALU_RESULT: wWbData = wAluResult;
      WB_MEM_RDATA : wWbData = wLoadData;     // [FIX-6]
      WB_IMMEDIATE : wWbData = rIdExImm;
      WB_PC_IMM    : wWbData = wPcTarget;   // AUIPC: jalr=0 이므로 PC + imm 그대로
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

  // [FIX-1] RISC-V 명세: 시프트 양은 rs2(또는 즉치)의 하위 5비트만 사용
  //         SRAI는 즉치의 bit10(instr[30])=1 이 함께 들어오므로 이전 코드에서는
  //         시프트 양이 1024 이상이 되어 항상 잘못된 결과가 나왔음
  logic [4:0] wShamt;
  assign wShamt = rs2[4:0];

  always_comb begin
    alu_result = 32'd0;
    case (alu_control)
      ALU_ADD : alu_result = rs1 + rs2;
      ALU_SUB : alu_result = rs1 - rs2;
      ALU_SLL : alu_result = rs1 << wShamt;
      ALU_SLT : alu_result = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;
      ALU_SLTU: alu_result = (rs1 < rs2) ? 32'd1 : 32'd0;
      ALU_XOR : alu_result = rs1 ^ rs2;
      ALU_SRL : alu_result = rs1 >> wShamt;
      ALU_SRA : alu_result = $signed(rs1) >>> wShamt;
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
      // [FIX-5] 19 + 1 + 1 + 6 + 4 + 1 = 32비트 (이전 20은 33비트가 되어 폭 경고 발생)
      OP_BTYPE              : imm_extend = {{19{instr_code[31]}}, instr_code[31], instr_code[7], instr_code[30:25], instr_code[11:8], 1'b0};
      OP_ULTYPE, OP_UATYPE  : imm_extend = {instr_code[31:12], 12'b0};
      OP_JTYPE              : imm_extend = {{12{instr_code[31]}}, instr_code[19:12], instr_code[20], instr_code[30:21], 1'b0};
      default               : imm_extend = 32'd0;
    endcase
  end

endmodule


// [FIX-6] 로드 데이터 확장기
module load_extend (
  input  logic [2:0]  funct3,
  input  logic [1:0]  byte_off,
  input  logic [31:0] rdata,
  output logic [31:0] ldata
);

  logic [7:0]  wByte;
  logic [15:0] wHalf;

  always_comb begin
    case (byte_off)
      2'd0:    wByte = rdata[7:0];
      2'd1:    wByte = rdata[15:8];
      2'd2:    wByte = rdata[23:16];
      default: wByte = rdata[31:24];
    endcase
    wHalf = byte_off[1] ? rdata[31:16] : rdata[15:0];

    case (funct3)
      3'b000:  ldata = {{24{wByte[7]}}, wByte};   // LB
      3'b001:  ldata = {{16{wHalf[15]}}, wHalf};  // LH
      3'b100:  ldata = {24'd0, wByte};            // LBU
      3'b101:  ldata = {16'd0, wHalf};            // LHU
      default: ldata = rdata;                     // LW
    endcase
  end

endmodule
