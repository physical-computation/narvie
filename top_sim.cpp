#include "Vtop_sim.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <string>
#include <cstdlib>
#include <cstdio>

vluint64_t main_time = 0;

double sc_time_stamp () {
	return main_time;
}

int main(int argc, char** argv) {
	bool vcdTrace = true;
	VerilatedVcdC* tfp = NULL;
	
	Verilated::commandArgs(argc, argv);
	Vtop_sim* top = new Vtop_sim;

	top->eval();
	top->eval();
	
	if(vcdTrace) {
		Verilated::traceEverOn(true);
		
		tfp = new VerilatedVcdC;
		top->trace(tfp, 99);
		
		std::string vcdName = argv[0];
		vcdName += ".vcd";
		std::cout << vcdName << std::endl;
		tfp->open(vcdName.c_str());
	}
	
	top->CLOCK = 0;
	top->eval();
	
	while (!Verilated::gotFinish()) {
		top->CLOCK = top->CLOCK ? 0 : 1;
		top->eval();
		
		if (tfp != NULL) {
			tfp->dump (main_time);
		}
		
		main_time++;
		if(main_time == 1000000) {
			break;
		}
	}
	
	top->final();
	
	if (tfp != NULL) {
		tfp->close();
		delete tfp;
	}
	
	delete top;
	exit(0);
}
