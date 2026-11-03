`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/14 18:14:24
// Design Name: 
// Module Name: top
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


module top (
    input  clk,
    input  rst,
    // uart
    input  rx,
    output tx,
    // sr04
    input  echo,
    output trig,
    // dht 11
    inout  dht11,

    //physics
    input [3:0] sw,
    input btnl,
    input btnr,
    input btnu,
    input btnd,
    //fnd
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    // UART
    wire w_rx_pop, w_tx_push, w_tx_done;
    wire [7:0] w_tx_data, w_rx_data;
    wire w_fifo_rx_empty, w_fifo_tx_full;

    // ascii_decoder -> controller
    wire w_dht11_start, w_sr04_start, w_watch_get, w_stopwatch_get;
    wire [2:0] w_state;
    wire w_rs_stopwatch, w_clear_stopwatch, w_down_stopwatch, w_lap_stopwatch;
    wire w_edit_watch, w_left_watch, w_right_watch, w_up_watch, w_down_watch;
    wire w_cu_done;
    // sr04
    wire w_sr04_done, w_cu_sr04_start;
    wire [8:0] w_sr04_distance;

    // dht11
    wire w_dht11_done, w_cu_dht11_start, w_dht11_valid;
    wire [7:0] w_dht11_humidity_int, w_dht11_humidity_dec;
    wire [7:0] w_dht11_temperature_int, w_dht11_temperature_dec;

    // controller -> ascii_sender
    wire       w_send_start;
    wire [8:0] w_send_data;
    wire       w_ascii_done;

    // smartwatch
    wire w_smart_l, w_smart_r, w_smart_u, w_smart_d;
    wire [4:0] w_watch_hour, w_lap_hour;
    wire [5:0] w_watch_min, w_watch_sec, w_lap_min, w_lap_sec;
    wire [6:0] w_watch_msec, w_lap_msec;
    wire [4:0] w_stopwatch_hour;
    wire [5:0] w_stopwatch_min, w_stopwatch_sec;
    wire [ 6:0] w_stopwatch_msec;

    // o_mux
    wire [17:0] w_mux_o;


    uart_fifo u_uart_fifo (
        .clk          (clk),              // I
        .rst          (rst),              // I
        .rx           (rx),               // I .. output
        .rx_pop       (w_rx_pop),         // I .. ascii_decoder
        .tx_push      (w_tx_push),        // I .. ascii_encoder
        .tx_data      (w_tx_data),        // I .. ascii_encoder .. [7:0]
        .rx_data      (w_rx_data),        // O .. ascii_decoder .. [7:0]
        .fifo_rx_empty(w_fifo_rx_empty),  // O .. ascii_decoder
        .fifo_tx_full (w_fifo_tx_full),
        .tx_done      (w_tx_done),        // O .. ascii_encoder
        .tx           (tx)                // O .. output
    );

    ascii_sender u_ascii_sender (
        .clk          (clk),
        .reset        (rst),
        .selected_data(w_send_data),     // from cu
        .send_start   (w_send_start),    // from uart fifo
        .full         (w_fifo_tx_full),  // to uart fifo
        .push         (w_tx_push),       // to uart fifo
        .done         (w_ascii_done),
        .tx_data      (w_tx_data)        // to uart fifo
        //output reg busy
    );

    ascii_decoder u_ascii_decoder (
        .clk            (clk),
        .rst            (rst),
        .cu_done        (w_cu_done),
        .rx_valid       (~w_fifo_rx_empty),
        .rx_full        (),
        .rx_data        (w_rx_data),
        .rx_pop         (w_rx_pop),
        .dht11_start    (w_dht11_start),
        .sr04_start     (w_sr04_start),
        .watch_get      (w_watch_get),
        .stopwatch_get  (w_stopwatch_get),
        .state          (w_state),
        .rs_stopwatch   (w_rs_stopwatch),
        .clear_stopwatch(w_clear_stopwatch),
        .down_stopwatch (w_down_stopwatch),
        .lap_stopwatch  (w_lap_stopwatch),
        .edit_watch     (w_edit_watch),
        .left_watch     (w_left_watch),
        .right_watch    (w_right_watch),
        .up_watch       (w_up_watch),
        .down_watch     (w_down_watch)
    );

    controller u_cu (
        .clk            (clk),
        .rst            (rst),
        // ascii_decoder btn
        .cu_done        (w_cu_done),
        .state          (w_state),
        .rs_stopwatch   (w_rs_stopwatch),
        .clear_stopwatch(w_clear_stopwatch),
        .down_stopwatch (w_down_stopwatch),
        .lap_stopwatch  (w_lap_stopwatch),
        .edit_watch     (w_edit_watch),
        .left_watch     (w_left_watch),
        .right_watch    (w_right_watch),
        .up_watch       (w_up_watch),
        .down_watch     (w_down_watch),
        //sr04
        .sr04_done      (w_sr04_done),
        .sr04_distance  (w_sr04_distance),
        .sr04_start     (w_sr04_start),
        .cu_sr04_start  (w_cu_sr04_start),          // sr04top
        //dht11
        .dht11_done     (w_dht11_done),
        .humidity_int   (w_dht11_humidity_int),
        .humidity_dec   (w_dht11_humidity_dec),
        .temperature_int(w_dht11_temperature_int),
        .temperature_dec(w_dht11_temperature_dec),
        .dht11_start    (w_dht11_start),
        .cu_dht11_start (w_cu_dht11_start),         // dht11top
        //smartwatch
        .sw             (sw[1]),
        .w_hour         (w_watch_hour),
        .w_min          (w_watch_min),
        .w_sec          (w_watch_sec),
        .w_msec         (w_watch_msec),
        .s_hour         (w_lap_hour),
        .s_min          (w_lap_min),
        .s_sec          (w_lap_sec),
        .s_msec         (w_lap_msec),
        .smart_l        (w_smart_l),
        .smart_r        (w_smart_r),
        .smart_u        (w_smart_u),
        .smart_d        (w_smart_d),
        // physical btn,sw
        .btnl           (btnl),
        .btnr           (btnr),
        .btnu           (btnu),
        .btnd           (btnd),
        // output to encoder
        .ascii_done     (w_ascii_done),
        .send_start     (w_send_start),
        .data           (w_send_data)
    );

    sr04_top u_sr04_top (
        .clk     (clk),              // I
        .rst     (rst),              // I
        .start   (w_cu_sr04_start),  // I .. cu
        .echo    (echo),             // I .. input
        .trigger (trig),             // O .. output
        .done    (w_sr04_done),      // O .. cu
        .distance(w_sr04_distance)   // O .. cu .. [8:0]
        // output [3:0] fnd_com,
        // output [7:0] fnd_data
    );

    dht11_top u_dht11_top (
        .clk            (clk),                      // I
        .rst            (rst),                      // I
        .start          (w_cu_dht11_start),         // I  .. cu
        .dht11          (dht11),                    // IO .. inout
        .done           (w_dht11_done),             // O  .. cu
        .valid          (w_dht11_valid),            // O  .. cu
        .humidity_int   (w_dht11_humidity_int),     // O  .. cu .. [7:0]
        .humidity_dec   (w_dht11_humidity_dec),     // O  .. cu .. [7:0]
        .temperature_int(w_dht11_temperature_int),  // O  .. cu .. [7:0]
        .temperature_dec(w_dht11_temperature_dec)   // O  .. cu .. [7:0]
        // input sw,
        // output [3:0] fnd_com,
        // output [7:0] fnd_data
    );


    smartwatch u_smartwatch (
        .clk     (clk),               // I
        .reset   (rst),               // I
        .btn_L   (w_smart_l),         // I .. cu .. run_stop
        .btn_R   (w_smart_r),         // I .. cu .. clear
        .btn_U   (w_smart_u),         // I .. cu .. mode
        .btn_D   (w_smart_d),         // I .. cu .. lap_register
        .sw      ({sw[3],sw[1]}),           // I .. [2:0]
        .lap_hour(w_lap_hour),
        .lap_min (w_lap_min),
        .lap_sec (w_lap_sec),
        .lap_msec(w_lap_msec),
        .w_hour  (w_watch_hour),      // O .. [4:0]
        .w_min   (w_watch_min),       // O .. [5:0]
        .w_sec   (w_watch_sec),       // O .. [5:0] 
        .w_msec  (w_watch_msec),      // O .. [6:0]
        .s_hour  (w_stopwatch_hour),  // O .. [4:0]
        .s_min   (w_stopwatch_min),   // O .. [5:0]
        .s_sec   (w_stopwatch_sec),   // O .. [5:0] 
        .s_msec  (w_stopwatch_msec),  // O .. [6:0]
        .led     (),                  // O .. [2:0]
        .led15   ()                   // O 
    );

    o_mux u_o_mux (
        .sw(sw[2:1]),  // 00 : watch .. 01 : stopwatch .. 10 : sr04 .. 11 : dht11
        .display(sw[0]),  // sw[0]
        .w_hour(w_watch_hour),
        .w_min(w_watch_min),
        .w_sec(w_watch_sec),
        .w_msec(w_watch_msec),
        .s_hour(w_stopwatch_hour),
        .s_min(w_stopwatch_min),
        .s_sec(w_stopwatch_sec),
        .s_msec(w_stopwatch_msec),
        .humidity_int(w_dht11_humidity_int),
        .humidity_dec(w_dht11_humidity_dec),
        .temperature_int(w_dht11_temperature_int),
        .temperature_dec(w_dht11_temperature_dec),
        .distance(w_sr04_distance),
        .mux_o(w_mux_o)
    );

    fnd_controller u_fnd_ctrl (
        .clk     (clk),      // I
        .rst     (rst),      // I
        .fnd_in  (w_mux_o),  // I .. cu .. [17:0]
        .fnd_com (fnd_com),  // O .. output ..[3:0]
        .fnd_data(fnd_data)  // O .. output ..[7:0]
    );
endmodule

module controller (
    input        clk,
    input        rst,
    output       cu_done,
    input  [2:0] state,
    input        rs_stopwatch,
    input        clear_stopwatch,
    input        down_stopwatch,
    input        lap_stopwatch,
    input        edit_watch,
    input        left_watch,
    input        right_watch,
    input        up_watch,
    input        down_watch,
    input        sr04_done,
    input  [8:0] sr04_distance,
    input        sr04_start,
    output       cu_sr04_start,
    input        dht11_done,
    input  [7:0] humidity_int,
    input  [7:0] humidity_dec,
    input  [7:0] temperature_int,
    input  [7:0] temperature_dec,
    input        dht11_start,
    output       cu_dht11_start,
    input        sw,
    input  [4:0] w_hour,
    input  [5:0] w_min,
    input  [5:0] w_sec,
    input  [6:0] w_msec,
    input  [4:0] s_hour,
    input  [5:0] s_min,
    input  [5:0] s_sec,
    input  [6:0] s_msec,
    output       smart_l,
    output       smart_r,
    output       smart_u,
    output       smart_d,
    input        btnl,
    input        btnr,
    input        btnu,
    input        btnd,
    input        ascii_done,       // ← 추가: ascii_sender의 done
    output       send_start,
    output [8:0] data
);

    parameter [2:0] IDLE = 3'd4, SR04 = 3'd0, DHT11 = 3'd1, WATCH = 3'd2, STOPWATCH = 3'd3;
    reg [2:0] c_state, n_state;
    reg [3:0] cnt_reg, cnt_next;
    reg [8:0] data_reg, data_next;
    reg oe_reg, oe_next;
    reg wait_done_reg, wait_done_next; 
    reg [4:0] w_hour_reg, s_hour_reg;
    reg [5:0] w_min_reg, s_min_reg, w_sec_reg, s_sec_reg;
    reg [6:0] w_msec_reg, s_msec_reg;
    reg smart_l_reg, smart_r_reg, smart_u_reg, smart_d_reg;
    reg send_start_reg, send_start_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            data_reg <= 0;
            cnt_reg <= 0;
            oe_reg <= 0;
            send_start_reg <= 0;
            wait_done_reg <= 0;
        end else begin
            c_state        <= n_state;
            data_reg       <= data_next;
            cnt_reg        <= cnt_next;
            oe_reg         <= oe_next;
            send_start_reg <= send_start_next;
            wait_done_reg  <= wait_done_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        data_next = data_reg;
        cnt_next = cnt_reg;
        oe_next = oe_reg;
        send_start_next = send_start_reg;
        wait_done_next = wait_done_reg;
        w_hour_reg = w_hour;
        w_min_reg = w_min;
        w_sec_reg = w_sec;
        w_msec_reg = w_msec;
        s_hour_reg = s_hour;
        s_min_reg = s_min;
        s_sec_reg = s_sec;
        s_msec_reg = s_msec;

        case (c_state)
            IDLE: begin
                n_state = state;
            end

            SR04: begin
                if (!oe_reg) begin
                    if (sr04_done) begin
                        oe_next        = 1'b1;
                        cnt_next       = 0;
                        wait_done_next = 1'b0;
                    end
                end else begin
                    if (!wait_done_reg && !send_start_reg) begin
                        data_next       = sr04_distance;
                        send_start_next = 1'b1;
                        wait_done_next  = 1'b1;
                    end else if (send_start_reg) begin
                        send_start_next = 1'b0;  // 펄스 1클럭만 유지
                    end else if (wait_done_reg && ascii_done) begin
                        n_state        = IDLE;
                        oe_next        = 1'b0;
                        wait_done_next = 1'b0;
                    end
                end
            end

            DHT11: begin
                if (!oe_reg) begin
                    if (dht11_done) begin
                        oe_next        = 1'b1;
                        cnt_next       = 0;
                        wait_done_next = 1'b0;
                    end
                end else begin
                    if (!wait_done_reg && !send_start_reg) begin
                        case (cnt_reg)
                            4'd0: data_next = temperature_int;
                            4'd1: data_next = temperature_dec;
                            4'd2: data_next = humidity_int;
                            4'd3: data_next = humidity_dec;
                        endcase
                        send_start_next = 1'b1;
                        wait_done_next  = 1'b1;
                    end else if (send_start_reg) begin
                        send_start_next = 1'b0;
                    end else if (wait_done_reg && ascii_done) begin
                        if (cnt_reg == 4'd3) begin
                            n_state        = IDLE;
                            oe_next        = 1'b0;
                            cnt_next       = 0;
                            wait_done_next = 1'b0;
                        end else begin
                            cnt_next       = cnt_reg + 1;
                            wait_done_next = 1'b0;
                        end
                    end
                end
            end

            WATCH: begin
                if (!oe_reg) begin
                    w_hour_reg     = w_hour;
                    w_min_reg      = w_min;
                    w_sec_reg      = w_sec;
                    w_msec_reg     = w_msec;
                    oe_next        = 1'b1;
                    cnt_next       = 0;
                    wait_done_next = 1'b0;
                end else begin
                    if (!wait_done_reg && !send_start_reg) begin
                        case (cnt_reg)
                            4'd0: data_next = w_hour_reg;
                            4'd1: data_next = w_min_reg;
                            4'd2: data_next = w_sec_reg;
                            4'd3: data_next = w_msec_reg;
                        endcase
                        send_start_next = 1'b1;
                        wait_done_next  = 1'b1;
                    end else if (send_start_reg) begin
                        send_start_next = 1'b0;
                    end else if (wait_done_reg && ascii_done) begin
                        if (cnt_reg == 4'd3) begin
                            n_state        = IDLE;
                            oe_next        = 1'b0;
                            cnt_next       = 0;
                            wait_done_next = 1'b0;
                        end else begin
                            cnt_next       = cnt_reg + 1;
                            wait_done_next = 1'b0;
                        end
                    end
                end
            end

            STOPWATCH: begin
                if (!oe_reg) begin
                    s_hour_reg     = s_hour;
                    s_min_reg      = s_min;
                    s_sec_reg      = s_sec;
                    s_msec_reg     = s_msec;
                    oe_next        = 1'b1;
                    cnt_next       = 0;
                    wait_done_next = 1'b0;
                end else begin
                    if (!wait_done_reg && !send_start_reg) begin
                        case (cnt_reg)
                            4'd0: data_next = s_hour_reg;
                            4'd1: data_next = s_min_reg;
                            4'd2: data_next = s_sec_reg;
                            4'd3: data_next = s_msec_reg;
                        endcase
                        send_start_next = 1'b1;
                        wait_done_next  = 1'b1;
                    end else if (send_start_reg) begin
                        send_start_next = 1'b0;
                    end else if (wait_done_reg && ascii_done) begin
                        if (cnt_reg == 4'd3) begin
                            n_state        = IDLE;
                            oe_next        = 1'b0;
                            cnt_next       = 0;
                            wait_done_next = 1'b0;
                        end else begin
                            cnt_next       = cnt_reg + 1;
                            wait_done_next = 1'b0;
                        end
                    end
                end
            end
        endcase
    end

    assign send_start     = send_start_reg;
    assign data           = data_reg;
    assign cu_sr04_start  = sr04_start;
    assign cu_dht11_start = dht11_start;
    assign cu_done = (c_state != IDLE) && (n_state == IDLE);
    //control smartwatch btn
    always @(*) begin
        smart_l_reg = 0;
        smart_r_reg = 0;
        smart_u_reg = 0;
        smart_d_reg = 0;
        case (sw)
            1'b0: begin
                smart_l_reg = btnl | left_watch;
                smart_r_reg = btnr | right_watch;
                smart_u_reg = btnu | up_watch;
                smart_d_reg = btnd | down_watch;
            end
            1'b1: begin
                smart_l_reg = btnl | rs_stopwatch;
                smart_r_reg = btnr | clear_stopwatch;
                smart_u_reg = btnu | down_stopwatch;
                smart_d_reg = btnd | lap_stopwatch;
            end
        endcase
    end

    assign smart_l = smart_l_reg;
    assign smart_r = smart_r_reg;
    assign smart_u = smart_u_reg;
    assign smart_d = smart_d_reg;

endmodule

module o_mux (
    input [1:0] sw,  // 00 : watch .. 01 : stopwatch .. 10 : sr04 .. 11 : dht11
    input display,
    input [4:0] w_hour,
    input [5:0] w_min,
    input [5:0] w_sec,
    input [6:0] w_msec,
    input [4:0] s_hour,
    input [5:0] s_min,
    input [5:0] s_sec,
    input [6:0] s_msec,
    input [7:0] humidity_int,
    input [7:0] humidity_dec,
    input [7:0] temperature_int,
    input [7:0] temperature_dec,
    input [8:0] distance,
    output [17:0] mux_o
);


    reg [17:0] mux_reg;
    wire [8:0] distance100 = distance / 100;
    wire [8:0] distance10 = distance % 100;

    always @(*) begin
        mux_reg = 0;
        case (sw)
            2'b00: begin  // watch
                if (!display) mux_reg = {4'd0, w_hour, 3'd0, w_min};
                else mux_reg = {3'd0, w_sec, 2'd0, w_msec};
            end
            2'b01: begin  // stopwatch
                if (!display) mux_reg = {4'd0, s_hour, 3'd0, s_min};
                else mux_reg = {3'd0, s_sec, 2'd0, s_msec};
            end
            2'b10: begin  // sr04
                mux_reg = {distance100, distance10};
            end
            2'b11: begin  // dht11
                if (!display)
                    mux_reg = {1'd0, temperature_int, 1'd0, temperature_dec};
                else mux_reg = {1'd0, humidity_int, 1'd0, humidity_dec};
            end
        endcase
    end

    assign mux_o = mux_reg;
endmodule

module ascii_sender (
    input clk,
    input reset,
    input [8:0] selected_data,  // from cu
    input send_start,  // from uart fifo
    input full,  // from uart fifo
    output reg push,  //  to uart fifo
    output reg done,
    output reg [7:0] tx_data  // to uart fifo

    //output reg busy
);

    wire [7:0] w_digit_100, w_digit_10, w_digit_1;
    wire [3:0] digit_100, digit_10, digit_1;
    reg [8:0] save_data;

    ascii_encoder U_ASCII_ENCODER_D_S_100 (
        .data(digit_100),
        .ascii_data(w_digit_100)
    );

    ascii_encoder U_ASCII_ENCODER_D_S_10 (
        .data(digit_10),
        .ascii_data(w_digit_10)
    );

    ascii_encoder U_ASCII_ENCODER_D_S_1 (
        .data(digit_1),
        .ascii_data(w_digit_1)
    );

    digit_splitter U_DIGIT_SPLITTER (
        .data_control_unit(save_data),  // 연속적으로 신호가 들어와도 하던일 마저 진행
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100)
    );

    localparam [2:0] IDLE = 0, SEND_100 = 1, SEND_10 = 2, SEND_1 = 3;
    reg [2:0] c_state, n_state;

    //ascii_sender 입력 시 신호가 연속으로 들어와도 겹치지 않도록 idle,send_data가 1일때만 새로운 데이터가 들어왔다고 아는것
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            save_data <= 9'd0;
        end else if (c_state == IDLE && send_start) begin
            save_data <= selected_data;
        end
    end


    // current_state
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            done <= 1'b0;
        end else begin
            c_state <= n_state;
            done <= (c_state == SEND_1) && !full;
        end
    end

    // next_state
    always @(*) begin
        n_state = c_state;
        case (c_state)
            IDLE: begin
                if (send_start) begin
                    n_state = SEND_100;
                end else begin
                    n_state = IDLE;
                end
            end
            SEND_100: begin
                if (!full) begin
                    n_state = SEND_10;
                end else begin
                    n_state = SEND_100;
                end
            end
            SEND_10: begin
                if (!full) begin
                    n_state = SEND_1;
                end else begin
                    n_state = SEND_10;
                end
            end
            SEND_1: begin
                if (!full) begin
                    n_state = IDLE;
                end else begin
                    n_state = SEND_1;
                end
            end
            default: n_state = IDLE;
        endcase
    end

    // output logic
    always @(*) begin
        push = 1'b0;
        tx_data = 8'h00;
        //busy = (c_state != IDLE); //register추가하고 신호 무시되지 않도록 busy신호추가
        case (c_state)
            SEND_100: begin
                tx_data = w_digit_100;
                if (!full && digit_100 != 0)
                    push = 1'b1;  // full이 아닐 때만 push 발생
            end
            SEND_10: begin
                tx_data = w_digit_10;
                if (!full) push = 1'b1;  // full이 아닐 때만 push 발생
            end
            SEND_1: begin
                tx_data = w_digit_1;
                if (!full) push = 1'b1;  // full이 아닐 때만 push 발생
            end
            default: begin
                push = 1'b0;
                tx_data = 8'h00;
            end
        endcase
    end
endmodule

module ascii_encoder (
    input [3:0] data,
    output reg [7:0] ascii_data
);

    always @(*) begin
        case (data)
            4'd0: ascii_data = 8'h30;  //0
            4'd1: ascii_data = 8'h31;  //1
            4'd2: ascii_data = 8'h32;  //2
            4'd3: ascii_data = 8'h33;  //3
            4'd4: ascii_data = 8'h34;  //4
            4'd5: ascii_data = 8'h35;  //5
            4'd6: ascii_data = 8'h36;  //6
            4'd7: ascii_data = 8'h37;  //7
            4'd8: ascii_data = 8'h38;  //8
            4'd9: ascii_data = 8'h39;  //9
            4'd10: ascii_data = 8'h3A;  // :
            default: ascii_data = 8'h30;
        endcase
    end

endmodule

module digit_splitter (
    input  [8:0] data_control_unit, // control_unit에서 받는 신호, 센서거리때문에 9비트
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100
);

    assign digit_1   = data_control_unit % 10;
    assign digit_10  = (data_control_unit / 10) % 10;
    assign digit_100 = (data_control_unit / 100) % 10;

endmodule
