`include "uvm_macros.svh"
import uvm_pkg::*;

interface counter_if(input clk);
  
  logic       rstn;
  logic       enable;
  logic [2:0] counter;
  logic       o_tick;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output  rstn;
    output  enable;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input counter;
    input o_tick;
    input rstn;
    input enable;
  endclocking

  modport drv_mb (clocking drv_cb, input clk);
  modport mon_mb (clocking mon_cb, input clk);

  // 1. property: To be counter value 0 occuruted after reset when posedge clk
  // |=> : 앞 조건이 참이면 "다음클럭"뒤 조건을 확인해라.
  property p_reset_clear_counter;
    @(posedge clk)(!rstn) |=>(counter == 3'b000);
  endproperty

  //assertion
  A_RESET_CLEAR:assert property (p_reset_clear_counter)
    else `uvm_error("[ASSERT]","RESET_ASSERT property p_reset_clear_counter!!")

endinterface

class counter_seq_item extends uvm_sequence_item;
  rand  bit         enable;
        bit         rstn;
        logic [2:0] counter;
        logic       o_tick;

  constraint c_en {enable dist{0 := 1, 1:= 9};}

  function new(string name = "counter_seq_item");
    super.new(name);
  endfunction

  // register item
  `uvm_object_utils_begin(counter_seq_item)
    `uvm_field_int(enable   , UVM_DEFAULT)
    `uvm_field_int(rstn     , UVM_DEFAULT)
    `uvm_field_int(counter  , UVM_DEFAULT)
    `uvm_field_int(o_tick   , UVM_DEFAULT)
  `uvm_object_utils_end

  virtual function string conver2string();
    return $sformatf("rstn = %d, enable - %d, counter = %d, o_tick = %d", rstn,enable,counter,o_tick);
  endfunction
endclass

// sequence
class counter_sequence extends uvm_sequence;
  `uvm_object_utils(counter_sequence)

  function new(string name = "counter_seq");
    super.new(name);
  endfunction

  virtual task body();
    counter_seq_item c_item;
   repeat(100) begin
    //new_counter_seq_item
    c_item = counter_seq_item::type_id::create("c_item");
    //reandomized()
    start_item(c_item);
    if(!c_item.randomize()) begin
      `uvm_fatal(get_type_name(),"c_item randomized fail")
    end
    c_item.rstn = 1;
    finish_item(c_item);
  end
endtask
endclass

