`timescale 1ns / 1ps

//Moore FSM
module watch_control_unit (
    input  clk,
    input  reset,
    input  i_shift_up,    //btn_L
    input  i_shift_down,  //btn_R
    input  i_time_up,     //btn_U
    input  i_time_down,   //btn_D
    output [2:0] o_select,   // current_state = last state
    output o_time_up,
    output o_time_down
);

 parameter normal = 3'b000, sel_msec = 3'b001, sel_sec = 3'b010, sel_min = 3'b011, sel_hour = 3'b100;

reg [2:0] current_state, next_state;

//output
assign o_select = current_state;  
assign o_time_up = i_time_up;
assign o_time_down = i_time_down;

 // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= normal;
        end else begin
            current_state <= next_state;
        end
    end

      // next state Combinational Logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            normal: begin
                if (i_shift_up) begin
                    next_state = sel_msec;
                end else begin
                    if (i_shift_down) 
                    next_state = normal;
                end
            end
            sel_msec: begin
                if (i_shift_up) begin
                    next_state = sel_sec;
                end else begin
                    if (i_shift_down) 
                    next_state = sel_hour;
                end

            end
            sel_sec: begin
                if (i_shift_up) begin
                    next_state = sel_min;
                end else begin
                    if(i_shift_down) 
                    next_state = sel_msec;
                end

            end
            sel_min: begin
                if (i_shift_up) begin
                    next_state = sel_hour;
                end else begin
                    if(i_shift_down)
                    next_state = sel_sec;
                end

                
            end
            sel_hour: begin
                if (i_shift_up) begin
                    next_state = normal;
                end else begin
                    if (i_shift_down) 
                    next_state = sel_min;
                end
            end
            default: next_state = current_state;
        endcase
    end

    
endmodule
