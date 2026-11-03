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


module uart_fifo (
    input        clk,
    input        rst,
    input        rx,
    input        rx_pop,
    input        tx_push,
    input  [7:0] tx_data,
    output [7:0] rx_data,
    output       fifo_rx_empty,
    output       tx_done,
    output       fifo_tx_full,
    output       tx
);

    wire w_fifo_tx_empty, w_uart_rx_done, w_uart_tx_busy;
    wire [7:0] w_fifo_tx_data, w_uart_rx_data;

    uart_controller u_uart_controller (
        .clk(clk),
        .rst(rst),
        .tx_start(~w_fifo_tx_empty),
        .tx_data(w_fifo_tx_data),  // watch output value [7:0]
        .rx(rx),
        .tx_busy(w_uart_tx_busy),
        .tx_done(tx_done),
        .tx(tx),
        .rx_data(w_uart_rx_data),  // [7:0] // ok
        .rx_done(w_uart_rx_done)  // ok
    );

    fifo #(
        .ADDR_WIDTH(3)
    ) fifo_rx (
        .clk(clk),
        .rst(rst),
        .push(w_uart_rx_done),  // ok // done 이 high 면 그때 pop
        .pop(rx_pop),  // ok
        .wdata(w_uart_rx_data),  // push data[7:0] // ok
        .rdata(rx_data),  // pop data[7:0] // ok
        .full(),  // 필요없음
        .empty(fifo_rx_empty)  // ok 0으로 떨어지면 그때부터 pop
    );

    fifo #(
        .ADDR_WIDTH(3)
    ) fifo_tx (
        .clk(clk),
        .rst(rst),
        .push(tx_push),
        .pop(~w_uart_tx_busy),
        .wdata(tx_data),  // push data[7:0]
        .rdata(w_fifo_tx_data),  // pop data[7:0]
        .full(fifo_tx_full),  // 필요한가..?
        .empty(w_fifo_tx_empty)
    );
endmodule
