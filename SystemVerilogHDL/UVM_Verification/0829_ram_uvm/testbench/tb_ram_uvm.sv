`include "uvm_macros.svh"
import uvm_pkg::*;

interface ram_if(input clk);

  logic we;
  logic [$clog2(256)-1:0] addr;
  logic [7:0] wdata;
  logic [7:0] rdata;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output we;
    output addr;
    output wdata;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input we;
    input addr;
    input wdata;
    input rdata;
  endclocking
endinterface

class ram_seq_item extends uvm_sequence_item;
  rand bit we;
  rand bit [$clog2(256)-1:0] addr;
  rand bit [7:0] wdata;
  logic [7:0] rdata;

  //init parents
  function new (string name = "ram_seq_item");
    super.new(name);
  endfunction 

  //register item
  `uvm_object_utils_begin(ram_seq_item)
    `uvm_field_int(we, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_DEFAULT)
    `uvm_field_int(wdata, UVM_DEFAULT)
    `uvm_field_int(rdata, UVM_DEFAULT)
  `uvm_object_utils_end

  virtual function string convert2string();
    return $sformatf(" we = %d, addr = %d, wdata = %d, rdata = %d",we,addr,wdata,rdata);
  endfunction
endclass

//sequence(transaction)
class ram_sequence extends uvm_sequence;
  `uvm_object_utils(ram_sequence)


  function new (string name = "ram_seq");
    super.new(name);
  endfunction

  virtual task body();
    ram_seq_item r_item; // handler
    repeat(3000000) begin
      r_item = ram_seq_item::type_id::create("r_item"); // = new
      start_item(r_item); //handshake with uvm
        if(!r_item.randomize()) begin
          `uvm_fatal(get_type_name(),"r_item randomize fail")
        end
      finish_item(r_item);
    end
  endtask

endclass

//driver(build, run)
class ram_driver extends uvm_driver #(ram_seq_item);
  `uvm_component_utils(ram_driver)
  virtual ram_if r_if; 
  ram_seq_item r_item;

  function new (string name = "ram_drv", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void  build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual ram_if)::get(this,"*","r_if",r_if)) begin
      `uvm_fatal(get_name()," unable to access ram interface ")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

      r_if.drv_cb.we    <= 0;
      r_if.drv_cb.addr  <= 0;
      r_if.drv_cb.wdata <= 0;
      @(r_if.drv_cb);
      forever begin
        seq_item_port.get_next_item(r_item);
          @(r_if.drv_cb);
          r_if.drv_cb.we    <= r_item.we;
          r_if.drv_cb.addr  <= r_item.addr;
          r_if.drv_cb.wdata <= r_item.wdata;
        seq_item_port.item_done();
      end
  endtask
endclass

