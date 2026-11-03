`include "uvm_macros.svh"
import uvm_pkg::*;

//interface
interface fifo_if(input clk);

  logic rstn;
  logic push;
  logic pop;
  logic [7:0] wdata;
  logic [7:0] rdata;
  logic full;
  logic empty;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output rstn;
    output push;
    output pop;
    output wdata;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rstn;
    input push;
    input pop;
    input wdata;
    input rdata;
    input full;
    input empty;
  endclocking

endinterface

//regist item
class fifo_seq_item extends uvm_sequence_item;
  bit            rstn;
  rand bit       push;
  rand bit       pop;
  rand bit [7:0] wdata;
  logic    [7:0] rdata;
  logic          full;
  logic          empty;

  function new (string name = "fifo_seq_item");
    super.new(name);
  endfunction

  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_int(rstn, UVM_DEFAULT)
    `uvm_field_int(push, UVM_DEFAULT)
    `uvm_field_int(pop, UVM_DEFAULT)
    `uvm_field_int(wdata, UVM_DEFAULT)
    `uvm_field_int(rdata, UVM_DEFAULT)
    `uvm_field_int(full, UVM_DEFAULT)
    `uvm_field_int(empty, UVM_DEFAULT)
  `uvm_object_utils_end

  virtual function string convert2string();
    return $sformatf("rstn = %d, push = %d, pop = %d, wdata = %d, rdata = %d, full = %d, empty = %d",rstn,push,pop,wdata,rdata,full,empty);
  endfunction
endclass

//sequence(transaction)
class fifo_sequence extends uvm_sequence;
  `uvm_object_utils(fifo_sequence)

  function new (string name = "fifo_seq");
    super.new(name);
  endfunction 

  virtual task body();
    fifo_seq_item f_item; // handler
    repeat(100) begin
    f_item = fifo_seq_item::type_id::create("f_item");
    start_item(f_item);
    if(!f_item.randomize()) begin
      `uvm_fatal(get_type_name()," f_item randomize fail")
    end
    f_item.rstn = 1;
    finish_item(f_item);
  end
  endtask

endclass

