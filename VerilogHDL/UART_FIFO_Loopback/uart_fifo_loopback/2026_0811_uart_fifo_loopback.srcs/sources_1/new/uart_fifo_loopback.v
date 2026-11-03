`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/11 14:41:00
// Design Name: 
// Module Name: uart_fifo_loopback
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


module uart_fifo_loopback(
    input clk,
    input rst,
    input rx,
    output tx_done,
    output tx
);

    wire w_fifo_tx_empty, w_fifo_tx_full, w_fifo_rx_empty, w_uart_rx_done, w_uart_tx_busy;
    wire [7:0] w_fifo_tx_data,w_fifo_rx_data, w_uart_rx_data;

uart_controller u_uart_controller (
    .clk(clk),
    .rst(rst),
    .tx_start(~w_fifo_tx_empty),
    .tx_data(w_fifo_tx_data),   // watch output value [7:0]
    .rx(rx),
    .tx_busy(w_uart_tx_busy),
    .tx_done(tx_done),
    .tx(tx),
    .rx_data(w_uart_rx_data), // [7:0]
    .rx_done(w_uart_rx_done)
);

fifo #(
    .ADDR_WIDTH (2)
) fifo_rx (
    .clk(clk),
    .rst(rst),
    .push(w_uart_rx_done),
    .pop(~w_fifo_tx_full),
    .wdata(w_uart_rx_data),  // push data[7:0]
    .rdata(w_fifo_rx_data),  // pop data[7:0]
    .full(),
    .empty(w_fifo_rx_empty)
);

fifo #(
    .ADDR_WIDTH (2)
) fifo_tx (
    .clk(clk),
    .rst(rst),
    .push(~w_fifo_rx_empty),
    .pop(~w_uart_tx_busy),
    .wdata(w_fifo_rx_data),  // push data[7:0]
    .rdata(w_fifo_tx_data),  // pop data[7:0]
    .full(w_fifo_tx_full),
    .empty(w_fifo_tx_empty)
);
endmodule
