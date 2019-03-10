#!/bin/bash

set -e

export UART_RX=../peripherals/uart-rx
export UART_TX=../peripherals/uart-tx

export UART_MODULES="$UART_TX/baudgen_tx.v $UART_TX/uart_tx.v \
    $UART_RX/baudgen_rx.v $UART_RX/uart_rx.v"

export COMMON_MODULES="verilog/mux2to1.v verilog/alu_control.v verilog/pipeline_registers.v \
    verilog/alu.v ../data_memory_iCE40UP5K.v verilog/program_counter.v verilog/branch_decide.v \
    verilog/forwarding_unit.v verilog/branch_predictor.v verilog/imm_gen.v verilog/control_unit.v \
    verilog/adder.v verilog/CSR_iCE40UP5K.v verilog/dataMem_mask_gen.v"

export NARVIE_MODULES="../cpu.v ../rx_instruction.v ../main.v ../uart_regfile.v"

export MODULES="$COMMON_MODULES $UART_MODULES $NARVIE_MODULES"
