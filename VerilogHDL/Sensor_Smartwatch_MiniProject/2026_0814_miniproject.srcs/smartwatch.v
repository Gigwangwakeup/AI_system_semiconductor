`timescale 1ns / 1ps

module smartwatch (
    input clk,
    input reset,
    input btn_L,    //run_stop
    input btn_R,    //clear
    input btn_U,     //mode
    input btn_D,     // lap_register
    input [2:0] sw,
    output [4:0] o_hour,
    output [5:0] o_min, 
    output [5:0] o_sec,
    output [6:0] o_msec,
    output [2:0] led,
    output led15
);

    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire [3:0] w_fnd_com;
    wire [7:0] w_fnd_data;
    wire [6:0] w1_msec;
    wire [5:0] w1_sec;
    wire [5:0] w1_min;
    wire [4:0] w1_hour;
    wire [6:0] w_msec, w_lap_ms;
    wire [5:0] w_sec, w_lap_s;
    wire [5:0] w_min, w_lap_m;
    wire [4:0] w_hour, w_lap_h;

    
    assign led = sw;

    top_stopwatch U_STOPWATCH_TOP (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),    //run_stop
        .btn_R(btn_R),    //clear
        .btn_U(btn_U),     //mode
        .btn_D(btn_D),     // lap_register
        .sw(sw),
        .lap_hour(w_lap_h),
        .lap_min(w_lap_m),
        .lap_sec(w_lap_s),
        .lap_msec(w_lap_ms)

    );

    top_watch U_WATCH_TOP (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),
        .btn_R(btn_R),
        .btn_U(btn_U),
        .btn_D(btn_D),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .w2_hour(w_hour),
        .led15(led15)
    );

    mux_2x1_2 U_CHANGE_MODE (

        .sw1(sw[1]),
        .watch_msec(w_msec),
        .watch_sec(w_sec),
        .watch_min(w_min),
        .watch_hour(w_hour),
        .sw_msec(w_lap_ms),
        .sw_sec(w_lap_s),
        .sw_min(w_lap_m),
        .sw_hour(w_lap_h),
        .o_msec(o_msec),
        .o_sec(o_sec),
        .o_min(o_min),
        .o_hour(o_hour)

    );
 

endmodule

module mux_2x1_2 #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (

    input sw1,
    input [MSEC_WIDTH-1:0] watch_msec,
    input [SEC_WIDTH-1:0] watch_sec,
    input [MIN_WIDTH-1:0] watch_min,
    input [HOUR_WIDTH-1:0] watch_hour,

    input [MSEC_WIDTH-1:0] sw_msec,
    input [ SEC_WIDTH-1:0] sw_sec,
    input [ MIN_WIDTH-1:0] sw_min,
    input [HOUR_WIDTH-1:0] sw_hour,

    output [MSEC_WIDTH-1:0] o_msec,
    output [ SEC_WIDTH-1:0] o_sec,
    output [ MIN_WIDTH-1:0] o_min,
    output [HOUR_WIDTH-1:0] o_hour

);

    assign o_msec = sw1 ? watch_msec : sw_msec;
    assign o_sec  = sw1 ? watch_sec : sw_sec;
    assign o_min  = sw1 ? watch_min : sw_min;
    assign o_hour = sw1 ? watch_hour : sw_hour;

endmodule