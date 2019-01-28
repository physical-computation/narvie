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
	  m_tx_byte_count(0),
	  m_rxStart(0),
	  m_evalStart(0),
	  m_txStart(0)
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
		if (m_core.v__DOT__m__DOT__register_files__DOT__instruction_rcv)
		{
			m_evalStart = m_tickcount;
		}

		if (m_core.v__DOT__m__DOT__register_files__DOT__send_regfile)
		{
			m_txStart = m_tickcount;
			m_is_tx = true;
		}

		if (m_is_tx && m_uart.m_rx_state == RXIDLE)
		{
			m_tx_byte_count += 1;
		}

		if (m_tx_byte_count == 128)
		{
			printf("RX from %9lu, for %4lu cycles. ", m_rxStart, m_evalStart - m_rxStart);
			printf("EX from %9lu, for %2lu cycles. ", m_evalStart, m_txStart - m_evalStart);
			printf("TX from %9lu, for %6lu cycles. ", m_txStart, m_tickcount - m_txStart);
			printf(" In total this is %6lu cycles.\n", m_tickcount - m_rxStart);

			m_is_evaluating = false;
			m_tx_byte_count = 0;
			m_is_tx = false;
		}
	}
	else
	{
		if (m_uart.m_tx_state == TXDATA)
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
