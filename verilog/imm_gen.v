//RISC-V IMMEDIATE GENERATOR

module imm_gen(inst, imm);
	
	input [31:0] inst;
	output reg [31:0] imm;
	
	initial begin
		imm = 32'b0;
	end
	
	always @(*) begin
		case ({inst[6:5], inst[3:2]})
			4'b0000: //I-type
				imm <= { {21{inst[31]}}, inst[30:20] };
			4'b1101: //I-type JALR
				imm <= { {21{inst[31]}}, inst[30:21], 1'b0 };
			4'b0100: //S-type
				imm <= { {21{inst[31]}}, inst[30:25], inst[11:7] };
			4'b0101: //U-type
				imm <= { inst[31:12], 12'b0 };
			4'b0001: //U-type
				imm <= { inst[31:12], 12'b0 };
			4'b1111: //UJ-type
				imm <= { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
			4'b1100: //SB-type
				imm <= { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
			default : imm <= { {21{inst[31]}}, inst[30:20] };
		endcase
	end
	
endmodule
