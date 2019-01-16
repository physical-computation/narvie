# REPL

The REPL is written in nodejs and the source files are contained within [`repl`](../repl/).

## Usage

When the REPL is started it will attempt to connect to the serial port.
Once it is connected it provides a prompt to the user.
Any RISC-V instruction can be typed into this prompt.

Examples of instructions include `nop`, `add rd, rs1, rs2`, `li rd, immediate`.

Entering a branch or jump instructions (e.g. `jal x0 8`) will have not effect the next instruction executed as the program counter is ignored.

To see example risk-v instructions generated by a compiler try using [compiler explorer](https://godbolt.org/z/7GSkZk).

## Configuration

The REPL is configured by editing `./repl/config.js` which contains comments documenting the purpose of each configuration option.

## Mocking

The serial port can be mocked to use a TCP stream instead.
This is useful if you are running the processor as a verilator simulation rather than on an FPGA.

Additionally, the writing and reading from the serial port can be mocked.
This is useful for testing of the node script if there is not a simulation running or FPGA connected.