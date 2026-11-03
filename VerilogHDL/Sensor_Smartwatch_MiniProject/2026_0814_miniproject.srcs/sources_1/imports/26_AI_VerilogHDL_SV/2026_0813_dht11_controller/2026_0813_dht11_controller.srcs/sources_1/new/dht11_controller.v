`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/13 15:13:19
// Design Name: 
// Module Name: dht11_controller
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


module dht11_controller (
    input         clk,
    input         rst,
    input         start,        // trigger
    inout         dht11,
    output [15:0] humidity,
    output [15:0] temperature,
    output        done,         // 수신종료
    output        valid         // 8bit check sum ok :1, Not ok :0
);
    // ============================================================================
    // wire, reg
    // ============================================================================
    // dht11 direction control
    wire dht11_out;
    wire drive;
    // FSM
    localparam [2:0] IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4, DATA = 5, STOP = 6;
    reg [2:0] c_state, n_state;
    reg [$clog2(19_000)-1:0] us_tick_cnt_next, us_tick_cnt_reg;
    reg drive_reg, drive_next;
    reg dht11_out_reg, dht11_out_next;
    reg [39:0] data_reg, data_next;
    reg [$clog2(40)-1:0] bit_cnt_reg, bit_cnt_next;
    reg done_reg, done_next;
    wire clear;
    //2-F/F
    reg dht11_sync1, dht11_sync2, dht11_sync3;
    // compare
    wire [7:0] rx_data, com_data;
    reg valid_reg;
    wire [15:0] humidity_reg, temperature_reg;

    assign state = c_state;
    // ============================================================================
    // 2-F/F
    // ============================================================================
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dht11_sync1 <= 0;
            dht11_sync2 <= 0;
            dht11_sync3 <= 0;
        end else begin
            dht11_sync1 <= dht11;
            dht11_sync2 <= dht11_sync1;
            dht11_sync3 <= dht11_sync2;
        end
    end

    // ============================================================================
    // dht11 direction control
    // ============================================================================
    // fpga to dht11
    assign dht11 = (drive) ? dht11_out : 1'bz;

    // ============================================================================
    // FSM (FPGA <-> dht)
    // ============================================================================
    assign drive = drive_reg;
    assign clear = (c_state == IDLE) ? 1'b1 : 1'b0;
    assign done = done_reg;
    assign rx_data = data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8];
    assign com_data = data_reg[7:0];
    assign dht11_out = dht11_out_reg;
    assign humidity_reg = data_reg[39:24];
    assign temperature_reg = data_reg[23:8];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            us_tick_cnt_reg <= 0;
            drive_reg       <= 1'b1;
            dht11_out_reg   <= 0;
            data_reg        <= 0;
            bit_cnt_reg     <= 0;
            done_reg        <= 0;

        end else begin
            c_state         <= n_state;
            us_tick_cnt_reg <= us_tick_cnt_next;
            drive_reg       <= drive_next;
            dht11_out_reg   <= dht11_out_next;
            data_reg        <= data_next;
            bit_cnt_reg     <= bit_cnt_next;
            done_reg        <= done_next;
        end
    end

    always @(*) begin
        n_state          = c_state;
        us_tick_cnt_next = us_tick_cnt_reg;
        drive_next       = drive_reg;
        dht11_out_next   = dht11_out_reg;
        data_next        = data_reg;
        bit_cnt_next     = bit_cnt_reg;
        done_next        = done_reg;
        case (c_state)
            IDLE: begin
                done_next = 1'b0;
                dht11_out_next = 1'b1;
                drive_next = 1'b1;
                if (start) begin
                    n_state = START;
                    us_tick_cnt_next = 0;
                end
            end
            START: begin
                dht11_out_next = 1'b0;
                if (tick_us) begin
                    if (us_tick_cnt_reg == 19_000 - 1) begin
                        n_state = WAIT;
                        us_tick_cnt_next = 0;
                    end else begin
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                dht11_out_next = 1'b1;
                if (tick_us) begin
                    if (us_tick_cnt_reg == 30 - 1) begin
                        n_state = SYNCL;
                        us_tick_cnt_next = 0;
                        dht11_out_next = 1'b0;
                    end else begin
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin
                drive_next = 1'b0;  // fpga is not drive dht11 line
                if (dht11_sync2 && (!dht11_sync3)) begin
                    n_state = SYNCH;
                end
            end
            SYNCH: begin
                if ((!dht11_sync2) && dht11_sync3) begin
                    n_state = DATA;
                end
            end
            DATA: begin  // 100Mhz                
                if (dht11_sync2 && (!dht11_sync3)) begin  // 상승엣지
                    us_tick_cnt_next = 0;
                end else if ((!dht11_sync2) && dht11_sync3) begin // 하강엣지
                    us_tick_cnt_next = 0;
                    if (us_tick_cnt_reg < 5_000) begin
                        data_next = {data_reg[38:0], 1'b0};
                    end else begin
                        data_next = {data_reg[38:0], 1'b1};
                    end
                    if (bit_cnt_reg == 40 - 1) begin
                        n_state = STOP;
                        bit_cnt_next = 0;
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end else if (dht11_sync3) begin
                    us_tick_cnt_next = us_tick_cnt_reg + 1;
                end
            end
            STOP: begin
                done_next = 1'b1;
                if (tick_us) begin
                    if (us_tick_cnt_reg == 50) begin
                        n_state = IDLE;
                        us_tick_cnt_next = 0;
                    end else begin
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end


    // ============================================================================
    // check sum
    // ============================================================================
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            valid_reg <= 0;
        end else begin
            if (done_reg) begin
                if (rx_data == com_data) begin
                    valid_reg <= 1'b1;
                end else begin
                    valid_reg <= 1'b0;
                end
            end
        end
    end
    assign valid = valid_reg;
    assign humidity =(valid) ? humidity_reg : 0;
    assign temperature = (valid) ? temperature_reg : 0;
    // ============================================================================
    // instance
    // ============================================================================
    us_tick_dht11 u_us_tick_gen (
        .clk(clk),
        .rst(rst),
        .run_stop(1'b1),
        .clear(clear),
        .tick_us(tick_us)
    );

  

endmodule

module us_tick_dht11 (
    input  clk,
    input  rst,
    input  run_stop,
    input  clear,
    output tick_us
);


    reg [6:0] tick_cnt;

    always @(posedge clk, posedge rst, posedge clear) begin
        if (rst | clear) begin
            tick_cnt <= 0;
        end else begin
            if (run_stop) begin
                if (tick_cnt == (100 - 1)) begin
                    tick_cnt <= 0;
                end else begin
                    tick_cnt <= tick_cnt + 1;
                end
            end else begin
                tick_cnt <= tick_cnt;
            end
        end
    end

    assign tick_us = (tick_cnt == (100 - 1)) ? 1'b1 : 1'b0;
endmodule
