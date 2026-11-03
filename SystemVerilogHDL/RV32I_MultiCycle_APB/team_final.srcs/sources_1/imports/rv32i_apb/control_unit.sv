module control_unit
  import rv32_pkg::*;
(
  input  logic               clk,
  input  logic               rst_n,

  // Status and instruction
  input  logic               ready,
  input  logic [31:0]        instr_code,

  // Datapath control
  output logic               pc_en,
  output logic               branch,
  output logic               jal,
  output logic               jalr,
  output logic               rf_we,
  output logic               alusrc_sel,
  output alu_control_e       alu_control,
  output writeback_select_e  rf_srcsel,

  // Bus control
  output logic               bus_we,
  output logic               transfer,
  output logic [2:0]         itype
);

  opcode_e    wOpcode;
  logic [2:0] wFunct3;
  cpu_state_e rState;
  cpu_state_e wStateNext;

  assign wOpcode = opcode_e'(instr_code[6:0]);
  assign wFunct3 = instr_code[14:12];

  always_ff @(posedge clk) begin
    if (!rst_n)
      rState <= CPU_FETCH;
    else
      rState <= wStateNext;
  end

  // Instruction sequencing.  The memory stage waits for the APB response.
  always_comb begin
    wStateNext = rState;
    pc_en      = 1'b0;

    case (rState)
      CPU_FETCH  : wStateNext = CPU_DECODE;
      CPU_DECODE : wStateNext = CPU_EXECUTE;
      CPU_EXECUTE: begin
        case (wOpcode)
          OP_STYPE, OP_ILTYPE: wStateNext = CPU_MEMORY;
          default: begin
            wStateNext = CPU_FETCH;
            pc_en      = 1'b1;
          end
        endcase
      end
      CPU_MEMORY: begin
        if (wOpcode == OP_STYPE) begin
          if (ready) begin
            pc_en      = 1'b1;
            wStateNext = CPU_FETCH;
          end
        end else begin
          wStateNext = ready ? CPU_WRITEBACK : CPU_MEMORY;
        end
      end
      CPU_WRITEBACK: begin
        wStateNext = CPU_FETCH;
        pc_en      = 1'b1;
      end
      default: begin
        wStateNext = CPU_FETCH;
      end
    endcase
  end

  // Decode controls. Defaults match the original implementation.
  always_comb begin
    rf_we       = 1'b0;
    branch      = 1'b0;
    jal         = 1'b0;
    jalr        = 1'b0;
    alusrc_sel  = 1'b0;
    alu_control = ALU_ADD;
    rf_srcsel   = WB_ALU_RESULT;
    bus_we      = 1'b0;
    transfer    = 1'b0;
    itype       = 3'b111;

    case (rState)
      CPU_FETCH,
      CPU_DECODE: ;

      CPU_EXECUTE: begin
        case (wOpcode)
          OP_RTYPE: begin
            rf_we       = 1'b1;
            alusrc_sel  = 1'b0;
            alu_control = alu_control_e'({instr_code[30], wFunct3});
            rf_srcsel   = WB_ALU_RESULT;
          end
          OP_BTYPE: begin
            branch      = 1'b1;
            alusrc_sel  = 1'b0;
            alu_control = alu_control_e'({1'b0, wFunct3});
          end
          OP_STYPE: begin
            alusrc_sel  = 1'b1;
            alu_control = ALU_ADD;
          end
          OP_ITYPE: begin
            rf_we      = 1'b1;
            alusrc_sel = 1'b1;
            rf_srcsel  = WB_ALU_RESULT;
            if (wFunct3 == 3'b101)
              alu_control = alu_control_e'({instr_code[30], wFunct3});
            else
              alu_control = alu_control_e'({1'b0, wFunct3});
          end
          OP_ILTYPE: begin
            alusrc_sel  = 1'b1;
            alu_control = ALU_ADD;
          end
          OP_ULTYPE: begin
            rf_we     = 1'b1;
            rf_srcsel = WB_IMMEDIATE;
          end
          OP_UATYPE: begin
            rf_we     = 1'b1;
            rf_srcsel = WB_PC_IMM;
          end
          OP_JTYPE: begin
            rf_we     = 1'b1;
            rf_srcsel = WB_PC_PLUS4;
            jal       = 1'b1;
          end
          OP_JRTYPE: begin
            rf_we     = 1'b1;
            rf_srcsel = WB_PC_PLUS4;
            jalr      = 1'b1;
          end
          default: ;
        endcase
      end

      CPU_MEMORY: begin
        itype    = wFunct3;
        transfer = 1'b1;
        if (wOpcode == OP_STYPE)
          bus_we = 1'b1;
      end

      CPU_WRITEBACK: begin
        rf_we     = 1'b1;
        rf_srcsel = WB_MEM_RDATA;
      end

      default: ;
    endcase
  end

endmodule

