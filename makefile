
SIM_DIR = ./sim

TB_NAME = tb_fpga

# Top Level simulation file, contains all testcases and controls to the rtl in tb_fpga.sv
CPP_FILE = ../tb/sim_top.cpp
CPP_FILE += ../tb/FpgaSim.cpp
CPP_FILE += ../tb/testcases/TestPrbsCipher.cpp

# Top Level FPGA testbench, contains all the RTL routing
TB_TOP = ../tb/tb_fpga.sv

INC_DIR = -I../tb
INC_DIR += -I../tb/axi_interconnect


INC_DIR += -I../rtl/common
INC_DIR += -I../rtl/tx
INC_DIR += -I../rtl/rx
INC_DIR += -I../rtl/fifo
INC_DIR += -I../rtl/axis_broadcaster

.DEFAULT_GOAL := help
.PHONY: help build



## sim: Runs the simulation and generates the output files in ./sim
sim: clean create_sim_dir
	@cd $(SIM_DIR);\
	verilator -Wall -cc -CFLAGS "-g" --trace $(TB_TOP) $(INC_DIR) --exe $(CPP_FILE); \
	make -j -C obj_dir -f V$(TB_NAME).mk V$(TB_NAME); \
	./obj_dir/V$(TB_NAME) -t

## waves: Displays the waves generated by Verilator
waves:
	cd $(SIM_DIR); \
	gtkwave wave.vcd --rcvar 'fontname_signals Monospace 12' --rcvar 'fontname_waves Monospace 12'
	#gtkwave wave.vcd

## create_sim_dir: Creates sim directory if it doesn't exist
create_sim_dir:
	@mkdir -p $(SIM_DIR)

## --------------------------------
## clean: delete simulation output files
clean:
	rm -rf $(SIM_DIR)/obj_dir;


## help: Generate help message
help: makefile
	@echo "------------------------------------------------------------\n"
	@echo "*Make Options:"
	@echo ""
	@sed -n 's/^##/ -/p' $<
	@echo ""
	@echo "*Requried Tools:"
	@echo ""
	@echo " - Verialtor     : Simulation"
	@echo " - Gtkwave       : Used for viewing waveforms"
	@echo ""
	@echo "------------------------------------------------------------\n"
