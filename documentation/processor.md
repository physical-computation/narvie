# Processor

The processor originally support the [RV32I instruction set](https://riscv.org/specifications) and has a five-stage pipeline, forwarding unit and branch predictor.
It was modified to be used as the backend of the riscv-repl.

## Processor Modifications

The `cpu` module has an output `inst_in` which is set to the address of the next instruction to be evaluated (the program counter) and an input `inst_out` from which the instruction is read.
The modified processor entirely ignores the value of `inst_in`.
The input to `cpu`, `inst_in` is normally set to `0x13000000` (riscv `nop` instruction) except for the first processor clock cycle after an instruction is read from UART when is it set to that instruction.

Additionally, the processor clock input is normally held high.
Once an instruction is read from UART, the processor clock oscillates for six cycles (there are six rising edges) and then is held high again.
During these cycles, the instruction moves down the stages of the processor and the registers are updated.

The final modification is to add a 2024 bit output from the `register_file` module which allows the register file to be read and sent over UART.

## UART Interface

As RISC-V is a little-endian all UART transmissions will also be little-endian.

### Input

The processor waits until it has read four bytes our UART.
These bytes should contain the instruction in little endian form.
For example the instruction `add t0, a0, a1` is `00B502B3` in binary and should be transmitted over UART as `0xB3`, `0x02`, `0xB5`, `0x00`.

| Index | Byte expected        |
|-------|----------------------|
| 0     | `inst & 0x000000FF`  |
| 1     | `inst & 0x0000FF00`  |
| 2     | `inst & 0x00FF0000`  |
| 3     | `inst & 0xFF000000`  |

## Output

After the instruction is evaluated the register file is transmitted over UART.
 and as such the the least significant byte of `x0` is transmitted first and the most significant byte of `x31` is transmitted last.
In all 128 bytes are transmitted.

| Index | Register name | Transmitted byte   |
|-------|---------------|--------------------|
| 0     | `x0`          | `x0 & 0x000000FF`  |
| 1     | `x0`          | `x0 & 0x0000FF00`  |
| 2     | `x0`          | `x0 & 0x00FF0000`  |
| 3     | `x0`          | `x0 & 0xFF000000`  |
| 4     | `x1`          | `x1 & 0x000000FF`  |
| 5     | `x1`          | `x1 & 0x0000FF00`  |
| 6     | `x1`          | `x1 & 0x00FF0000`  |
| 7     | `x1`          | `x1 & 0xFF000000`  |
| ...   | ...           | ...                |
| 124   | `x31`         | `x31 & 0x000000FF` |
| 125   | `x31`         | `x31 & 0x0000FF00` |
| 126   | `x31`         | `x31 & 0x00FF0000` |
| 127   | `x31`         | `x31 & 0xFF000000` |
