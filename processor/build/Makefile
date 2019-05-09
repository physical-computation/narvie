#!/bin/bash

ROOT_DIR	= 	$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
NARVIE_ROOT	= 	$(abspath $(ROOT_DIR)/..)
VERILATOR_OUT	?= 	$(NARVIE_ROOT)/build/verilator

SAIL		= 	$(NARVIE_ROOT)/sail
UART_RX		= 	$(NARVIE_ROOT)/peripherals/uart-rx
UART_TX		= 	$(NARVIE_ROOT)/peripherals/uart-tx
NARVIE_VERILOG	= 	$(NARVIE_ROOT)/narvie-verilog
VERILATOR_SRC	= 	$(NARVIE_ROOT)/simulator-src

UART_MODULES	= 	$(UART_TX)/baudgen_tx.v			$(UART_TX)/uart_tx.v			\
			$(UART_RX)/baudgen_rx.v			$(UART_RX)/uart_rx.v

COMMON_MODULES	= 	$(SAIL)/verilog/mux2to1.v		$(SAIL)/verilog/alu_control.v		\
			$(SAIL)/verilog/pipeline_registers.v	$(SAIL)/verilog/alu.v			\
			$(SAIL)/verilog/program_counter.v	$(SAIL)/verilog/branch_decide.v		\
			$(SAIL)/verilog/forwarding_unit.v	$(SAIL)/verilog/branch_predictor.v	\
			$(SAIL)/verilog/imm_gen.v		$(SAIL)/verilog/control_unit.v		\
			$(SAIL)/verilog/adder.v			$(SAIL)/verilog/CSR_iCE40UP5K.v		\
			$(SAIL)/verilog/dataMem_mask_gen.v

NARVIE_MODULES	= 	$(NARVIE_VERILOG)/cpu.v			$(NARVIE_VERILOG)/rx_instruction.v	\
    			$(NARVIE_VERILOG)/main.v		$(NARVIE_VERILOG)/uart_regfile.v	\
    			$(NARVIE_VERILOG)/data_memory_iCE40UP5K.v

MODULES		=	$(COMMON_MODULES)			$(UART_MODULES)				\
			$(NARVIE_MODULES)


PROJECT		=	rv32i_ice40MDP

.PHONY: clean burn all bitstream verilator

all: bitstream

fpga:
	mkdir fpga

$(VERILATOR_OUT):
	mkdir $(VERILATOR_OUT)

$(VERILATOR_OUT)/Vnarvie.mk:	$(VERILATOR_SRC)/top_sim.v		$(MODULES)				\
				$(SAIL)/config.vlt $(UART_MODULES)	$(VERILATOR_SRC)/main.cpp		\
				$(VERILATOR_SRC)/testbench.cpp		$(VERILATOR_SRC)/uartsim.cpp		\
				$(VERILATOR_OUT)			Makefile
	verilator \
		-Wall \
		--cc $(VERILATOR_SRC)/top_sim.v $(MODULES) $(SAIL)/config.vlt \
		-I$(UART_RX) \
		--prefix Vnarvie \
		--cc $(VERILATOR_SRC)/main.cpp $(VERILATOR_SRC)/testbench.cpp $(VERILATOR_SRC)/uartsim.cpp \
		--exe \
		-Mdir $(VERILATOR_OUT) \
		-CFLAGS "-std=c++11 -g -O3 -fPIC -Wall -Werror"



$(VERILATOR_OUT)/libvnarvie.a: $(VERILATOR_OUT)/Vnarvie.mk Makefile
	cd $(VERILATOR_OUT) && \
	make -j -f Vnarvie.mk && \
	cp Vnarvie__ALL.a libvnarvie.a && \
	ar -q libvnarvie.a testbench.o uartsim.o verilated.o

fpga/$(PROJECT).blif: fpga $(MODULES) $(NARVIE_VERILOG)/top.v Makefile
	cd $(SAIL) && \
	yosys -p "synth_ice40 -blif $(ROOT_DIR)/fpga/$(PROJECT).blif;" $(MODULES) $(NARVIE_VERILOG)/top.v Makefile

fpga/$(PROJECT).asc: ../$(PROJECT).pcf fpga/$(PROJECT).blif
	arachne-pnr -d 5k -P uwg30 -p ../$(PROJECT).pcf ./fpga/$(PROJECT).blif -o fpga/$(PROJECT).asc Makefile

fpga/$(PROJECT).bin: fpga/$(PROJECT).asc Makefile
	icepack fpga/$(PROJECT).asc fpga/$(PROJECT).bin

verilator: $(VERILATOR_OUT)/libvnarvie.a

bitstream: fpga/$(PROJECT).bin

burn: fpga/$(PROJECT).bin
	iceprog -S fpga/$(PROJECT).bin

clean:
	rm -rf fpga $(VERILATOR_OUT)

