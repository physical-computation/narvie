# RV32I_iCE40

## Step 1 - Cloning the repository
To clone the respository, use: <br >
 `$ git clone --recursive git@github.com:physical-computation/RV32I_iCE40.git`<br >

## Step 2 - Building the toolchain
`cd` into the directory and then into `cross-compiler-build`, edit `conf/setup.conf` and set appropriately for risc-v. Afterwards, `cd` into `source` and run `./downloads.sh`, which will populate the folder with distributions of GCC, Newlib and Binutils.<br><br>
After downloading, `cd` back to `cross-compiler-build` and run `make`, this should automatically build the toolchains and place the executable binaries in `cross-compiler-build/bin`.

## Step 3 - Compiling the program
 `cd` into `program` and run `make`, this should generate an executable binary from `init.s` and `led.c`. Run `./getprog` to get the machine instructions into a file called `program.hex` as well as to automatically copy the file to `RV32I_iCE40/verilog`.<br><br>
 The processor contains a memory mapped register at location *0x2000*, and the program writes a value to that register which the lower 8 bits is then shown by the pin outputs (you can connect them to leds to see them blink).
 
## Step 4 - Programming the FPGA
1. If you're using the iCE40 MDP, then in the root of the repository run:<br>
`./progMDP`<br>
In this example device U3 is used.<br><br>

2. If you're using the iCE40 breakout board, run:<br>
`./prog`<br><br>

Note that the pins used will be dependent on the respective `pcf` files.
