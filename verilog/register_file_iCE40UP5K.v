module regfile(clk, write, wrAddr, wrData, rdAddrA, rdDataA, rdAddrB, rdDataB, led_test/*test led*/);
	input clk;
	input write;
	input [4:0] wrAddr;
	input [31:0] wrData;
	input [4:0] rdAddrA;
	output [31:0] rdDataA;
	input [4:0] rdAddrB;
	output [31:0] rdDataB;
	output [31:0] led_test; //test led
	
	//Block RAM interface
	wire[15:0] rdDataA_MSW;
	wire[15:0] rdDataA_LSW;
	
	wire[15:0] rdDataB_MSW;
	wire[15:0] rdDataB_LSW;
	
	wire[15:0] ledVal_MSW;
	wire[15:0] ledVal_LSW;
	
	wire RAM_write;
	
	wire[7:0] led_read_addr;
	assign led_read_addr = 8'd15;
	assign RAM_write = (wrAddr == 32'b0) ? 1'b0 : write;
	
	//data A block MSW
	SB_RAM40_4KNRNW dataA_MSW (
		.RDATA(rdDataA_MSW),
		.RADDR({3'b0, rdAddrA}),
		.RCLKN(clk),
		.RCLKE(1'b1),
		.RE(1'b1),
		.WADDR({3'b0, wrAddr}),
		.WCLKN(clk),
		.WCLKE(1'b1),
		.WDATA(wrData[31:16]),
		.WE(RAM_write),
		.MASK(16'b0)
	);
	defparam dataA_MSW.READ_MODE=0;
	defparam dataA_MSW.WRITE_MODE=0;
	
	//data A block LSW
	SB_RAM40_4KNRNW dataA_LSW (
		.RDATA(rdDataA_LSW),
		.RADDR({3'b0, rdAddrA}),
		.RCLKN(clk),
		.RCLKE(1'b1),
		.RE(1'b1),
		.WADDR({3'b0, wrAddr}),
		.WCLKN(clk),
		.WCLKE(1'b1),
		.WDATA(wrData[15:0]),
		.WE(RAM_write),
		.MASK(16'b0)
	);
	defparam dataA_LSW.READ_MODE=0;
	defparam dataA_LSW.WRITE_MODE=0;
	
	
	//data B block MSW
	SB_RAM40_4KNRNW dataB_MSW (
		.RDATA(rdDataB_MSW),
		.RADDR({3'b0, rdAddrB}),
		.RCLKN(clk),
		.RCLKE(1'b1),
		.RE(1'b1),
		.WADDR({3'b0, wrAddr}),
		.WCLKN(clk),
		.WCLKE(1'b1),
		.WDATA(wrData[31:16]),
		.WE(RAM_write),
		.MASK(16'b0)
	);
	defparam dataB_MSW.READ_MODE=0;
	defparam dataB_MSW.WRITE_MODE=0;
	
	//data B block LSW
	SB_RAM40_4KNRNW dataB_LSW (
		.RDATA(rdDataB_LSW),
		.RADDR({3'b0, rdAddrB}),
		.RCLKN(clk),
		.RCLKE(1'b1),
		.RE(1'b1),
		.WADDR({3'b0, wrAddr}),
		.WCLKN(clk),
		.WCLKE(1'b1),
		.WDATA(wrData[15:0]),
		.WE(RAM_write),
		.MASK(16'b0)
	);
	defparam dataB_LSW.READ_MODE=0;
	defparam dataB_LSW.WRITE_MODE=0;
	
	
	
	//ledVal block MSW
	SB_RAM40_4KNRNW ledVal_MSW_inst (
		.RDATA(ledVal_MSW),
		.RADDR(led_read_addr),
		.RCLKN(clk),
		.RCLKE(1'b1),
		.RE(1'b1),
		.WADDR({3'b0, wrAddr}),
		.WCLKN(clk),
		.WCLKE(1'b1),
		.WDATA(wrData[31:16]),
		.WE(RAM_write),
		.MASK(16'b0)
	);
	defparam ledVal_MSW_inst.READ_MODE=0;
	defparam ledVal_MSW_inst.WRITE_MODE=0;
	
	//ledVal block LSW
	SB_RAM40_4KNRNW ledVal_LSW_inst (
		.RDATA(ledVal_LSW),
		.RADDR(led_read_addr),
		.RCLKN(clk),
		.RCLKE(1'b1),
		.RE(1'b1),
		.WADDR({3'b0, wrAddr}),
		.WCLKN(clk),
		.WCLKE(1'b1),
		.WDATA(wrData[15:0]),
		.WE(RAM_write),
		.MASK(16'b0)
	);
	defparam ledVal_LSW_inst.READ_MODE=0;
	defparam ledVal_LSW_inst.WRITE_MODE=0;
	
	//signal assignments
	assign rdDataA = ((wrAddr==rdAddrA) & write & wrAddr!=32'b0) ? wrData : {rdDataA_MSW, rdDataA_LSW};
	assign rdDataB = ((wrAddr==rdAddrB) & write & wrAddr!=32'b0) ? wrData : {rdDataB_MSW, rdDataB_LSW};
	assign led_test = {ledVal_MSW, ledVal_LSW};//test led
	
endmodule
