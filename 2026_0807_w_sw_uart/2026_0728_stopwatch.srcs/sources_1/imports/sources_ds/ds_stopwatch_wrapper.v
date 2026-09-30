`timescale 1ns / 1ps

module ds_stopwatch_wrapper#(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input reset,
    input btn_L,  // runstop
    input btn_R,  // clear
    input btn_U,  // mode
    input btn_D,  // record
    input [2:0] sw,
    output display_mode,
    output [6:0] o_msec,
    output [5:0] o_sec,
    output [5:0] o_min,
    output [4:0] o_hour
);

    assign led = 2'b11;
    assign display_mode = sw[0];

    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire w_run_stop, w_clear, w_mode, w_record;
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;
    wire [6:0] rw_msec;
    wire [5:0] rw_sec;
    wire [5:0] rw_min;
    wire [4:0] rw_hour;
    

    ds_btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    ds_btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    ds_btn_debounce U_BD_MODE (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );

    ds_btn_debounce U_BD_RECORD (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );

    ds_control_unit U_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_run_stop(w_btn_L),
        .i_clear(w_btn_R),
        .i_mode(w_btn_U),
        .i_record(w_btn_D),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode),
        .o_record(w_record)
    );

    ds_record U_RECORD (
    .clk(clk),
    .reset(reset),
    .btn_L(w_btn_L),
    .btn_R(w_btn_R),
    .hour(w_hour),
    .min(w_min),
    .sec(w_sec),
    .msec(w_msec),
    .sw(sw[2]),
    .record(w_record),
    .o_hour(rw_hour),
    .o_min(rw_min),
    .o_sec(rw_sec),
    .o_msec(rw_msec)
);

    ds_stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .run_stop(w_run_stop),
        .clear(w_clear),
        .mode(w_mode),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

    ds_mux_8x4 U_MUX_8x4 (
        .sel(sw[2]),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .r_msec(rw_msec),
        .r_sec(rw_sec),
        .r_min(rw_min),
        .r_hour(rw_hour),
        .o_msec(o_msec),
        .o_sec(o_sec),
        .o_min(o_min),
        .o_hour(o_hour)
);

endmodule

module ds_mux_8x4 (
    input sel,
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    input [4:0] hour,
    input [6:0] r_msec,
    input [5:0] r_sec,
    input [5:0] r_min,
    input [4:0] r_hour,
    output reg [6:0] o_msec,
    output reg [5:0] o_sec,
    output reg [5:0] o_min,
    output reg [4:0] o_hour
);


always @(*) begin
    case(sel)
        0: begin
            o_msec = msec;
            o_sec = sec;
            o_min = min;
            o_hour = hour;
        end
        1: begin
            o_msec = r_msec;
            o_sec = r_sec;
            o_min = r_min;
            o_hour = r_hour;
        end
    endcase
end

endmodule

module ds_stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input reset,
    input run_stop,
    input clear,
    input mode,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);

    // parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;

    wire w_tick_100hz, w_tick_sec, w_tick_min, w_tick_hour;

    ds_time_counter #(
        .BIT_WIDTH(HOUR_WIDTH),
        .TIMES    (24)
    ) U_HOUR_COUNTER (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_tick_hour),
        .mode      (mode),
        .run_stop  (run_stop),
        .clear     (clear),
        .time_count(hour),
        .o_tick    ()
    );

    ds_time_counter #(
        .BIT_WIDTH(MIN_WIDTH),
        .TIMES    (60)
    ) U_MIN_COUNTER (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_tick_min),
        .mode      (mode),
        .run_stop  (run_stop),
        .clear     (clear),
        .time_count(min),
        .o_tick    (w_tick_hour)
    );

    ds_time_counter #(
        .BIT_WIDTH(SEC_WIDTH),
        .TIMES    (60)
    ) U_SEC_COUNTER (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_tick_sec),
        .mode      (mode),
        .run_stop  (run_stop),
        .clear     (clear),
        .time_count(sec),
        .o_tick    (w_tick_min)
    );

    ds_time_counter #(
        .BIT_WIDTH(MSEC_WIDTH),
        .TIMES    (100)
    ) U_MSEC_COUNTER (
        .clk       (clk),
        .reset     (reset),
        .i_tick    (w_tick_100hz),
        .mode      (mode),
        .run_stop  (run_stop),
        .clear     (clear),
        .time_count(msec),
        .o_tick    (w_tick_sec)
    );

    ds_tick_gen_100hz U_TICK_GEN_100HZ (
        .clk   (clk),
        .reset (reset),
        .o_tick(w_tick_100hz)
    );

endmodule

module ds_record (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input [4:0] hour,
    input [5:0] min,
    input [5:0] sec,
    input [6:0] msec,
    input sw,
    input record,
    output [6:0] o_msec,
    output [5:0] o_sec,
    output [5:0] o_min,
    output [4:0] o_hour
);
    reg [23:0] w_record[0:4];
    reg [ 2:0] counter;
    reg [23:0] o_record;

    assign o_msec = o_record[6:0];
    assign o_sec = o_record[12:7];
    assign o_min = o_record[18:13];
    assign o_hour = o_record[23:19];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (!sw) begin
                counter <= 0;
            end     
            else if (btn_L) begin
                    if (counter == 0) counter <= 4;
                    else counter <= counter - 1;
                end else if (btn_R) begin
                    if (counter == 4) counter <= 0;
                    else counter <= counter + 1;
                end else counter <= counter;
            end
        end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            w_record[0] <= 0;
            w_record[1] <= 0;
            w_record[2] <= 0;
            w_record[3] <= 0;
            w_record[4] <= 0;
        end else begin
            case (sw)
                0:
                if (record) begin
                    w_record[0] <= w_record[1];
                    w_record[1] <= w_record[2];
                    w_record[2] <= w_record[3];
                    w_record[3] <= w_record[4];
                    w_record[4] <= {hour, min, sec, msec};
                end
                1:
                if (counter == 0) o_record <= w_record[4];
                else if (counter == 1) o_record <= w_record[3];
                else if (counter == 2) o_record <= w_record[2];
                else if (counter == 3) o_record <= w_record[1];
                else o_record <= w_record[0];
            endcase
        end
    end

endmodule


module ds_time_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      mode,
    input                      run_stop,
    input                      clear,
    output     [BIT_WIDTH-1:0] time_count,
    output reg                 o_tick
);

    reg [BIT_WIDTH-1:0] counter_reg;

    assign time_count = counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
        end else begin
            if (i_tick & run_stop) begin
                if (!mode) begin
                    counter_reg <= counter_reg + 1;
                    if (counter_reg == (TIMES - 1)) begin
                        counter_reg <= 0;
                        o_tick <= 1'b1;
                    end
                end else begin
                    counter_reg <= counter_reg - 1;
                    if (counter_reg == 0) begin
                        counter_reg <= (TIMES - 1);
                        o_tick <= 1'b1;
                    end
                end
            end else begin
                o_tick <= 1'b0;
            end
        end
    end

endmodule


module ds_tick_gen_100hz (
    input clk,
    input reset,
    output reg o_tick
);

    parameter F_COUNT = 1_000_000;
    reg [$clog2(F_COUNT) -1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_COUNT - 1)) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
        end
    end

endmodule

module ds_control_unit (
    input  clk,
    input  reset,
    input  i_run_stop,
    input  i_clear,
    input  i_mode,
    input  i_record,
    output o_run_stop,
    output o_clear,
    output o_mode,
    output o_record
);

    parameter STOP = 0, RUN = 1, CLEAR = 2, MODE = 3, RECORD = 4;

    reg [2:0] c_state, n_state;

    // reg == current_state / next == next_state / 출력도 피드백 구조로 state와 next 구조에 넣고 싶을 때.
    reg run_stop_reg, run_stop_next, clear_reg, clear_next, mode_reg, mode_next, record_reg, record_next;

    // Output
    //assign {o_clear, o_run_stop, o_mode} = (c_state == STOP) ? 3'b000  :
    //                                        (c_state == RUN) ? 3'b010  :
    //                                        (c_state == CLEAR) ? 3'b100:
    //                                        (c_state == MODE) ? 3'b000 : 3'b000;

    assign o_run_stop = run_stop_reg;
    assign o_clear = clear_reg;
    assign o_mode = mode_reg;
    assign o_record = record_reg;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= STOP;
            run_stop_reg <= 1'b0;
            clear_reg <= 1'b0;
            mode_reg <= 1'b0;
            record_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            run_stop_reg <= run_stop_next;
            clear_reg <= clear_next;
            mode_reg <= mode_next;
            record_reg <= record_next;
        end
    end

    // Next CL
    always @(*) begin
        n_state      = c_state;
        run_stop_next = run_stop_reg;
        clear_next   = clear_reg;
        mode_next    = mode_reg;
        record_next = record_reg;
        case (c_state)
            STOP: begin
                // moore output
                run_stop_next = 1'b0;
                clear_next = 1'b0;
                if (i_run_stop) n_state = RUN;
                else if (i_clear) n_state = CLEAR;
                else if (i_mode) n_state = MODE;
                else n_state = c_state;
            end
            RUN: begin
                run_stop_next = 1'b1;
                if (i_run_stop) n_state = STOP;
                else if (i_record) begin
                    record_next = 1'b1;
                    n_state = RECORD;
                end
            end
            CLEAR: begin
                clear_next = 1'b1;
                n_state = STOP;
            end
            MODE: begin
                mode_next = ~mode_reg;
                n_state = STOP;
            end
            RECORD: begin
                record_next = 1'b0;
                n_state = RUN;     
            end
        endcase
    end

endmodule

module ds_btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);
    reg [7:0] q_reg;    // 8tab shift register SIPO
    reg edge_reg;
    wire debounce;      // output of 8 input AND gate

    //reg [5:0] counter_reg;
    reg [$clog2(500)-1:0] counter_reg;     // 필요 비트수 모를 때.
    reg o_1Mhz;

    // clock div : 100Mhz -> 1Mhz
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter_reg <= 0;
            o_1Mhz <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
            if(counter_reg == (500 -1)) begin
                counter_reg <= 0;
                o_1Mhz <= ~o_1Mhz;
            end
        end 
    end

    // 8bit shift register, SPIO
    always @(posedge o_1Mhz, posedge reset) begin
        if(reset) begin
            q_reg <= 8'h00;
        end else begin
            //q_reg <= {q_reg[6:0], i_btn};  // shift left
            q_reg <= {i_btn, q_reg[7:1]};   // SIPO동작  shift right
        end
    end

    // 8bit input AND gate
    assign debounce = &q_reg;

    // 1clock delay by debounce
    always @(posedge clk, posedge reset) begin
        if(reset) edge_reg <= 1'b0;
        else begin
            edge_reg <= debounce;
        end 
    end 

    // edge detetion
    assign o_btn = debounce & (~edge_reg);

endmodule