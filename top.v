//top.v
//Top level entity, linking cpu with data and instruction memory

module top(led, tx, rx);
	output[7:0] led;
	output tx;
	input rx;

	reg[7:0] tx_data;
	reg tx_start;
	wire tx_ready;
	wire clk_proc;

	localparam noop = 32'h13000000;

	//input	clk;
	wire clk48;
	reg ENCLKHF = 1'b1; //clock enable
	reg CLKHF_POWERUP = 1'b1; //power up the HFOSC circuit

	SB_HFOSC #(.CLKHF_DIV("0b00")) OSCInst0 (
		.CLKHFEN(ENCLKHF),
		.CLKHFPU(CLKHF_POWERUP),
		.CLKHF(clk48)
	);

	reg clk24 = 0;
	reg clk12 = 0;
	reg clk6 = 0;

	always @(posedge clk48) begin
		clk24 <= ~clk24;
	end
	always @(posedge clk24) begin
		clk12 <= ~clk12;
	end
	always @(posedge clk12) begin
		clk6 <= ~clk6;
	end

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
	reg send_regfile = 0;

	wire [31:0] instruction_buffer;
	reg [31:0] clocks_counter = 6;
	reg do_execute = 0;
	wire instruction_rcv;
	reg [5:0] reg_counter = 32;
	reg rstn = 0;

    // reg [31:0] mem [0:31];
    // genvar i;
    // generate
    //     for (i=0; i<32; i=i+1)
    //         assign regfile[(32 * i) +: 32] = mem[i];
    // endgenerate

	// initial begin
	// 	$readmemh("regsim.hex", mem);
	// end

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

	assign inst_out = (bytes_loaded == 4) ? instruction_buffer : noop;

	data_memory data_mem(
			.clk(clk_proc),
			.addr(data_addr),
			.write_data(data_WrData),
			.memwrite(data_memwrite),
			.memread(data_memread),
			.read_data(data_out),
			.sign_mask(data_sign_mask),
			.led()
		);

	tx_regfile TX0 (
		.clk12(clk12),
		.rstn(rstn),
		.tx(tx),
        .reg_file(regfile),
        .do_write(send_regfile),
        .ready(tx_ready),
		.led(led[1])
	);

	rx_instruction RX0 (
		.clk12(clk12),
		.rstn(rstn),
		.rx(rx),
		.instruction(instruction_buffer),
		.instruction_rcv(instruction_rcv)
	);

	assign clk_proc = do_execute ? clk6 : 1;

	always @(posedge clk12) begin
		rstn <= 1;
		if (instruction_rcv == 1 && do_execute == 0) begin
			led[2] <= !led[2];
			clocks_counter <= 0;
			do_execute <= 1;
		end
		if (do_execute == 1) begin
			clocks_counter <= clocks_counter + 1;
		end
		if (clocks_counter == 10 && do_execute == 1) begin
			do_execute <= 0;
			send_regfile <= 1;
		end
		if (send_regfile == 1) begin
			send_regfile <= 0;
		end
	end

endmodule
