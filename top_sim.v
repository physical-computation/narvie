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
