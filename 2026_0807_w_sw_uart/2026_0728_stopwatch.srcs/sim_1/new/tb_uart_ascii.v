`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/10 09:04:22
// Design Name: 
// Module Name: tb_uart_ascii
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


module tb_uart_ascii ();

    parameter BAUD_RATE = (100_000_000 / 9600) * 10;

    // uart
    reg clk, rst, rx;
    wire rx_done, tx;
    wire [7:0] rx_data;

    //ascii decoder
    wire sw_run, sw_record, sw_clear, sw_mode;
    wire w_up, w_left, w_right, w_edit;

    uart_loop_back dut1 (
        .clk(clk),  //i
        .rst(rst),  //i
        .rx(rx),  //i
        .rx_done(rx_done),  //o
        .rx_data(rx_data),  //o [7:0]
        .tx(tx)  //o
    );

    ascii_decoder dut2 (
        .clk(clk),  //i
        .rst(rst),  //i
        .rx_done(rx_done),  //i
        .rx_data(rx_data),  //i [7:0]
        .sw_run(sw_run),  //o
        .sw_record(sw_record),  //o
        .sw_clear(sw_clear),  //o
        .sw_mode(sw_mode),  //o
        .w_up(w_up),  //o
        .w_left(w_left),  //o
        .w_right(w_right),  //o
        .w_edit(w_edit)  //o
    );

    integer i = 0;

    task input_rx_task(input [7:0] data);
    begin
        for(i=0; i<8; i=i+1) begin
            rx = data[i];
            #BAUD_RATE;
        end
        rx = 0;
        #BAUD_RATE;
    end
    endtask

    initial begin
        clk = 0;
    end

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        rx  = 1;
        #10
        rst = 0;
        #10

    end
endmodule
