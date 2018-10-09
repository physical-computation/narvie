//top.v
//Top level entity, linking cpu with data and instruction memory

module top(clk, led);
	input clk;
	output[7:0] led;
	
	wire[31:0] inst_in;
	wire[31:0] inst_out;
	wire[31:0] data_out;
	wire[31:0] data_addr;
	wire[31:0] data_WrData;
	wire data_memwrite;
	wire data_memread;
	
	cpu processor( 
			.clk(clk), 
			.led(led), 
			.inst_mem_in(inst_in), 
			.inst_mem_out(inst_out), 
			.data_mem_out(data_out), 
			.data_mem_addr(data_addr), 
			.data_mem_WrData(data_WrData), 
			.data_mem_memwrite(data_memwrite), 
			.data_mem_memread(data_memread)
		);
			
	/*instruction_memory inst_mem( 
			.addr(inst_in), 
			.out(inst_out)
		);
	
	data_memory data_mem( 
			.addr(data_addr),
			.write_data(data_WrData),
			.memwrite(data_memwrite), 
			.memread(data_memread), 
			.read_data(data_out)
		);*/

endmodule
