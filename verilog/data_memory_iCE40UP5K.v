//Data memory

module data_memory (clk, addr, write_data, memwrite, memread, read_data);
	input clk;
	input[31:0] addr;
	input[31:0] write_data;
	input memwrite, memread;
	output [31:0] read_data;

	/*reg [31:0] data_memory[0:2**13-1];
	
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
	end*/
	
	wire[15:0] read_data_MSW;
	wire[15:0] read_data_LSW;
	wire WREN;
	wire CS;
	
	assign read_data = {read_data_MSW, read_data_LSW};
	assign WREN = memwrite & (~memread);
	assign CS = memwrite | memread;
	
	SB_SPRAM256KA datamem_MSW(
		.DATAIN(write_data[31:16]),
		.ADDRESS(addr[13:0]), //take lower 14 bits
		.WREN(WREN),
		.CHIPSELECT(CS),
		.CLOCK(clk),
		.DATAOUT(read_data_MSW),
		.MASKWREN(4'b1111), //4 bits to mask 16-bit (4-nibble) data
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1)
	);
	
	SB_SPRAM256KA datamem_LSW(
		.DATAIN(write_data[15:0]),
		.ADDRESS(addr[13:0]), //take lower 14 bits
		.WREN(WREN),
		.CHIPSELECT(CS),
		.CLOCK(clk),
		.DATAOUT(read_data_LSW),
		.MASKWREN(4'b1111), //4 bits to mask 16-bit (4-nibble) data
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1)
	);
	
endmodule
