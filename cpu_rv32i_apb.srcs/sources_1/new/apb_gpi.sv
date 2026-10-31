`timescale 1ns / 1ps

module apb_gpi (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic [ 7:0] GPI_IN,
    output logic        PREADY,
    output logic [31:0] PRDATA
);

    localparam GPI_CTR_ADDR = 8'h00, GPI_IDR_ADDR = 8'h04;

    logic [31:0] GPI_CTR;
    logic [ 7:0] GPI_IDR;

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            GPI_CTR <= 32'h0;
        end else begin
            if (PREADY && PWRITE) begin
                if (PADDR[7:0] == GPI_CTR_ADDR) GPI_CTR <= PWDATA[7:0];
            end
        end
    end

    assign PRDATA = (PADDR[7:0] == GPI_CTR_ADDR) ? GPI_CTR :
                   (PADDR[7:0] == GPI_IDR_ADDR) ? {24'h0,GPI_IDR} : 32'hx;


    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign GPI_IDR[i] = (GPI_CTR[i]) ? GPI_IN[i] : 1'bz;
        end
    endgenerate
endmodule

// module apb_gpi (
//       input  logic        clk,
//       input  logic        rst_n,
//       input  logic        PSEL,
//       input  logic        PENABLE,
//       input  logic [31:0] PADDR,
//       input  logic [31:0] PWDATA,
//       input  logic        PWRITE,
//       input  logic [ 7:0] GPI_IN,
//       output logic        PREADY,
//       output logic [31:0] PRDATA
// );  

// localparam GPI_CTR_ADDR = 8'h00, GPI_IDR_ADDR = 8'h04;

//   logic [31:0] GPI_CTR, GPI_CTR_NEXT;
//   logic [7:0] GPI_IDR, GPI_IDR_NEXT;

//     typedef enum logic [1:0] {
//         IDLE,
//         SETUP,
//         ACCESS
//     } gpi_state_e;

//     gpi_state_e c_state, n_state;

//     always_ff @(posedge clk) begin
//         if(!rst_n) begin
//             c_state <= IDLE;
//             GPI_CTR <= 32'h0;
//             GPI_IDR <= 8'b0;
//         end else begin
//             c_state <= n_state;
//             GPI_CTR <= GPI_CTR_NEXT;
//             GPI_IDR <= GPI_IDR_NEXT;
//         end
//     end

//     always_comb begin
//         n_state = c_state;
//         GPI_CTR_NEXT = GPI_CTR;
//         GPI_IDR_NEXT = GPI_IDR;

//         case(c_state)
//         IDLE : begin
//             if(PSEL) n_state = SETUP;
//         end
//         SETUP : begin
//             if(PSEL & PENABLE) n_state = ACCESS;
//             if(PWRITE && (PADDR[7:0] == GPI_CTR_ADDR)) GPI_CTR_NEXT = PWDATA[7:0];
//         end
//         ACCESS : begin
//             n_state = IDLE;
//             GPI_IDR_NEXT = GPI_IN;
//         end
//         endcase
//     end

//     always_comb begin
//         case(PADDR[7:0])
//         GPI_CTR_ADDR : PRDATA = GPI_CTR;
//         GPI_IDR_ADDR : PRDATA = {24'h0, GPI_IDR};
//         default : PRDATA = 32'h0;
//         endcase
//     end

//     assign PREADY = (PENABLE && PSEL) ? 1'b1 : 1'b0;

// endmodule
