TREEROOT	= ../Sunflower-toolchain
include $(TREEROOT)/conf/setup.conf

# must agree with index.js
AS_PATH = ./compiler-files/a.S
ELF_PATH = ./compiler-files/a.elf
MACH_PATH = ./compiler-files/machine-code

all:	assemble extract clean

assemble:
	$(AS) -o $(ELF_PATH) $(AS_PATH)

extract:
	$(OBJCOPY) -O binary --only-section=.text $(ELF_PATH) $(MACH_PATH)

clean:
	rm -f AS_PATH
	rm -f ELF_PATH
	rm -f MACH_PATH

