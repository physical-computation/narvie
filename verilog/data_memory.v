//Data memory

module data_memory (addr, write_data, memwrite, memread, read_data);

	input[31:0] addr;
	input[31:0] write_data;
	input memwrite, memread;
	output reg [31:0] read_data;

	reg [31:0] data_memory[0:2**13-1];
	
	initial begin
		read_data = 32'b0;
	end
	
	always @(*) begin
		if (memwrite == 1'b1) begin
			data_memory[addr] <= write_data;
		end
		if (memread == 1'b1) begin
			read_data <= data_memory[addr];
		end
	end
endmodule
