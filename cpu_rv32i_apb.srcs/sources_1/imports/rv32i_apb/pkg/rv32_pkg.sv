package rv32_pkg;

  // RV32I opcode field (instruction[6:0])
  typedef enum logic [6:0] {
    OP_RTYPE  = 7'b011_0011,
    OP_STYPE  = 7'b010_0011,
    OP_ITYPE  = 7'b001_0011,
    OP_ILTYPE = 7'b000_0011,
    OP_BTYPE  = 7'b110_0011,
    OP_ULTYPE = 7'b011_0111,
    OP_UATYPE = 7'b001_0111,
    OP_JTYPE  = 7'b110_1111,
    OP_JRTYPE = 7'b110_0111
  } opcode_e;

  // {funct7[5], funct3}; values preserve the original ALU-control encoding.
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b1000,
    ALU_SLL  = 4'b0001,
    ALU_SLT  = 4'b0010,
    ALU_SLTU = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_SRL  = 4'b0101,
    ALU_SRA  = 4'b1101,
    ALU_OR   = 4'b0110,
    ALU_AND  = 4'b0111
  } alu_control_e;

  // {1'b0, funct3}; values intentionally share the ALU-control encoding.
  typedef enum logic [3:0] {
    BRANCH_EQ  = 4'b0000,
    BRANCH_NE  = 4'b0001,
    BRANCH_LT  = 4'b0100,
    BRANCH_GE  = 4'b0101,
    BRANCH_LTU = 4'b0110,
    BRANCH_GEU = 4'b0111
  } branch_control_e;

  typedef enum logic [2:0] {
    WB_ALU_RESULT = 3'b000,
    WB_MEM_RDATA  = 3'b001,
    WB_IMMEDIATE  = 3'b010,
    WB_PC_IMM     = 3'b011,
    WB_PC_PLUS4   = 3'b100
  } writeback_select_e;

  typedef enum logic [2:0] {
    CPU_FETCH,
    CPU_DECODE,
    CPU_EXECUTE,
    CPU_MEMORY,
    CPU_WRITEBACK
  } cpu_state_e;

endpackage

