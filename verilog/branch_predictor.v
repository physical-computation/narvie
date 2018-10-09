//Branch Predictor FSM

module branch_predictor(
		clk,
		actual_branch_decision, 
		branch_decode_sig, 
		branch_mem_sig, 
		in_addr, 
		offset, 
		branch_addr, 
		prediction
	);
	
	//inputs
	input clk;
	input actual_branch_decision;
	input branch_decode_sig;
	input branch_mem_sig;
	input[31:0] in_addr;
	input[31:0] offset;
	
	//outputs
	output[31:0] branch_addr;
	output prediction;
	
	//internal state
	reg[1:0] s;
	
	reg branch_mem_sig_reg;
	
	initial begin
		s = 2'b00;
		branch_mem_sig_reg = 1'b0;
	end
	
	always @(negedge clk) begin
		branch_mem_sig_reg <= branch_mem_sig;
	end
	
	//using this microarchitecture, branches can't occur consecutively
	//therefore can use branch_mem_sig
	//as every branch follows a bubble, so a 0 to 1 transition
	always @(posedge clk) begin
		if (branch_mem_sig_reg) begin
			s[1] = (s[1]&s[0]) | (s[0]&actual_branch_decision) | (s[1]&actual_branch_decision);
			s[0] = (s[1]&(!s[0])) | ((!s[0])&actual_branch_decision) | (s[1]&actual_branch_decision);
		end
	end
	
	assign branch_addr = in_addr + offset;
	
	assign prediction = s[1] & branch_decode_sig;
	
endmodule
