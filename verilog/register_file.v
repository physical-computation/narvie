module regfile(clk, write, wrAddr, wrData, rdAddrA, rdDataA, rdAddrB, rdDataB, led_test/*test led*/);
	input clk;
	input write;
	input [4:0] wrAddr;
	input [31:0] wrData;
	input [4:0] rdAddrA;
	output [31:0] rdDataA;
	input [4:0] rdAddrB;
	output [31:0] rdDataB;
	output [31:0] led_test; //test led

	reg[31:0] regfile [0:31];

	assign rdDataA = ((wrAddr==rdAddrA) & write & wrAddr!=32'b0) ? wrData : regfile[rdAddrA];
	assign rdDataB = ((wrAddr==rdAddrB) & write & wrAddr!=32'b0) ? wrData : regfile[rdAddrB];
	assign led_test = regfile[15];//test led
	
	initial begin
		regfile[0] = 32'b0;	//register x0 = 0
	end
	
	always @(posedge clk) begin
		if (write && wrAddr!=32'b0) begin
			regfile[wrAddr] <= wrData;
		end
	end
endmodule
