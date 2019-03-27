#!/bin/bash

set -e

cd ../sail
source ../module-list.sh

TESTBENCH_DIR=../testbench
VERILATOR_SRC=$TESTBENCH_DIR/verilator_src
BUILD_DIR=$TESTBENCH_DIR/verilator_built

verilator \
-Wall \
--cc $VERILATOR_SRC/top_sim.v $MODULES config.vlt \
-I$UART_RX \
--exe $VERILATOR_SRC/main.cpp $VERILATOR_SRC/testbench.cpp $VERILATOR_SRC/uartsim.cpp \
-o narvie \
-Mdir $BUILD_DIR \
-CFLAGS "-std=c++14 -g -O3"


