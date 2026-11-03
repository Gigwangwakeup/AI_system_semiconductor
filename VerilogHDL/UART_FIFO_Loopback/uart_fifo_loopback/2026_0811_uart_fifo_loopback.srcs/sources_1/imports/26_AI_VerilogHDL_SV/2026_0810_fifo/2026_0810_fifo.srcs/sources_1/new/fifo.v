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
    parameter ADDR_WIDTH = 2
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
        .ADDR_WIDTH(2),
        .BIT_WIDTH (8)
    ) u_reg_file (
        .clk(clk),
        .waddr(w_wptr),
        .raddr(w_rptr),
        .wdata(wdata),
        .we(push & ~full),
        .rdata(rdata)
    );

    control_unit #(
        .ADDR_WIDTH(2)
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
    parameter ADDR_WIDTH = 2,
    BIT_WIDTH = 8
) (
    input                   clk,
    input  [ADDR_WIDTH-1:0] waddr,
    input  [ADDR_WIDTH-1:0] raddr,
    input  [ BIT_WIDTH-1:0] wdata,
    input                   we,
    output [ BIT_WIDTH-1:0] rdata
);

    parameter DEPTH = 2 ** ADDR_WIDTH;
    reg [BIT_WIDTH -1:0] register_file[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    //output CL
    assign rdata = register_file[raddr];

endmodule

module control_unit #(
    parameter ADDR_WIDTH = 2
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




    // localparam [1:0] IDLE = 0, PUSH = 1, POP = 2, PUSH_POP = 3;

    // reg [1:0] c_state, n_state;
    // reg c_empty, n_empty;
    // reg c_full, n_full;
    // reg [1:0] c_wptr, n_wptr;
    // reg [1:0] c_rptr, n_rptr;


    // //  c_state SL
    // always @(posedge clk, posedge rst) begin
    //     if (rst) begin
    //         c_state <= IDLE;
    //         c_empty <= 1'b1;
    //         c_full  <= 1'b0;
    //         c_wptr  <= 2'b0;
    //         c_rptr  <= 2'b0;
    //     end else begin
    //         c_state <= n_state;
    //         c_empty <= n_empty;
    //         c_full  <= n_full;
    //         c_wptr  <= n_wptr;
    //         c_rptr  <= n_rptr;
    //     end
    // end

    // // output & next state
    // always @(*) begin
    //     n_state = c_state;
    //     n_empty = c_empty;
    //     n_full  = c_full;
    //     n_wptr  = c_wptr;
    //     n_rptr  = c_rptr;
    //     case (c_state)
    //         IDLE: begin
    //             if(push && pop) begin
    //                 n_state = PUSH_POP;
    //             end else if (push) begin
    //                 n_state = PUSH;
    //             end else if (pop) begin
    //                 n_state = POP;
    //             end
    //         end
    //         PUSH: begin
    //             if (push) begin
    //                 n_wptr  = c_wptr + 1;
    //                 n_empty = 1'b0;
    //             end
    //             if (n_wptr == c_rptr) begin
    //                 n_full = 1'b1;
    //             end
    //             if (push && pop) begin
    //                 n_state = PUSH_POP;
    //             end else if (pop) begin
    //                 n_state = POP;
    //             end
    //         end
    //         POP: begin
    //             if (pop) begin
    //                 n_rptr = c_rptr + 1;
    //                 n_full = 1'b0;
    //             end
    //             if (n_rptr == c_wptr) begin
    //                 n_empty = 1'b1;
    //             end
    //             if (pop && push) begin
    //                 c_state = PUSH_POP;
    //             end else if (push) begin
    //                 c_state = PUSH;
    //             end
    //         end
    //         PUSH_POP: begin
    //             if (c_full) begin
    //                 n_rptr = c_rptr + 1;
    //                 n_full = 1'b0;
    //             end else if (c_empty) begin
    //                 n_wptr  = c_wptr + 1;
    //                 n_empty = 1'b0;
    //             end else begin
    //                 n_wptr = c_wptr + 1;
    //                 n_rptr = c_rptr + 1;
    //             end
    //         end
    //     endcase
    // end
    // assign wptr  = c_wptr;
    // assign rptr  = c_rptr;
    // assign full  = c_full;
    // assign empty = c_empty;

endmodule
