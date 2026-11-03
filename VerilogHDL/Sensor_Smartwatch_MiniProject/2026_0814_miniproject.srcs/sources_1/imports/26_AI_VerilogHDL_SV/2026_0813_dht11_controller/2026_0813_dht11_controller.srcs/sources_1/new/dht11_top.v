`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/14 10:40:27
// Design Name: 
// Module Name: dht11_top
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


module dht11_top (
    input clk,
    input rst,
    input start,
    inout dht11,
    output done,
    output valid,
    output [7:0] humidity_int,
    output [7:0] humidity_dec,
    output [7:0] temperature_int,
    output [7:0] temperature_dec
    // input sw,
    // output [3:0] fnd_com,
    // output [7:0] fnd_data
);

    wire [15:0] data,w_humidity,w_temperature;

    btn_debounce u_bd_start (
        .clk  (clk),
        .rst  (rst),
        .i_btn(start),
        .o_btn(w_bd_start)
    );

    dht11_controller u_dht11_ctrl (
        .clk        (clk),
        .rst        (rst),
        .start      (w_bd_start),   // trigger
        .dht11      (dht11),
        .humidity   (w_humidity),
        .temperature(w_temperature),
        .done       (done),             // 수신종료
        .valid      (valid)         // 8bit check sum ok :1, Not ok :0
    );

    assign humidity_int = w_humidity[15:8];
    assign humidity_dec = w_humidity[7:0];
    assign temperature_int = w_temperature[15:8];
    assign temperature_dec = w_temperature[7:0];

    // assign data = (sw) ? w_humidity : w_temperature;

    // fnd_controller u_fnd_ctrl (
    //     .clk(clk),
    //     .rst(rst),
    //     .fnd_in(data),
    //     .fnd_com(fnd_com),
    //     .fnd_data(fnd_data)
    // );

endmodule
