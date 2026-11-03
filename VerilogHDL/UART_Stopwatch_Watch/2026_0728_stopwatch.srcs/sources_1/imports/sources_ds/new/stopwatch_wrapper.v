`timescale 1ns / 1ps

module stopwatch_wrapper(
    input clk,
    input reset,
    input btn_L,  // runstop
    input btn_R,  // clear
    input btn_U,  // mode
    input btn_D,  // record
    input [2:0] sw,
    output display_mode,
    output [6:0] o_msec,
    output [5:0] o_sec,
    output [5:0] o_min,
    output [4:0] o_hour
);

    assign led = 2'b11;
    assign display_mode = sw[0];

    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire w_run_stop, w_clear, w_mode, w_record;
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;
    wire [6:0] rw_msec;
    wire [5:0] rw_sec;
    wire [5:0] rw_min;
    wire [4:0] rw_hour;
    

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    btn_debounce U_BD_MODE (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );

    btn_debounce U_BD_RECORD (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_run_stop(w_btn_L),
        .i_clear(w_btn_R),
        .i_mode(w_btn_U),
        .i_record(w_btn_D),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode),
        .o_record(w_record)
    );

    record U_RECORD (
    .clk(clk),
    .reset(reset),
    .btn_L(w_btn_L),
    .btn_R(w_btn_R),
    .hour(w_hour),
    .min(w_min),
    .sec(w_sec),
    .msec(w_msec),
    .sw(sw[2]),
    .record(w_record),
    .o_hour(rw_hour),
    .o_min(rw_min),
    .o_sec(rw_sec),
    .o_msec(rw_msec)
);

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .run_stop(w_run_stop),
        .clear(w_clear),
        .mode(w_mode),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

    mux_8x4 U_MUX_8x4 (
        .sel(sw[2]),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .r_msec(rw_msec),
        .r_sec(rw_sec),
        .r_min(rw_min),
        .r_hour(rw_hour),
        .o_msec(o_msec),
        .o_sec(o_sec),
        .o_min(o_min),
        .o_hour(o_hour)
);

endmodule
