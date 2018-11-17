ENTRY(_start)
SEARCH_DIR(../Sunflower-toolchain/tools/riscv/riscv32-elf/lib)

SECTIONS
{
  . = 0x00;
  .text . : 
  { 
  	_text = . ;
  	*(.text) 
  	. = 0x400;
  	*(.strings)
  	_etext = . ;
  }
  
  .data . : 
  { 
  	*(.data) 
  }
  
  .bss . : 
  { 
  	*(.bss) 
  }
}
