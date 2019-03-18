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
	output clk_proc;
    output[31:0] inst_out;
	input regfile_do_write;
	input [4:0] regfile_write_addr;
	input [31:0] regfile_write_data;
	input [4:0] regfile_read_address0;
	input [4:0] regfile_read_address1;
	output[31:0] regfile_read_data0;
	output[31:0] regfile_read_data1;


	localparam noop = 32'h13000000;
    localparam SENDING       = 2'b00;
    localparam READY         = 2'b01;
    localparam ABOUT_TO_SEND = 2'b11;

    reg[1:0] state = READY;
	reg[7:0] index;
    reg[7:0] next_index;

	reg[31:0] regfile[31:0];
	reg send_regfile = 0;

	reg do_execute = 0;
	reg [3:0] proc_cycle_count = 1;
	reg rstn = 0;

	wire tx_ready;
    reg [7:0] tx_data;
	wire [31:0] instruction_buffer;
	wire instruction_rcv;

	initial begin
		regfile[0] = 32'b0;
	end

	assign clk_proc = proc_cycle_count[0];
	assign inst_out = (do_execute == 1 && proc_cycle_count[3:1] == 0)
		? instruction_buffer
		: noop;

	always @(posedge clk_proc) begin
		if(regfile_do_write == 1 && regfile_write_addr != 0) begin
			regfile[regfile_write_addr] <= regfile_write_data;
		end
		regfile_read_data0 <= regfile[regfile_read_address0];
		regfile_read_data1 <= regfile[regfile_read_address1];
	end

	always @(posedge clk12)
		tx_data <= regfile[next_index[6:2]][8 * next_index[1:0] +: 8];

	always @(posedge clk12) begin
		rstn <= 1;
		if (instruction_rcv == 1 && do_execute == 0) begin
			proc_cycle_count <= 0;
			do_execute <= 1;
		end
		if (do_execute == 1) begin
			if (proc_cycle_count[3:1] == 4) begin
				do_execute <= 0;
				send_regfile <= 1;
			end
			proc_cycle_count <= proc_cycle_count + 1;
		end
		if (send_regfile == 1) begin
			send_regfile <= 0;
		end
	end

    always @(posedge clk12) begin
        if (send_regfile == 1 && state == READY) begin
            state <= ABOUT_TO_SEND;
            index <= 0;
            next_index <= 1;
        end

        if (state == ABOUT_TO_SEND && tx_ready == 0) begin
            state <= SENDING;
        end

        if (tx_ready == 1 && state == SENDING) begin
            if (index == 127)
                state <= READY;
            else
                state <= ABOUT_TO_SEND;

            index <= next_index;
            next_index <= next_index + 1;
        end
    end

	rx_instruction RX0 (
		.clk12(clk12),
		.rstn(rstn),
		.rx(rx),
		.instruction(instruction_buffer),
		.instruction_rcv(instruction_rcv)
	);

	uart_tx #(.BAUDRATE(`B115200)) TX0 (
        .clk(clk12),
        .rstn(rstn),
        .data(tx_data),
        .start(state == ABOUT_TO_SEND),
        .tx(tx),
        .ready(tx_ready)
    );
endmodule
