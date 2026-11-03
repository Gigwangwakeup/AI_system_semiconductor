`timescale 1ns / 1ps

module adder(
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [8:0] y
    );

    always @(*) begin
        y = a + b;
    end

endmodule
