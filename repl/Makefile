TREEROOT	= ../Sunflower-toolchain
include $(TREEROOT)/conf/setup.conf

# must agree with index.js
AS_PATH = ./compiler-files/a.S
ELF_PATH = ./compiler-files/a.elf
MACH_PATH = ./compiler-files/machine-code
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

