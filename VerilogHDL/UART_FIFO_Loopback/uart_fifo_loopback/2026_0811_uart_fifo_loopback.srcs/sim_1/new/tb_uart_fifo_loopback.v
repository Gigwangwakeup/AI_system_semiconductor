`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/11 15:06:34
// Design Name: 
// Module Name: tb_uart_fifo_loopback
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


module tb_uart_fifo_loopback ();

    parameter BAUD_TICK = (100_000_000 / 9600) * 10;

    reg clk, rst, rx;
    wire tx;

    //simulation
    integer i,j;
    reg [7:0] receive_data, send_data;

    uart_fifo_loop_back dut (
        .clk(clk),
        .rst(rst),
        .rx (rx),
        .tx (tx)
    );

    task SENDER_FOR_UART_RX(input [7:0] send_data);
        begin
            //START 
            rx = 0; // start bit
            #(BAUD_TICK);
            //DATA
            for (i = 0; i < 8; i = i + 1) begin
                rx = send_data[i];
                #(BAUD_TICK);
            end
            rx = 1; // stop bit
            #(BAUD_TICK);
        end
    endtask

    // pc uart receiver
    task RECEIVER();
        begin
            // 
            wait(~tx);
            #(BAUD_TICK/2);
            if(tx)
                $display("%0t : start bit error", $time);
            for(j = 0; j < 8; j = j + 1) begin
                #(BAUD_TICK);
                receive_data[j] = tx;
            end
            #(BAUD_TICK);
            if(~tx) begin
                $display("%0t : stop bit error", $time);
            end
        end
    endtask

    initial begin
        clk = 0;
    end

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        rx  = 1;
        #10;
        rst = 0;
        #10;
        // simulation for UART RX
        send_data = 8'h31;
        SENDER_FOR_UART_RX(send_data);
        RECEIVER();
        if(send_data == receive_data) begin
            $display("%0t : PASS !!", $time);
        end else begin
            $display("%0t : FAIL !! send_data =  %d, receive_data = %d", $time,send_data, receive_data);
        end

        // #(BAUD_TICK * 12);
        #100;
        $stop;
    end

endmodule
