//top.v
//Top level entity, linking cpu with data and instruction memory

module uart_instruction(clk12, tx, rx, regfile, clk_proc, inst_out);
	input clk12;
	output tx;
	input rx;
    input[1023:0] regfile;
	output reg clk_proc = 1;
    output[31:0] inst_out;

	reg[7:0] tx_data;
	reg tx_start;
	wire tx_ready;

	localparam noop = 32'h13000000;

	reg send_regfile = 0;

	reg do_execute = 0;
	reg [2:0] proc_cycle_count;
	reg rstn = 0;

	wire [31:0] instruction_buffer;
	wire instruction_rcv;

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
        .reg_file(regfile),
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
