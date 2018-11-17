#include <stdio.h>
#include <string.h>
#include "uart_print.h"

void uart_print(char* str) {
	int i;
	volatile unsigned int *tx_byte = (unsigned int *)0x2001;
	for(i=0; str[i]!='\0'; i++) {
		*tx_byte = (char)(str[i]);
	}
}
