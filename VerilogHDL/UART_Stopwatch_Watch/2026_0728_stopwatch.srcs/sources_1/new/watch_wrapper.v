`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/31 11:39:06
// Design Name: 
// Module Name: watch_wrapper
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


module stopwatch_watch #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input        clk,
    input        reset,
    input        rx,
    input        btn_D,    // edit_time,
    input        btn_L,    // left,
    input        btn_R,    // right,
    input        btn_U,    // up,
    input  [2:0] sw,       // {record, stopwatch/watch, display_mode},
    output       tx,
    output [1:0] led,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_watch_btn_D, w_watch_btn_L, w_watch_btn_R, w_watch_btn_U, w_watch_sw;
    wire w_w_btn_D, w_w_btn_L, w_w_btn_R, w_w_btn_U;
    wire w_stopwatch_btn_D, w_stopwatch_btn_L, w_stopwatch_btn_R, w_stopwatch_btn_U;
    wire w_sw_btn_D, w_sw_btn_L, w_sw_btn_R, w_sw_btn_U;
    wire [1:0] w_stopwatch_sw, w_watch_ds;
    wire w_display, w_watch_display, w_stopwatch_display;
    wire [MSEC_WIDTH -1:0] w_msec, w_watch_msec, w_stopwatch_msec;
    wire [SEC_WIDTH -1:0] w_sec, w_watch_sec, w_stopwatch_sec;
    wire [MIN_WIDTH -1:0] w_min, w_watch_min, w_stopwatch_min;
    wire [HOUR_WIDTH -1:0] w_hour, w_watch_hour, w_stopwatch_hour;

    //uart loop back
    wire w_rx_done;
    wire [7:0] w_rx_data;
    wire w_sw_run, w_sw_record, w_sw_clear, w_sw_mode;
    wire w_w_up, w_w_left, w_w_right, w_w_edit;

    assign led = sw[1:0];

    i_demux u_i_demux (
        .btn_D(btn_D),
        .btn_L(btn_L),
        .btn_R(btn_R),
        .btn_U(btn_U),
        .sw(sw),
        .watch_btn_D(w_w_btn_D),
        .watch_btn_L(w_w_btn_L),
        .watch_btn_R(w_w_btn_R),
        .watch_btn_U(w_w_btn_U),
        .watch_sw(w_watch_sw),
        .stopwatch_btn_D(w_sw_btn_D),
        .stopwatch_btn_L(w_sw_btn_L),
        .stopwatch_btn_R(w_sw_btn_R),
        .stopwatch_btn_U(w_sw_btn_U),
        .stopwatch_sw(w_stopwatch_sw)
    );

    assign w_watch_btn_D = w_w_btn_D | w_w_edit;
    assign w_watch_btn_L = w_w_btn_L | w_w_left;
    assign w_watch_btn_R = w_w_btn_R | w_w_right;
    assign w_watch_btn_U = w_w_btn_U | w_w_up;
    assign w_stopwatch_btn_D = w_sw_btn_D | w_sw_record;
    assign w_stopwatch_btn_L = w_sw_btn_L | w_sw_clear;
    assign w_stopwatch_btn_R = w_sw_btn_R | w_sw_mode;
    assign w_stopwatch_btn_U = w_sw_btn_U | w_sw_run;

    gk_watch_wrapper #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) u_watch_wrapper (
        .clk(clk),
        .reset(reset),
        .btn_D(w_watch_btn_D),  // edit_time,
        .btn_L(w_watch_btn_L),  // left,
        .btn_R(w_watch_btn_R),  // right,
        .btn_U(w_watch_btn_U),  // up,
        .sw({
            2'b00, w_watch_sw
        }),  // [2:0] {record, stopwatch/watch, display_mode},
        .display_mode(w_watch_display),  // sw[0]
        .msec(w_watch_msec),  // [MSEC_WIDTH -1:0]
        .sec(w_watch_sec),  // [SEC_WIDTH -1:0] 
        .min(w_watch_min),  // [MIN_WIDTH -1:0] 
        .hour(w_watch_hour),  // [HOUR_WIDTH -1:0]
        .edit_time(w_watch_edit),
        .ds(w_watch_ds)  //[1:0]
        // output [1:0] led,
        // output [3:0] fnd_com,
        // output [7:0] fnd_data
    );

    // output mux display,msec,sec,min,hour 
    ds_stopwatch_wrapper #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) u_stopwatch_wrapper (
        .clk(clk),
        .reset(reset),
        .btn_D(w_stopwatch_btn_D),  // record
        .btn_L(w_stopwatch_btn_L),  // clear
        .btn_R(w_stopwatch_btn_R),  // mode
        .btn_U(w_stopwatch_btn_U),  // runstop
        .sw({w_stopwatch_sw[1], 1'b0, w_stopwatch_sw[0]}),
        .display_mode(w_stopwatch_display),
        .o_msec(w_stopwatch_msec),
        .o_sec(w_stopwatch_sec),
        .o_min(w_stopwatch_min),
        .o_hour(w_stopwatch_hour)
    );

    o_mux #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) u_o_mux (
        .watch_stopwatch(sw[1]),
        .watch_display(w_watch_display),
        .watch_msec(w_watch_msec),
        .watch_sec(w_watch_sec),
        .watch_min(w_watch_min),
        .watch_hour(w_watch_hour),
        .stopwatch_display(w_stopwatch_display),
        .stopwatch_msec(w_stopwatch_msec),
        .stopwatch_sec(w_stopwatch_sec),
        .stopwatch_min(w_stopwatch_min),
        .stopwatch_hour(w_stopwatch_hour),
        .display(w_display),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

    fnd_controller #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) u_fnd_controller (
        .clk(clk),
        .rst(reset),
        .display_mode(w_display),  // sw[0]
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .edit_time(w_watch_edit),
        .ds(w_watch_ds),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );
    // reg sw1_sync1, sw1_sync;
    // always @(posedge clk) begin
    //     sw1_sync1 <= sw[1];   // 1?‹¨ ?™ê¸°í™”
    //     sw1_sync  <= sw1_sync1; // 2?‹¨ ?™ê¸°í™” (ë©”í??Š¤?…Œ?´ë¸? ë°©ì?)
    // end

    uart_loop_back u_uart_loop_back (
        .clk(clk),
        .rst(reset),
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data),
        .tx(tx)
    );

    ascii_decoder u_ascii_decoder (
        .clk(clk),
        .rst(reset),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data),
        .sw_run(w_sw_run),
        .sw_record(w_sw_record),
        .sw_clear(w_sw_clear),
        .sw_mode(w_sw_mode),
        .w_up(w_w_up),
        .w_left(w_w_left),
        .w_right(w_w_right),
        .w_edit(w_w_edit)
    );
endmodule



module i_demux (
    input            btn_D,
    input            btn_L,
    input            btn_R,
    input            btn_U,
    input      [2:0] sw,
    output reg       watch_btn_D,
    output reg       watch_btn_L,
    output reg       watch_btn_R,
    output reg       watch_btn_U,
    output reg       watch_sw,
    output reg       stopwatch_btn_D,
    output reg       stopwatch_btn_L,
    output reg       stopwatch_btn_R,
    output reg       stopwatch_btn_U,
    output reg [1:0] stopwatch_sw
);

    wire watch_stopwatch = sw[1];


    always @(*) begin
        watch_btn_D     = 1'b0;
        watch_btn_L     = 1'b0;
        watch_btn_R     = 1'b0;
        watch_btn_U     = 1'b0;
        watch_sw        = 1'b0;
        stopwatch_btn_D = 1'b0;
        stopwatch_btn_L = 1'b0;
        stopwatch_btn_R = 1'b0;
        stopwatch_btn_U = 1'b0;
        stopwatch_sw    = 2'b00;
        case (watch_stopwatch)
            1'b1: begin
                watch_btn_D = btn_D;
                watch_btn_L = btn_L;
                watch_btn_R = btn_R;
                watch_btn_U = btn_U;
                watch_sw = sw[0];
            end
            1'b0: begin
                stopwatch_btn_D = btn_D;
                stopwatch_btn_L = btn_L;
                stopwatch_btn_R = btn_R;
                stopwatch_btn_U = btn_U;
                stopwatch_sw = {sw[2], sw[0]};
            end
        endcase
    end
endmodule

module o_mux #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input watch_stopwatch,
    input watch_display,
    input [MSEC_WIDTH -1:0] watch_msec,
    input [SEC_WIDTH -1:0] watch_sec,
    input [MIN_WIDTH -1:0] watch_min,
    input [HOUR_WIDTH -1:0] watch_hour,
    input stopwatch_display,
    input [MSEC_WIDTH -1:0] stopwatch_msec,
    input [SEC_WIDTH -1:0] stopwatch_sec,
    input [MIN_WIDTH -1:0] stopwatch_min,
    input [HOUR_WIDTH -1:0] stopwatch_hour,
    output reg display,
    output reg [MSEC_WIDTH -1:0] msec,
    output reg [SEC_WIDTH -1:0] sec,
    output reg [MIN_WIDTH -1:0] min,
    output reg [HOUR_WIDTH -1:0] hour
);

    always @(*) begin
        case (watch_stopwatch)
            1'b1: begin
                display = watch_display;
                msec    = watch_msec;
                sec     = watch_sec;
                min     = watch_min;
                hour    = watch_hour;
            end
            1'b0: begin
                display = stopwatch_display;
                msec    = stopwatch_msec;
                sec     = stopwatch_sec;
                min     = stopwatch_min;
                hour    = stopwatch_hour;
            end
            default: begin
                display = stopwatch_display;
                msec    = stopwatch_msec;
                sec     = stopwatch_sec;
                min     = stopwatch_min;
                hour    = stopwatch_hour;
            end
        endcase
    end


endmodule
