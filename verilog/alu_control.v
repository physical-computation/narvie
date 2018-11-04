//RISC-V ALU CONTROL UNIT
module ALUControl(FuncCode, ALUCtl, Opcode);
	input[3:0] FuncCode;
	input[6:0] Opcode;
	output reg[6:0] ALUCtl;
	
	initial begin
		ALUCtl = 7'b0;
	end
	
	/*
	conditions: (leading 2 bits of ALUCtl)
	Equal: 001
	Not Equal: 010
	Less Than: 011
	Greater than or equal: 100
	Less than unsigned: 101
	Greater than or equal unsigned: 110
	do nothing: just set to 000
	*/
	
	always @(*) begin
		case(Opcode)
			7'b0110111: //LUI, U-Type
				ALUCtl <= 7'b0000010;		
			7'b0010111: //AUIPC, U-Type
				ALUCtl <= 7'b0000010;
			7'b1101111: //JAL, UJ-Type
				ALUCtl <= 7'b0001111; //Tell the ALU to do nothing
			7'b1100111: //JALR, I-Type
				ALUCtl <= 7'b0001111; //Tell the ALU to do nothing
			7'b1100011: //Branch, SB-Type
				case(FuncCode[2:0])
					3'b000: 
						ALUCtl <= 7'b0010110; //BEQ conditions
					3'b001: 
						ALUCtl <= 7'b0100110; //BNE conditions
					3'b100: 
						ALUCtl <= 7'b0110110; //BLT conditions
					3'b101: 
						ALUCtl <= 7'b1000110; //BGE conditions
					3'b110: 
						ALUCtl <= 7'b1010110; //BLTU conditions untested
					3'b111: 
						ALUCtl <= 7'b1100110; //BGEU conditions untested
					default  : 
						ALUCtl <= 7'b0001111; //Should not happen
				endcase
			
			7'b0000011: //Loads, I-Type
				case(FuncCode[2:0])
					3'b000: 
						ALUCtl <= 7'b0000010; //LB
					3'b001: 
						ALUCtl <= 7'b0000010; //LH
					3'b010: 
						ALUCtl <= 7'b0000010; //LW
					3'b100: 
						ALUCtl <= 7'b0000010; //LBU
					3'b101: 
						ALUCtl <= 7'b0000010; //LHU
					default: 
						ALUCtl <= 7'b0001111; //Should not happen
				endcase
			
			7'b0100011: //Stores, S-Type
				case(FuncCode[2:0])
					3'b000: 
						ALUCtl <= 7'b0000010; //SB
					3'b001: 
						ALUCtl <= 7'b0000010; //SH
					3'b010: 
						ALUCtl <= 7'b0000010; //SW
					default: 
						ALUCtl <= 7'b0001111; //Should not happen
				endcase
			
			7'b0010011: //Immediate operations, I-Type
				case(FuncCode[2:0])
					3'b000: 
						ALUCtl <= 7'b0000010; //ADDI
					3'b010: 
						ALUCtl <= 7'b0000111; //SLTI
					3'b011: 
						ALUCtl <= 7'b0000111; //SLTIU
					3'b100: 
						ALUCtl <= 7'b0001000; //XORI
					3'b110: 
						ALUCtl <= 7'b0000001; //ORI
					3'b111: 
						ALUCtl <= 7'b0000000; //ANDI
					3'b001: 
						ALUCtl <= 7'b0000101; //SLLI
					3'b101:
						case(FuncCode[3])
							1'b0: 
								ALUCtl <= 7'b0000011; //SRLI
							1'b1: 
								ALUCtl <= 7'b0000100; //SRAI untested
							default: 
								ALUCtl <= 7'b0001111; //Should not happen
						endcase
					default: 
						ALUCtl <= 7'b0001111; //Should not happen
				endcase
			
			7'b0110011: //ADD SUB & logic shifts, R-Type
				case(FuncCode[2:0])
					3'b000:
						case(FuncCode[3])
							1'b0: 
								ALUCtl <= 7'b0000010; //ADD
							1'b1: 
								ALUCtl <= 7'b0000110; //SUB
							default: 
								ALUCtl <= 7'b0001111; //Should not happen
						endcase
					3'b001: 
						ALUCtl <= 7'b0000101; //SLL
					3'b010: 
						ALUCtl <= 7'b0000111; //SLT
					3'b011: 
						ALUCtl <= 7'b0000111; //SLTU
					3'b100: 
						ALUCtl <= 7'b0001000; //XOR
					3'b101:
						case(FuncCode[3])
							1'b0: 
								ALUCtl <= 7'b0000011; //SRL
							1'b1: 
								ALUCtl <= 7'b0000100; //SRA untested 
							default: 
								ALUCtl <= 7'b0001111; //Should not happen
						endcase
					3'b110: 
						ALUCtl <= 7'b0000001; //OR
					3'b111: 
						ALUCtl <= 7'b0000000; //AND
					default: 
						ALUCtl <= 7'b0001111; //Should not happen
				endcase
			
			7'b1110011:
				case(FuncCode[1:0]) //use lower 2 bits of FuncCode to determine operation
					2'b01:
						ALUCtl <= 7'b0001001; //CSRRW
					2'b10:
						ALUCtl <= 7'b0001010; //CSRRS
					2'b11:
						ALUCtl <= 7'b0001011; //CSRRC
					default:
						ALUCtl <= 7'b0001111;
				endcase
			
			default: 
				ALUCtl <= 7'b0001111; //Should not happen
		endcase
	end
endmodule
