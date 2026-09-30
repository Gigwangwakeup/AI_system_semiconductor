`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/28 16:52:33
// Design Name: 
// Module Name: top
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


module gk_watch_wrapper #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input reset,
    input btn_D,  // edit_time,
    input btn_L,  // left,
    input btn_R,  // right,
    input btn_U,  // up,
    input [2:0] sw,  // {record, stopwatch/watch, display_mode},
    output [MSEC_WIDTH -1:0] msec,
    output [SEC_WIDTH -1:0] sec,
    output [MIN_WIDTH -1:0] min,
    output [HOUR_WIDTH -1:0] hour,
    output display_mode,  // sw[0]
    output edit_time,
    output [1:0] ds
    // output [1:0] led,
    // output [3:0] fnd_com,
    // output [7:0] fnd_data
);

    wire w_bd_edit_time, w_bd_left, w_bd_right, w_bd_up;
    wire w_edit_time, w_left, w_right, w_up;
    // wire [MSEC_WIDTH-1:0] w_msec;
    // wire [SEC_WIDTH-1:0] w_sec;
    // wire [MIN_WIDTH-1:0] w_min;
    // wire [HOUR_WIDTH-1:0] w_hour;
    // wire [1:0] w_ds;

    assign display_mode = sw[0];

    assign led = 2'b11;
    assign edit_time = w_edit_time;

    gk_btn_debounce watch_bd_edit_time (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btn_D),
        .o_btn(w_bd_edit_time)
    );
    gk_btn_debounce watch_bd_left (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btn_L),
        .o_btn(w_bd_left)
    );
    gk_btn_debounce watch_bd_right (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btn_R),
        .o_btn(w_bd_right)
    );

   gk_btn_debounce watch_bd_up (
        .clk  (clk),
        .rst  (reset),
        .i_btn(btn_U),
        .o_btn(w_bd_up)
    );

    gk_control_unit u_control_unit (
        .clk        (clk),
        .rst        (reset),
        .i_left     (w_bd_left),
        .i_right    (w_bd_right),
        .i_edit_time(w_bd_edit_time),
        .o_left     (w_left),
        .o_right    (w_right),
        .o_edit_time(w_edit_time)
    );

    gk_stopwatch_datapath #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) u_stopwatch_datapath (
        .clk(clk),
        .reset(reset),
        .edit_time(w_edit_time),
        .left(w_left),
        .right(w_right),
        .up(w_bd_up),
        .display_mode(display_mode),
        .ds(ds),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );


    // fnd_controller #(
    //     .MSEC_WIDTH(MSEC_WIDTH),
    //     .SEC_WIDTH (SEC_WIDTH),
    //     .MIN_WIDTH (MIN_WIDTH),
    //     .HOUR_WIDTH(HOUR_WIDTH)
    // ) u_fnd_controller (
    //     .clk(clk),
    //     .rst(reset),
    //     .msec(w_msec),
    //     .sec(w_sec),
    //     .min(w_min),
    //     .hour(w_hour),
    //     .display_mode(display_mode),  // sw[0]
    //     .edit_time(w_edit_time),
    //     .ds(w_ds),
    //     .fnd_com(fnd_com),
    //     .fnd_data(fnd_data)
    // );
endmodule
