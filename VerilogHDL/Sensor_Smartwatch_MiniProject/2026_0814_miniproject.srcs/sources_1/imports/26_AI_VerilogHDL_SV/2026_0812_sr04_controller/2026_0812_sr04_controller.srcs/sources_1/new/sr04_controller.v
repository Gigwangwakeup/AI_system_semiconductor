`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/12 12:12:49
// Design Name: 
// Module Name: sr04_controller
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
// module sr04_controller(
//     input clk,
//     input rst,
//     input start,
//     input echo,
//     output trigger,
//     output done,
//     output [8:0] distance
//     );

//     parameter [2:0] IDLE = 0, TRIG = 1, WAIT = 2, ECHO = 3, CALC = 4, BUSY = 5;

//     reg [2:0] c_state, n_state;
//     reg [15:0] us_tick_cnt_reg,us_tick_cnt_next;
//     reg [15:0] calc_reg, calc_next;
//     reg [8:0] calc_distance_reg, calc_distance_next;
//     reg [8:0] distance_reg, distance_next;
//     reg done_reg, done_next, trigger_reg, trigger_next;

//     // ---- 나눗셈용 레지스터 추가 ----
//     reg [15:0] calc_rem_reg, calc_rem_next;      // 남은 값
//     reg div_busy_reg, div_busy_next;             // 나눗셈 진행중 플래그

//     wire clear; // to us_tick_gen
//     wire w_tick_us;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             c_state <= IDLE;
//             us_tick_cnt_reg <= 0;
//             distance_reg <= 0;
//             done_reg <= 0;
//             trigger_reg <= 0;
//             calc_reg <= 0;
//             calc_distance_reg <= 0;
//             calc_rem_reg <= 0;
//             div_busy_reg <= 0;
//         end else begin
//             c_state <= n_state;
//             us_tick_cnt_reg <= us_tick_cnt_next;
//             distance_reg <= distance_next;
//             done_reg <= done_next;
//             trigger_reg <= trigger_next;
//             calc_reg <= calc_next;
//             calc_distance_reg <= calc_distance_next;
//             calc_rem_reg <= calc_rem_next;
//             div_busy_reg <= div_busy_next;
//         end
//     end

//     always @(*) begin
//         n_state = c_state;
//         us_tick_cnt_next = us_tick_cnt_reg;
//         distance_next = distance_reg;
//         done_next = done_reg;
//         trigger_next = trigger_reg;
//         calc_next = calc_reg;
//         calc_distance_next = calc_distance_reg;
//         calc_rem_next = calc_rem_reg;
//         div_busy_next = div_busy_reg;
//         case(c_state)
//             IDLE : begin
//                 done_next = 1'b0;
//                 if(start) begin
//                     n_state = TRIG;
//                     us_tick_cnt_next = 0;
//                 end
//             end

//             TRIG : begin          
//                 if (tick_us) begin
//                     if (us_tick_cnt_reg == 11) begin
//                         n_state = WAIT;
//                         trigger_next = 1'b0;
//                         us_tick_cnt_next = 0;
//                     end else begin
//                         trigger_next = 1'b1;
//                         us_tick_cnt_next = us_tick_cnt_reg + 1;
//                     end
//                 end
//             end

//             WAIT : begin
//                 if(tick_us) begin
//                     if(echo == 1'b1) begin
//                         n_state = ECHO;
//                         us_tick_cnt_next = us_tick_cnt_reg + 1;
//                     end
//                 end
//             end

//             ECHO : begin
//                 if(tick_us) begin
//                     if(echo == 1'b0) begin
//                         n_state = CALC;
//                         us_tick_cnt_next = 0;
//                         if (us_tick_cnt_reg <= 18000) begin // 18ms
//                             calc_next = us_tick_cnt_reg;
//                         end else begin
//                             calc_next = 0;                        
//                         end
//                         // CALC 진입하자마자 나눗셈 시작 준비
//                         calc_rem_next = calc_reg;
//                         calc_distance_next = 0;
//                         div_busy_next = 1'b1;
//                     end else begin
//                         us_tick_cnt_next = us_tick_cnt_reg + 1;
//                     end
//                 end
//             end

//             CALC : begin
//                 if(tick_us) begin
//                     if (us_tick_cnt_reg == 1000 -1) begin
//                         n_state = BUSY;
//                         us_tick_cnt_next = 0;
//                         distance_next = calc_distance_reg;
//                     end else begin
//                         us_tick_cnt_next = us_tick_cnt_reg + 1;
//                         if (div_busy_reg) begin
//                             if (calc_rem_reg >= 58) begin
//                                 calc_rem_next = calc_rem_reg - 58;
//                                 calc_distance_next = calc_distance_reg + 1;
//                             end else begin
//                                 div_busy_next = 1'b0; 
//                             end
//                         end
//                     end
//                 end
//             end

//             BUSY : begin
//                 if(tick_us) begin
//                     if (us_tick_cnt_reg == 10000 -1) begin
//                         n_state = IDLE;
//                         us_tick_cnt_next = 0;
//                         done_next = 1'b1;                        
//                     end else begin
//                         us_tick_cnt_next = us_tick_cnt_reg + 1;
//                     end
//                 end
//             end
//         endcase
//     end

//     assign clear = (c_state == IDLE) ? 1'b1:1'b0;
//     assign distance = distance_reg;
//     assign done = done_reg;
//     assign trigger = trigger_reg;


// us_tick_sr04 u_us_tick(
//     .clk(clk),
//     .rst(rst),
//     .run_stop(1'b1),
//     .clear(clear),
//     .tick_us(tick_us)
// );
   

// endmodule

module sr04_controller(
    input clk,
    input rst,
    input start,
    input echo,
    output trigger,
    output done,
    output [8:0] distance
    );

    parameter [2:0] IDLE = 0, TRIG = 1, WAIT = 2, ECHO = 3, CALC = 4, BUSY = 5;

    reg [2:0] c_state, n_state;
    reg [15:0] us_tick_cnt_reg,us_tick_cnt_next;
    reg [15:0] calc_reg, calc_next;
    reg [8:0] calc_distance_reg, calc_distance_next;
    reg [8:0] distance_reg, distance_next;
    reg done_reg, done_next, trigger_reg, trigger_next;

    wire clear; // to us_tick_gen

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            us_tick_cnt_reg <= 0;
            distance_reg <= 0;
            done_reg <= 0;
            trigger_reg <= 0;
            calc_reg <= 0;
            calc_distance_reg <= 0;
        end else begin
            c_state <= n_state;
            us_tick_cnt_reg <= us_tick_cnt_next;
            distance_reg <= distance_next;
            done_reg <= done_next;
            trigger_reg <= trigger_next;
            calc_reg <= calc_next;
            calc_distance_reg <= calc_distance_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        us_tick_cnt_next = us_tick_cnt_reg;
        distance_next = distance_reg;
        done_next = done_reg;
        trigger_next = trigger_reg;
        calc_next = calc_reg;
        calc_distance_next = calc_distance_reg;
        case(c_state)
            IDLE : begin
                done_next = 1'b0;
                if(start) begin
                    n_state = TRIG;
                    us_tick_cnt_next = 0;
                end
            end

            TRIG : begin          
                if (tick_us) begin
                    if (us_tick_cnt_reg == 11) begin
                        n_state = WAIT;
                        trigger_next = 1'b0;
                        us_tick_cnt_next = 0;
                    end else begin
                        trigger_next = 1'b1;
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                    end
                end
            end

            WAIT : begin
                if(tick_us) begin
                    if(echo == 1'b1) begin
                        n_state = ECHO;
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                    end
                end
            end

            ECHO : begin
                if(tick_us) begin
                    if(echo == 1'b0) begin
                        n_state = CALC;
                        us_tick_cnt_next = 0;
                        if (us_tick_cnt_reg <= 18000) begin // 18ms
                            calc_next = us_tick_cnt_reg;
                        end else begin
                            calc_next = 0;                        
                        end
                    end else begin
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                    end
                end
            end

            CALC : begin
                if(tick_us) begin
                    if (us_tick_cnt_reg == 1000 -1) begin
                        n_state = BUSY;
                        us_tick_cnt_next = 0;
                        distance_next = calc_distance_reg;
                    end else begin
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                        calc_distance_next = calc_reg / 58;
                    end
                end
            end

            BUSY : begin
                if(tick_us) begin
                    if (us_tick_cnt_reg == 10000 -1) begin
                        n_state = IDLE;
                        us_tick_cnt_next = 0;
                        done_next = 1'b1;                        
                    end else begin
                        us_tick_cnt_next = us_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

    assign clear = (c_state == IDLE) ? 1'b1:1'b0;
    assign distance = distance_reg;
    assign done = done_reg;
    assign trigger = trigger_reg;


us_tick_sr04 u_us_tick(
    .clk(clk),
    .rst(rst),
    .run_stop(1'b1),
    .clear(clear),
    .tick_us(tick_us)
);
   

endmodule

module us_tick_sr04 (
    input clk,
    input rst,
    input run_stop,
    input clear,
    output tick_us
);


reg [6:0] tick_cnt;

always @(posedge clk, posedge rst, posedge clear) begin
    if(rst | clear) begin
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

assign tick_us = (tick_cnt == (100 -1)) ? 1'b1 : 1'b0;
endmodule
