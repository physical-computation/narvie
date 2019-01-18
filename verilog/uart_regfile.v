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
		$display("write %h to %d (%b%b)", regfile_write_data, regfile_write_addr, regfile_do_write, do_execute);
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

	wire tx_ready;
    reg [7:0] tx_data;

    // STATE

    localparam SENDING       = 2'b00;
    localparam READY         = 2'b01;
    localparam ABOUT_TO_SEND = 2'b11;

    reg[1:0] state = READY;
    reg[1:0] byte_index = 0;
    reg[4:0] word_index = 0;

    // UPDATE

    always @(posedge clk12/* or negedge rstn*/) begin
        if (send_regfile == 1 && state == READY) begin
            state <= ABOUT_TO_SEND;
            byte_index <= 0;
            word_index <= 0;
            tx_data <= regfilePort[7:0];
        end

        if (state == ABOUT_TO_SEND && tx_ready == 0) begin
            state <= SENDING;
        end

        if (tx_ready == 1 && state == SENDING) begin
            // $display("sending %d, %d", word_index, byte_index);
            if (byte_index == 3)
                word_index <= word_index + 1;

            if (byte_index == 3 && word_index == 31)
                state <= READY;
            else
                state <= ABOUT_TO_SEND;

            byte_index <= byte_index + 1;
            tx_data <= regfilePort[(8 * (word_index * 4 + byte_index + 1)) +: 8];
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
