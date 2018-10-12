//Program counter

module program_counter(start, inAddr, outAddr, clk);
	input start;
	input clk;
	input[31:0] inAddr;
	output reg[31:0] outAddr;
	
	initial begin
		outAddr <= 32'b0;
	end

	always @(posedge clk) begin
		if (start == 1'b1) begin
			outAddr = inAddr;
		end
	end
endmodule
