`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/12 17:24:39
// Design Name: 
// Module Name: sr04_top
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


module sr04_top(
    input clk,
    input rst,
    input start,
    input echo,
    output trigger,
    output done,
    output [8:0] distance
    // output [3:0] fnd_com,
    // output [7:0] fnd_data
    );

    wire w_bd_btnL;
    // wire [8:0] w_distance;
    // reg echo_sync1, echo_sync2;

    btn_debounce u_bdL(
    .clk(clk),
    .rst(rst),
    .i_btn(start),
    .o_btn(w_bd_btnL)
);

sr04_controller u_sr04_ctrl(
    .clk(clk),
    .rst(rst),
    .start(w_bd_btnL),
    .echo(echo),
    .trigger(trigger),
    .done(done),
    .distance(distance)
    );


//     fnd_controller u_fnd_ctrl (
//     .clk(clk),
//     .rst(rst),
//     .fnd_in({5'b00000,w_distance}),
//     .fnd_com(fnd_com),
//     .fnd_data(fnd_data)
// );

endmodule
