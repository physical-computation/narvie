#include "../verilator_sim/Vtop_sim.h"
#include "uartsim.h"
#include "verilated.h"
#include <cstdlib>
#include <memory>

class TESTBENCH
{
	unsigned long m_tickcount;
	Vtop_sim m_core;
	UARTSIM m_uart;

	bool m_is_evaluating;
	unsigned long m_tx_byte_count;
	bool m_is_tx;
	unsigned long m_rxStart;
	unsigned long m_evalStart;
	unsigned long m_txStart;

  public:
	TESTBENCH();

	virtual ~TESTBENCH() = default;

	virtual void tick();
	virtual bool done();
};
