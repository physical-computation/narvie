module top();
	reg clk = 0;
	
	reg[31:0] input1;
	reg[31:0] input2;
	wire[31:0] data_out;
	
	adder adder_inst(
		.input1(input1),
		.input2(input2),
		.out(data_out)
	);

//simulation
always
 #0.5 clk = ~clk;

initial begin
	$dumpfile ("adder.vcd"); 
 	$dumpvars; 
 	
 	input1 = 32'd0;
 	input2 = 32'd0;
 	
 	#5
 	
 	input1 = 32'd0;
 	input2 = 32'd10;
 	
 	#5
 	
 	input1 = 32'd1000;
 	input2 = 32'd10;
 	
 	#5
 	
 	$finish;
end

endmodule
