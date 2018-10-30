.globl _start
.align	2

_start:

init:
	li		sp,8192
	addi  sp,sp,-1
	j			main


