module rv32i_top(
  input   logic         clk,
  input   logic         rstn
  );

  logic [31:0]  instr_code;
  logic [31:0]  instr_addr;
  logic [31:0]  daddr;
  logic [31:0]  dwdata;
  logic [31:0]  drdata;
  logic         dwe;
  logic [ 2:0]  itype;

  rv32i_cpu u_rv32i_cpu(
    .*
  );

  instruction_rom u_instr_rom(
    .*
  );

  data_memory u_data_mem(
    .*
  );

endmodule

module rv32i_cpu(
  input   logic         clk,
  input   logic         rstn,
  input   logic [31:0]  drdata,
  input   logic [31:0]  instr_code,
  output  logic [31:0]  instr_addr,
  output  logic [31:0]  daddr,
  output  logic [31:0]  dwdata,
  output  logic         dwe,
  output  logic [ 2:0]  itype
);
  
  logic rf_we;
  logic alusrc_sel;
  logic [3:0] alu_control;
  logic rfsrc_sel;
  logic branch;

  control_unit u_control_unit(
    .*
  );

  datapath u_datapath(
    .*
  );
endmodule
