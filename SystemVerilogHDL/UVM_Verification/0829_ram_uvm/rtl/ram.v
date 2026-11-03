`timescale 1ns / 1ps

module ram #(
    parameter WIDTH = 8,
    DEPTH = 256    
    )(
    input clk,
    input we,
    input [$clog2(DEPTH) -1:0] addr,
    input [WIDTH -1:0] wdata,
    output [WIDTH -1:0] rdata
);

reg [WIDTH -1:0] ram [0:DEPTH -1];

assign rdata = ram[addr];

always @(posedge clk) begin
    if(we) begin
        ram[addr] <= wdata;
    end
end
endmodule