//monitor(build, run)
class ram_monitor extends uvm_monitor();
  `uvm_component_utils(ram_monitor) // regist into the factory
  virtual ram_if r_if; // handler only read
  uvm_analysis_port #(ram_seq_item) send; // for broadcast
  ram_seq_item r_item; // basket

  function new (string name = "ram_mon", uvm_component c = null); 
    super.new(name,c);
    send = new("write",this);
  endfunction

  //build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual ram_if)::get(this,"*","r_if",r_if))begin
      `uvm_fatal(get_name()," unable to access ram interface ")
    end
  endfunction

  //run phase
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      r_item = ram_seq_item::type_id::create("r_item");
      @(r_if.mon_cb);
      r_item.we     = r_if.mon_cb.we;
      r_item.addr   = r_if.mon_cb.addr;
      r_item.wdata  = r_if.mon_cb.wdata;
      r_item.rdata  = r_if.mon_cb.rdata;

      send.write(r_item);
      `uvm_info("MON",$sformatf("we = %d, addr = %d, wdata = %d, rdata = %d",r_item.we,r_item.addr,r_item.wdata,r_item.rdata),UVM_HIGH)
    end
  endtask

endclass

//agent(drv,mon,sqr / build, connect)
class ram_agent extends uvm_agent();
  `uvm_component_utils(ram_agent)
  ram_driver  drv;
  ram_monitor mon;
  uvm_sequencer #(ram_seq_item) sqr;

  function new (string name = "ram_agt", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv = ram_driver::type_id::create("drv",this);
    mon = ram_monitor::type_id::create("mon",this);
    sqr = uvm_sequencer #(ram_seq_item)::type_id::create("sqr",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass

//scoreboard(build,write,report)
class ram_scoreboard extends uvm_scoreboard();
  `uvm_component_utils(ram_scoreboard)
 uvm_analysis_imp #(ram_seq_item,ram_scoreboard) recv;

  logic [7:0] mem_model [0:255]; // sw mem
  int pass_cnt = 0, fail_cnt = 0;

 function new (string name = "ram_scb", uvm_component c = null);
  super.new(name,c);
  recv = new("read",this);
 endfunction

 virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
 endfunction

 virtual function void write(ram_seq_item r_item);
  `uvm_info(get_type_name(), r_item.convert2string(),UVM_HIGH)

  if(r_item.we) begin
    //write the mem
    mem_model[r_item.addr] = r_item.wdata;
    `uvm_info(get_type_name(),$sformatf("WRITE addr = %d, wdata = %d model",r_item.addr,r_item.wdata),UVM_MEDIUM)
  end else begin
    //read the mem
    if(mem_model[r_item.addr] === r_item.rdata) begin
      `uvm_info(get_type_name(),$sformatf("READ PASS !! addr = %d, expected = %d, actual = %d",r_item.addr,mem_model[r_item.addr],r_item.rdata),UVM_MEDIUM)
      pass_cnt ++;
    end else begin
      `uvm_info(get_type_name(),$sformatf("READ FAIL !! addr = %d, expected = %d, actual = %d",r_item.addr,mem_model[r_item.addr],r_item.rdata),UVM_NONE)
      fail_cnt ++;
    end
  end
 endfunction

 virtual function void report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info(get_type_name(),$sformatf("Result pass : %d", pass_cnt), UVM_NONE)
  `uvm_info(get_type_name(),$sformatf("Result fail : %d", fail_cnt), UVM_NONE)
 endfunction
endclass

//coverage
class ram_coverage extends uvm_subscriber#(ram_seq_item);
  `uvm_component_utils(ram_coverage)

  ram_seq_item r_item;
  covergroup ram_cg;
    option.per_instance =1;
    cp_we:coverpoint r_item.we{
      bins write[]  = {1};
      bins read[]   = {[0:1]};
    }
    cp_addr:coverpoint r_item.addr{
      bins range0_to255[] = {[0:255]};
    }
    cp_wdata:coverpoint r_item.wdata iff(r_item.we==1) {
      bins range0_to255[] = {[0:255]};
    }
    cp_rdata:coverpoint r_item.rdata{
      bins range0_to255[] = {[0:255]};
    }
    cx_en_addr : cross cp_we, cp_addr;
    cx_addr_wdata: cross cp_addr,cp_wdata;
  endgroup
    function new (string name = "ram_cov", uvm_component c = null);
      super.new(name,c);
      ram_cg = new();
    endfunction

    virtual function void write(ram_seq_item t_item);
      r_item = t_item;
      ram_cg.sample(); // sample, bins one time hit
    endfunction

    virtual function void report_phase(uvm_phase phase);
      `uvm_info("COV",$sformatf("\n*** Coverage Report ***"),UVM_NONE);
      `uvm_info("COV",$sformatf("** Overall = %2d **",ram_cg.get_inst_coverage()),UVM_NONE);
      `uvm_info("COV",$sformatf("** we      = %2d **",ram_cg.cp_we.get_inst_coverage()),UVM_NONE);
      `uvm_info("COV",$sformatf("** addr    = %2d **",ram_cg.cp_addr.get_inst_coverage()),UVM_NONE);
      `uvm_info("COV",$sformatf("** wdata   = %2d **",ram_cg.cp_wdata.get_inst_coverage()),UVM_NONE);
      `uvm_info("COV",$sformatf("** rdata   = %2d **",ram_cg.cp_rdata.get_inst_coverage()),UVM_NONE);
      `uvm_info("COV",$sformatf("** en_addr   = %2d **",ram_cg.cx_en_addr.get_inst_coverage()),UVM_NONE);
      `uvm_info("COV",$sformatf("** addr_wdata   = %2d **",ram_cg.cx_addr_wdata.get_inst_coverage()),UVM_NONE);
      `uvm_info("COV",$sformatf("\n***********************"),UVM_NONE);
    endfunction
endclass

// environment(agt,scb + build,connect)
class ram_environment extends uvm_env();
  `uvm_component_utils(ram_environment)

  ram_agent agt;
  ram_scoreboard scb;
  ram_coverage cov;

  function new (string name = "ram_env", uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = ram_agent::type_id::create("agt",this);
    scb = ram_scoreboard::type_id::create("scb",this);
    cov = ram_coverage::type_id::create("cov",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.send.connect(scb.recv);
    agt.mon.send.connect(cov.analysis_export); //monitor : caller, scoreboard,coverage : call
  endfunction
endclass

// test(env,seq + build,run)
class ram_test extends uvm_test();
  `uvm_component_utils(ram_test)
  ram_environment env;
  ram_sequence seq;

  function new(string name = "ram_test",uvm_component c = null);
    super.new(name,c);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ram_environment::type_id::create("env",this);
    seq = ram_sequence::type_id::create("seq",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
      seq.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass
  
module tb_ram_uvm();

  logic  clk = 0;
  always #5 clk = ~clk;

  ram_if r_if(clk);

  ram dut (
    .clk(clk),
    .we(r_if.we),
    .addr(r_if.addr),
    .wdata(r_if.wdata),
    .rdata(r_if.rdata)
  );


  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0,tb_ram_uvm);
  end

  initial begin
    uvm_config_db#(virtual ram_if)::set(null,"*","r_if",r_if);
    run_test("ram_test");
  end

endmodule
