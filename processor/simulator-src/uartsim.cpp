#include "uartsim.h"
#include <stdio.h>
#include <stdint.h>

#define UART_BAUD_COUNTS (UART_CLOCK_RATE / UART_BAUD_RATE)

void UartSimulator_init(UartSimulator *simulator, int (*write)(uint8_t, void *), int (*try_read)(uint8_t *, void *), void *read_write_state)
{
        simulator->write = write;
        simulator->try_read = try_read;
        simulator->read_write_state = read_write_state;

        // UART state
        simulator->rx_baudcounter = 0;
        simulator->rx_state = RXINIT;
        simulator->rx_busy = 0;
        simulator->rx_changectr = 0;
        simulator->last_tx = 0;
        simulator->tx_baudcounter = 0;
        simulator->tx_state = TXIDLE;
        simulator->tx_busy = 0;
        simulator->rx_data = 0;
        simulator->tx_data = 0;
}

int UartSimulator_tick(UartSimulator *simulator, int i_tx)
{
        int o_rx = 1;

        if ((!i_tx) && (simulator->last_tx))
                simulator->rx_changectr = 0;
        else
                simulator->rx_changectr++;
        simulator->last_tx = i_tx;

        if (simulator->rx_state == RXINIT)
        {
                if (i_tx)
                {
                        simulator->rx_state = RXIDLE;
                }
        }
        else if (simulator->rx_state == RXIDLE)
        {
                if (!i_tx)
                {
                        simulator->rx_state = RXDATA;
                        simulator->rx_baudcounter = UART_BAUD_COUNTS + UART_BAUD_COUNTS / 2 - 1;
                        simulator->rx_baudcounter -= simulator->rx_changectr;
                        simulator->rx_busy = 0;
                        simulator->rx_data = 0;
                }
        }
        else if (simulator->rx_baudcounter <= 0)
        {
                if (simulator->rx_busy >= (1 << (8 + 0 + 1 - 1)))
                {
                        simulator->rx_state = RXIDLE;
                        uint8_t buf = (simulator->rx_data >> (32 - 8 - 1 - 0)) & 0x0ff;
                        simulator->write(buf, simulator->read_write_state);
                }
                else
                {
                        simulator->rx_busy = (simulator->rx_busy << 1) | 1;
                        // Low order bit is transmitted first, in this
                        // order:
                        //	Start bit (1'b1)
                        //	bit 0
                        //	bit 1
                        //	bit 2
                        //	...
                        //	bit N-1
                        //	(possible parity bit)
                        //	stop bit
                        //	(possible secondary stop bit)
                        simulator->rx_data = ((i_tx & 1) << 31) | (simulator->rx_data >> 1);
                }
                simulator->rx_baudcounter = UART_BAUD_COUNTS - 1;
        }
        else
                simulator->rx_baudcounter--;

        if (simulator->tx_state == TXIDLE)
        {
                uint8_t buf;
                if (simulator->try_read(&buf, simulator->read_write_state) == 0)
                {
                        simulator->tx_data = ((~0) << (8 + 0 + 1)) | (buf << 1);
                        simulator->tx_busy = (1 << (8 + 0 + 1 + 1)) - 1;
                        simulator->tx_state = TXDATA;
                        o_rx = 0;
                        simulator->tx_baudcounter = UART_BAUD_COUNTS - 1;
                }
        }
        else if (simulator->tx_baudcounter <= 0)
        {
                simulator->tx_data >>= 1;
                simulator->tx_busy >>= 1;
                if (!simulator->tx_busy)
                        simulator->tx_state = TXIDLE;
                else
                        simulator->tx_baudcounter = UART_BAUD_COUNTS - 1;
                o_rx = simulator->tx_data & 1;
        }
        else
        {
                simulator->tx_baudcounter--;
                o_rx = simulator->tx_data & 1;
        }

        return o_rx;
}
