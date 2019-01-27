//Forwarding Unit
module ForwardingUnit(rs1, rs2, MEM_RegWriteAddr, WB_RegWriteAddr, MEM_RegWrite, WB_RegWrite, EX_CSRR_Addr, MEM_CSRR_Addr, WB_CSRR_Addr, MEM_CSRR, WB_CSRR, MEM_fwd1, MEM_fwd2, WB_fwd1, WB_fwd2);
	input[4:0] rs1;
	input[4:0] rs2;
	input[4:0] MEM_RegWriteAddr;
	input[4:0] WB_RegWriteAddr;
	input MEM_RegWrite;
	input WB_RegWrite;
	input[11:0] EX_CSRR_Addr;
	input[11:0] MEM_CSRR_Addr;
	input[11:0] WB_CSRR_Addr;
	input MEM_CSRR;
	input WB_CSRR;
	output MEM_fwd1;
	output MEM_fwd2;
	output WB_fwd1;
	output WB_fwd2;
	
	//if data hazard detected, assign RegWrite to decide if...
	//result MEM or WB stage should be rerouted to ALU input 
	assign MEM_fwd1 = (MEM_RegWriteAddr != 5'b0 && MEM_RegWriteAddr ==  rs1)?MEM_RegWrite:1'b0;
	assign MEM_fwd2 = (MEM_RegWriteAddr != 5'b0 && MEM_RegWriteAddr ==  rs2 && MEM_RegWrite == 1'b1) || (EX_CSRR_Addr == MEM_CSRR_Addr && MEM_CSRR == 1'b1)?1'b1:1'b0;

	//from wb stage
	assign WB_fwd1 = (WB_RegWriteAddr != 5'b0 && WB_RegWriteAddr ==  rs1 && WB_RegWriteAddr != MEM_RegWriteAddr)?WB_RegWrite:1'b0;
	assign WB_fwd2 = (WB_RegWriteAddr != 5'b0 && WB_RegWriteAddr ==  rs2 && WB_RegWrite == 1'b1 && WB_RegWriteAddr != MEM_RegWriteAddr) || (EX_CSRR_Addr == WB_CSRR_Addr && WB_CSRR == 1'b1 && MEM_CSRR_Addr != WB_CSRR_Addr)?1'b1:1'b0;
	
endmodule
