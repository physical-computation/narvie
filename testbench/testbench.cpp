#include "testbench.h"
#include "../verilator_sim/Vtop_sim.h"
#include "Vtop_sim.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>
#include <memory>

TESTBENCH::TESTBENCH()
	: m_uart(8001), m_core(), m_tickcount(0),
	  m_is_evaluating(false), m_is_tx(false),
	  m_rxStart(0), m_rxEnd(0),
	  m_txStart(0), m_txEnd(0)
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

	if (m_is_evaluating)
	{
		if (!m_core.rx)
		{
			m_rxEnd = m_tickcount + 1;
		}

		if (!m_core.tx)
		{
			if (!m_is_tx)
			{
				m_is_tx = true;
				m_txStart = m_tickcount;
			}
			m_txEnd = m_tickcount + 1;
		}

		if (m_is_tx && m_tickcount > m_txEnd && m_tickcount - m_txEnd > 100000)
		{
			m_is_evaluating = false;
			m_is_tx = false;
			printf("RX started at %9lu, for %4lu cycles. \
TX started at %9lu, for %6lu cycles. \
This suggests execution took %2lu cycles. \
In total this is %6lu cycles.\n",
				   m_rxStart, m_rxEnd - m_rxStart,
				   m_txStart, m_txEnd - m_txStart,
				   m_txStart - m_rxEnd,
				   m_txEnd - m_rxStart);
		}
	}
	else
	{
		if (!m_core.rx)
		{
			m_is_evaluating = true;
			m_rxStart = m_tickcount;
		}
	}

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
