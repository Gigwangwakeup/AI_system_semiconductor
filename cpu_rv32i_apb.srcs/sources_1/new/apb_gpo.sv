`timescale 1ns / 1ps

module apb_gpo (
    input  logic        clk,
    input  logic        rst_n,

    // APB interface
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,

    // GPO output
    output logic [7:0]  GPO_OUT,

    output logic        PREADY,
    output logic [31:0] PRDATA
);

    // Register address
    localparam GPO_CTR_ADDR = 8'h00, GPO_ODR_ADDR = 8'h04;

    // Registers
    logic [31:0] GPO_CTR;
    logic [7:0]  GPO_ODR;

    assign PREADY = (PSEL && PENABLE) ? 1'b1 : 1'b0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            GPO_CTR <= 32'h0;
            GPO_ODR <= 8'b0;
        end else begin
            if (PREADY && PWRITE) begin
                // CTR : 0x00
                if (PADDR[7:0] == GPO_CTR_ADDR)
                    GPO_CTR <= PWDATA[7:0];
                // ODR : 0x04
                else if (PADDR[7:0] == GPO_ODR_ADDR)
                    GPO_ODR <= PWDATA[7:0];
            end
        end
    end

    //==========================================================
    // Read
    //==========================================================
    // always_comb begin
    //     case (PADDR[7:0])

    //         GPO_CTR_ADDR:
    //             PRDATA = GPO_CTR;

    //         GPO_ODR_ADDR:
    //             PRDATA = {24'h0, GPO_ODR};

    //         default:
    //             PRDATA = 32'h0000_0000;

    //     endcase
    // end

    assign PRDATA = (PADDR[7:0] == GPO_CTR_ADDR) ? GPO_CTR :
                    (PADDR[7:0] == GPO_ODR_ADDR) ? {24'h0, GPO_ODR} : 32'hx;

    //==========================================================
    // GPO Output
    //==========================================================
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign GPO_OUT[i] = GPO_CTR[i] ? GPO_ODR[i] : 1'bz;
        end
    endgenerate

endmodule