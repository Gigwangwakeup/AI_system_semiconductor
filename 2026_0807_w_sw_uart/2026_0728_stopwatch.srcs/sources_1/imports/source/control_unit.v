`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/24 15:21:25
// Design Name: 
// Module Name: control_unit
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


module gk_control_unit(
    input clk,
    input rst,
    input i_left,
    input i_right,
    input i_edit_time,
    output o_left,
    output o_right,
    output o_edit_time
    );

    parameter RUN = 1'b0, EDITTIME = 1'b1;

    reg c_state,n_state;

    assign o_left   = (c_state == EDITTIME && i_left) ? 1 : 0;
    assign o_right  = (c_state == EDITTIME && i_right) ? 1 : 0;
    assign o_edit_time = (c_state == EDITTIME) ? 1:0;

    //state register
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            c_state <= RUN;
        end else begin
            c_state <= n_state;
        end
    end
    //next CL
    always @(*)begin
        n_state = c_state;
        case(c_state) 
            RUN : 
                if(i_edit_time) begin
                    n_state = EDITTIME;
                end else begin
                    n_state = c_state;
                end
            EDITTIME : 
                if(i_edit_time) begin
                    n_state = RUN;
                end else begin
                    n_state = c_state;
                end
        endcase
    end
endmodule

