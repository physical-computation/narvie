//top.v
//Top level entity, linking cpu with data and instruction memory

module top(led, tx, rx);
	output[7:0] led;
	output tx;
	input rx;

	//input	clk;
	wire clk48;
	reg ENCLKHF = 1'b1; //clock enable
	reg CLKHF_POWERUP = 1'b1; //power up the HFOSC circuit

	SB_HFOSC #(.CLKHF_DIV("0b00")) OSCInst0 (
		.CLKHFEN(ENCLKHF),
		.CLKHFPU(CLKHF_POWERUP),
		.CLKHF(clk48)
	);

	reg clk24 = 0;
	reg clk12 = 0;

	always @(posedge clk48) begin
		clk24 <= ~clk24;
	end
	always @(posedge clk24) begin
		clk12 <= ~clk12;
	end

	main m (
		.clk12(clk12),
		.led(led),
		.tx(tx),
		.rx(rx),
	);

endmodule
