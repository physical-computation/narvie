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

  public:
	TESTBENCH();

	virtual ~TESTBENCH() = default;

	virtual void tick();
	virtual bool done();
};
