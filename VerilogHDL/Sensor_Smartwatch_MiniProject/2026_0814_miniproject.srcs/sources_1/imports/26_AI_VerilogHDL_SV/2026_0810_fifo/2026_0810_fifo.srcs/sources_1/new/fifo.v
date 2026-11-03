`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/10 15:20:52
// Design Name: 
// Module Name: fifo
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


module fifo #(
    parameter ADDR_WIDTH = 3
) (
    input        clk,
    input        rst,
    input        push,
    input        pop,
    input  [7:0] wdata,  // push data
    output [7:0] rdata,  // pop data
    output       full,
    output       empty
);

    wire [ADDR_WIDTH -1:0] w_wptr, w_rptr;


    register_file #(
        .ADDR_WIDTH(3),
        .BIT_WIDTH (8)
    ) u_reg_file (
        .clk(clk),
        .waddr(w_wptr),
        .raddr(w_rptr),
        .wdata(wdata),
        .we(push & ~full),
        .rdata(rdata)
    );

    fifo_control_unit #(
        .ADDR_WIDTH(3)
    ) u_ctrl_unit (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );
endmodule

module register_file #(
    parameter ADDR_WIDTH = 3,
    BIT_WIDTH = 8
) (
    input                   clk,
    input  [ADDR_WIDTH-1:0] waddr,
    input  [ADDR_WIDTH-1:0] raddr,
    input  [ BIT_WIDTH-1:0] wdata,
    input                   we,
    output [ BIT_WIDTH-1:0] rdata
);

    localparam DEPTH = 2 ** ADDR_WIDTH;
    reg [BIT_WIDTH -1:0] register_file[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    //output CL
    assign rdata = register_file[raddr];

endmodule

module fifo_control_unit #(
    parameter ADDR_WIDTH = 3
) (
    input                   clk,
    input                   rst,
    input                   push,
    input                   pop,
    output [ADDR_WIDTH-1:0] wptr,
    output [ADDR_WIDTH-1:0] rptr,
    output                  full,
    output                  empty
);

    reg [ADDR_WIDTH-1:0] wptr_reg, wptr_next;
    reg [ADDR_WIDTH-1:0] rptr_reg, rptr_next;
    reg full_reg, full_next;
    reg empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    // state SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            wptr_reg  <= 1'b0;
            rptr_reg  <= 1'b0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;

        end
    end

    // next CL
    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            2'b00: begin
                //init
            end
            2'b01: begin
                //pop only
                if(!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end
                if (wptr_reg == rptr_next) begin
                    empty_next = 1'b1;
                end
            end
            2'b10: begin
                //push only
                if(!full_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end
                if (wptr_next == rptr_reg) begin
                    full_next = 1'b1;
                end
            end
            2'b11: begin
                //push pop
                if (full_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                end else if (empty_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end

endmodule
