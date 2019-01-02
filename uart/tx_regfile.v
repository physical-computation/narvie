module tx_regfile(
            clk12,
            rstn,
            tx,
            do_write,
            reg_file,
            ready,
            led,
        );

    // IN/OUTPUTS

    input wire clk12;
    input wire rstn;
    output wire tx;
    input wire do_write;
    input wire [1023:0] reg_file;
    output wire ready;
    output reg led;

    // CONNECTIONS

    wire tx_ready;
    reg [7:0] tx_data;

    assign ready = (state == READY);

    // STATE

    localparam SENDING  = 2'b00;
    localparam READY         = 2'b01;
    localparam ABOUT_TO_SEND = 2'b11;

    reg [1:0] state = READY;
    reg [6:0] byte_index = 0;

    // MESSAGES

    localparam DO_WRITE        = 3'b000;
    localparam SEND_STARTED    = 3'b010;
    localparam TX_IS_READY     = 3'b001;
    localparam RESET           = 3'b111;

    // UPDATE

    task update;
        input reg [2:0] msg;
    begin
        case(msg)
            DO_WRITE: begin
                if (state == READY) begin
		            led <= !led;
                    state <= ABOUT_TO_SEND;
                    byte_index <= 0;
                    tx_data <= reg_file[7:0];
                end
            end
            SEND_STARTED: begin
                state <= SENDING;
            end
            TX_IS_READY: begin
                if (state == SENDING) begin
                    if (byte_index == 7'h7F) begin
                        state <= READY;
                        byte_index <= 0;
                    end else begin
                        state <= ABOUT_TO_SEND;
                        byte_index <= byte_index + 1;
                        tx_data <= reg_file[(8 * (byte_index + 1)) +: 8];
                    end
                end
            end
            default: begin // or RESET
                state <= READY;
                byte_index <= 0;
            end
        endcase
    end
    endtask

    always @(posedge clk12/* or negedge rstn*/) begin
        if (rstn == 0)
            update(RESET);

        if (do_write == 1)
            update(DO_WRITE);

        if (state == ABOUT_TO_SEND && tx_ready == 0)
            update(SEND_STARTED);

        if (tx_ready == 1)
            update(TX_IS_READY);
    end

	uart_tx #(.BAUDRATE(`B115200)) TX0 (
        .clk(clk12),
        .rstn(rstn),
        .data(tx_data),
        .start(state == ABOUT_TO_SEND),
        .tx(tx),
        .ready(tx_ready)
    );
endmodule