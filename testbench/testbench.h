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
	bool m_is_tx;
	unsigned long m_rxStart;
	unsigned long m_rxEnd;
	unsigned long m_txStart;
	unsigned long m_txEnd;

  public:
	TESTBENCH();

	virtual ~TESTBENCH() = default;

	virtual void tick();
	virtual bool done();
};
