`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/28 12:25:08
// Design Name: 
// Module Name: stopwatch
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


module gk_stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input reset,
    input edit_time,
    input left,
    input right,
    input up,
    input display_mode,
    output [1:0] ds,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);
    wire [MSEC_WIDTH-1:0] w_msec_edit;
    wire [ SEC_WIDTH-1:0] w_sec_edit;
    wire [ MIN_WIDTH-1:0] w_min_edit;
    wire [HOUR_WIDTH-1:0] w_hour_edit;
    wire w_tick_100hz, w_msec_tick, w_sec_tick, w_min_tick;

    wire [3:0] w_sec_ten, w_sec_unit;
    wire [3:0] w_min_ten, w_min_unit;
    wire [3:0] w_hour_ten, w_hour_unit;


    gk_tick_gen_100hz #(
        .F_COUNT(1_000_000)
    ) u_tick_gen_100hz (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_100hz)
    );

    gk_time_counter #(
        .BIT_WIDTH(MSEC_WIDTH),  // time_count bit
        .TIMES(100),     // time base
        .INIT(0)
    ) u_msec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_100hz),
        .edit_time(1'b0),
        .time_edit(7'd0),
        .time_count(msec),
        .o_tick(w_msec_tick)
    );

    gk_time_counter #(
        .BIT_WIDTH(SEC_WIDTH),  // time_count bit
        .TIMES(60),     // time base
        .INIT(0)
    ) u_sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_msec_tick),
        .edit_time(edit_time),
        .time_edit(w_sec_edit),
        .time_count(sec),
        .o_tick(w_sec_tick)
    );
    gk_time_counter #(
        .BIT_WIDTH(MIN_WIDTH),  // time_count bit
        .TIMES(60),     // time base
        .INIT(0)
    ) u_min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .edit_time(edit_time),
        .time_edit(w_min_edit),
        .time_count(min),
        .o_tick(w_min_tick)
    );

    gk_time_counter #(
        .BIT_WIDTH(HOUR_WIDTH),  // time_count bit
        .TIMES(24),     // time base
        .INIT(12)
    ) u_hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .edit_time(edit_time),
        .time_edit(w_hour_edit),
        .time_count(hour),
        .o_tick()
    );

    gk_bin2bcd #(
        .TIMES(60)
    ) u_bin2bcd_sec (
        .time_in (sec),
        .bcd_ten (w_sec_ten),
        .bcd_unit(w_sec_unit)
    );

    gk_bin2bcd #(
        .TIMES(60)
    ) u_bin2bcd_min (
        .time_in (min),
        .bcd_ten (w_min_ten),
        .bcd_unit(w_min_unit)
    );

    gk_bin2bcd #(
        .TIMES(24)
    ) u_bin2bcd_hour (
        .time_in (hour),
        .bcd_ten (w_hour_ten),
        .bcd_unit(w_hour_unit)
    );

    gk_bcd_combiner #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) u_bcd_combiner (
        .clk(clk),
        .rst(reset),
        .edit_time(edit_time),
        .display_mode(display_mode),  //L : sec, H : Hour
        .left(left),
        .right(right),
        .up(up),
        .sec_ten_in(w_sec_ten),
        .sec_unit_in(w_sec_unit),
        .min_ten_in(w_min_ten),
        .min_unit_in(w_min_unit),
        .hour_ten_in(w_hour_ten),
        .hour_unit_in(w_hour_unit),
        .ds(ds),
        .sec_edit(w_sec_edit),
        .min_edit(w_min_edit),
        .hour_edit(w_hour_edit)
    );

endmodule

module gk_tick_gen_100hz (
    input  clk,
    input  reset,
    output o_tick
);

    parameter F_COUNT = 1_000_000;

    reg o_tick_r = 0;
    reg [$clog2(F_COUNT)-1:0] tick_count;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            tick_count <= 0;
        end else begin
            tick_count <= tick_count + 1;
            if (tick_count == (F_COUNT - 1)) begin
                o_tick_r   <= 1'b1;
                tick_count <= 0;
            end else begin
                o_tick_r <= 1'b0;
            end
        end
    end

    assign o_tick = o_tick_r;

endmodule

module gk_time_counter #(
    parameter BIT_WIDTH = 7,  // time_count bit
    parameter TIMES = 100,
    parameter INIT = 0
) (
    input clk,
    input reset,
    input i_tick,
    input edit_time,
    input [BIT_WIDTH -1:0] time_edit,
    output [BIT_WIDTH-1:0] time_count,
    output o_tick
);

    reg [BIT_WIDTH-1:0] time_count_r;
    reg o_tick_r;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            time_count_r <= INIT;
            o_tick_r <= 1'b0;
        end else begin
            if (edit_time) begin
                time_count_r <= time_edit;
            end else begin
                if (i_tick) begin
                    time_count_r <= time_count_r + 1;
                    if (time_count_r == TIMES - 1) begin
                        time_count_r <= 0;
                        o_tick_r <= 1'b1;
                    end
                end else begin
                    o_tick_r <= 1'b0;
                end
            end
        end
    end

    assign time_count = time_count_r;
    assign o_tick = o_tick_r;

endmodule

module gk_bin2bcd #(
    parameter TIMES = 60
) (
    input [$clog2(TIMES)-1:0] time_in,
    output reg [3:0] bcd_ten,
    output reg [3:0] bcd_unit
);

    always @(*) begin
        if (time_in >= 50) begin
            bcd_ten  = 4'd5;
            bcd_unit = time_in - 6'd50;
        end else if (time_in >= 40) begin
            bcd_ten  = 4'd4;
            bcd_unit = time_in - 6'd40;
        end else if (time_in >= 30) begin
            bcd_ten  = 4'd3;
            bcd_unit = time_in - 6'd30;
        end else if (time_in >= 20) begin
            bcd_ten  = 4'd2;
            bcd_unit = time_in - 6'd20;
        end else if (time_in >= 10) begin
            bcd_ten  = 4'd1;
            bcd_unit = time_in - 6'd10;
        end else begin
            bcd_ten  = 0;
            bcd_unit = time_in[3:0];
        end
    end
endmodule

module gk_bcd_combiner #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                    clk,
    input                    rst,
    input                    edit_time,
    input                    display_mode,  //L : sec, H : Hour
    input                    left,
    input                    right,
    input                    up,
    input  [            3:0] sec_ten_in,
    input  [            3:0] sec_unit_in,
    input  [            3:0] min_ten_in,
    input  [            3:0] min_unit_in,
    input  [            3:0] hour_ten_in,
    input  [            3:0] hour_unit_in,
    output [            1:0] ds,
    output [ SEC_WIDTH -1:0] sec_edit,
    output [ MIN_WIDTH -1:0] min_edit,
    output [HOUR_WIDTH -1:0] hour_edit
);

    reg [3:0] hour_ten, hour_unit;
    reg [3:0] min_ten, min_unit;
    reg [3:0] sec_ten, sec_unit;

    assign hour_edit = (hour_ten << 3) + (hour_ten << 1) + hour_unit;
    assign min_edit  = (min_ten << 3) + (min_ten << 1) + min_unit;
    assign sec_edit  = (sec_ten << 3) + (sec_ten << 1) + sec_unit;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            hour_ten  <= 0;
            hour_unit <= 0;
            min_ten   <= 0;
            min_unit  <= 0;
            sec_ten   <= 0;
            sec_unit  <= 0;
        end else begin
            if (edit_time) begin
                case ({
                    display_mode, ds
                })
                    5'b111:
                    if (up) begin
                        if (hour_ten > 1 || (hour_ten == 1 && hour_unit > 3))
                            hour_ten <= 0;
                        else hour_ten <= hour_ten + 1;
                    end
                    5'b110:
                    if (up) begin
                        if (hour_unit == 9 || (hour_ten > 1 && hour_unit == 3))
                            hour_unit <= 0;
                        else hour_unit <= hour_unit + 1;
                    end
                    5'b101:
                    if (up) begin
                        if (min_ten == 5) min_ten <= 0;
                        else min_ten <= min_ten + 1;
                    end
                    5'b100:
                    if (up) begin
                        if (min_unit == 9) min_unit <= 0;
                        else min_unit <= min_unit + 1;
                    end
                    5'b011:
                    if (up) begin
                        if (sec_ten == 5) sec_ten <= 0;
                        else sec_ten <= sec_ten + 1;
                    end
                    5'b010:
                    if (up) begin
                        if (sec_unit == 9) sec_unit <= 0;
                        else sec_unit <= sec_unit + 1;
                    end
                endcase
            end else begin
                hour_ten  <= hour_ten_in;
                hour_unit <= hour_unit_in;
                min_ten   <= min_ten_in;
                min_unit  <= min_unit_in;
                sec_ten   <= sec_ten_in;
                sec_unit  <= sec_unit_in;
            end
        end
    end

    gk_time_digit_sel u_time_ds (
        .clk(clk),
        .rst(rst),
        .edit_time(edit_time),
        .display_mode(display_mode),
        .left(left),
        .right(right),
        .ds(ds)
    );
endmodule

module gk_time_digit_sel (
    input clk,
    input rst,
    input edit_time,
    input display_mode,
    input left,
    input right,
    output [1:0] ds
);
    reg [1:0] digit_cnt;
    reg display_mode_r0, display_mode_r1, display_mode_r2;
    wire mode_edge_detect;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            display_mode_r0 <= 0;
            display_mode_r1 <= 0;
            display_mode_r2 <= 0;
        end else begin
            display_mode_r0 <= display_mode;
            display_mode_r1 <= display_mode_r0;
            display_mode_r2 <= display_mode_r1;
        end
    end

    assign mode_edge_detect = display_mode_r2 & ~display_mode_r1;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            digit_cnt <= 2'b11;
        end else begin
            case (edit_time)
                1'b1: begin
                    if (display_mode) begin
                        if (left) begin
                            digit_cnt <= digit_cnt + 1;
                        end
                        if (right) begin
                            digit_cnt <= digit_cnt - 1;
                        end
                    end else begin
                        if (mode_edge_detect) begin
                            if (digit_cnt > 1) 
                                digit_cnt <= digit_cnt;
                            else
                                digit_cnt <= 2;
                        end else begin
                            if (left) begin
                                digit_cnt <= digit_cnt + 1;
                                if ((digit_cnt < 1) | (digit_cnt == 3))
                                    digit_cnt <= 2;
                            end
                            if (right) begin
                                digit_cnt <= digit_cnt - 1;
                                if ((digit_cnt == 2 | digit_cnt < 3))
                                    digit_cnt <= 3;
                            end
                        end
                    end
                end
                1'b0: digit_cnt <= 2;
            endcase
        end
    end

    assign ds = digit_cnt;
endmodule
