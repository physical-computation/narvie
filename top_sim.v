//top_sim.v
//Top level simulation, linking cpu with data and instruction memory

`include "uart/baudgen.vh"

module top_sim(CLOCK, led, tx);

	output[7:0] led;
	output tx;

	reg[7:0] tx_data;
	reg tx_start;
	wire tx_ready;
	wire clk_proc;

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

	//Register File
	wire regfile_do_write;
	wire[4:0] regfile_write_addr;
	wire[31:0] regfile_write_data;
	wire[4:0] regfile_read_address0;
	wire[4:0] regfile_read_address1;
	wire[31:0] regfile_read_data0;
	wire[31:0] regfile_read_data1;

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

	regfile register_files(
			.clk(clk_proc),
			.write(regfile_do_write),
			.wrAddr(regfile_write_addr),
			.wrData(regfile_write_data),
			.rdAddrA(regfile_read_address0),
			.rdDataA(regfile_read_data0),
			.rdAddrB(regfile_read_address1),
			.rdDataB(regfile_read_data1)
		);

	instruction_memory inst_mem(
			.addr(inst_in),
			.out(inst_out)
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

		uart_tx #(.BAUDRATE(`B115200)) TX0 (
			.clk(CLOCK),
			.rstn(1'b1),
			.data(tx_data),
			.start(1'b1),
			.tx(tx),
			.ready(tx_ready)
		);

	assign clk_proc = (tx_start) ? 1'b1 : CLOCK;

	reg intermediate = 0;

	always @(posedge CLOCK) begin
		if(data_memwrite == 1'b1 && data_addr == 32'h2001) begin
			tx_data <= data_WrData[7:0];
			tx_start <= 1'b1;
			intermediate <= 1'b0;
		end
		if(tx_ready == 1'b0 && tx_start == 1'b1) begin
			tx_start <= 1'b1;
			intermediate <= 1'b1;
		end
		if(intermediate == 1'b1 && tx_ready == 1'b1 && tx_start == 1'b1) begin
			tx_start <= 1'b0;
			intermediate <= 1'b0;
		end
	end

endmodule
