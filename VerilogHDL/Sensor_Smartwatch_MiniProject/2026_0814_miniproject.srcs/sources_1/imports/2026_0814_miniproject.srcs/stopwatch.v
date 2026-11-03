`timescale 1ns / 1ps

module top_stopwatch (
    input        clk,
    input        reset,
    input        btn_L,     //run_stop
    input        btn_R,     //clear
    input        btn_U,     //mode
    input        btn_D,     // lap_register
    input   sw,
    output [4:0] hour,
    output [5:0] min,
    output [5:0] sec,
    output [6:0] msec,
    output [4:0] lap_hour,
    output [5:0] lap_min,
    output [5:0] lap_sec,
    output [6:0] lap_msec
);

    parameter F_COUNT = 1_000_000;

    assign led = 3'b111;
    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire w_run_stop, w_clear, w_mode;
    wire [6:0] w_msec, w_lap_msec;
    wire [5:0] w_sec, w_lap_sec;
    wire [5:0] w_min, w_lap_min;
    wire [4:0] w_hour, w_lap_hour;
    //wire [4:0] disp_hour;
    //wire [5:0] disp_min;
    //wire [5:0] disp_sec;
    //wire [6:0] disp_msec;

    // choice lap_time, real time
    assign hour = sw ? w_lap_hour : w_hour;
    assign min  = sw ? w_lap_min : w_min;
    assign sec  = sw ? w_lap_sec : w_sec;
    assign msec = sw ? w_lap_msec : w_msec;

    assign lap_hour = w_lap_hour;
    assign lap_min = w_lap_min;
    assign lap_sec = w_lap_sec;
    assign lap_msec = w_lap_msec;

    stopwatch_datapath #(
        .F_COUNT(F_COUNT)
    ) U_STOPWATCH_DATAPATH (
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

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    btn_debounce U_BD_MODE (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );

    btn_debounce U_BD_LAP (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_run_stop(w_btn_L),
        .i_clear(w_btn_R),
        .i_mode(w_btn_U),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode)
    );

    lap_register U_LAP_REG (
        .clk(clk),
        .reset(reset),
        .clear(w_clear),
        .save_pulse(w_btn_D),
        .hour(w_hour),
        .min(w_min),
        .sec(w_sec),
        .msec(w_msec),
        .lap_hour(w_lap_hour),
        .lap_min(w_lap_min),
        .lap_sec(w_lap_sec),
        .lap_msec(w_lap_msec)
    );

endmodule


module stopwatch_datapath #(

    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5,
    F_COUNT = 1_000_000
) (
    input clk,
    input reset,
    input run_stop,
    input clear,
    input mode,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);


    // parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;
    wire w_tick_100hz, w_tick_sec, w_tick_min, w_tick_hour;


    time_counter #(
        .BIT_WIDTH(HOUR_WIDTH),
        .TIMES(24)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_hour),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_count(hour),
        .o_tick()
    );

    time_counter #(
        .BIT_WIDTH(MIN_WIDTH),
        .TIMES(60)
    ) U_MIN_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_count(min),
        .o_tick(w_tick_hour)
    );


    time_counter #(
        .BIT_WIDTH(SEC_WIDTH),
        .TIMES(60)
    ) U_SEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_count(sec),
        .o_tick(w_tick_min)
    );


    time_counter #(
        .BIT_WIDTH(MSEC_WIDTH),
        .TIMES(100)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .time_count(msec),
        .o_tick(w_tick_sec)
    );


    tick_gen_100hz #(
        .F_COUNT(F_COUNT)
    ) U_TICK_GEN_100HZ (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_100hz)
    );

endmodule


module time_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input run_stop,
    input clear,
    output [BIT_WIDTH-1:0] time_count,
    output reg o_tick
);

    reg [$clog2(TIMES)-1:0] counter_reg;

    assign time_count = counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            if (i_tick & run_stop) begin
                if (!mode) begin
                    counter_reg <= counter_reg + 1;
                    if (counter_reg == (TIMES - 1)) begin
                        counter_reg <= 0;
                        o_tick <= 1'b1;
                    end
                end else begin
                    counter_reg <= counter_reg - 1;
                    if (counter_reg == 0) begin
                        counter_reg <= (TIMES - 1);
                        o_tick <= 1'b1;
                    end
                end
            end else begin
                o_tick <= 1'b0;
            end
        end
    end

endmodule


module tick_gen_100hz (
    input clk,
    input reset,
    output reg o_tick
);
    parameter F_COUNT = 1_000_000;

    reg [$clog2(F_COUNT) - 1 : 0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
        end
    end

endmodule


// number_register
module lap_register (
    input clk,
    input reset,
    input clear,
    input save_pulse,
    input [4:0] hour,
    input [5:0] min,
    input [5:0] sec,
    input [6:0] msec,
    output reg [4:0] lap_hour,
    output reg [5:0] lap_min,
    output reg [5:0] lap_sec,
    output reg [6:0] lap_msec
);

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            lap_hour <= 0;
            lap_min  <= 0;
            lap_sec  <= 0;
            lap_msec <= 0;
        end else begin
            if (save_pulse) begin
                lap_hour <= hour;
                lap_min  <= min;
                lap_sec  <= sec;
                lap_msec <= msec;
            end
        end
    end
endmodule