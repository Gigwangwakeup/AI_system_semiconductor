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


module uart_fifo_loop_back (
    input  clk,
    input  rst,
    input  rx,
    output tx
);

    wire w_baud_tick;
    wire w_rx_done;
    wire [7:0] w_rx_data;
    wire w_fifo_tx_full, w_fifo_tx_empty, w_fifo_rx_empty, w_tx_busy;
    wire [7:0] w_fifo_rx_rdata;
    wire [7:0] w_fifo_tx_rdata;

    uart_rx u_uart_rx (
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),           // I
        .baud_tick(w_baud_tick),  // I
        .rx_done  (w_rx_done),    // O
        .rx_data  (w_rx_data)     // O [7:0]
    );


    fifo #(
        .ADDR_WIDTH(2)
    ) u_fifo_rx (
        .clk  (clk),
        .rst  (rst),
        .push (w_rx_done),
        .pop  (~w_fifo_tx_full),
        .wdata(w_rx_data),        // push data
        .rdata(w_fifo_rx_rdata),  // pop data
        .full (),
        .empty(w_fifo_rx_empty)
    );

    fifo #(
        .ADDR_WIDTH(2)
    ) u_fifo_tx (
        .clk  (clk),
        .rst  (rst),
        .push (~w_fifo_rx_empty),
        .pop  (~w_tx_busy),
        .wdata(w_fifo_rx_rdata),   // push data
        .rdata(w_fifo_tx_rdata),   // pop data
        .full (w_fifo_tx_full),
        .empty(w_fifo_tx_empty)
    );

    uart_tx u_uart_tx (
        .clk      (clk),
        .rst      (rst),
        .tx_start (~w_fifo_tx_empty),  //(tx_start),     // I
        .tx_data  (w_fifo_tx_rdata),   // I [7:0]
        .baud_tick(w_baud_tick),       // I
        .tx_busy  (w_tx_busy),         // O
        .tx_done  (),                  // O
        .tx       (tx)                 // O
    );

    

    baud_tick_gen #(
        .BAUD_RATE (153_600),
        .CLK_PERIOD(100_000_000)
    ) u_baud_tick_gen (
        .clk        (clk),
        .rst        (rst),
        .o_baud_tick(w_baud_tick)
    );
endmodule
