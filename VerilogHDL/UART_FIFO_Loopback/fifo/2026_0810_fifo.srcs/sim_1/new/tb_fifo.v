`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/10 16:39:48
// Design Name: 
// Module Name: tb_fifo
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


module tb_fifo ();

    reg clk, rst, push, pop;
    reg  [7:0] wdata;
    wire [7:0] rdata;
    wire full, empty;
    integer i;

    // for random simuation
    reg [7:0] compare_buffer [0:3];
    reg [1:0] push_cnt, pop_cnt;

    integer count = 0;
    integer pass_cnt = 0, fail_cnt = 0;


    fifo #(
        .ADDR_WIDTH(2)
    ) dut (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wdata(wdata),  // push data [7:0]
        .rdata(rdata),  // pop data [7:0]
        .full (full),
        .empty(empty)
    );

    task push_task(input [7:0] t_wdata);
        begin
            push  = 1'b1;
            wdata = t_wdata;
            #10;
            push = 1'b0;
            #10;
        end
    endtask

    task pop_task();
        begin
            pop = 1'b1;
            #10;
            pop = 1'b0;
            #10;
        end
    endtask

    task push_pop_task(input [7:0] w_data);
        begin
            push  = 1'b1;
            wdata = w_data;
            pop   = 1'b1;
            #10;
            push = 1'b0;
            pop  = 1'b0;
            #10;
        end
    endtask
    initial begin
        clk = 0;
    end

    always #5 clk = ~clk;

    initial begin
        rst   = 1'b1;
        push  = 1'b0;
        pop   = 1'b0;
        wdata = 8'h00;
        #10;
        rst = 1'b0;
        // @(negedge clk);
        // //push only 5times
        // push_task(8'h0a);
        // push_task(8'h0b);
        // push_task(8'h0c);
        // push_task(8'h0d);
        // push_task(8'h0e);

        // //pop only 5times
        // pop_task();
        // pop_task();
        // pop_task();
        // pop_task();
        // pop_task();

        // //push pop
        // push = 1'b1;
        // #10;
        // push = 1'b0;
        // #10;
        // push_pop_task(8'h01);
        // push_pop_task(8'h02);
        // push_pop_task(8'h03);
        // push_pop_task(8'h04);
        // push_pop_task(8'h05);
        // push_pop_task(8'h06);
        // push_pop_task(8'h07);
        // push_pop_task(8'h08);
        pop = 1'b1;
        #10;
        pop = 1'b0;
        #10;
        $display("%0t : RANDOM test start",$time);
        push_cnt = 0;
        pop_cnt = 0;
        // empty state
        for (i = 0; i < 256; i = i + 1) begin
            @(posedge clk);
            #1;
            push = $random % 2;  // $random % 가지수
            pop = $random % 2;
            wdata = $random % 256; // 낮게 하고 싶다면 더 낮은 모듈러 쓰면 됌
            $display("%0t : push : %d, pop : %d, wdata = %d",$time,push,pop,wdata); 
            // $display는 같은 time slot에 적용 전 인지 후 인지 모름 if non-block 연산이 있다면
            // $strobe는 무조건 연산 후를 시뮬레이션

            @(negedge clk);
            if((!full)&push) begin
                compare_buffer[push_cnt] = wdata;
            $display("%0t : compare_buffer : %d, push : %d",$time,compare_buffer[push_cnt],push); 
                push_cnt = push_cnt +1;
            end            
            if((!empty)&pop) begin
                if(compare_buffer[pop_cnt] == rdata) begin
                    $display("%0t : PASS!! compare_data = %d, rdata = %d, pop = %d, empty = %d",
                    $time,compare_buffer[pop_cnt],rdata,pop,empty);
                    pass_cnt = pass_cnt +1;
                end else begin
                    $display("%0t : FAIL!! compare_data = %d, rdata = %d, pop = %d, empty = %d",
                    $time,compare_buffer[pop_cnt],rdata,pop,empty);
                    fail_cnt = fail_cnt +1;
                end                    
                pop_cnt = pop_cnt +1;
            end
            if (push & count < 4) begin
                count = count + 1;
            end
            if (pop & count > 0 ) begin
                count = count - 1;
            end
            // #10;
            if (count == 4 & full) begin
                $display("%0t : Full PASS!! count = %d, full = %d", $time, count, full);
            end

            if (count == 0 & empty) begin
                $display("%0t : Empty PASS!! count = %d, empty = %d", $time, count, empty);
            end
        end
        $display("%0t : pass count =  %d, fail count = %d",$time,pass_cnt,fail_cnt);    
        $stop;
    end
endmodule
