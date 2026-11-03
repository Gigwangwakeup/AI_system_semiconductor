`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/08 22:05:07
// Design Name: 
// Module Name: tb_ascii_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_ascii_decoder();

    reg clk, rst, rx_done;
    reg [7:0] rx_data;
    wire run, record, clear, mode, up, left, right, edit;

    parameter BAUD_RATE = (100_000_000 / 9600) * 10;

ascii_decoder dut(
    .clk(clk),
    .rst(rst),
    .rx_done(rx_done),
    .rx_data(rx_data),
    .sw_run(run),
    .sw_record(record),
    .sw_clear(clear),
    .sw_mode(mode),
    .w_up(up),
    .w_left(left),
    .w_right(right),
    .w_edit(edit)
);

initial begin
    clk = 0;
end
    
always #5 clk = ~clk;

initial begin
    rst = 1;
    rx_done = 0;
    #10;
    rst = 0;
    @(posedge clk);
    rx_done = 1;
    rx_data = 8'h72;
    @(posedge clk);
    rx_done = 0;
    #BAUD_RATE;
    @(posedge clk);
    rx_done = 1;
    rx_data = 8'h73;
    @(posedge clk);
    rx_done = 0;
    #BAUD_RATE;
    @(posedge clk);
    rx_done = 1;
    rx_data = 8'h44;
    @(posedge clk);
    rx_done = 0;
    #BAUD_RATE;
    @(posedge clk);
    rx_done = 1;
    rx_data = 8'h55;
    @(posedge clk);
    rx_done = 0;
    #10;
    $stop;
    end
endmodule
