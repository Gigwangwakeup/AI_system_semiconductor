`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/07 15:04:46
// Design Name: 
// Module Name: uart_loop_back
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


module uart_loop_back(
    input clk,
    input rst,
    input rx,
    output rx_done,
    output [7:0] rx_data,
    output tx
    );

    wire w_baud_tick;
    wire w_rx_done;
    wire [7:0] w_rx_data;

    assign rx_data = w_rx_data;
    assign rx_done = w_rx_done;

    baud_tick_gen #(
        .BAUD_RATE (153_600),
        .CLK_PERIOD(100_000_000)
    ) u_baud_tick_gen (
        .clk        (clk),
        .rst        (rst),
        .o_baud_tick(w_baud_tick)
    );

    uart_tx u_uart_tx ( 
        .clk      (clk),
        .rst      (rst),
        .tx_start (w_rx_done),      //(tx_start),     // I
        .tx_data  (w_rx_data),      // I [7:0]
        .baud_tick(w_baud_tick),  // I
        .tx_busy  (),      // O
        .tx_done  (),      // O
        .tx       (tx)            // O
    );

    uart_rx u_uart_rx (
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),           // I
        .baud_tick(w_baud_tick),  // I
        .rx_done  (w_rx_done),      // O
        .rx_data  (w_rx_data)       // O [7:0]
    );
endmodule
