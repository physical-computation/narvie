//top.v
//Top level entity, linking cpu with data and instruction memory

module main(clk12, led, tx, rx);
	input clk12;
	output[7:0] led;
	output tx;
	input rx;

	//Interface
	wire[31:0] inst_in;
	wire[31:0] inst_out;
	wire[31:0] data_out;
	wire[31:0] data_addr;
	wire[31:0] data_WrData;
	wire data_memwrite;
	wire data_memread;
	wire[3:0] data_sign_mask;
	wire[1023:0] regfile;
	wire clk_proc;

	cpu processor(
			.clk(clk_proc),
			.inst_mem_in(inst_in),
			.inst_mem_out(inst_out),
			.data_mem_out(data_out),
			.data_mem_addr(data_addr),
			.data_mem_WrData(data_WrData),
			.data_mem_memwrite(data_memwrite),
			.data_mem_memread(data_memread),
			.data_mem_sign_mask(data_sign_mask),
			.regfile(regfile)
		);

	data_memory data_mem(
			.clk(clk_proc),
			.addr(data_addr),
			.write_data(data_WrData),
			.memwrite(data_memwrite),
			.memread(data_memread),
			.read_data(data_out),
			.sign_mask(data_sign_mask),
			.led(led)
		);

	uart_instruction uart_instruction(
			.clk12(clk12),
			.tx(tx),
			.rx(rx),
			.regfile(regfile),
			.clk_proc(clk_proc),
			.inst_out(inst_out)
		);

endmodule
