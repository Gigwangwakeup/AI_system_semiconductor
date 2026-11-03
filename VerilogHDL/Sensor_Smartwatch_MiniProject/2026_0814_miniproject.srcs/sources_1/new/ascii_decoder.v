module ascii_decoder (
    input        clk,
    input        rst,
    input        cu_done,
    input        rx_valid,
    input        rx_full,
    input  [7:0] rx_data,
    output       rx_pop,
    output       dht11_start,
    output       sr04_start,
    output       watch_get,
    output       stopwatch_get,
    output [2:0] state,
    output       rs_stopwatch,
    output       clear_stopwatch,
    output       down_stopwatch,
    output       lap_stopwatch,
    output       edit_watch,
    output       left_watch,
    output       right_watch,
    output       up_watch,
    output       down_watch
);

    reg [31:0] acc, acc_reg;
    reg dht11_start_reg, sr04_start_reg, watch_get_reg, stopwatch_get_reg;
    reg rs_stopwatch_reg, clear_stopwatch_reg, down_stopwatch_reg, lap_stopwatch_reg;
    reg edit_watch_reg, left_watch_reg, right_watch_reg, up_watch_reg, down_watch_reg;
    reg [$clog2(810)-1:0] cnt;
    // reg [6:0] cnt;
    reg [2:0] state_reg;

    assign rx_pop = (rx_valid) ? 1'b1 : 1'b0;

    //덧셈 저장, don't touch
    always @(posedge clk, posedge rst) begin
    if (rst) begin
        acc_reg   <= 0;
        acc       <= 0;
        state_reg <= 3'd4;
    end else if (cu_done) begin
        acc_reg   <= 0;
        acc       <= 0;
        state_reg <= 3'd4;
    end else begin
        if (cnt == 810) begin
            acc <= 0;
        end

        if (rx_pop) begin
            acc_reg <= acc_reg + rx_data;
            if (rx_data == 8'h2e) begin
                acc <= acc_reg;
                acc_reg <= 0;
            end
        end

        case(acc_reg)
            32'd681 : state_reg <= 3'd0;
            32'd770 : state_reg <= 3'd1;
            32'd887 : state_reg <= 3'd2;
            32'd669 : state_reg <= 3'd3;
            default : state_reg <= 3'd4;
        endcase
    end
end
    
    always @(*) begin
        dht11_start_reg = 0;
        sr04_start_reg = 0;
        watch_get_reg = 0;
        stopwatch_get_reg = 0;
        rs_stopwatch_reg = 0;
        clear_stopwatch_reg = 0;
        down_stopwatch_reg = 0;
        lap_stopwatch_reg = 0;
        edit_watch_reg = 0;
        left_watch_reg = 0;
        right_watch_reg = 0;
        up_watch_reg = 0;
        down_watch_reg = 0;
        case(acc)
            32'd770 : begin // get dht11
                if (cnt == 810) begin
                    dht11_start_reg = 1'b0;
                end else begin
                    dht11_start_reg = 1'b1;
                end
            end
            32'd681 : begin // get sr04
                if (cnt == 810) begin
                    sr04_start_reg = 1'b0;
                end else begin
                    sr04_start_reg = 1'b1;
                end
            end
            32'd887 : begin // get watch
                if (cnt == 810) begin
                    watch_get_reg = 1'b0;
                end else begin
                    watch_get_reg = 1'b1;
                end
            end
            32'd669 : begin // get lap
                if (cnt == 810) begin
                    stopwatch_get_reg = 1'b0;
                end else begin
                    stopwatch_get_reg = 1'b1;
                end
            end
            32'd1250 : begin // rs stopwatch
                if (cnt == 810) begin
                    rs_stopwatch_reg = 1'b0;
                end else begin
                    rs_stopwatch_reg = 1'b1;
                end
            end
            32'd1540 : begin // clear stopwatch
                if (cnt == 810) begin
                    clear_stopwatch_reg = 1'b0;
                end else begin
                    clear_stopwatch_reg = 1'b1;
                end
            end
            32'd1461 : begin // down stopwatch
                if (cnt == 810) begin
                    down_stopwatch_reg = 1'b0;
                end else begin
                    down_stopwatch_reg = 1'b1;
                end
            end
            32'd1338 : begin // lap stopwatch
                if (cnt == 810) begin
                    lap_stopwatch_reg = 1'b0;
                end else begin
                    lap_stopwatch_reg = 1'b1;
                end
            end
            32'd989 : begin // edit watch
                if (cnt == 810) begin
                    edit_watch_reg = 1'b0;
                end else begin
                    edit_watch_reg = 1'b1;
                end
            end
            32'd994 : begin // left watch
                if (cnt == 810) begin
                    left_watch_reg = 1'b0;
                end else begin
                    left_watch_reg = 1'b1;
                end
            end
            32'd1109 : begin // right watch
                if (cnt == 810) begin
                    right_watch_reg = 1'b0;
                end else begin
                    right_watch_reg = 1'b1;
                end
            end
            32'd796 : begin // up watch
                if (cnt == 810) begin
                    up_watch_reg = 1'b0;
                end else begin
                    up_watch_reg = 1'b1;
                end
            end
            32'd1007 : begin // down watch
                if (cnt == 810) begin
                    down_watch_reg = 1'b0;
                end else begin
                    down_watch_reg = 1'b1;
                end
            end
        endcase
    end
    // output 
    assign dht11_start = dht11_start_reg;
    assign sr04_start = sr04_start_reg;
    assign watch_get = watch_get_reg;
    assign stopwatch_get = stopwatch_get_reg;
    assign state = state_reg;

    assign rs_stopwatch = rs_stopwatch_reg;
    assign clear_stopwatch = clear_stopwatch_reg;
    assign down_stopwatch = down_stopwatch_reg;
    assign lap_stopwatch = lap_stopwatch_reg;
    assign edit_watch = edit_watch_reg;
    assign left_watch = left_watch_reg;
    assign right_watch = right_watch_reg;
    assign up_watch = up_watch_reg;
    assign down_watch = down_watch_reg;

    // butten debounce
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cnt <= 0;
            // r_rx_done <= 0;
        end else begin
            if (rx_valid) begin
                cnt <= 0;
            end else if (cnt == 810) begin
                cnt <= cnt;
            end else begin
                cnt <= cnt +1;
            end
        end
    end


    // // reg r_rx_done;/
    // reg r_sw_run, r_sw_record, r_sw_clear, r_sw_mode;
    // reg r_w_up, r_w_left, r_w_right, r_w_edit;

    // reg [6:0] cnt;
    // // race condition
    // always @(posedge clk, posedge rst) begin
    //     if (rst) begin
    //         cnt <= 0;
    //         // r_rx_done <= 0;
    //     end else begin
    //         if (rx_done) begin
    //             cnt <= 0;
    //         end else if (cnt == 80) begin
    //             cnt <= cnt;
    //         end else begin
    //             cnt <= cnt +1;
    //         end
    //     end
    // end

    // // Lookup-table
    // always @(*) begin
    //     r_sw_run = 0;
    //     r_sw_record = 0;
    //     r_sw_clear = 0;
    //     r_sw_mode = 0;
    //     r_w_up = 0;
    //     r_w_left = 0;
    //     r_w_right = 0;
    //     r_w_edit = 0;
    //     case (rx_data)
    //         8'h72: r_sw_run = 1;
    //         8'h73: r_sw_record = 1;
    //         8'h63: r_sw_clear = 1;
    //         8'h6D: r_sw_mode = 1;
    //         8'h55: r_w_up = 1;
    //         8'h4C: r_w_left = 1;
    //         8'h52: r_w_right = 1;
    //         8'h44: r_w_edit = 1;
    //     endcase
    // end

    // // output 800ns pulse  
    // assign sw_run    = (cnt == 80) ? 0 : r_sw_run;
    // assign sw_record = (cnt == 80) ? 0 : r_sw_record;
    // assign sw_clear  = (cnt == 80) ? 0 : r_sw_clear;
    // assign sw_mode   = (cnt == 80) ? 0 : r_sw_mode;
    // assign w_up      = (cnt == 80) ? 0 : r_w_up;
    // assign w_left    = (cnt == 80) ? 0 : r_w_left;
    // assign w_right   = (cnt == 80) ? 0 : r_w_right;
    // assign w_edit    = (cnt == 80) ? 0 : r_w_edit;

endmodule