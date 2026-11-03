`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/20 12:41:39
// Design Name: 
// Module Name: fnd_controller
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
module fnd_controller #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                    clk,
    input                    rst,
    input  [MSEC_WIDTH -1:0] msec,
    input  [ SEC_WIDTH -1:0] sec,
    input  [ MIN_WIDTH -1:0] min,
    input  [HOUR_WIDTH -1:0] hour,
    input                    display_mode,  // sw[0]
    input                    edit_time,
    input  [            1:0] ds,
    output [            3:0] fnd_com,
    output [            7:0] fnd_data
);

    // =============================================================================================
    // wire, reg
    // =============================================================================================
    wire [3:0] w_mux_out_ms, w_mux_out_mh, w_mux_out;
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [2:0] digit_sel;
    wire [3:0] w_dot_onoff;
    wire       clk_1Khz;
    // =============================================================================================
    // instance
    // =============================================================================================
    clk_divider u_clk_divider (
        .clk     (clk),
        .rst     (rst),
        .clk_1Khz(clk_1Khz)
    );
    counter u_counter (
        .clk      (clk_1Khz),
        .rst      (rst),
        .digit_sel(digit_sel)
    );

    decoder_2x4 u_decoder_2x4 (
        .digit_sel(digit_sel[1:0]),
        .fnd_com  (fnd_com)
    );

    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) u_ds_msec (
        .ds_in(msec),
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) u_ds_sec (
        .ds_in(sec),
        .digit_1(w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) u_ds_min (
        .ds_in(min),
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) u_ds_hour (
        .ds_in(hour),
        .digit_1(w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    comparator_dot #(
        .MSEC_WIDTH(MSEC_WIDTH)
    ) u_comp_dot (
        .msec(msec),
        .ds(ds),
        .edit_time(edit_time),
        .dot_onoff(w_dot_onoff)
    );

    mux_8x1 u_mux_8x1_a (
        .sel    (digit_sel),
        .in0    (w_msec_digit_1),
        .in1    (w_msec_digit_10),
        .in2    (w_sec_digit_1),
        .in3    (w_sec_digit_10),
        .in4    ({3'b111, w_dot_onoff[0]}),
        .in5    ({3'b111, w_dot_onoff[1]}),
        .in6    ({3'b111, w_dot_onoff[2]}),  // sel 3'b110, dot display
        .in7    ({3'b111, w_dot_onoff[3]}),
        .mux_out(w_mux_out_ms)
    );
    mux_8x1 u_mux_8x1_b (
        .sel    (digit_sel),
        .in0    (w_min_digit_1),
        .in1    (w_min_digit_10),
        .in2    (w_hour_digit_1),
        .in3    (w_hour_digit_10),
        .in4    ({3'b111, w_dot_onoff[0]}),
        .in5    ({3'b111, w_dot_onoff[1]}),
        .in6    ({3'b111, w_dot_onoff[2]}),
        .in7    ({3'b111, w_dot_onoff[3]}),
        .mux_out(w_mux_out_mh)
    );

    mux_2x1 u_mux_2x1 (
        .sel(display_mode),
        .in0(w_mux_out_ms),
        .in1(w_mux_out_mh),
        .mux_out(w_mux_out)
    );

    bcd u_bcd (
        .bcd_in (w_mux_out),
        .bcd_out(fnd_data)
    );
endmodule


// =============================================================================================
// module
// =============================================================================================
module clk_divider (
    input clk,
    input rst,
    output clk_1Khz,
    output clk_50Mhz,  // 2분주
    output clk_25Mhz,  // 4분주
    output clk_16Mhz,  // 6분주
    output clk_8Mhz_1_1,  //12분주 1:1
    output clk_8Mhz_2_1,  //12분주 2:1
    output clk_8Mhz_1_2  //12분주 1:2
);
    reg [15:0] cnt = 16'h0000;
    reg clk_1Khz_reg = 1'b0;
    //과제
    reg [3:0] cnt12 = 4'b0000;
    reg
        clk_50Mhz_r,
        clk_25Mhz_r,
        clk_16Mhz_r,
        clk_8Mhz_1_1_r,
        clk_8Mhz_2_1_r,
        clk_8Mhz_1_2_r = 1'b0;

    // 1Khz
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt <= 16'h0000;
            clk_1Khz_reg <= 1'b0;
        end else begin
            cnt <= cnt + 1;
            if (cnt == (50000 - 1)) begin
                cnt <= 16'h0000;
                clk_1Khz_reg <= ~clk_1Khz_reg;
            end
        end
    end

    assign clk_1Khz = clk_1Khz_reg;


    //12 카운터
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt12 <= 4'b1111;
        end else begin
            cnt12 <= cnt12 + 1;
            if (cnt12 == (12 - 1)) begin
                cnt12 <= 4'b0000;
            end
        end
    end
    //과제 분주된 클럭 출력 
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            clk_50Mhz_r <= 1'b0;
            clk_25Mhz_r <= 1'b0;
            clk_16Mhz_r <= 1'b0;
            clk_8Mhz_1_1_r <= 1'b0;
            clk_8Mhz_2_1_r <= 1'b0;
            clk_8Mhz_1_2_r <= 1'b0;
        end else begin
            clk_50Mhz_r <= cnt12[0];
            clk_25Mhz_r <= cnt12[1];

            if (cnt12 % 3 == 2) begin
                clk_16Mhz_r <= ~clk_16Mhz_r;
            end

            if (cnt12 % 6 == 5) begin
                clk_8Mhz_1_1_r <= ~clk_8Mhz_1_1_r;
            end

            if (cnt12 < 8) begin
                clk_8Mhz_2_1_r <= 1'b1;
            end else begin
                clk_8Mhz_2_1_r <= 1'b0;
            end
            if (cnt12 < 4) begin
                clk_8Mhz_1_2_r <= 1'b1;
            end else begin
                clk_8Mhz_1_2_r <= 1'b0;
            end
        end
    end

    assign clk_50Mhz = clk_50Mhz_r;
    assign clk_25Mhz = clk_25Mhz_r;
    assign clk_16Mhz = clk_16Mhz_r;
    assign clk_8Mhz_1_1 = clk_8Mhz_1_1_r;
    assign clk_8Mhz_2_1 = clk_8Mhz_2_1_r;
    assign clk_8Mhz_1_2 = clk_8Mhz_1_2_r;

endmodule

module counter (
    input clk,
    input rst,
    output [2:0] digit_sel
);

    reg [2:0] cnt = 3'b000;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt <= 3'b000;
        end else begin
            cnt <= cnt + 1;
        end
    end

    assign digit_sel = cnt;
endmodule

module decoder_2x4 (
    input      [1:0] digit_sel,
    output reg [3:0] fnd_com
);
    always @(digit_sel) begin
        case (digit_sel)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1110;
        endcase
    end

endmodule

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH -1:0] ds_in,
    output [           3:0] digit_1,
    output [           3:0] digit_10
    // output [ 3:0] digit_100,
    // output [ 3:0] digit_1000
);

    assign digit_1  = ds_in % 10;
    assign digit_10 = (ds_in / 10) % 10;
    // assign digit_100  = (ds_in / 100) % 10;
    // assign digit_1000 = (ds_in / 1000) % 10;

endmodule

// module comparator_dot #(
//     parameter MSEC_WIDTH = 7
// ) (
//     input [MSEC_WIDTH-1:0] msec,
//     output dot_onoff
// );

//     assign dot_onoff = (msec < 50);
    
// endmodule

module comparator_dot #(
    parameter MSEC_WIDTH = 7
) (
    input [MSEC_WIDTH-1:0] msec,
    input [1:0] ds,
    input edit_time,
    output reg [3:0] dot_onoff
);
    wire w_dot_onoff;

    assign w_dot_onoff = (msec < 50);

    always @(*) begin
        if (edit_time) begin
            case(ds)
                2'b00 : dot_onoff = 4'b1110;
                2'b01 : dot_onoff = 4'b1101;
                2'b10 : dot_onoff = 4'b1011;
                2'b11 : dot_onoff = 4'b0111;
            endcase
        end else  begin
            dot_onoff = {1'b1,w_dot_onoff,2'b11};
        end
    end    
endmodule

module mux_2x1 (
    input sel,  // display
    input [3:0] in0,  // m
    input [3:0] in1,  // 
    output [3:0] mux_out
);

    assign mux_out = (sel) ? in1 : in0;
endmodule

module mux_8x1 (
    input [2:0] sel,
    input [3:0] in0,  //sel 3'b000
    input [3:0] in1,  //sel 3'b001
    input [3:0] in2,  //sel 3'b010
    input [3:0] in3,  //sel 3'b011
    input [3:0] in4,  //sel 3'b100
    input [3:0] in5,  //sel 3'b101
    input [3:0] in6,  //sel 3'b110
    input [3:0] in7,  //sel 3'b111

    output reg [3:0] mux_out
);

    always @(*) begin
        case (sel)
            3'b000: mux_out = in0;
            3'b001: mux_out = in1;
            3'b010: mux_out = in2;
            3'b011: mux_out = in3;
            3'b100: mux_out = in4;
            3'b101: mux_out = in5;
            3'b110: mux_out = in6;
            3'b111: mux_out = in7;
        endcase
    end
endmodule

module bcd (
    input  [3:0] bcd_in,
    output [7:0] bcd_out
);

    reg [7:0] bcd_out_r = 0;

    assign bcd_out = bcd_out_r;


    always @(*)begin // always 구문안의 출력은 항상 reg 타입이어야한다.
        case (bcd_in)
            4'b0000: bcd_out_r = 8'hc0;
            4'b0001: bcd_out_r = 8'hf9;
            4'b0010: bcd_out_r = 8'ha4;
            4'b0011: bcd_out_r = 8'hb0;
            4'b0100: bcd_out_r = 8'h99;
            4'b0101: bcd_out_r = 8'h92;
            4'b0110: bcd_out_r = 8'h82;
            4'b0111: bcd_out_r = 8'hf8;
            4'b1000: bcd_out_r = 8'h80;
            4'b1001: bcd_out_r = 8'h90;
            4'b1010: bcd_out_r = 8'h88;
            4'b1011: bcd_out_r = 8'h83;
            4'b1100: bcd_out_r = 8'hc6;
            4'b1101: bcd_out_r = 8'ha1;
            4'b1110: bcd_out_r = 8'h7F;  //8'h86;
            4'b1111: bcd_out_r = 8'hFF;  //8'h8e;
        endcase
    end

endmodule