//reset seq
class fifo_rstn_sequence extends uvm_sequence;
  `uvm_object_utils(fifo_rstn_sequence)

  function new(string name = "fifo_rstn_seq");
    super.new(name);
  endfunction

  virtual task body();
    fifo_seq_item f_item;
    repeat(5) begin
      f_item = fifo_seq_item::type_id::create("f_item");
      start_item(f_item);
      f_item.rstn = 0;
      f_item.push = 0;
      f_item.pop = 0;
      f_item.wdata = 0;
      finish_item(f_item);
    end
  endtask
endclass

//driver(build+run)
class fifo_driver extends uvm_driver #(fifo_seq_item);
  `uvm_component_utils(fifo_driver)
  virtual fifo_if f_if;
  fifo_seq_item f_item;

  function new (string name = "fifo_drv", uvm_component c = null);
    super.new(name,c);
  endfunction 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual fifo_if)::get(this,"*","f_if",f_if)) begin
      `uvm_fatal(get_name(),"unable to access fifo interface")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(f_item);
      @(f_if.drv_cb);
      f_if.drv_cb.rstn <= f_item.rstn;
      f_if.drv_cb.push <= f_item.push;
      f_if.drv_cb.pop <= f_item.pop;
      f_if.drv_cb.wdata <= f_item.wdata;
      seq_item_port.item_done;
    end
  endtask
endclass

//monitor
class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)
  virtual fifo_if f_if;
  fifo_seq_item f_item;
  uvm_analysis_port #(fifo_seq_item) send;

  function new (string name = "fifo_mon", uvm_component c = null);
    super.new(name,c);
    send = new("write",this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual fifo_if)::get(this,"*","f_if",f_if))
      `uvm_fatal(get_name(),"unable to access fifo interface")
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      f_item = fifo_seq_item::type_id::create("f_item");
      @(f_if.mon_cb);
      f_item.rstn = f_if.mon_cb.rstn;
      f_item.push = f_if.mon_cb.push;
      f_item.pop = f_if.mon_cb.pop;
      f_item.wdata = f_if.mon_cb.wdata;
      f_item.rdata = f_if.mon_cb.rdata;
      f_item.full = f_if.mon_cb.full;
      f_item.empty = f_if.mon_cb.empty;

      send.write(f_item);
      `uvm_info("MON",$sformatf("push = %d, pop = %d, wdata = %d, rdata = %d, full = %d, empty = %d",f_item.push,f_item.pop,f_item.wdata,f_item.rdata,f_item.full,f_item.empty),UVM_HIGH)      
    end
  endtask
endclass

//agent
class fifo_agent extends uvm_agent;
  `uvm_component_utils(fifo_agent)
  fifo_driver drv;
  fifo_monitor mon;
  uvm_sequencer #(fifo_seq_item) sqr;

  function new(string name = "fifo_agt", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = fifo_driver::type_id::create("drv",this);
    mon = fifo_monitor::type_id::create("mon",this);
    sqr = uvm_sequencer #(fifo_seq_item)::type_id::create("sqr",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)
  uvm_analysis_imp #(fifo_seq_item,fifo_scoreboard) recv;

  bit [7:0] model_mem [0:7]; // momory
  bit [7:0] expected_rdata;
  bit       expected_full,expected_empty;
  int       wptr;           // write pointer
  int       rptr;           // read pointer
  int       count;          // 

  int full_pass = 0, full_fail = 0;
  int empty_pass = 0, empty_fail = 0;
  int data_pass = 0, data_fail = 0;

  function new(string name = "fifo_scb", uvm_component c = null);
    super.new(name,c);
    recv = new("recv",this);
  endfunction

  virtual function void write(fifo_seq_item item);
    
  //model reset  
  if(!item.rstn) begin
      wptr = 0;
      rptr = 0;
      count = 0;
    end

    // check before accepting push,pop
    expected_full = (count == 8);
    expected_empty = (count == 0);

    // full check
    if(expected_full != item.full) begin
      `uvm_error("SCB", $sformatf(" Full mismatch : expected = %d, dut = %d ",expected_full,item.full))
      full_fail ++;
    end else begin
      full_pass ++;
    end

    // empty check
    if(expected_empty != item.empty) begin
      `uvm_error("SCB", $sformatf(" empty mismatch : expected = %d, dut = %d ",expected_empty,item.empty))
      empty_fail ++;
    end else begin
      empty_pass ++;
    end
    //pop
    if(item.pop && !item.empty) begin
      expected_rdata = model_mem[rptr]; // rptr current location
      if (expected_rdata != item.rdata) begin
        `uvm_error("SCB", $sformatf(" data fail : expected = %d, dut = %d ",expected_rdata,item.rdata))
        data_fail ++;
      end else begin
        data_pass ++;
      end
      rptr = (rptr +1) % 8;
      count --;
    end
    //push
    if(item.push && !item.full) begin
      model_mem[wptr] = item.wdata;
      wptr = (wptr + 1) % 8;
      count++;
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),$sformatf("\nFULL  : pass=%d fail=%d\nEMPTY : pass=%d fail=%d\nDATA  : pass=%d fail=%d", full_pass,full_fail,empty_pass,empty_fail,data_pass,data_fail), UVM_NONE)
  endfunction
endclass

class fifo_environment extends uvm_env;
  `uvm_component_utils(fifo_environment)

  fifo_agent      agt;
  fifo_scoreboard scb;

  function new (string name = "fifo_env", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = fifo_agent::type_id::create("agt",this);
    scb = fifo_scoreboard::type_id::create("scb",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.send.connect(scb.recv);
  endfunction
endclass

class fifo_test extends uvm_test;
  `uvm_component_utils(fifo_test)

  fifo_environment    env;
  fifo_rstn_sequence  rstn_seq;
  fifo_sequence       seq;

  function new (string name = "fifo_test", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_environment::type_id::create("env",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    rstn_seq  = fifo_rstn_sequence::type_id::create("rstn_seq");
    seq       = fifo_sequence::type_id::create("seq");

    rstn_seq.start(env.agt.sqr);
    seq.start(env.agt.sqr);

    phase.drop_objection(this);
  endtask
endclass

module tb_fifo_uvm ();
  
  logic clk = 0;
  always #5 clk = ~clk;

  fifo_if f_if(clk);

fifo #(
  .ADDR_WIDTH(3)
) dut (
    .clk(clk),
    .rstn(f_if.rstn),
    .push(f_if.push),
    .pop(f_if.pop),
    .wdata(f_if.wdata),  // push data
    .rdata(f_if.rdata),  // pop data
    .full(f_if.full),
    .empty(f_if.empty)
);

  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0,tb_fifo_uvm);
  end

  initial begin
    uvm_config_db#(virtual fifo_if)::set(null,"*","f_if",f_if);
    run_test("fifo_test");
  end

endmodule
