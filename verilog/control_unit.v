//RISC-V CONTROL UNIT
module control(
	opcode, 
	MemtoReg, 
	RegWrite, 
	MemWrite, 
	MemRead,
	Branch,
	ALUSrc,
	Jump,
	Jalr,
	Lui,
	Auipc,
	Fence,
	CSRR
	);
	
	input[6:0] opcode;
	output MemtoReg, RegWrite, MemWrite, MemRead, Branch, ALUSrc, Jump, Jalr, Lui, Auipc, Fence, CSRR;
	
	assign MemtoReg = (~opcode[5]) & (~opcode[4]) & (~opcode[3]) & (opcode[0]);
	assign RegWrite = ((~(opcode[4] | opcode[5])) | opcode[2] | opcode[4]) & opcode[0];
	assign MemWrite = (~opcode[6]) & (opcode[5]) & (~opcode[4]);
	assign MemRead = (~opcode[5]) & (~opcode[4]) & (~opcode[3]) & (opcode[1]);
	assign Branch = (opcode[6]) & (~opcode[4]) & (~opcode[2]);
	assign ALUSrc = ~(opcode[6] | opcode[4]) | (~opcode[5]);
	assign Jump = (opcode[6]) & (opcode[5]) & (~opcode[4]) & (opcode[2]);
	assign Jalr = (opcode[6]) & (opcode[5]) & (~opcode[4]) & (~opcode[3]) & (opcode[2]);
	assign Lui = (~opcode[6]) & (opcode[5]) & (opcode[4]) & (~opcode[3]) & (opcode[2]);
	assign Auipc = (~opcode[6]) & (~opcode[5]) & (opcode[4]) & (~opcode[3]) & (opcode[2]);
	assign Fence = (~opcode[5]) & opcode[3] & (opcode[2]);
	assign CSRR = (opcode[6]) & (opcode[4]);
	
endmodule
	
