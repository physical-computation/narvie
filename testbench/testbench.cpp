#include "testbench.h"
#include "../verilator_sim/Vtop_sim.h"
#include "Vtop_sim.h"
#include "verilated.h"
#include <cstdlib>
#include <memory>

TESTBENCH::TESTBENCH()
	: m_uart(8000), m_core(), m_tickcount(0)
{
	// attempts baud rate of 115200
	// guessed from source code of uartsim.cpp
	m_uart.setup(104);
}

void TESTBENCH::tick(void)
{
	m_core.rx = m_uart(m_core.tx);

	// Increment our own internal time reference
	m_tickcount++;

	// Make sure any combinatorial logic depending upon
	// inputs that may have changed before we called tick()
	// has settled before the rising edge of the clock.
	m_core.CLOCK = 0;
	m_core.eval();

	// Toggle the clock

	// Rising edge
	m_core.CLOCK = 1;
	m_core.eval();

	// Falling edge
	m_core.CLOCK = 0;
	m_core.eval();
}

bool TESTBENCH::done(void) { return (Verilated::gotFinish()); }
