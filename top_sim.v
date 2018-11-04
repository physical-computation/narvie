//top_sim.v
//Top level simulation, linking cpu with data and instruction memory

module top_sim(CLOCK, led);
	
	output[7:0] led;
	
	//input	CLOCK;
	input CLOCK;
	
	
	//Interface
	wire[31:0] inst_in;
	wire[31:0] inst_out;
	wire[31:0] data_out;
	wire[31:0] data_addr;
	wire[31:0] data_WrData;
	wire data_memwrite;
	wire data_memread;
	wire[3:0] data_sign_mask;
	
	cpu processor( 
			.clk(CLOCK), 
			.inst_mem_in(inst_in), 
			.inst_mem_out(inst_out), 
			.data_mem_out(data_out), 
			.data_mem_addr(data_addr), 
			.data_mem_WrData(data_WrData), 
			.data_mem_memwrite(data_memwrite), 
			.data_mem_memread(data_memread),
			.data_mem_sign_mask(data_sign_mask)
		);
			
	instruction_memory inst_mem( 
			.addr(inst_in), 
			.out(inst_out)
		);
	
	data_memory data_mem(
			.clk(CLOCK),
			.addr(data_addr),
			.write_data(data_WrData),
			.memwrite(data_memwrite), 
			.memread(data_memread), 
			.read_data(data_out),
			.sign_mask(data_sign_mask),
			.led(led)
		);

endmodule
