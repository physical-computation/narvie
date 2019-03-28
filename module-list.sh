#!/bin/bash

set -e

export SAIL=$NARVIE_ROOT/sail
export UART_RX=$NARVIE_ROOT/peripherals/uart-rx
export UART_TX=$NARVIE_ROOT/peripherals/uart-tx
export NARVIE_VERILOG=$NARVIE_ROOT/narvie-verilog

export UART_MODULES="$UART_TX/baudgen_tx.v $UART_TX/uart_tx.v \
    $UART_RX/baudgen_rx.v $UART_RX/uart_rx.v"

export COMMON_MODULES="$SAIL/verilog/mux2to1.v $SAIL/verilog/alu_control.v $SAIL/verilog/pipeline_registers.v \
    $SAIL/verilog/alu.v $SAIL/verilog/program_counter.v $SAIL/verilog/branch_decide.v \
    $SAIL/verilog/forwarding_unit.v $SAIL/verilog/branch_predictor.v $SAIL/verilog/imm_gen.v $SAIL/verilog/control_unit.v \
    $SAIL/verilog/adder.v $SAIL/verilog/CSR_iCE40UP5K.v $SAIL/verilog/dataMem_mask_gen.v"

export NARVIE_MODULES="$NARVIE_VERILOG/cpu.v $NARVIE_VERILOG/rx_instruction.v \
    $NARVIE_VERILOG/main.v $NARVIE_VERILOG/uart_regfile.v \
    $NARVIE_VERILOG/data_memory_iCE40UP5K.v"

export MODULES="$COMMON_MODULES $UART_MODULES $NARVIE_MODULES"
