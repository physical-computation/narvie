//Program counter

module program_counter(inAddr, outAddr, clk);
	input clk;
	input[31:0] inAddr;
	output reg[31:0] outAddr;
	
	initial begin
		outAddr <= 32'b0;
	end

	always @(posedge clk) begin
		outAddr = inAddr;
	end
endmodule
