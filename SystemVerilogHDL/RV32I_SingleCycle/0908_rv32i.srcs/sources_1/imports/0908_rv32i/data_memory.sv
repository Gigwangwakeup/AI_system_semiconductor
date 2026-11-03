module data_memory(
  input   logic         clk,
  input   logic [31:0]  daddr, 
  input   logic [31:0]  dwdata,
  input   logic         dwe,
  input   logic [ 2:0]  itype,
  output  logic [31:0]  drdata
);

  logic [31:0] dmem [0:127];

    always_ff @(posedge clk) begin
      if(dwe)
        case(itype)
          3'b000 : begin
            case(daddr[1:0])
              2'b00 : dmem[daddr[31:2]][7:0]   <= dwdata[7:0];
              2'b01 : dmem[daddr[31:2]][15:8]  <= dwdata[7:0];
              2'b10 : dmem[daddr[31:2]][23:16] <= dwdata[7:0];
              2'b11 : dmem[daddr[31:2]][31:24] <= dwdata[7:0];             
            endcase
          end
          3'b010 : begin
            case(daddr[1])
              1'b0 : dmem[daddr[31:2]][15:0]   <= dwdata[15:0];
              1'b1 : dmem[daddr[31:2]][31:16]  <= dwdata[15:0];
            endcase
          end
          3'b010 : begin
            dmem[daddr[31:2]]  <= dwdata;
          end
          default : begin
            dmem[daddr[31:2]]  <= dmem[daddr[31:2]];
          end
        endcase
    end

    always_comb begin
      if(!dwe) begin //dwe == 0 IL-type
        case(itype)
          3'b000 : drdata = {{24{dmem[daddr[31:2]][7]}}, dmem[daddr[31:2]][7:0]};
          3'b001 : drdata = {{16{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:0]};
          3'b010 : drdata = dmem[daddr[31:2]];
          3'b100 : drdata = {{24{1'b0}}, dmem[daddr[31:2]][7:0]};
          3'b101 : drdata = {{16{1'b0}}, dmem[daddr[31:2]][15:0]};
          default : drdata = {{24{dmem[daddr[31:2]][7]}}, dmem[daddr[31:2]][7:0]};          
        endcase
      end
    end
endmodule
