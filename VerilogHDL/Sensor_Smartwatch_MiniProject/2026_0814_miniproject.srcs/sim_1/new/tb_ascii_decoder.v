`timescale 1ns / 1ps

module tb_ascii_decoder ();

    reg clk, rst, cu_done, rx_valid, rx_full;
    reg [7:0] rx_data;
    wire rx_pop, dht11_start, sr04_start, watch_get, stopwatch_get;
    wire [2:0] state;
    wire rs_stopwatch, clear_stopwatch, down_stopwatch, lap_stopwatch, edit_watch, left_watch, right_watch, up_watch, down_watch;



    ascii_decoder dut (
        .clk(clk),
        .rst(rst),
        .cu_done(cu_done),
        .rx_valid(rx_valid),
        .rx_full(rx_full),
        .rx_data(rx_data),
        .rx_pop(rx_pop),
        .dht11_start(dht11_start),
        .sr04_start(sr04_start),
        .watch_get(watch_get),
        .stopwatch_get((stopwatch_get)),
        .state(state),
        .rs_stopwatch(rs_stopwatch),
        .clear_stopwatch(clear_stopwatch),
        .down_stopwatch(down_stopwatch),
        .lap_stopwatch(lap_stopwatch),
        .edit_watch(edit_watch),
        .left_watch(left_watch),
        .right_watch(right_watch),
        .up_watch(up_watch),
        .down_watch(down_watch)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        cu_done = 0;
        rx_valid = 0;
        rx_full = 0;
        rx_data = 0;
        #10;
        rst = 0;
        #10;
        // ---- "get dht11" (마침표 전까지 9글자) ----
        rx_data  = 8'h67;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // g
        rx_data  = 8'h65;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // e
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // (space)
        rx_data  = 8'h64;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // d
        rx_data  = 8'h68;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // h
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h31;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // 1
        rx_data  = 8'h31;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // 1

        #20;  // <- 이 시점 파형에서 state=1, dht11_start=0 인지 확인

        // ---- 마침표 ----
        rx_data  = 8'h2e;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // .

        #20;  // <- 이 시점 파형에서 acc=770, dht11_start=1 인지 확인

        #8200; // <- cnt가 810 될 때까지 대기, dht11_start가 0으로 내려가는지 확인

        // ---- cu_done 펄스로 리셋 ----
        cu_done = 1;
        #10;
        cu_done = 0;
        #10;

        #20;   // <- 이 시점 파형에서 state=4, acc=0, acc_reg=0 인지 확인

        // ---- "get sr04" (마침표 전까지 8글자) ----
        rx_data  = 8'h67;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // g
        rx_data  = 8'h65;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // e
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // (space)
        rx_data  = 8'h73;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // s
        rx_data  = 8'h72;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // r
        rx_data  = 8'h30;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // 0
        rx_data  = 8'h34;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // 4

        #20;  // <- 이 시점 파형에서 state=0 인지 확인

        // ---- 마침표 ----
        rx_data  = 8'h2e;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // .

        #20;  // <- 이 시점 파형에서 acc=681, sr04_start=1 인지 확인

        #9000; // <- cnt가 810 될 때까지 대기, sr04_start가 0으로 내려가는지 확인

        cu_done = 1;
        #10;
        cu_done = 0;
        #10;

        // =====================================================
        // ③ "get watch."
        // =====================================================
        rx_data  = 8'h67;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // g
        rx_data  = 8'h65;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // e
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // (space)
        rx_data  = 8'h77;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // w
        rx_data  = 8'h61;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // a
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h63;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // c
        rx_data  = 8'h68;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // h
        #20;  // <- state=2 확인
        rx_data  = 8'h2e;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // .
        #20;  // <- acc=887, watch_get=1 확인
        #8200;  // watch_get=0으로 하강 확인

        cu_done = 1;
        #10;
        cu_done = 0;
        #10;
        #20;  // <- 리셋 확인

        // =====================================================
        // ④ "get lap."  (stopwatch, acc=669)
        //    -> stopwatch_get과 lap_stopwatch 둘 다 1이 떠야 함
        // =====================================================
        rx_data  = 8'h67;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // g
        rx_data  = 8'h65;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // e
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // (space)
        rx_data  = 8'h6c;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // l
        rx_data  = 8'h61;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // a
        rx_data  = 8'h70;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // p
        #20;  // <- state=3 확인
        rx_data  = 8'h2e;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // .
        #20;  // <- acc=669, stopwatch_get=1, lap_stopwatch=1 확인
        #8200;  // stopwatch_get=0, lap_stopwatch=0 으로 하강 확인
        cu_done = 1;
        #10;
        cu_done = 0;
        #10;

        // =====================================================
        // ⑤ "run stopwatch."
        //    -> rs_stopwatch = 1
        // =====================================================
        rx_data  = 8'h72;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // r
        rx_data  = 8'h73;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  //s
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // space
        rx_data  = 8'h73;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // s
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h6f;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // o
        rx_data  = 8'h70;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // p
        rx_data  = 8'h77;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // w
        rx_data  = 8'h61;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // a
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h63;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // c
        rx_data  = 8'h68;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // h

        #20;
        // <- 여기서 명령어 입력 완료 확인

        rx_data  = 8'h2e;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // .

        #20;
        // <- 여기서 rs_stopwatch = 1 확인

        #8200;
        // <- cnt가 810에 도달하면서 rs_stopwatch = 0 확인
        cu_done = 1;
        #10;
        cu_done = 0;
        #10;

        // =====================================================
        // ⑥ 다시 "run stopwatch."
        //    -> rs_stopwatch = 1
        // =====================================================
        rx_data  = 8'h72;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // r
        rx_data  = 8'h73;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // s
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // space
        rx_data  = 8'h73;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // s
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h6f;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // o
        rx_data  = 8'h70;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // p
        rx_data  = 8'h77;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // w
        rx_data  = 8'h61;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // a
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h63;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // c
        rx_data  = 8'h68;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // h

        #20;

        rx_data  = 8'h2e;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // .

        #20;
        // <- 여기서 rs_stopwatch = 1 확인

        #8200;
        // <- 다시 rs_stopwatch = 0 확인
        cu_done = 1;
        #10;
        cu_done = 0;
        #10;

        // =====================================================
        // ⑤ "lap stopwatch"
        //    acc = 1338
        //    -> lap_stopwatch = 1
        //    -> 약 810 cycle 후 lap_stopwatch = 0
        // =====================================================
        rx_data  = 8'h6c;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // l
        rx_data  = 8'h61;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // a
        rx_data  = 8'h70;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // p
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // space
        rx_data  = 8'h73;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // s
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h6f;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // o
        rx_data  = 8'h70;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // p
        rx_data  = 8'h77;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // w
        rx_data  = 8'h61;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // a
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h63;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // c
        rx_data  = 8'h68;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // h

        #20;
        rx_data  = 8'h2e;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  //.
        #20;
        // <- 여기서 acc = 1338 확인
        // <- 여기서 lap_stopwatch = 1 확인

        #8200;
        // <- cnt가 810에 도달한 후 lap_stopwatch = 0 확인

        cu_done = 1;
        #10;
        cu_done = 0;
        #10;

        #20;
        // <- 여기서 acc = 0확인

        // =====================================================
        // ⑥ "edit watch"
        //    acc = 989
        //    -> edit_watch = 1
        //    -> 약 810 cycle 후 edit_watch = 0
        // =====================================================
        rx_data  = 8'h65;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // e
        rx_data  = 8'h64;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // d
        rx_data  = 8'h69;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // i
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h20;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // space
        rx_data  = 8'h77;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // w
        rx_data  = 8'h61;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // a
        rx_data  = 8'h74;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // t
        rx_data  = 8'h63;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // c
        rx_data  = 8'h68;
        rx_valid = 1;
        #10;
        rx_valid = 0;
        #10;  // h

        #20;
        // <- 여기서 acc = 989 확인

        #20;
        // <- 여기서 edit_watch = 1 확인

        #8200;
        // <- cnt가 810에 도달한 후 edit_watch = 0 확인

        $stop;
    end

endmodule
