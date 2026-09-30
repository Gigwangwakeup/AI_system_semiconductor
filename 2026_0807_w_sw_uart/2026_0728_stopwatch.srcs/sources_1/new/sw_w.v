`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/02 16:38:38
// Design Name: 
// Module Name: sw_w
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


module sw_w ();

    reg clk,reset,btn_D,btn_L,btn_R,btn_U;
    reg [2:0] sw;
    wire [1:0] led;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    stopwatch_watch  #(
        .MSEC_WIDTH(7),
        .SEC_WIDTH (6),
        .MIN_WIDTH (6),
        .HOUR_WIDTH(5)
    ) dut (
        .clk(clk),        //input        
        .reset(reset),      //input        
        .btn_D(btn_D),      // edit_time,//input        
        .btn_L(btn_L),      // left,//input        
        .btn_R(btn_R),      // right,//input        
        .btn_U(btn_U),      // up,//input        
        .sw(sw),         // {record, stopwatch/watch, display_mode},//input  [2:0] 
        .led(led),        //output [1:0] 
        .fnd_com(fnd_com),    //output [3:0] 
        .fnd_data(fnd_data)   //output [7:0] 
    );

initial begin
    clk = 0;
end

always #5 clk = ~clk;

initial begin
    //reg ì´ˆê¸°?™” 
    reset = 1;
    btn_D = 0;
    btn_L = 0;
    btn_R = 0;
    btn_U = 0;
    sw = 0;
    #10
    reset = 0;
    #10
    sw[1] = 1; // watch mode
    #10
    btn_D = 1; // FSM = edit_time 
    sw[0] = 1; // display for hour,min
    #800
    btn_D = 0;
    btn_U = 1; // hour unit +1
    #800
    btn_U = 0;
    btn_R = 1; // min_ten
    #800
    btn_R = 0; 
    btn_U = 1; // min_ten + 1
    #800
    btn_U = 0;
    btn_D = 1; // FSM = RUN
    #800
    btn_D = 0; 
    #10000
    $stop;
end
endmodule
