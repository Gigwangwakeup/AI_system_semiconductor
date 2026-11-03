`timescale 1ns / 1ps

module smartwatch (
    input clk,
    input reset,
    input btn_L,    //run_stop
    input btn_R,    //clear
    input btn_U,     //mode
    input btn_D,     // lap_register
    input [1:0]sw,
    output [4:0] lap_hour,
    output [5:0] lap_min,
    output [5:0] lap_sec,
    output [6:0] lap_msec,
    output [4:0] s_hour,
    output [5:0] s_min, 
    output [5:0] s_sec,
    output [6:0] s_msec,
    output [4:0] w_hour,
    output [5:0] w_min, 
    output [5:0] w_sec,
    output [6:0] w_msec,
    output [2:0] led,
    output led15
);

    reg w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    reg s_btn_L, s_btn_R, s_btn_U, s_btn_D;

    wire [3:0] w_fnd_com;
    wire [7:0] w_fnd_data;


    always @(*) begin
        s_btn_L = 0;
        s_btn_R = 0;
        s_btn_U = 0;
        s_btn_D = 0;
        w_btn_L = 0;
        w_btn_R = 0;
        w_btn_U = 0;
        w_btn_D = 0;
        if(sw[0]) begin
            s_btn_L = btn_L;
            s_btn_R = btn_R;
            s_btn_U = btn_U;
            s_btn_D = btn_D;
        end else begin
            w_btn_L = btn_L;
            w_btn_R = btn_R;
            w_btn_U = btn_U;
            w_btn_D = btn_D;
        end
    end

    top_stopwatch U_STOPWATCH_TOP (
        .clk(clk),
        .reset(reset),
        .btn_L(s_btn_L),    //run_stop
        .btn_R(s_btn_R),    //clear
        .btn_U(s_btn_U),     //mode
        .btn_D(s_btn_D),     // lap_register
        .sw(sw[1]), // sw[3]
        .hour(s_hour),
        .min(s_min),
        .sec(s_sec),
        .msec(s_msec),
        .lap_hour(lap_hour),
        .lap_min(lap_min),
        .lap_sec(lap_sec),
        .lap_msec(lap_msec)

    );

    top_watch U_WATCH_TOP (
        .clk(clk),
        .reset(reset),
        .btn_L(w_btn_L),
        .btn_R(w_btn_R),
        .btn_U(w_btn_U),
        .btn_D(w_btn_D),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .w2_hour(w_hour),
        .led15(led15)
    );
 

endmodule