//reset sequence
class reset_counter_sequence extends uvm_sequence;
  `uvm_object_utils(reset_counter_sequence)

  function new (string name = "reset_seq");
    super.new(name);
  endfunction

  virtual task body();
    counter_seq_item c_item;
  repeat(3) begin
    c_item = counter_seq_item::type_id::create("c_item");
    start_item(c_item);
    c_item.rstn = 0;
    c_item.enable = 0;
    finish_item(c_item);
  end
endtask
endclass

// driver
class counter_driver extends uvm_driver #(counter_seq_item);
  //static
  `uvm_component_utils(counter_driver)
  virtual counter_if c_if;
  counter_seq_item c_item;

  function new (string name = "counter_drv", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // interface
    if(!uvm_config_db#(virtual counter_if)::get(this,"*","c_if",c_if)) begin
      `uvm_fatal(get_name()," unable to access counter interface");
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    c_if.drv_cb.rstn   <= 0;
    c_if.drv_cb.enable <= 0;
    
          @(c_if.drv_cb);
    forever begin
        //drive
        //get_seq_item
        seq_item_port.get_next_item(c_item);
  
          @(c_if.drv_cb);
          c_if.drv_cb.rstn   <= c_item.rstn;
          c_if.drv_cb.enable  <= c_item.enable;
  
        seq_item_port.item_done();
    end
  endtask
endclass


// monitor
class counter_monitor extends uvm_monitor;
  `uvm_component_utils(counter_monitor)

  virtual counter_if c_if;
  uvm_analysis_port #(counter_seq_item) send;
  counter_seq_item c_item;

  function new (string name = "counter_mon", uvm_component c = null);
    super.new(name,c);
    send = new("write", this);
  endfunction

  // build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual counter_if)::get(this,"*","c_if",c_if)) begin
      `uvm_fatal(get_name()," unable to access counter interface");
    end
  endfunction

  // run phase
  virtual task run_phase(uvm_phase phase);
    forever begin
      c_item = counter_seq_item::type_id::create("c_item");
      @(c_if.mon_cb);
      c_item.rstn     = c_if.mon_cb.rstn;
      c_item.enable   = c_if.mon_cb.enable;
      c_item.counter  = c_if.mon_cb.counter;
      c_item.o_tick   = c_if.mon_cb.o_tick;

      send.write(c_item);
      `uvm_info("MON",$sformatf("enable = %d, counter = %d, o_tick = %d",c_item.enable,c_item.counter,c_item.o_tick),UVM_HIGH)
    end
  endtask
endclass

//agent
class counter_agent extends uvm_agent;
  `uvm_component_utils(counter_agent)

  counter_driver drv;
  counter_monitor mon;
  uvm_sequencer #(counter_seq_item) sqr;
  
  function new (string name = "counter_agt", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = counter_driver::type_id::create("drv",this);
    mon = counter_monitor::type_id::create("mon",this);
    sqr = uvm_sequencer #(counter_seq_item)::type_id::create("sqr",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass

// scoreboard
class counter_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(counter_scoreboard)

    uvm_analysis_imp#(counter_seq_item,counter_scoreboard) recv;

    bit [2:0] expected_count = 0;
    int pass_cnt = 0, fail_cnt = 0;
    int skip_cnt = 0;
    bit exp_o_tick = 0;


    function new (string name = "counter_scb", uvm_component c = null);
      super.new(name,c);
      recv = new("read", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
    endfunction

    virtual function void write(counter_seq_item c_item);
     `uvm_info(get_type_name(),c_item.conver2string(),UVM_HIGH)

    if(!c_item.rstn)begin
      expected_count = 0;
      exp_o_tick =0;
    end


     if(c_item.counter == 3'bxxx) begin
       `uvm_info(get_type_name(),$sformatf("Skip !! counter is x"),UVM_NONE)
       skip_cnt ++;
     end else begin
       if(c_item.enable) begin 
         if(expected_count == 7)
           exp_o_tick = 1'b1;
         else 
           exp_o_tick = 1'b0;
       end else begin
          expected_count = expected_count;
          exp_o_tick = 1'b0;
        end
       if(exp_o_tick == c_item.o_tick)
           `uvm_info(get_type_name(),$sformatf("tick Pass !! exp_tick = %d, tick = %d",exp_o_tick,c_item.o_tick),UVM_HIGH)
       else
           `uvm_info(get_type_name(),$sformatf("tick Fail !! exp_tick = %d, tick = %d",exp_o_tick,c_item.o_tick),UVM_NONE)
       //pass, fail
        if(expected_count == c_item.counter) begin
           `uvm_info(get_type_name(),$sformatf("count Pass !! expected = %d, counter = %d",expected_count,c_item.counter),UVM_HIGH)
         pass_cnt ++;
       end else begin

           `uvm_info(get_type_name(),$sformatf("Fail !! expected = %d, counter = %d",expected_count,c_item.counter),UVM_NONE)
         fail_cnt ++;
       end
      if(c_item.enable && c_item.rstn)
        expected_count ++;
    end
   endfunction

   virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),$sformatf("\n________________"),UVM_NONE)
    `uvm_info(get_type_name(),$sformatf("Result Pass : %d",pass_cnt),UVM_NONE)
    `uvm_info(get_type_name(),$sformatf("Result Fail : %d",fail_cnt),UVM_NONE)
    `uvm_info(get_type_name(),$sformatf("Result Skip : %d",skip_cnt),UVM_NONE)
  endfunction
endclass

// environment
class counter_environment extends uvm_env;
  `uvm_component_utils(counter_environment)
  // instance object
  counter_agent       agt;
  counter_scoreboard  scb;
  
  function new(string name = "counter_env", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agt = counter_agent::type_id::create("agt",this);
    scb = counter_scoreboard::type_id::create("scb",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    agt.mon.send.connect(scb.recv);
  endfunction
endclass

//test
class counter_test extends uvm_test;
  `uvm_component_utils(counter_test)

  counter_environment env;
  counter_sequence    seq;
  reset_counter_sequence rseq;

  function new(string name = "counter_test", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = counter_environment::type_id::create("env",this);
    seq = counter_sequence::type_id::create("seq",this);
    rseq = reset_counter_sequence::type_id::create("rseq",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // start run phase
    phase.raise_objection(this);
    rseq.start(env.agt.sqr);
    seq.start(env.agt.sqr);
//    @(posedge env.agt.drv.c_if.clk);
    // stop run phase
    phase.drop_objection(this);
  endtask
endclass

module tb_counter();

  logic clk = 0;
  always #5 clk = ~clk;

  counter_if c_if(clk);

  counter dut (
    .clk    (clk          ),
    .rstn   (c_if.rstn    ),
    .enable (c_if.enable  ),
    .counter(c_if.counter ),
    .o_tick (c_if.o_tick  )
  );

  // for make vcs waveform
  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0,tb_counter);
  end

  initial begin
    //interface set
    uvm_config_db#(virtual counter_if)::set(null,"*","c_if",c_if);
    // run test
    run_test("counter_test");
  end

endmodule
