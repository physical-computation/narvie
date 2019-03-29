
#ifndef UARTSIM_H
#define UARTSIM_H

#include <stdint.h>

// Setup
#define UART_BAUD_RATE 115200
#define UART_CLOCK_RATE 12000000

#define TXIDLE 0
#define TXDATA 1
#define RXIDLE 0
#define RXDATA 1
#define RXINIT 2

#ifdef __cplusplus
extern "C"
{
#endif

	typedef struct
	{
		/* must return 0 on success, negative number on error. 	*/
		int (*write)(uint8_t, void *);
		/* must return 0 on read, 1 if there is no data and a 	*/
		/* negative number on error. */
		int (*try_read)(uint8_t *, void *);
		void *read_write_state;

		// UART state
		int rx_baudcounter;
		int rx_state;
		int rx_busy;
		int rx_changectr;
		int last_tx;
		int tx_baudcounter;
		int tx_state;
		int tx_busy;
		unsigned rx_data;
		unsigned tx_data;

	} UartSimulator;

	void UartSimulator_init(UartSimulator *simulator, int (*write)(uint8_t, void *), int (*try_read)(uint8_t *, void *), void *read_write_state);

	// This function is called on every tick.  The input is the
	// the output txuart transmit wire from the device.  The output is to
	// be connected to the the rxuart receive wire into the device.  This
	// makes hookup and operation very simple.
	//
	int UartSimulator_tick(UartSimulator *simulator, int i_tx);

#ifdef __cplusplus
}
#endif

#endif
