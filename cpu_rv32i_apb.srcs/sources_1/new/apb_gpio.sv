`timescale 1ns / 1ps

module apb_gpio (
    input logic clk,
    input logic rst_n,

    //APB INTERFACE
    input logic PSEL,
    input logic PENABLE,
    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,
    input logic PWRITE,

    input logic [7:0] GPIO_IN,

    // GPO OUTPUT
    output logic PREADY,
    output logic [31:0] PRDATA,
    output logic [7:0] GPIO_OUT
);

    localparam GPIO_CTR_ADDR = 8'h00, GPIO_ODR_ADDR = 8'h04, GPIO_IDR_ADDR = 8'h08;

    logic [31:0] GPIO_CTR;
    logic [ 7:0] GPIO_ODR;
    logic [ 7:0] GPIO_IDR;

    assign PREADY = (PSEL && PENABLE) ? 1'b1 : 1'b0;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            GPIO_CTR <= 32'h0;
            GPIO_ODR <= 8'h0;
        end else begin
            if (PREADY && PWRITE) begin
                if (PADDR[7:0] == GPIO_CTR_ADDR) GPIO_CTR <= PWDATA[7:0];
                else if (PADDR[7:0] == GPIO_ODR_ADDR) GPIO_ODR <= PWDATA[7:0];
            end
        end
    end

    //write
    assign PRDATA = (PADDR[7:0] == GPIO_CTR_ADDR) ? GPIO_CTR :
                        (PADDR[7:0] == GPIO_ODR_ADDR) ? {24'h0, GPIO_ODR} :
                            (PADDR[7:0] == GPIO_IDR_ADDR) ? {24'h0, GPIO_IDR} : 32'hz;


    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign GPIO_OUT[i] = GPIO_CTR[i] ? GPIO_ODR[i] : 1'bz;
            assign GPIO_IDR[i] = GPIO_IN[i];
        end
    endgenerate

endmodule
