# Makefile for iceup5k FPGA
# Outputs the build files to seperate build directory.
# TOP name is required for the build option to work
# SIM name is required for the sim option to work

# Project setup
PROJ      = top
TOP       = top
BUILD     = ./build
DEVICE    = up5k
FOOTPRINT = sg48
PCF       = pins
FREQ 	  = 12

# Source directories
SRC_DIR   = src
TB_DIR    = testbench



#$(TB_DIR)/filter_input_tb.v \
#			$(SRC_DIR)/fir/filter_input.v \
#			$(SRC_DIR)/bram/bram.v

# Simulation files list
SIM_FILES = $(TB_DIR)/top_tb.v \
			$(SRC_DIR)/top.v \
			$(SRC_DIR)/uart/uart_tx.v \
			$(SRC_DIR)/uart/uart_rx.v \
			$(SRC_DIR)/bram/bram.v \
			$(SRC_DIR)/bram/dual_port_bram.v \
			$(SRC_DIR)/fir/filter_input_bram.v \
			$(SRC_DIR)/fir/SB_MAC16.v \
			$(SRC_DIR)/fir/fir_multiplex.v \
			$(SRC_DIR)/async_fifo/fifo_mem.v \
			$(SRC_DIR)/async_fifo/synchronizer.v \
			$(SRC_DIR)/async_fifo/read_ptr.v \
			$(SRC_DIR)/async_fifo/write_ptr.v \
			$(SRC_DIR)/async_fifo/async_fifo.v \
			$(SRC_DIR)/clock/clock.v \
			$(SRC_DIR)/clock/rst_synchronizer.v 


# Simulation file name
SIM       = top
# Source files list
FILES = $(SRC_DIR)/top.v \
			$(SRC_DIR)/uart/uart_tx.v \
			$(SRC_DIR)/uart/uart_rx.v \
			$(SRC_DIR)/bram/bram.v \
			$(SRC_DIR)/bram/dual_port_bram.v \
			$(SRC_DIR)/fir/filter_input_bram.v \
			$(SRC_DIR)/fir/fir_multiplex.v \
			$(SRC_DIR)/async_fifo/fifo_mem.v \
			$(SRC_DIR)/async_fifo/synchronizer.v \
			$(SRC_DIR)/async_fifo/read_ptr.v \
			$(SRC_DIR)/async_fifo/write_ptr.v \
			$(SRC_DIR)/async_fifo/async_fifo.v \
			$(SRC_DIR)/clock/clock.v \
			$(SRC_DIR)/clock/rst_synchronizer.v 

# Simulation files list
#SIM_FILES = top_tb.v top.v clock.v clock_divider.v fifo.v uart_tx.v bram.v uart_rx.v
# Simulation file name
#SIM       = top
# Files
#FILES = top.v
#FILES += bram.v clock.v clock_divider.v fifo.v uart_tx.v

.PHONY: all clean prog timing verify sim


all: build prog
	

$(BUILD)/$(PROJ).json: $(FILES) | folder
	yosys -p  'synth_ice40 -dsp -top $(TOP) -blif $(BUILD)/$(PROJ).blif -json $@' -ql $(BUILD)/$(PROJ).yslog $^

$(BUILD)/$(PROJ).asc: $(BUILD)/$(PROJ).json | folder
	nextpnr-ice40 --$(DEVICE) --package $(FOOTPRINT) --json $< --pcf $(PCF).pcf --asc $@ -ql $(BUILD)/$(PROJ).nplog

$(BUILD)/$(PROJ).bin: $(BUILD)/$(PROJ).asc | folder
	icepack $< $@

$(BUILD)/$(PROJ).out: $(FILES) | folder
	@echo 'are the used verilog files for compilation'	
	$(info $(FILES))
	iverilog -o $@ -D VCD_OUTPUT=dummy_vcd_output -D NO_ICE40_DEFAULT_ASSIGNMENTS $^ 

$(BUILD)/$(SIM)_tb: $(SIM_FILES)| folder
	iverilog -o $@ -D VCD_OUTPUT=$(SIM)_tb -D INTERACTIVE_SIM -D NO_ICE40_DEFAULT_ASSIGNMENTS $^

# vvp creates file in the main directory, couldn't make it to create file in sub directory.
$(SIM)_tb.vcd: $(BUILD)/$(SIM)_tb
	vvp $<

folder:
	mkdir -p $(BUILD)

build: $(BUILD)/$(PROJ).bin 
	./resrc_util.sh

prog: $(BUILD)/$(PROJ).bin
	@echo 'Programming in RAM Mode'
	iceprog -S $(BUILD)/$(PROJ).bin

timing: $(BUILD)/$(PROJ).asc
	icetime -tmd hx$(DEVICE) $(BUILD)/$(PROJ).asc

clean:
	rm build/*
	rm $(SIM)_tb.vcd 

verify: $(BUILD)/$(PROJ).out

sim: $(SIM)_tb.vcd
	#gtkwave --rcvar "splash_disable on" --rcvar "do_initial_zoom_fit 1" $< $(BUILD)/$(PROJ).gtkw
	surfer $<
