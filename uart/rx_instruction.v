module rx_instruction(
            clk12,
            rstn,
            rx,
            instruction,
            instruction_rcv
        );

    // IN/OUTPUTS

    input wire clk12;
    input wire rstn;
    input wire rx;
    output reg [31:0] instruction;
    output reg instruction_rcv = 0;

    // CONNECTIONS

    wire rx_rcv;
    wire [7:0] rx_data;

    // STATE

    reg [1:0] byte_index = 0;

    // UPDATE

    // always @(posedge clk) begin
    //     if (rstn == 0) begin
    //         instruction_rcv <= 0;
    //         byte_index <= 0;
    //     end
    // end

    always @(posedge clk12) begin
        if (rx_rcv == 1) begin
            instruction[(8 * byte_index) +: 8] <= rx_data;
            byte_index <= byte_index + 1;
        end
        if (rx_rcv == 1 && byte_index == 3)
            instruction_rcv <= 1;
        else
            instruction_rcv <= 0;
    end

	uart_rx #(.BAUDRATE(`B115200)) RX0 (
        .clk(clk12),
        .rstn(rstn),
        .rx(rx),
        .data(rx_data),
        .rcv(rx_rcv)
    );
endmodule
