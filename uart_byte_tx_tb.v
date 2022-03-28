`timescale 1ns / 1ns
`define clk_period 20

module uart_byte_tx_tb;
reg sys_clk;
reg reset_n;

wire UART_TX;

reg tx_start;
reg [7:0] tx_data;
wire tx_state;
wire tx_done;

uart_byte_tx #
(
    .CLK_FREQ       ('d50000000     ),  // 50MHz system clock
    .BAUD_RATE      ('d115200       )
)uart_byte_tx_inst0
(
    .clk_in         (sys_clk        ),  // system clock
    .rst_n_in       (reset_n        ),  // system reset, active low
    .tx_start       (tx_start       ),	// start with pos edge
    .tx_data        (tx_data        ),	// data need to transfer
    .tx_done        (tx_done        ),  // transfer done
    .tx_state       (tx_state       ),  // sending duration
    .rs232_tx       (UART_TX		)	// uart transfer pin
);

initial sys_clk = 1;
always #(`clk_period/2) sys_clk = ~sys_clk;

initial reset_n = 0;
always #(`clk_period*50) reset_n = 1'b1;

initial
begin
    tx_start = 0;
    tx_data = 8'h0;

    #(`clk_period*50)
    tx_data = 8'haa;

    #(`clk_period*10)
    tx_start = 1;

    #(`clk_period*2)
    tx_start = 0;
    //@(posedge rx_done)
    //#(`clk_period*5000);
	//$stop;	
end

endmodule

