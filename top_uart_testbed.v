`timescale 1us/1us

module main;
    reg	clk = 0;
    reg [11:0] counter = 0;
    wire uart1;
    wire uart2;
    reg rstn = 0;

    wire rcv;
    wire [7:0] data;

    // reg [7:0] queue [3:0];
    // reg [15:0] index = 0;
    reg [31:0] mem [0:31];
    wire [1023:0] regfile;
    reg ini = 1;

    wire [31:0] instruction_buffer;
    wire instruction_rcv;

    wire rx_received;

    genvar i;
    generate
        for (i=0; i<32; i=i+1)
            assign regfile[(32 * i) +: 32] = mem[i];
    endgenerate

	initial begin
		$readmemh("regsim.hex", mem);
	end

    // initial begin
    //     queue[0] = "A";
    //     queue[1] = "B";
    //     queue[2] = "C";
    //     queue[3] = "D";
    // end



    tx_regfile txr (
        .clk12(clk),
        .rstn(rstn),
        .tx(uart1),
        .do_write(ini),
        .reg_file(regfile),
        .ready(ready)
    );

	rx_instruction RX0 (
		.clk12(clk),
		.rstn(rstn),
		.rx(uart1),
		.instruction(instruction_buffer),
		.instruction_rcv(instruction_rcv)
	);


    always @(posedge clk)
        rstn <= 1;

    always @* begin
        if (rstn == 0)
            ini <= 1;
    end

    always @(negedge ready) begin
        ini <= 0;
    end

    always @(posedge instruction_rcv) begin
        $display("0x%h", instruction_buffer);
    end

    // always @(posedge clk) begin
    //     if (counter == 0) begin
    //     //     $display(
    //     //         "write = %h, read = %c, counter = %b",
    //     //         queue[(index + 1) & 16'h0003], read, counter
    //     //     );

    //         if (index == 10)
    //             $finish;
    //         else
    //             index <= index + 1;
    //     end
    //     counter <= counter + 1;
    // end

    // (* ivl_synthesis_off *)
    always #1 begin
        clk <= !clk;
    end

    always #1000000 begin
        $finish;
    end

    // initial #3000 $finish;

endmodule