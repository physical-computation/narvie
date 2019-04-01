#ifndef TESTBENCH_H
#define TESTBENCH_H

#include "Vnarvie.h"
#include "uartsim.h"
#include "verilated.h"
#include <cstdlib>

#ifdef __cplusplus
extern "C"
{
#endif

	typedef struct
	{
		unsigned long tickcount;
		Vnarvie *core;
		UartSimulator *uart;

		bool is_evaluating;
		unsigned long tx_byte_count;
		bool is_tx;
		unsigned long rxStart;
		unsigned long evalStart;
		unsigned long txStart;

	} NarvieSimulator;

	void NarvieSimulator_init(NarvieSimulator *simulator, Vnarvie *core, UartSimulator *uart);
	void NarvieSimulator_tick(NarvieSimulator *simulator);
	void main_loop(int (*write)(uint8_t, void *), int (*try_read)(uint8_t *, void *), void *read_write_state);

#ifdef __cplusplus
}
#endif

#endif
