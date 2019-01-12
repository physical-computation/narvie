//top_sim.v
//Top level simulation, linking cpu with data and instruction memory

`include "uart/baudgen.vh"

module top_sim(CLOCK, led, tx, rx);
	input CLOCK;
	output[7:0] led;
	output tx;
	input rx;

	main m (
		.clk12(CLOCK),
		.led(led),
		.tx(tx),
		.rx(rx)
	);
endmodule
