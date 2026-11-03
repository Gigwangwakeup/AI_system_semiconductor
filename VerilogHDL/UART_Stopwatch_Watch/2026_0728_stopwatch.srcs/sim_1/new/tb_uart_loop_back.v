`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/08 12:46:03
// Design Name: 
// Module Name: tb_uart_loop_back
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


module tb_uart_loop_back();

    reg clk, rst, rx;
    wire rx_done, tx;
    wire [7:0] rx_data;

    parameter BAUD_RATE = (100_000_000 / 9600) * 10;

    uart_loop_back dut(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .tx(tx)
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
            rst = 1;
            rx = 1;
            #10
            rst = 0;
            #10
            rx_task(8'h55);
            rx_task(8'haa);
        end

endmodule
