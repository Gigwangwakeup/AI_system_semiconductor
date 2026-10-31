module apb_requester (
  // Clock and reset
  input  logic        clk,
  input  logic        rst_n,

  // CPU request
  input  logic [31:0] bus_addr,
  input  logic [31:0] bus_wdata,
  input  logic        transfer,
  input  logic        bus_we,

  // CPU response
  output logic        ready,
  output logic [31:0] bus_rdata,

  // APB response
  input  logic        PREADY0, // APB RAM
  input  logic        PREADY1, // GPI
  input  logic        PREADY2, // GPO
  input  logic        PREADY3, // GPIO
  input  logic        PREADY4, // FND
  input  logic        PREADY5, // UART
  input  logic        PREADY6,
  input  logic [31:0] PRDATA0,
  input  logic [31:0] PRDATA1,
  input  logic [31:0] PRDATA2,
  input  logic [31:0] PRDATA3,
  input  logic [31:0] PRDATA4,
  input  logic [31:0] PRDATA5,
  input  logic [31:0] PRDATA6,

  // APB request
  output logic [31:0] PADDR,
  output logic [31:0] PWDATA,
  output logic        PWRITE,
  output logic        PENABLE,
  output logic        PSEL0,
  output logic        PSEL1,
  output logic        PSEL2,
  output logic        PSEL3,
  output logic        PSEL4,
  output logic        PSEL5,
  output logic        PSEL6
);

  typedef enum logic [1:0] {
    APB_IDLE,
    APB_SETUP,
    APB_ACCESS
  } apb_state_e;

  apb_state_e rState;
  apb_state_e wStateNext;

  logic        wAddrDecEn;
  logic [2:0]  wRespSel;
  logic [31:0] rPAddr;
  logic [31:0] wPAddrNext;
  logic [31:0] rPWData;
  logic [31:0] wPWDataNext;
  logic        rPWrite;
  logic        wPWriteNext;

  assign PADDR  = {4'b0000, rPAddr[27:0]};
  assign PWDATA = rPWData;
  assign PWRITE = rPWrite;

  // APB request registers
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      rState  <= APB_IDLE;
      rPAddr  <= 32'h0;
      rPWData <= 32'h0;
      rPWrite <= 1'b0;
    end else begin
      rState  <= wStateNext;
      rPAddr  <= wPAddrNext;
      rPWData <= wPWDataNext;
      rPWrite <= wPWriteNext;
    end
  end

  // APB requester FSM
  always_comb begin
    wStateNext  = rState;
    wPAddrNext  = rPAddr;
    wPWDataNext = rPWData;
    wPWriteNext = rPWrite;
    PENABLE     = 1'b0;
    wAddrDecEn  = 1'b0;

    case (rState)
      APB_IDLE: begin
        if (transfer) begin
          wPAddrNext  = bus_addr;
          wPWDataNext = bus_wdata;
          wPWriteNext = bus_we;
          wStateNext  = APB_SETUP;
        end
      end

      APB_SETUP: begin
        wAddrDecEn = 1'b1;
        PENABLE     = 1'b0;
        wStateNext  = APB_ACCESS;
      end

      APB_ACCESS: begin
        wAddrDecEn = 1'b1;
        PENABLE     = 1'b1;
        if (ready)
          wStateNext = APB_IDLE;
      end
    endcase
  end

  address_decoder u_address_decoder (
    .enable  (wAddrDecEn),
    .mux_sel (wRespSel),
    .PADDR   (rPAddr),
    .PSEL0   (PSEL0),
    .PSEL1   (PSEL1),
    .PSEL2   (PSEL2),
    .PSEL3   (PSEL3),
    .PSEL4   (PSEL4),
    .PSEL5   (PSEL5),
    .PSEL6   (PSEL6)
  );

  apb_mux u_apb_mux (
    .sel       (wRespSel),
    .bus_rdata (bus_rdata),
    .ready     (ready),
    .PRDATA0   (PRDATA0),
    .PRDATA1   (PRDATA1),
    .PRDATA2   (PRDATA2),
    .PRDATA3   (PRDATA3),
    .PRDATA4   (PRDATA4),
    .PRDATA5   (PRDATA5),
    .PRDATA6   (PRDATA6),
    .PREADY0   (PREADY0),
    .PREADY1   (PREADY1),
    .PREADY2   (PREADY2),
    .PREADY3   (PREADY3),
    .PREADY4   (PREADY4),
    .PREADY5   (PREADY5),
    .PREADY6   (PREADY6)
  );

endmodule


module address_decoder (
  input  logic        enable,

  input  logic [31:0] PADDR,

  output logic [2:0]  mux_sel,
  output logic        PSEL0,
  output logic        PSEL1,
  output logic        PSEL2,
  output logic        PSEL3,
  output logic        PSEL4,
  output logic        PSEL5,
  output logic        PSEL6
);

  always_comb begin
    PSEL0   = 1'b0;
    PSEL1   = 1'b0;
    PSEL2   = 1'b0;
    PSEL3   = 1'b0;
    PSEL4   = 1'b0;
    PSEL5   = 1'b0;
    PSEL6   = 1'b0;
    mux_sel = 3'b000;

    if (enable) begin
      case (PADDR[31:28])
        4'b0001: begin // APB RAM
          PSEL0   = 1'b1;
          mux_sel = 3'b000;
        end

        4'b0010: begin // GPI, GPO, GPIO, FND, UART, etc.
          case (PADDR[11:8])
            4'b0000: begin
              PSEL1   = 1'b1;
              mux_sel = 3'b001;
            end
            4'b0001: begin
              PSEL2   = 1'b1;
              mux_sel = 3'b010;
            end
            4'b0010: begin
              PSEL3   = 1'b1;
              mux_sel = 3'b011;
            end
            4'b0011: begin
              PSEL4   = 1'b1;
              mux_sel = 3'b100;
            end
            4'b0100: begin
              PSEL5   = 1'b1;
              mux_sel = 3'b101;
            end
            4'b0101: begin
              PSEL6   = 1'b1;
              mux_sel = 3'b110;
            end
          endcase
        end
      endcase
    end
  end

endmodule


module apb_mux (
  input  logic [2:0]  sel,
  input  logic [31:0] PRDATA0,
  input  logic [31:0] PRDATA1,
  input  logic [31:0] PRDATA2,
  input  logic [31:0] PRDATA3,
  input  logic [31:0] PRDATA4,
  input  logic [31:0] PRDATA5,
  input  logic [31:0] PRDATA6,

  input  logic        PREADY0,
  input  logic        PREADY1,
  input  logic        PREADY2,
  input  logic        PREADY3,
  input  logic        PREADY4,
  input  logic        PREADY5,
  input  logic        PREADY6,

  output logic [31:0] bus_rdata,
  output logic        ready
);

  always_comb begin
    case (sel)
      3'b000: begin
        bus_rdata = PRDATA0;
        ready     = PREADY0;
      end
      3'b001: begin
        bus_rdata = PRDATA1;
        ready     = PREADY1;
      end
      3'b010: begin
        bus_rdata = PRDATA2;
        ready     = PREADY2;
      end
      3'b011: begin
        bus_rdata = PRDATA3;
        ready     = PREADY3;
      end
      3'b100: begin
        bus_rdata = PRDATA4;
        ready     = PREADY4;
      end
      3'b101: begin
        bus_rdata = PRDATA5;
        ready     = PREADY5;
      end
      3'b110: begin
        bus_rdata = PRDATA6;
        ready     = PREADY6;

      end
      default : begin
        bus_rdata = PRDATA0;
        ready     = PREADY0;
      end
    endcase
  end

endmodule

