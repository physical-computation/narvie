# `> narvie`

[![Build Status](https://travis-ci.com/physical-computation/narvie.svg?branch=master)](https://travis-ci.com/physical-computation/narvie)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=physical-computation/narvie)](https://dependabot.com)

A Read Eval Print Loop (REPL) for RISC-V instructions.
Only UNIX systems have been tested.
`narvie` stands for native RISC-V instruction evaluator.

## Installation

Either download a pre-built narvie binary ([ubuntu linux](https://github.com/physical-computation/narvie/releases/latest/download/narvie-cli-linux), [mac OS](https://github.com/physical-computation/narvie/releases/latest/download/narvie-cli-osx)) or build using cargo:

1. [Download Rustup and install Rust](https://www.rust-lang.org/tools/install).
2. [Install verilator](https://www.veripool.org/projects/verilator/wiki/Installing). Version 3.916 is recommended.
3. Run `$ cargo install narvie-cli`.

## Running

`narvie` can be run either as a simulation or by connecting a `narvie` processor (running on an FPGA) to your computer.

Once the cli is running type RISC-V instructions into the prompt. Examples are `nop`, `li t0, 1678`, or `addi t0, t0, 1`. `narvie` will compile the instructions into binary, run them and display the new micro-architectural state (currently only the values of the registers are displayed). When done, use `ctrl-c` to quit `narvie`.

### Simulation

* To start a simulation try `$ narvie-cli --simulate`.

#### Running on an FPGA

* After connecting a `narvie` processor to your computer via usb run `$ narvie-cli ADDRESS --baud 115200` where `ADDRESS` is the serial port to which the processor is connected to. Replace `115200` with the baud rate that the processor is configured to use.

## Building `narvie`

To build `narvie-cli`, [`verilator` is needed](https://www.veripool.org/projects/verilator/wiki/Installing).
To synthesise the verilog and flash to an FPGA `./progMDP` uses `yosys`, `arachne-pnr` and `icestorm`.
However, other tools can also be used for sythensis.

* Download Rustup and install Rust. (<https://www.rust-lang.org/tools/install>)
* Clone this repository.
* Run `cargo build` to build `narvie-cli`.
* From the `processor` directory, run `./progMDP` to generate `narvie-processor`'s byte stream and to flash a lattice Mobile Development Board.

## Documentation

* [REPL documentation](documentation/repl.md)
* [Processor documentation](documentation/processor.md)

## Demo

This demo shows the RISC-V REPL running in a simulation.

![RISCV REPL demo](/images/demo.gif?raw=true)

## License

As this project borrows GPL licensed code from other sources it too is licensed under the GPL.

## Acknowledgements

The risc-v processor was implemented based on verilog modules developed by Ryan Voo @rjlv2.
The only modifications made to the processor were related to breaking the pipeline and instruction fetch mechinisms to allow instructions to be executed individually.

The verilog UART modules can be found at <https://github.com/FPGAwars/FPGA-peripherals>.

The verilator UART simulator testbench code (`testbench/uartsim.h` and `testbench/uartsim.c`) are implemented based on <http://zipcpu.com/blog/2017/06/21/looking-at-verilator.html>.

## Minimum Version of Rust

`narvie` will officially support current stable Rust only.

---

### Citing `narvie` in research

Harry Sarson, Ryan Voo, and Phillip Stanley-Marbell. "Evaluating RISC-V Instructions Natively with Narvie". Poster, *Proceedings of the  European Conference on Systems (EuroSys'19)*. Dresden, Germany, March 2019.

**BibTeX:**

        @inproceedings{Sarson:2019,
        author = {Harry Sarson and Ryan Voo and Phillip Stanley-Marbell},
        title = {Evaluating RISC-V Instructions Natively with Narvie},
        booktitle = {Proceedings of the  European Conference on Systems},
        series = {EuroSys'19},
        year = {2019},
        location = {Dresden, Germany},
        numpages = {2},
        publisher = {ACM},
        address = {New York, NY, USA},
        }
