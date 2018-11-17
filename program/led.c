#include<stdio.h>
#include <stdlib.h>
#include "uart_print.h"

void infinite_loop(int i, int delay, int shift_right, int decrease_delay, const int delay_step_change){
	int j=0;
	volatile unsigned int *led = (unsigned int *)0x2000;
	//char hello[9] = {};
	char* hello = "Hello!\r\n\0";
	while(1){
  	//delay
  	//for (j=0; j<625000; j++){}; //625000
  	
  	for (j=0; j<delay; j++);
  	
  	if(shift_right == 1) i = i >> 1;
  	else i = i << 1;
  	
  	*led = i;
  	/*hello[0] = 'H';
  	hello[1] = 'e';
  	hello[2] = 'l';
  	hello[3] = 'l';
  	hello[4] = 'o';
  	hello[5] = '!';
  	hello[6] = '\n';
  	hello[7] = '\r';
  	hello[8] = '\0';*/
  	uart_print(hello);
  	
  	if(i == 128) {
  		shift_right = 1;
  		if(decrease_delay == 1) delay -= delay_step_change;
  		else delay += delay_step_change;
  	}
  	else if(i == 1) {
  		shift_right = 0;
  		if(decrease_delay == 1) delay -= delay_step_change;
  		else delay += delay_step_change;
  	}
  	
  	if(delay == 10000) decrease_delay = 0;
  	else if (delay == 400000) decrease_delay = 1;
  	
  	
  	
  	//test 3
  	//if(shift_dir == 0) i = i << shift_amt;
  	//else i = i >> shift_amt;
  	//shift_amt = shift_amt + shift_amt_increment;
  	//shift_dir = shift_dir ^ 1;
  	//if(shift_amt == 7) shift_amt_increment = -1;
  	//else if(shift_amt == 1) shift_amt_increment = 1;
  	
  	//test 2
  	//i = i ^ mask;
  	
  	//test 1
  	//if(shift_right == 1) i = i >> 1;
  	//else i = i << 1;
  	//if(i == 128) shift_right = 1;
  	//else if(i == 1) shift_right = 0;
  }
}

int main()
{
	//int j=0;
	
	//test 4
	int i = 1;
	int delay = 400000;
	int shift_right = 0;
	int decrease_delay = 1;
	const int delay_step_change = 39000;
	
	//test 3
	//uint16_t i = 1;
	//int shift_amt = 7;
	//int shift_dir = 0; //left
	//int shift_amt_increment = -1;
	
	//test 2
	//uint32_t i = 170;
	//uint32_t mask = 255;
	
	//test 1
  //uint16_t i = 1;
  //uint8_t shift_right = 0;
  
  //volatile unsigned int *led = (unsigned int *)0x2000;
  
  //int j=0;
	/*while(1){
  	//delay
  	//for (j=0; j<625000; j++){}; //625000
  	
  	//test 4
  	//for (j=0; j<delay; j++);
  	
  	//if(shift_right == 1) i = i >> 1;
  	//else i = i << 1;
  	
  	//if(i == 128) {
  	//	shift_right = 1;
  	//	if(decrease_delay == 1) delay -= delay_step_change;
  	//	else delay += delay_step_change;
  	//}
  	//else if(i == 1) {
  	//	shift_right = 0;
  	//	if(decrease_delay == 1) delay -= delay_step_change;
  	//	else delay += delay_step_change;
  	//}
  	
  	//if(delay == 10000) decrease_delay = 0;
  	//else if (delay == 400000) decrease_delay = 1;
  	
  	
  	
  	//test 3
  	//if(shift_dir == 0) i = i << shift_amt;
  	//else i = i >> shift_amt;
  	//shift_amt = shift_amt + shift_amt_increment;
  	//shift_dir = shift_dir ^ 1;
  	//if(shift_amt == 7) shift_amt_increment = -1;
  	//else if(shift_amt == 1) shift_amt_increment = 1;
  	
  	//test 2
  	//i = i ^ mask;
  	
  	//test 1
  	//if(shift_right == 1) i = i >> 1;
  	//else i = i << 1;
  	//if(i == 128) shift_right = 1;
  	//else if(i == 1) shift_right = 0;
  	
  	*led = i;
  }*/
  
  
  infinite_loop(i, delay, shift_right, decrease_delay, delay_step_change);
}



