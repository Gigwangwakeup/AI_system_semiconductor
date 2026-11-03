module tb_rv32i();

logic clk = 0, rst = 1;
logic [15:0] sw;
logic [15:0] led;

always #5 clk = ~clk;

rv32i_top dut (
  .*
);

//initial begin
//  $fsdbDumpfile("wave.fsdb");
//  $fsdbDumpvars(0, tb_rv32i);
//end

initial begin
  #10;
  rst = 0;
  #10;
  sw = 16'h5A00;

  #25000;
  $finish;
end

endmodule
