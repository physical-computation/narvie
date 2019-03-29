# `> narvie`

A Read Eval Print Loop (REPL) for RISC-V instructions.
Only UNIX systems have been tested.
`narvie` stands for native RISC-V instruction evaluator.

## Installation

* Download Rustup and install Rust. (<https://www.rust-lang.org/tools/install>)
* `cd` into the `repl` subdirectory and run `cargo build`.

To run the RISC-V REPL in simulation, `verilator` is needed.
To synthesise the verilog and flash to an FPGA `./progMDP` uses `yosys`, `arachne-pnr` and `icestorm`.
However, other tools can also be used for sythensis.
`nc` is needed to forward the serial port to a `TCP` port.

## Running

You will need two terminals to run the RISC-V REPL.

### First Terminal

#### Simulation

* `$ ./sim` to start the simulation.

#### Running on an FPGA

* `$ ./progMDP` to synthesise the verilog and to flash the `narvie` processsor to a connected FPGA.

### Second Terminal

* Run `$ ./repl/target/debug/narvie --help`, `narvie` should display helpful output to the terminal.
* To connect the `narvie` cli to a simulation run `$ ./repl/target/debug/narvie --tcp 8001`.
* To connect the `narvie` cli to an FGPA run `$ ./repl/target/debug/narvie --baud 115200 ADDRESS` where `ADDRESS` is the serial port that the `narvie` processor is connected to. To list avialible serial ports, run `$ ./repl/target/debug/narvie` with no arguments.
* Type instructions into the prompt. Examples are `nop`, `li t0, 1678`, or `addi t0, t0, 1`.
* When done, use `ctrl-c` to quit the repl.

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

---

### If you use `narvie` in your research, please cite it as:
Harry Sarson, Ryan Voo, and Phillip Stanley-Marbell. "Evaluating RISC-V Instructions Natively with Narvie". Poster, *Proceedings of the  European Conference on Systems (EuroSys'19)*. Dresden, Germany, March 2019.

**BibTeX:**
````
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
````
