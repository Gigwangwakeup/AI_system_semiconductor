`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/05 11:44:54
// Design Name: 
// Module Name: uart
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


module uart_controller (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,   // watch output value
    input        rx,
    output       tx_busy,
    output       tx_done,
    output       tx,
    output [7:0] rx_data,
    output       rx_done
);
    // baud_tick
    wire w_baud_tick;

    baud_tick_gen #(
        .BAUD_RATE (153_600),
        .CLK_PERIOD(100_000_000)
    ) u_baud_tick_gen (
        .clk        (clk),
        .rst        (rst),
        .o_baud_tick(w_baud_tick)
    );

    uart_tx u_uart_tx ( //tick gen 속도가 16배로 바뀌었으니 내부 로직 수정해줘야함.
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),      //(tx_start),     // I
        .tx_data  (tx_data),      // I [7:0]
        .baud_tick(w_baud_tick),  // I
        .tx_busy  (tx_busy),      // O
        .tx_done  (tx_done),      // O
        .tx       (tx)            // O
    );

    uart_rx u_uart_rx (
        .clk      (clk),
        .rst      (rst),
        .rx       (rx),           // I
        .baud_tick(w_baud_tick),  // I
        .rx_done  (rx_done),      // O
        .rx_data  (rx_data)       // O [7:0]
    );
endmodule




module baud_tick_gen #(
    parameter BAUD_RATE = 9600,
    CLK_PERIOD = 100_000_000
) (
    input  clk,
    input  rst,
    output o_baud_tick
);

    localparam F_COUNT = CLK_PERIOD / BAUD_RATE;
    // 방법 1
    // reg [$clog2(F_COUNT)-1:0] baud_cnt;
    // // 방법 2
    reg  [$clog2(F_COUNT)-1:0] baud_cnt_reg;
    wire [$clog2(F_COUNT)-1:0] baud_cnt_next;
    // wire baud_tick2;

    // //방법 1
    // //9600bps baud tick gen
    // //tick count = input freq / baud_tick_freq
    // always @(posedge clk, posedge rst) begin
    //     if (rst) begin
    //         baud_cnt <= 0;
    //     end else begin
    //         baud_cnt <= baud_cnt + 1;
    //         if (baud_cnt == (F_COUNT -1)) begin
    //             baud_cnt <= 0;
    //         end
    //     end
    // end

    // assign o_baud_tick = (baud_cnt == (F_COUNT -1)) ? 1 : 0 ;

    //방법2
    //baud_cnt SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            baud_cnt_reg <= 0;
        end else begin
            baud_cnt_reg <= baud_cnt_next;
        end
    end
    //next CL
    assign baud_cnt_next = (baud_cnt_reg == F_COUNT - 1) ? 0 : baud_cnt_reg + 1;
    // always @(*) begin
    //     baud_cnt_next = baud_cnt_reg;
    //     if(baud_cnt_reg == F_COUNT -1)
    //         baud_cnt_next = 0;
    //     else
    //         baud_cnt_next = baud_cnt_next + 1;
    // end

    //output CL
    assign o_baud_tick = (baud_cnt_reg == F_COUNT - 1) ? 1 : 0;


endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input  [7:0] tx_data,
    input        baud_tick,
    output       tx_busy,
    output       tx_done,
    output       tx
);

    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] c_state, n_state;
    reg tx_reg, tx_next;
    reg tx_busy_reg, tx_busy_next;
    reg tx_done_reg, tx_done_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [3:0] tick_cnt_reg, tick_cnt_next;
    reg [7:0] data_reg, data_next;

    // state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 3'd0;
            tx_reg       <= 1'b1;
            data_reg     <= 8'd0;
            tx_busy_reg  <= 1'b0;
            tx_done_reg  <= 1'b0;
            tick_cnt_reg <= 4'd0;
        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tx_reg       <= tx_next;
            data_reg     <= data_next;
            tx_busy_reg  <= tx_busy_next;
            tx_done_reg  <= tx_done_next;
            tick_cnt_reg <= tick_cnt_next;
        end
    end

    // next state CL
    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tx_next       = tx_reg;
        data_next     = data_reg;
        tx_busy_next  = tx_busy_reg;
        tx_done_next  = tx_done_reg;
        tick_cnt_next = tick_cnt_reg;
        case (c_state)
            IDLE: begin
                tx_next       = 1'b1;
                tx_done_next  = 1'b0;
                tick_cnt_next = 4'd0;
                if (tx_start) begin
                    tx_busy_next = 1'b1;
                    data_next    = tx_data;
                    n_state      = START;
                end
            end
            START: begin
                tx_next      = 1'b0;
                bit_cnt_next = 3'd0;
                if (baud_tick) begin
                    if (tick_cnt_reg == 15) begin
                        tick_cnt_next = 4'd0;
                        n_state = DATA;
                    end else begin
                        tick_cnt_next = tick_cnt_next + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_reg[0];
                if (baud_tick) begin
                    if (tick_cnt_reg == 15) begin
                        tick_cnt_next = 4'd0;
                        data_next    = {1'b0, data_reg[7:1]};
                        if (bit_cnt_reg < 7) begin
                            n_state      = DATA;
                            bit_cnt_next = bit_cnt_reg + 1;
                        end else begin
                            n_state = STOP;
                        end
                    end else begin
                        tick_cnt_next = tick_cnt_next + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (baud_tick) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 15) begin
                        tx_busy_next = 1'b0;
                        tx_done_next = 1'b1;  //tick
                        n_state      = IDLE;
                    end
                end
            end
        endcase
    end

    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;
    assign tx      = tx_reg;

endmodule

// module uart_btn_debounce (
//     input  clk,
//     input  rst,
//     input  btn,
//     output o_btn
// );

//     reg [$clog2(500)-1:0] cnt;
//     reg [7:0] shift_reg;
//     reg clk_1Mhz;
//     wire shift_and;
//     reg edge_reg;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             cnt <= 0;
//             clk_1Mhz <= 0;
//         end else begin
//             cnt <= cnt + 1;
//             if (cnt == 50 - 1) begin
//                 cnt <= 0;
//                 clk_1Mhz <= ~clk_1Mhz;
//             end
//         end
//     end

//     always @(posedge clk_1Mhz, posedge rst) begin
//         if (rst) begin
//             shift_reg <= 0;
//         end else begin
//             shift_reg <= {shift_reg[6:0], btn};
//         end
//     end

//     assign shift_and = &shift_reg;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             edge_reg <= 0;
//         end else begin
//             edge_reg <= shift_and;
//         end
//     end

//     assign o_btn = shift_and & (~edge_reg);

// endmodule

module uart_rx (
    input clk,
    input rst,
    input rx,
    input baud_tick,
    output rx_done,
    output [7:0] rx_data
);

    localparam [1:0] IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0] c_state, n_state;
    reg [7:0] c_rx_data, n_rx_data;
    reg [3:0] c_tick_cnt, n_tick_cnt;
    reg [2:0] c_bit_cnt, n_bit_cnt;
    // for CL output
    // reg c_rx_done;
    // for SL output
    reg c_rx_done, n_rx_done;

    // current state SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state    <= IDLE;
            c_tick_cnt <= 4'd0;
            c_bit_cnt  <= 3'd0;
            c_rx_data  <= 8'd0;
            c_rx_done  <= 1'b0;
        end else begin
            c_state    <= n_state;
            c_tick_cnt <= n_tick_cnt;
            c_bit_cnt  <= n_bit_cnt;
            c_rx_data  <= n_rx_data;
            c_rx_done  <= n_rx_done;
        end
    end

    // next state, output CL
    always @(*) begin
        n_state    = c_state;
        n_tick_cnt = c_tick_cnt;
        n_bit_cnt  = c_bit_cnt;
        n_rx_data  = c_rx_data;
        // c_rx_done = 0; // CL
        n_rx_done  = c_rx_done;
        case (c_state)
            IDLE: begin
                // c_rx_done = 0; // CL
                n_rx_done = 1'b0;
                n_bit_cnt = 0;
                if (baud_tick) begin
                    if (!rx) begin
                        if (c_tick_cnt == 7) begin
                            n_state    = START;
                            n_tick_cnt = 0;
                        end else begin
                            n_tick_cnt = c_tick_cnt + 1;
                        end
                    end else begin
                        // n_rx_data  = 0;
                        n_tick_cnt = 0;
                    end
                end
            end
            START: begin
                if (baud_tick) begin
                    if (c_tick_cnt == 15) begin
                        n_tick_cnt = 0;
                        n_state    = DATA;
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (baud_tick) begin
                    if (c_tick_cnt == 0) begin
                        // n_rx_data = c_rx_data[c_bit_cnt]; // PIPO, bit indexing
                        n_rx_data = {rx, c_rx_data[7:1]};  // SIPO, bitshift
                    end
                    if (c_tick_cnt == 15) begin
                        n_tick_cnt = 0;
                        if (c_bit_cnt == 7) begin
                            n_state = STOP;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1;
                        end
                    end else begin
                        n_tick_cnt = c_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (baud_tick) begin
                    // if (c_tick_cnt == 7) begin
                        n_state   = IDLE;
                        n_rx_done = 1'b1;
                        // c_rx_done = 1'b1;
                    // end else begin
                        // n_tick_cnt = c_tick_cnt + 1;
                    // end
                end
            end
        endcase
    end

    assign rx_done = c_rx_done;
    assign rx_data = c_rx_data;

endmodule
