`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/27 15:39:49
// Design Name: 
// Module Name: btn_debounce
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


module btn_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);
    // ====================================================================================
    // wire,reg
    // ====================================================================================
    reg  [7:0] q_reg;  // Stab shift register SIPO
    wire       debounce;
    reg        edge_reg;
    reg  [5:0] count;
    reg        clk_1mhz;
    // ====================================================================================
    // logic
    // ====================================================================================
    // 8bit shift register, SIPO
    always @(posedge clk_1mhz, posedge rst) begin
        if (rst) begin
            q_reg <= 8'h0;
        end else begin
            q_reg <= {q_reg[6:0], i_btn};  // shift left
            // q_reg <= {i_btn,q_reg[7:1]};
        end
    end
    // 8bit input AND gate
    // assign debounce = (q_reg == 8'hff);
    assign debounce = &q_reg;

    // 1-clock delay by debounce
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    // edge detection
    assign o_btn = debounce & ~edge_reg;

    //clock divider
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            clk_1mhz <= 0;
        end else begin
            count <= count + 1;
            if (count == 49) begin
                clk_1mhz <= ~clk_1mhz;
                count <= 0;
            end
        end
    end
endmodule
