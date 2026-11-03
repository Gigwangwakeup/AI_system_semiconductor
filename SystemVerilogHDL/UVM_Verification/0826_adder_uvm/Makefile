# ====UVM Testbench Makefile====

VCS					= vcs
TOP 				= tb_adder_test
TEST 				= adder_test
VERBOSITY		 	= UVM_MEDIUM

COMP_OPTS		= -full64 -sverilog -debug_access+all -kdb -lca -ntb_opts uvm-1.2 \
							-timescale=1ns/1ps \ 
RUN_OPTS		=	+UVM_VERBOSITY=$(VERBOSITY)

comp:
	$(VCS) $(COMP_OPTS) ./rtl/adder.sv ./testbench/tb_adder_uvm.sv -o simv

run:	comp
	./simv $(RUN_OPTS)

clean:
	rm -rf simv* csrc* *.log *.vpd *.fsdb *.key *.h DVE*

.PHONY: comp run clean
