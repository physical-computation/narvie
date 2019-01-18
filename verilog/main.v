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
	wire clk_proc;
	wire clk_reg;

	//Register File
	wire regfile_do_write;
	wire[4:0] regfile_write_addr;
	wire[31:0] regfile_write_data;
	wire[4:0] regfile_read_address0;
	wire[4:0] regfile_read_address1;
	wire[31:0] regfile_read_data0;
	wire[31:0] regfile_read_data1;

	wire[1023:0] regfile;

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
			.regfile_do_write(regfile_do_write),
			.regfile_write_addr(regfile_write_addr),
			.regfile_write_data(regfile_write_data),
			.regfile_read_address0(regfile_read_address0),
			.regfile_read_address1(regfile_read_address1),
			.regfile_read_data0(regfile_read_data0),
			.regfile_read_data1(regfile_read_data1)
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

	uart_regfile register_files(
			.clk12(clk12),
			.tx(tx),
			.rx(rx),
			.clk_proc(clk_proc),
			.inst_out(inst_out),
			.regfile_do_write(regfile_do_write),
			.regfile_write_addr(regfile_write_addr),
			.regfile_write_data(regfile_write_data),
			.regfile_read_address0(regfile_read_address0),
			.regfile_read_address1(regfile_read_address1),
			.regfile_read_data0(regfile_read_data0),
			.regfile_read_data1(regfile_read_data1)
		);

endmodule
