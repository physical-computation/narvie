# RISCV REPL

A Read Eval Print Loop (REPL) for RISC-V instructions.
Only UNIX systems are supported.

## Author

Harry Sarson (hds28), Pembroke College.

## Installation

* Install `verilator` version 3.874 or greater (https://www.veripool.org/wiki/verilator)
* Install `wget`, `gcc`, `libmpc`, `mpfr`, and `gmp`.
* Install `Sunflower-toolchain`:
  * Run `$ git submodule init && git submodule update && cd Sunflower-toolcahin`.
  * Edit `Sunflower-toolchain/conf/setup.conf` and set `SUNFLOWERROOT` the the absolute path of the `Sunflower-toolchain` directory; `TARGET` to `riscv`; and `TARGET-ARCH` to `riscv32-elf`.
  * In `Sunflower-toolchain/tools/source`, run `./downloads.sh`.
  * In `Sunflower-toolchain/tools` run `make`.
* Install node version 10 or greater (https://nodejs.org/en/)
* `cd` into the `repl` subdirectory and run `npm install`.

## Running

* `$ ./sim &` to start the simulation and move it to the background.
* `node repl` starts the interactive repl.
* Type instructions into the prompt. Examples are `nop`, `li t0, 1678`, or `addi t0, t0, 1`.
* When done, use `ctrl-c` to quit the repl, `fg` to bring the simulation to the forground and `ctrl-c` to quit the simulation.

## Documentation

* [REPL documentation](documentation/repl.md)
* [Processor documentation](documentation/processor.md)

## Demo

![RISCV REPL demo](/images/demo.gif?raw=true)

## License

As this project borrows GPL licensed code from other sources it too is licensed under the GPL.

## Acknowledgements

The risc-v processor was implemented by Ryan Voo @rjlv2.
The only modifications made to the processor were related to breaking the pipeline and instruction fetch mechinisms to allow instructions to be executed individually.

The verilog UART modules (`uart/baudgen_rx.v`, `uart/baudgen_tx.v`, `uart/baudgen.vh`, `uart/uart_rx.v` and `uart/uart_tx.v`) are copied unmodified from https://github.com/FPGAwars/FPGA-peripherals.

The verilator uart simulator code (`testbench/uartsim.h` and `testbench/uartsim.h`) are copied unmodified from https://github.com/ZipCPU/wbuart32.
