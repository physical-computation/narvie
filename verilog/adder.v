//adder

module adder(input1, input2, out);
	input[31:0] input1, input2;
	output[31:0] out;
	
	assign out = input1 + input2;
	
endmodule
