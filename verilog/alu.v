//RISC-V ALU
module alu(ALUctl, A, B, ALUOut, Branch_Enable);
	input[6:0] ALUctl;
	input[31:0] A, B;
	output reg[31:0] ALUOut;
	output reg Branch_Enable;
	
	initial begin
		ALUOut = 32'b0;
		Branch_Enable = 1'b0;
	end
	
	always @(ALUctl, A, B) begin
		case(ALUctl[3:0])
			4'b0000: ALUOut <= A & B; //AND
			4'b0001: ALUOut <= A | B; //OR
			4'b0010: ALUOut <= A + B; //ADD
			4'b0110: ALUOut <= A - B; //SUBTRACT
			4'b0111: ALUOut <= $signed(A) < $signed(B) ? 32'b1 : 32'b0; //SLT
			4'b0011: ALUOut <= A >> B[4:0]; //SRL
			4'b0100: ALUOut <= A >>> B[4:0]; //SRA
			4'b0101: ALUOut <= A << B[4:0]; //SLL
			4'b1000: ALUOut <= A ^ B; //XOR
			4'b1001: ALUOut <= A; //CSRRW
			4'b1010: ALUOut <= A | B; //CSRRS
			4'b1011: ALUOut <= (~A) & B; //CSRRC
			default: ALUOut <= 0; //Shouldn't reach this state
		endcase
	end
	
	/*
	conditions:
	Equal: 00
	Not Equal: 01
	Less Than: 10
	Greater than or equal: 11
	Less than unsigned: 10
	Greater than or equal unsigned: 11
	do nothing: just set to 00
	*/
	always @(ALUctl, ALUOut, A, B) begin
		case(ALUctl[6:4])
			3'b001: Branch_Enable <= (ALUOut==0);
			3'b010: Branch_Enable <= !(ALUOut==0);
			3'b011: Branch_Enable <= ($signed(A)<$signed(B));//(ALUOut[31]);
			3'b100: Branch_Enable <= ($signed(A)>=$signed(B));
			3'b101: Branch_Enable <= ($unsigned(A) < $unsigned(B));
			3'b110: Branch_Enable <= ($unsigned(A) >= $unsigned(B));
			default: Branch_Enable <= 1'b0;
		endcase
	end
	//assign Zero = (ALUOut==0);
endmodule
