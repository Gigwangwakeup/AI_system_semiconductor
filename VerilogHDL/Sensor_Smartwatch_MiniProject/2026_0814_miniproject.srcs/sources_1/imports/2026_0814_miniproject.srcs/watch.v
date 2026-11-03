`timescale 1ns / 1ps

module top_watch (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input btn_U,
    input btn_D,
    output led15,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] w2_hour
);

    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire w_time_up, w_time_down;
    wire [2:0] w_select;
    wire [4:0] hour;


    btn_debounce U_SHIFT_UP (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );
    btn_debounce U_SHIFT_DOWN (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );
    btn_debounce U_T_SET_UP (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );
    btn_debounce U_T_SET_DOWN (
        .clk  (clk),
        .rst(reset),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );

    watch_control_unit U_WAtCH_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_shift_up(w_btn_L),    //btn_L
        .i_shift_down(w_btn_R),  //btn_R
        .i_time_up(w_btn_U),     //btn_U
        .i_time_down(w_btn_D),   //btn_D
        .o_select(w_select),   // current_state = last state
        .o_time_up(w_time_up),
        .o_time_down(w_time_down)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .o_select(w_select),
        .time_up(w_time_up),
        .time_down(w_time_down),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(w2_hour)
    );


endmodule

module watch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input reset,
    input [2:0] o_select,
    input time_up,
    input time_down,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour

);


    wire w_tick_100hz, w_tick_sec, w_tick_min, w_tick_hour, w_tick_ban;

    wire w_msec_up = (o_select == 3'b001) && time_up;
    wire w_msec_down = (o_select == 3'b001) && time_down;
    wire w_sec_up = (o_select == 3'b010) && time_up;
    wire w_sec_down = (o_select == 3'b010) && time_down;
    wire w_min_up = (o_select == 3'b011) && time_up;
    wire w_min_down = (o_select == 3'b011) && time_down;
    wire w_hour_up = (o_select == 3'b100) && time_up;
    wire w_hour_down = (o_select == 3'b100) && time_down;

    
    assign w_tick_ban = (o_select == 3'b000);    

    tick_gen_100hz U_TICK_GEN (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_100hz)
    );

    watch_counter #(
        .BIT_WIDTH(7),
        .TIMES(100),
        .reset_value(0)
    ) U_MSEC_COUNTER_2 (
        .clk(clk),
        .reset(reset),
        .t_tick(w_tick_100hz),
        .time_up(w_msec_up),
        .time_down(w_msec_down),
        .time_count(msec),
        .tick_ban(w_tick_ban),
        .o_tick(w_tick_sec)
    );

    watch_counter #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .reset_value(0)
    ) u_SEC_COUNTER_2 (
        .clk(clk),
        .reset(reset),
        .t_tick(w_tick_sec),
        .time_up(w_sec_up),
        .time_down(w_sec_down),
        .time_count(sec),
        .tick_ban(w_tick_ban),
        .o_tick(w_tick_min)
    );

    watch_counter #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .reset_value(0)
    ) u_MIN_COUNTER_2 (
        .clk(clk),
        .reset(reset),
        .t_tick(w_tick_min),
        .time_up(w_min_up),
        .time_down(w_min_down),
        .time_count(min),
        .tick_ban(w_tick_ban),
        .o_tick(w_tick_hour)
    );

    watch_counter #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .reset_value(12)
    ) u_HOUR_COUNTER_2 (
        .clk(clk),
        .reset(reset),
        .t_tick(w_tick_hour),
        .time_up(w_hour_up),
        .time_down(w_hour_down),
        .time_count(hour),
        .tick_ban(w_tick_ban),
        .o_tick()
    );


endmodule

module watch_counter #(
    parameter BIT_WIDTH = 7,
    parameter TIMES = 100,
    parameter reset_value = 0
) (
    input clk,
    input reset,
    input t_tick,
    input time_up,
    input time_down,
    input tick_ban,
    output [BIT_WIDTH-1:0] time_count,
    output reg o_tick
);
    reg [$clog2(TIMES)-1:0] counter_reg;
    assign time_count = counter_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= reset_value;
            o_tick <= 1'b0;
        end else begin

            if (time_up) begin
                if (counter_reg == (TIMES - 1)) begin
                    counter_reg <= 0;
                end else begin
                    counter_reg <= counter_reg + 1;
                end
            end else if (time_down) begin
                if (counter_reg == 0) begin
                    counter_reg <= (TIMES - 1);
                end else begin
                    counter_reg <= counter_reg - 1;
                end
            end else if (t_tick && tick_ban) begin
                counter_reg <= counter_reg + 1;
            end
            if (t_tick && tick_ban && counter_reg == (TIMES - 1)) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
 
        end
    end
            

endmodule

