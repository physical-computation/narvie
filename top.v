//top.v
//Top level entity, linking cpu with data and instruction memory

module top(led);
	output[7:0] led;
	
	//input	clk;
	wire clk;
	reg ENCLKHF = 1'b1; //clock enable
	reg CLKHF_POWERUP = 1'b1; //power up the HFOSC circuit

	SB_HFOSC #(.CLKHF_DIV("0b11")) OSCInst0 (
		.CLKHFEN(ENCLKHF),
		.CLKHFPU(CLKHF_POWERUP),
		.CLKHF(clk)
	);
	
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
			.clk(clk), 
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
			.clk(clk),
			.addr(data_addr),
			.write_data(data_WrData),
			.memwrite(data_memwrite), 
			.memread(data_memread), 
			.read_data(data_out),
			.sign_mask(data_sign_mask),
			.led(led)
		);

endmodule
