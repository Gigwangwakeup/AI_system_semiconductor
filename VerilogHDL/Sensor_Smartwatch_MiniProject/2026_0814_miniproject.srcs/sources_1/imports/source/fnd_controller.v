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
module fnd_controller (
    input        clk,
    input        rst,
    input  [17:0]fnd_in,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    // =============================================================================================
    // wire, reg
    // =============================================================================================

    wire [3:0] mux_out;
    wire [3:0] w_digit0_1, w_digit0_10, w_digit1_1, w_digit1_10;
    wire [1:0] digit_sel;
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
        .digit_sel(digit_sel),
        .fnd_com  (fnd_com)
    );

    fnd_digit_splitter u_ds (
        .digit_in   (fnd_in),
        .digit0_1   (w_digit0_1),
        .digit0_10  (w_digit0_10),
        .digit1_1   (w_digit1_1),
        .digit1_10  (w_digit1_10)
    );
    mux_4x1 u_mux_4x1 (
        .sel       (digit_sel),
        .digit_1   (w_digit0_1),
        .digit_10  (w_digit0_10),
        .digit_100 (w_digit1_1),
        .digit_1000(w_digit1_10),
        .mux_out   (mux_out)
    );

    bcd u_bcd (
        .bcd_in (mux_out),
        .bcd_out(fnd_data)
    );
endmodule


// =============================================================================================
// module
// =============================================================================================
module clk_divider (
    input  clk,
    input  rst,
    output clk_1Khz,
    output clk_50Mhz, // 2분주
    output clk_25Mhz, // 4분주
    output clk_16Mhz, // 6분주
    output clk_8Mhz_1_1, //12분주 1:1
    output clk_8Mhz_2_1, //12분주 2:1
    output clk_8Mhz_1_2 //12분주 1:2
);
    reg [15:0] cnt = 16'h0000;
    reg clk_1Khz_reg = 1'b0;
    //과제
    reg [3:0]   cnt12 = 4'b0000;
    reg clk_50Mhz_r,clk_25Mhz_r,clk_16Mhz_r,clk_8Mhz_1_1_r,clk_8Mhz_2_1_r,clk_8Mhz_1_2_r = 1'b0;

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
        if(rst) begin
            cnt12 <= 4'b1111;
        end else begin
            cnt12 <= cnt12 + 1;
            if(cnt12 == (12-1)) begin
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
    output [1:0] digit_sel
);

    reg [1:0] cnt = 2'b00;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt <= 2'b00;
        end else begin
            cnt <= cnt + 1;
        end
    end

    assign digit_sel = cnt;
endmodule

module decoder_2x4 (
    input [1:0] digit_sel,
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

module fnd_digit_splitter (
    input  [17:0] digit_in,
    output [3:0] digit0_1,
    output [3:0] digit0_10,
    output [3:0] digit1_1,
    output [3:0] digit1_10
);

    assign digit0_1     = digit_in[8:0] % 10;
    assign digit0_10    = (digit_in[8:0] / 10) % 10;
    assign digit1_1     = digit_in[17:9] % 10;
    assign digit1_10    = (digit_in[17:9] / 10) % 10;

endmodule

module mux_4x1 (
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,

    output [3:0] mux_out
);

    assign mux_out = (sel == 2'b00) ? digit_1 : 
                     (sel == 2'b01) ? digit_10 :
                     (sel == 2'b10) ? digit_100: digit_1000;
endmodule

module bcd (
    input      [3:0] bcd_in,
    output reg [7:0] bcd_out
);

    always @(bcd_in)begin // always 구문안의 출력은 항상 reg 타입이어야한다.
        case (bcd_in)
            4'b0000: bcd_out = 8'hc0;
            4'b0001: bcd_out = 8'hf9;
            4'b0010: bcd_out = 8'ha4;
            4'b0011: bcd_out = 8'hb0;
            4'b0100: bcd_out = 8'h99;
            4'b0101: bcd_out = 8'h92;
            4'b0110: bcd_out = 8'h82;
            4'b0111: bcd_out = 8'hf8;
            4'b1000: bcd_out = 8'h80;
            4'b1001: bcd_out = 8'h90;
            4'b1010: bcd_out = 8'h88;
            4'b1011: bcd_out = 8'h83;
            4'b1100: bcd_out = 8'hc6;
            4'b1101: bcd_out = 8'ha1;
            4'b1110: bcd_out = 8'h86;
            4'b1111: bcd_out = 8'h8e;
        endcase
    end

endmodule
