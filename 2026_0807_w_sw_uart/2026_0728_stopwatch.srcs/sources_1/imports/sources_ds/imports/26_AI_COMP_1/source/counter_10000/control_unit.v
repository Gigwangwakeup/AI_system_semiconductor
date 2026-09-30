`timescale 1ns / 1ps

module control_unit (
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
