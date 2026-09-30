`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/30 17:37:14
// Design Name: 
// Module Name: tb_top
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


module tb_top();

    reg clk,rst,edit_time,left,right,up,display_mode;
    wire [7:0] msec;
    wire [6:0] sec;
    wire [6:0] min;
    wire [5:0] hour;

stopwatch_datapath dut (
    .clk(clk),
    .reset(rst),
    .edit_time(edit_time),
    .left(left),
    .right(right),
    .up(up),
    .display_mode(display_mode),
    .msec(msec),
    .sec(sec),
    .min(min),
    .hour(hour)
);


initial begin
    clk = 0;
end

always #5 clk = ~clk;

initial begin
    rst = 1;
    edit_time = 0;
    left = 0;
    right = 0;
    up = 0;
    display_mode = 0;
    #10
    rst = 0;
    #100
    edit_time = 1;
    #10
    display_mode = 1;
    #10
    left = 1;
    #10
    left = 0;
    #10
    left = 1;
    #10
    left = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    up = 1;
    #10
    up = 0;
    #10
    edit_time = 0;
    #100
    $stop;
end
endmodule
