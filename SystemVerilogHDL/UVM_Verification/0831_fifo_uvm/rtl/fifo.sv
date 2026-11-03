module fifo #(parameter ADDR_WIDTH = 3)(
  input   logic        clk,
  input   logic        rstn,
  input   logic        push,
  input   logic        pop,
  input   logic  [7:0] wdata,
  output  logic  [7:0] rdata,
  output  logic        empty,
  output  logic        full
);

  logic [ADDR_WIDTH -1:0] w_wptr,w_rptr;

 mem #(.ADDR_WIDTH(3), .BIT_WIDTH(8))
 u_mem(
    .clk(clk),
    .waddr(w_wptr),
    .raddr(w_rptr),
    .wdata(wdata),
    .we(push & ~full),
    .rdata(rdata)
);

fifo_control_unit #(.ADDR_WIDTH(3))
u_fifo_control_unit(
    .clk(clk),
    .rstn(rstn),
    .push(push),
    .pop(pop),
    .wptr(w_wptr),
    .rptr(w_rptr),
    .full(full),
    .empty(empty)
);


endmodule


module mem #(parameter ADDR_WIDTH = 3, BIT_WIDTH = 8)(
  input   logic                     clk,
  input   logic   [ADDR_WIDTH -1:0] waddr,
  input   logic   [ADDR_WIDTH -1:0] raddr,
  input   logic   [BIT_WIDTH -1:0 ] wdata,
  input   logic                     we,
  output  logic   [BIT_WIDTH -1:0 ] rdata
);

localparam DEPTH = 2**ADDR_WIDTH;
logic [BIT_WIDTH -1 :0] mem [0:DEPTH-1];

  always @(posedge clk) begin
    if(we)
      mem[waddr] <= wdata;
  end

  //output CL
  assign rdata = mem[raddr];
endmodule

module fifo_control_unit #(parameter ADDR_WIDTH = 3)(
  input   logic                   clk,
  input   logic                   rstn,
  input   logic                   push,
  input   logic                   pop,
  output  logic [ADDR_WIDTH -1:0] wptr,
  output  logic [ADDR_WIDTH -1:0] rptr,
  output  logic                   full,
  output  logic                   empty
);

  logic [ADDR_WIDTH -1:0] wptr_reg,wptr_next;
  logic [ADDR_WIDTH -1:0] rptr_reg,rptr_next;
  logic full_reg, full_next;
  logic empty_reg, empty_next;

  //state SL
  always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
      wptr_reg <= 0;
      rptr_reg <= 0;
      full_reg <= 0;
      empty_reg <= 1;
    end else begin
      wptr_reg <= wptr_next;
      rptr_reg <= rptr_next;
      full_reg <= full_next;
      empty_reg <= empty_next;
    end
  end

  //next, output CL
  always @(*) begin
    wptr_next = wptr_reg;
    rptr_next = rptr_reg;
    full_next = full_reg;
    empty_next = empty_reg;
    case({push,pop})
      2'b00 : begin
        //init
      end
      2'b01 : begin
        //pop only
        if(!empty_reg) begin
          rptr_next = rptr_reg +1;
          full_next = 1'b0;
        end
        if(wptr_reg == rptr_next) begin
          empty_next = 1'b1;
        end
      end
      2'b10 : begin
        //push only
        if(!full_reg) begin
          wptr_next = wptr_reg +1;
          empty_next = 1'b0;
        end
        if(rptr_reg == wptr_next) begin
          full_next = 1'b1;
        end
      end
      2'b11 : begin
        //push&pop
        if(full_reg) begin
          rptr_next = rptr_reg +1;
          full_next = 1'b0;
        end else if(empty_reg) begin
          wptr_next = wptr_reg +1;
          empty_next = 1'b0;
        end else begin
          wptr_next = wptr_reg +1;
          rptr_next = rptr_reg +1;
        end
      end
    endcase
  end

  assign wptr = wptr_reg;
  assign rptr = rptr_reg;
  assign full = full_reg;
  assign empty = empty_reg;

endmodule
