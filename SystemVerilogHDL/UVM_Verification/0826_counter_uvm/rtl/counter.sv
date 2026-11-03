module counter (
    input  logic       clk,
    input  logic       rstn,
    input  logic       enable,
    output logic [2:0] counter,
    output logic       o_tick
);

    always_ff @(posedge clk) begin
        if (!rstn) begin
            counter <= 3'd0;
            o_tick  <= 1'b0;
        end else begin
            if (enable) begin
                counter <= counter + 1;
                if (counter == 3'd7) begin
                    o_tick <= 1'b1;
                end else begin
                    o_tick <= 1'b0;
                end
            end else begin
                counter <= counter;
                o_tick  <= 1'b0;
            end
        end
    end

endmodule
