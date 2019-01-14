TREEROOT	= ../Sunflower-toolchain
include $(TREEROOT)/conf/setup.conf

# The following must agree with ./config.js

# This file should exist and contain the assembly when `make` is run.
AS_PATH = ./compiler-files/a.S
# The compiled riscv elf is written to this file.
ELF_PATH = ./compiler-files/a.elf
# The binary instruction (4 bytes) is written to this file.
MACH_PATH = ./compiler-files/machine-code
# The dissambly is written to this file, one instruction per line.
D_PATH = ./compiler-files/d.S

all:	assemble extract disassemble

assemble:
	$(AS) -o $(ELF_PATH) $(AS_PATH)

extract:
	$(OBJCOPY) -O binary --only-section=.text $(ELF_PATH) $(MACH_PATH)

disassemble:
	$(OBJDUMP) -d -M no-aliases --no-show-raw-insn $(ELF_PATH) \
	| grep "^ " \
	| cut -f2,3 \
	| cut -f1 --delimiter "#" \
	> $(D_PATH)

