//pipeline registers

module if_id (clk, data_in, data_out);
	input clk;
	input[63:0] data_in;
	output reg[63:0] data_out;
	
	initial begin
		data_out = 64'b0;
	end
	
	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule

module id_ex (clk, data_in, data_out);
	input clk;
	input[177:0] data_in;
	output reg[177:0] data_out;
	
	initial begin
		data_out = 178'b0;
	end
	
	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule

module ex_mem (clk, data_in, data_out);
	input clk;
	input[154:0] data_in;
	output reg[154:0] data_out;
	
	initial begin
		data_out = 155'b0;
	end
	
	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule

module mem_wb (clk, data_in, data_out);
	input clk;
	input[116:0] data_in;
	output reg[116:0] data_out;
	
	initial begin
		data_out = 117'b0;
	end
	
	always @(posedge clk) begin
		data_out <= data_in;
	end
endmodule
