#include "testbench.h"
#include "verilated.h"

int main(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);
	TESTBENCH *tb = new TESTBENCH();

	while (!tb->done())
	{
		tb->tick();
	}
	exit(EXIT_SUCCESS);
}
