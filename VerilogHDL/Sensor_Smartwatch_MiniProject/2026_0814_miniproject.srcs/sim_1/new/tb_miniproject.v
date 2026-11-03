`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// tb_top_simple.v
//
// top 모듈 테스트벤치 (쉬운 버전)
//  - "get watch." 같은 문자열을 한 글자씩 UART 직렬 신호로 rx 핀에 보냄
//  - sr04 echo, dht11 은 "가짜 센서"처럼 자동으로 응답해주는 코드가
//    따로 계속 대기하고 있음 (forever 블록)
//////////////////////////////////////////////////////////////////////////////

module tb_miniproject ();

    reg        clk, rst;
    reg        rx;
    wire       tx;
    reg        echo;
    wire       trig;
    reg  [3:0] sw;
    reg        btnl, btnr, btnu, btnd;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    // dht11 은 양방향(inout) 핀이라, 테스트벤치가 직접 값을 실어줄 수 없고
    // "0을 미느냐, 안 미느냐(뗀다=z)"로만 흉내를 냅니다.
    // pullup 은 실제 보드에 달린 풀업저항 역할 (아무도 안 밀면 자동으로 1).
    reg dht11_drive_low;
    wire dht11_line;
    pullup (dht11_line);
    assign dht11_line = dht11_drive_low ? 1'b0 : 1'bz;

    top DUT (
        .clk    (clk),
        .rst    (rst),
        .rx     (rx),
        .tx     (tx),
        .echo   (echo),
        .trig   (trig),
        .dht11  (dht11_line),
        .sw     (sw),
        .btnl   (btnl),
        .btnr   (btnr),
        .btnu   (btnu),
        .btnd   (btnd),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    // Basys3 기본 클럭 100MHz (10ns 주기)
    always #5 clk = ~clk;

    // =========================================================
    // 글자 한 개를 UART로 보내는 기본 동작 (9600bps, 8N1)
    //  0(start) -> 데이터 8비트(LSB부터) -> 1(stop)
    //  비트 하나 유지 시간 = 1/9600초 ≈ 104167ns
    // =========================================================
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            rx = 1'b0;  // start bit
            #104167;
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #104167;
            end
            rx = 1'b1;  // stop bit
            #104167;
        end
    endtask

    // =========================================================
    // [가짜 센서 1] SR04 : trig 뜨면 -> echo를 "거리*58us" 만큼 하이로 유지
    // =========================================================
    localparam SR04_DISTANCE_CM = 100;  // 테스트용 임의 거리(원하는 값으로 수정 가능)

    initial begin
        echo = 1'b0;
        forever begin
            @(posedge trig);
            @(negedge trig);  // trig 펄스 끝날 때까지 대기
            #200000;  // 초음파 왕복 준비하는 시간(임의값)
            echo = 1'b1;
            #(SR04_DISTANCE_CM * 58 * 1000);  // 거리(cm) * 58us
            echo = 1'b0;
        end
    end

    // =========================================================
    // [가짜 센서 2] DHT11 : host가 18ms 로우로 당겼다 놓으면
    //  -> 80us(low)+80us(high) 응답 시작 -> 40비트 데이터 -> 50us(low) 종료
    // =========================================================
    task dht11_bit(input v);
        begin
            dht11_drive_low = 1'b1;
            #50000;  // 모든 비트 공통 : 50us low
            dht11_drive_low = 1'b0;  // 놓으면 풀업때문에 high
            if (v) #70000;  // '1' : high 약 70us
            else #26000;  // '0' : high 약 26~28us
        end
    endtask

    task dht11_byte(input [7:0] b);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) dht11_bit(b[i]);  // MSB부터
        end
    endtask

    initial begin
        dht11_drive_low = 1'b0;
        forever begin
            @(negedge dht11_line);  // host가 로우로 당기기 시작
            @(posedge dht11_line);  // 18ms 후 host가 놓음
            #20000;  // 센서가 응답 준비하는 시간
            dht11_drive_low = 1'b1;
            #80000;
            dht11_drive_low = 1'b0;
            #80000;
            dht11_byte(8'd55);  // 습도 정수부 (원하는 값으로 수정 가능)
            dht11_byte(8'd0);  // 습도 소수부
            dht11_byte(8'd26);  // 온도 정수부
            dht11_byte(8'd0);  // 온도 소수부
            dht11_byte(8'd81);  // 체크섬 = 55+0+26+0
            dht11_drive_low = 1'b1;
            #50000;
            dht11_drive_low = 1'b0;
        end
    end

    // =========================================================
    // 메인 시퀀스
    // =========================================================
    initial begin
        clk  = 0;
        rst  = 1;
        rx   = 1'b1;  // UART 는 평소(idle)에 1
        sw   = 4'b0000;
        btnl = 0;
        btnr = 0;
        btnu = 0;
        btnd = 0;
        #100;
        rst = 0;
        #1000;

        // ===== ① "get watch." =====
        uart_send_byte(8'h67);  // g
        uart_send_byte(8'h65);  // e
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h20);  // (space)
        uart_send_byte(8'h77);  // w
        uart_send_byte(8'h61);  // a
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h63);  // c
        uart_send_byte(8'h68);  // h
        uart_send_byte(8'h2e);  // .
        #15000000;  // 15ms 대기 (watch 응답 다 받을 시간)

        // ===== ② "get sr04." =====
        uart_send_byte(8'h67);  // g
        uart_send_byte(8'h65);  // e
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h20);  // (space)
        uart_send_byte(8'h73);  // s
        uart_send_byte(8'h72);  // r
        uart_send_byte(8'h30);  // 0
        uart_send_byte(8'h34);  // 4
        uart_send_byte(8'h2e);  // .
        #20000000;  // 20ms 대기 (echo 응답 + 전송 시간)

        // ===== ③ "get dht11." =====
        uart_send_byte(8'h67);  // g
        uart_send_byte(8'h65);  // e
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h20);  // (space)
        uart_send_byte(8'h64);  // d
        uart_send_byte(8'h68);  // h
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h31);  // 1
        uart_send_byte(8'h31);  // 1
        uart_send_byte(8'h2e);  // .
        #45000000;  // 45ms 대기 (dht11 은 18ms 시작펄스 때문에 제일 오래 걸림)

        // ===== ④ "rs stopwatch." =====
        uart_send_byte(8'h72);  // r
        uart_send_byte(8'h73);  // s
        uart_send_byte(8'h20);  // (space)
        uart_send_byte(8'h73);  // s
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h6f);  // o
        uart_send_byte(8'h70);  // p
        uart_send_byte(8'h77);  // w
        uart_send_byte(8'h61);  // a
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h63);  // c
        uart_send_byte(8'h68);  // h
        uart_send_byte(8'h2e);  // .
        #15000000;

        // ===== ⑤ "lap stopwatch." =====
        uart_send_byte(8'h6c);  // l
        uart_send_byte(8'h61);  // a
        uart_send_byte(8'h70);  // p
        uart_send_byte(8'h20);  // (space)
        uart_send_byte(8'h73);  // s
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h6f);  // o
        uart_send_byte(8'h70);  // p
        uart_send_byte(8'h77);  // w
        uart_send_byte(8'h61);  // a
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h63);  // c
        uart_send_byte(8'h68);  // h
        uart_send_byte(8'h2e);  // .
        #15000000;

        // ===== ⑥ "get lap." =====
        uart_send_byte(8'h67);  // g
        uart_send_byte(8'h65);  // e
        uart_send_byte(8'h74);  // t
        uart_send_byte(8'h20);  // (space)
        uart_send_byte(8'h6c);  // l
        uart_send_byte(8'h61);  // a
        uart_send_byte(8'h70);  // p
        uart_send_byte(8'h2e);  // .
        #15000000;

        $display("6개 시퀀스 다 보냈음. 시뮬레이션 끝.");
        $stop;
    end

endmodule