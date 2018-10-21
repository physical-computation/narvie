//mask for loads/stores in data memory

module sign_mask_gen(func3, sign_mask);
	input[2:0] func3;
	output[3:0] sign_mask;
	
	reg[2:0] mask; 
	
	/*
	sign - for LBU and LHU the sign bit is 0, indicating read data should be zero extended, otherwise sign extended
	mask - for determining if the load/store operation is on word, halfword or byte
	
	TODO - a karnaugh map should be able to decribe the mask without case, the case is for reading convenience
	*/
	
	always @(*) begin
		case(func3)
			2'b00: mask <= 3'b001; //byte only
			2'b01: mask <= 3'b011; //halfword
			2'b10: mask <= 3'b111; //word
			default: mask <= 3'b000; //should not happen for loads/stores
		endcase
	end
	
	assign sign_mask = {(~func3[2]), mask};
	
endmodule
