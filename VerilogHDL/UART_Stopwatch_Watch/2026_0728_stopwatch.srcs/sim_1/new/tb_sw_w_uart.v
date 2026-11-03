`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/08 23:22:18
// Design Name: 
// Module Name: tb_sw_w_uart
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


module tb_sw_w_uart();

    parameter BAUD_RATE = (100_000_000 / 9600) * 10;


    reg clk,reset,rx,btnd,btnl,btnr,btnu;
    reg [2:0] sw;
    wire [1:0] led;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

stopwatch_watch #(
    .MSEC_WIDTH (7),
    .SEC_WIDTH (6),
    .MIN_WIDTH (6),
    .HOUR_WIDTH (5)
) dut (
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .btn_D(btnd),    // edit_time,
    .btn_L(btnl),    // left,
    .btn_R(btnr),    // right,
    .btn_U(btnu),    // up,
    .sw(sw), // [2:0]{record, stopwatch/watch, display_mode},
    .tx(tx),
    .led(led), //[1:0]
    .fnd_com(fnd_com), //[3:0]
    .fnd_data(fnd_data) //[7:0]
);
integer i;
        
        task rx_task;
            input [7:0] data;
    
            begin
                rx = 0;
                #(BAUD_RATE);
                for(i = 0; i < 8; i = i + 1)begin
                    rx = data[i];
                    #BAUD_RATE;
                end
                rx = 1;
                #BAUD_RATE;
            end
        endtask
        
        
initial begin
 clk = 0;
 end
 always #5 clk = ~clk;
 
initial begin
    // init
    reset = 1;
    rx = 1;
    btnd = 0;
    btnl = 0;
    btnr = 0;
    btnu = 0;
    sw = 3'b011; //{record, stopwatch_mod, hour/min display}
    #10;
    reset = 0;
    #20000;
    // stopwatch run is controled by physical btn
    btnr = 1;    
    #800;
    btnr = 0;
    rx_task(8'h44); // watch edit mode
    #BAUD_RATE;
    $stop;    
    end
    
endmodule
