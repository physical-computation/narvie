# RISCV REPL

A Read Eval Print Loop (REPL) for RISC-V instructions.
Only UNIX systems are supported.

## Installation

* Install verilator version 3.874 or greater (https://www.veripool.org/wiki/verilator)
* Install node version 10 or greater (https://nodejs.org/en/)
* `cd` into the `repl` subdirectory and run `npm install`.

## Running

* `$ ./sim &` to start the simulation and move it to the background.
* `node repl` starts the interactive repl.
* Type instructions into the prompt. Examples are `nop`, `li t0, 1678`, or `addi t0, t0, 1`.
* When done, use `ctrl-c` to quit the repl, `fg` to bring the simulation to the forground and `ctrl-c` to quit the simulation.

## Demo

![RISCV REPL demo](/images/demo.gif?raw=true)
