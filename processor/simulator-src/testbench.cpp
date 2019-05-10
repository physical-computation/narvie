#include "testbench.h"
#include "uartsim.h"
#include "Vnarvie.h"
#include "verilated.h"


void NarvieSimulator_init(NarvieSimulator *simulator, Vnarvie *core, UartSimulator *uart)
{
	simulator->tickcount = 0;
	simulator->core = core;
	simulator->uart = uart;

#if DO_TIMING
	simulator->is_evaluating = 0;
	simulator->tx_byte_count = 0;
	simulator->is_tx = 0;
	simulator->rxStart = 0;
	simulator->evalStart = 0;
	simulator->txStart = 0;
#endif
}

void NarvieSimulator_tick(NarvieSimulator *simulator)
{
	simulator->core->rx = UartSimulator_tick(simulator->uart, simulator->core->tx);

	// Increment our own internal time reference
	simulator->tickcount++;

#if DO_TIMING
	if (simulator->is_evaluating)
	{
		if (simulator->core->top_sim__DOT__m__DOT__register_files__DOT__instruction_rcv)
		{
			simulator->evalStart = simulator->tickcount;
		}

		if (simulator->core->top_sim__DOT__m__DOT__register_files__DOT__send_regfile)
		{
			simulator->txStart = simulator->tickcount;
			simulator->is_tx = true;
		}

		if (simulator->is_tx && simulator->uart->rx_state == RXIDLE)
		{
			simulator->tx_byte_count += 1;
		}

		if (simulator->tx_byte_count == 128)
		{
			fprintf(stderr, "RX from %9lu, for %4lu cycles. ", simulator->rxStart, simulator->evalStart - simulator->rxStart);
			fprintf(stderr, "EX from %9lu, for %2lu cycles. ", simulator->evalStart, simulator->txStart - simulator->evalStart);
			fprintf(stderr, "TX from %9lu, for %6lu cycles. ", simulator->txStart, simulator->tickcount - simulator->txStart);
			fprintf(stderr, " In total this is %6lu cycles.\n", simulator->tickcount - simulator->rxStart);

			simulator->is_evaluating = false;
			simulator->tx_byte_count = 0;
			simulator->is_tx = false;
		}
	}
	else
	{
		if (simulator->uart->tx_state == TXDATA)
		{
			simulator->is_evaluating = true;
			simulator->rxStart = simulator->tickcount;
		}
	}
#endif

	// Make sure any combinatorial logic depending upon
	// inputs that may have changed before we called tick()
	// has settled before the rising edge of the clock.
	simulator->core->CLOCK = 0;
	simulator->core->eval();

	// Toggle the clock

	// Rising edge
	simulator->core->CLOCK = 1;
	simulator->core->eval();

	// Falling edge
	simulator->core->CLOCK = 0;
	simulator->core->eval();
}

void main_loop(int (*write)(uint8_t, void *), int (*try_read)(uint8_t *, void *), void *read_write_state)
{
	UartSimulator uart;
	Vnarvie core;
	NarvieSimulator simulator;

	UartSimulator_init(&uart, write, try_read, read_write_state);
	NarvieSimulator_init(&simulator, &core, &uart);

	while (1)
	{
		NarvieSimulator_tick(&simulator);
	}

	exit(EXIT_SUCCESS);
}
