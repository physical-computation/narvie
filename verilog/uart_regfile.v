//top.v
//Top level entity, linking cpu with data and instruction memory

module uart_regfile(
			clk12,
			tx,
			rx,
			clk_proc,
			inst_out,
			regfile_do_write,
			regfile_write_addr,
			regfile_write_data,
			regfile_read_address0,
			regfile_read_address1,
			regfile_read_data0,
			regfile_read_data1
		);
	input clk12;
	output tx;
	input rx;
	output reg clk_proc = 1;
    output[31:0] inst_out;
	input regfile_do_write;
	input [4:0] regfile_write_addr;
	input [31:0] regfile_write_data;
	input [4:0] regfile_read_address0;
	input [4:0] regfile_read_address1;
	output[31:0] regfile_read_data0;
	output[31:0] regfile_read_data1;

	reg[7:0] tx_data;
	reg tx_start;
	wire tx_ready;

	localparam noop = 32'h13000000;

	reg[31:0] regfile[31:0];
	wire [1023:0] regfilePort;
	reg send_regfile = 0;

	reg do_execute = 0;
	reg [2:0] proc_cycle_count;
	reg rstn = 0;

	wire [31:0] instruction_buffer;
	wire instruction_rcv;

	//Regfile

    genvar i;
    generate
        for (i=0; i<32; i=i+1)
            assign regfilePort[(32 * i + 31):(32 * i)] = regfile[i];
    endgenerate

	initial begin
		regfile[0] = 32'b0;
	end

	always @(posedge clk_proc) begin
		if(regfile_do_write == 1 && regfile_write_addr != 0) begin
			regfile[regfile_write_addr] <= regfile_write_data;
		end
		regfile_read_data0 <= regfile[regfile_read_address0];
		regfile_read_data1 <= regfile[regfile_read_address1];
	end

	//UART

	assign inst_out = (do_execute == 1 && proc_cycle_count == 0)
		? instruction_buffer
		: noop;

	always @(posedge clk12) begin
		rstn <= 1;
		if (instruction_rcv == 1 && do_execute == 0) begin
			proc_cycle_count <= 0;
			do_execute <= 1;
			clk_proc <= 0;
		end
		if (do_execute == 1) begin
			if (proc_cycle_count == 4) begin
				do_execute <= 0;
				send_regfile <= 1;
			end
			if (clk_proc == 1) begin
				proc_cycle_count <= proc_cycle_count + 1;
			end
			clk_proc <= !clk_proc;
		end
		if (send_regfile == 1) begin
			send_regfile <= 0;
		end
	end

	tx_regfile TX0 (
		.clk12(clk12),
		.rstn(rstn),
		.tx(tx),
        .reg_file(regfilePort),
        .do_write(send_regfile),
        .ready(tx_ready)
	);

	rx_instruction RX0 (
		.clk12(clk12),
		.rstn(rstn),
		.rx(rx),
		.instruction(instruction_buffer),
		.instruction_rcv(instruction_rcv)
	);
endmodule
