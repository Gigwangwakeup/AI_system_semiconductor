module apb_ram (
  input  logic        clk,

  // CPU access type
  input  logic [2:0]  itype,

  // APB interface
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic [31:0] PADDR,
  input  logic [31:0] PWDATA,
  input  logic        PWRITE,
  output logic        PREADY,
  output logic [31:0] PRDATA
);

  logic [31:0] rDmem [0:127];

  assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

  // Store
  always_ff @(posedge clk) begin
    if (PWRITE && PENABLE) begin
      case (itype)
        3'b010: rDmem[PADDR[31:2]] <= PWDATA;
        default: rDmem[PADDR[31:2]] <= rDmem[PADDR[31:2]];
      endcase
    end
  end

  // Load
  assign PRDATA = PREADY ? rDmem[PADDR[31:2]] : 32'hz;

endmodule

