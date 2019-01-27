//RISC-V instruction memory
module instruction_memory(addr, out);
	input[31:0]	addr;
	output reg[31:0] out;

	reg[31:0] instruction_memory[0:2**10-1];

	initial begin
		//read from "program.hex" and store the instructions in instruction memory
		$readmemh("simulation/program.hex",instruction_memory);
	end

	assign out = instruction_memory[addr >> 2];

endmodule
