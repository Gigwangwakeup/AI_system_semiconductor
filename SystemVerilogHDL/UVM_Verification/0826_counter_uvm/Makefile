#vcs Make file
RTL_DIR	=	./rtl
TB_DIR	=	./testbench
BUILD_DIR	=	./build
INC_DIR	=	+incdir+$(RTL_DIR)
SIMV_DIR	=	./build/simv
#SIMV_OPT	=	-cm line+cond+fsm+tgl+branch+assert -cm_dir	coverage.vdb




run:
	mkdir -p $(BUILD_DIR)
	vcs -full64 -sverilog -debug_access+all -kdb -lca \
		-timescale=1ns/1ps \
		-ntb_opts uvm-1.2 \
		-o $(SIMV_DIR) ./rtl/counter.sv ./testbench/tb_counter_uvm.sv

simv:
	$(SIMV_DIR)

verdi:
	verdi -dbdir $(BUILD_DIR)/simv.daidir -ssf wave.fsdb &


clean:
	rm -rf $(BUILD_DIR) csrc novas* ucli.key verdilog files.f inter.fsdb .inter.fsdb.tbsim sys*

.PHONY : all vcs simv verdi clean
