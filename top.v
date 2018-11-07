//top.v
//Top level entity, linking cpu with data and instruction memory

module top(led, tx);
	output[7:0] led;
	output tx;
	
	reg[7:0] tx_data;
	reg tx_start;
	wire tx_ready;
	
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
	
	cpu processor( 
			.clk(clk_proc), 
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
			.clk(clk12),
			.rstn(1'b1),
			.data(tx_data),
			.start(tx_start),
			.tx(tx),
			.ready(tx_ready)
		);
	
	assign clk_proc = (tx_start) ? 1'b1 : clk6;
	
	always @(posedge clk6) begin
		if(data_memwrite == 1'b1 && data_addr == 32'h2000) begin
			tx_data <= data_WrData[7:0] + "0";
			tx_start <= 1'b1;
		end
		if(tx_ready == 1'b0 && tx_start == 1'b1) begin
			tx_start <= 1'b0;
		end
	end

endmodule
