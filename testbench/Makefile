#!/bin/bash

.PHONY: all, run, clean

all: verilator_built/narvie

verilator_built/narvie: verilator_src build.sh ../narvie-verilog/ ../sail
	./build.sh
	cd verilator_built && $(MAKE) -j -f Vtop_sim.mk narvie

run:
	./verilator_built/narvie

clean:
	$(RM) -rf verilator_built
