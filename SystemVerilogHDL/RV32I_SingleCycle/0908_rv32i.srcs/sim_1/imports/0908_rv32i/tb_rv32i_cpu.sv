module tb_rv32i_cpu();

  logic clk = 0,rstn = 0;

  always #5 clk = ~clk;

  rv32i_top dut(
    .clk(clk),
    .rstn(rstn)
  );

  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0,tb_rv32i_cpu);
  end

  initial begin
    #10;
    rstn = 1;
    #200;
    $finish;
  end

endmodule
