`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/28 15:12:03
// Design Name: 
// Module Name: tb_stopwatch
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


`timescale 1ns / 1ps

module tb_stopwatch ();

    // reg clk, reset, run_stop, clear, mode;
    // wire [6:0] msec;
    // wire [5:0] sec, min;
    // wire [4:0] hour;

    // // 1TICK 1_000_000ns ?�� 1Clock ?�� 10ns?��?��
    // // 1_000_000 = 100hz number 0f clock from 100Mhz, 1clock = 10nsec 
    // parameter TICK_DELAY = 1_000_000 * 10;

    // stopwatch_datapath DUT (
    //     .clk(clk),
    //     .reset(reset),
    //     .runstop(run_stop),
    //     .clear(clear),
    //     .mode(mode),
    //     .msec(msec),
    //     .sec(sec),
    //     .min(min),
    //     .hour(hour)
    // );

    // // generator clock 100Mhz
    // always #5 clk = ~clk;

    // initial begin
    //     clk = 0;
    //     reset = 1;
    //     run_stop = 1;
    //     clear = 0;
    //     mode = 0;
    //     #10;
    //     reset = 0;
    //     #(TICK_DELAY * 5);
    //     #100;
    //     $stop;

    // end


    reg clk, reset, run_stop, clear, mode, display_mode;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    parameter TICK_DELAY = 1_000_000 * 10;


top dut(
    .clk(clk),
    .reset(reset),
    .run_stop(run_stop),
    .clear(clear),
    .mode(mode),
    .display_mode(display_mode),
    .fnd_com(fnd_com), // O [3:0]
    .fnd_data(fnd_data) // O [7:0]
);

// generator clock 100Mhz
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        run_stop = 1;
        clear = 0;
        mode = 0;
        display_mode = 0; // sec,msec
        #10;
        reset = 0;
        #(TICK_DELAY * 5);
        #100;
        $stop;

    end
endmodule
