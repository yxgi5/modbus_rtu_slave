`timescale 1ns / 1ns
`define clk_period 20

module uart_byte_rx_tb;
reg sys_clk;
reg reset_n;

wire UART_TX;

reg tx_start;
reg [7:0] tx_data;
wire tx_state;
wire tx_done;

reg test;

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

wire [7:0] rx_data;
wire rx_done;
wire rx_state;

uart_byte_rx #
(
    .CLK_FREQ       ('d50000000     ),  // 50MHz system clock
    .BAUD_RATE      ('d115200       )
)uart_byte_rx_inst0
(
    .clk_in         (sys_clk        ),  // system clock
    .rst_n_in       (reset_n        ),  // system reset, active low
    .rx_data        (rx_data        ),	// data need to transfer
    .rx_done        (rx_done        ),  // transfer done
    .rx_state       (rx_state       ),  // sending duration
    .rs232_rx       (UART_TX		)	// uart transfer pin
);


initial sys_clk = 1;
always #(`clk_period/2) sys_clk = ~sys_clk;

initial reset_n = 0;
always #(`clk_period*50) reset_n = 1'b1;

initial
begin
    tx_start = 0;
    tx_data = 8'h0;
    test = 0;

    #(`clk_period*50)
    test = 1;
    #(`clk_period*1)
    test = 0;

//    #(`clk_period*50)
//    tx_data = 8'haa;

//    #(`clk_period*10)
//    tx_start = 1;

//    #(`clk_period*2)
//    tx_start = 0;
    //@(posedge rx_done)
    //#(`clk_period*5000);
	//$stop;	
end

parameter   IDLE    = 5'b0_0001;
parameter   TX_S0   = 5'b0_0010;
parameter   TX_S1   = 5'b0_0100;
parameter   TX_S2   = 5'b0_1000;
parameter   TX_S3   = 5'b1_0000;
reg [4:0]   state;
reg FF;
always @(posedge sys_clk or negedge reset_n)
begin
    if(!reset_n)
    begin
        state<=IDLE;
        FF<=1'b1;
    end
    else
    begin
        case(state)
        IDLE:
            begin
                if(test)
                begin
                    state <= TX_S0;
                    FF<=1'b1;
                end
                else
                begin
                    state <= IDLE;
                    FF<=1'b1;
                end
            end
        TX_S0:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= 8'hc2;
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= TX_S1;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        TX_S1:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= 8'hb3;
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= TX_S2;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        TX_S2:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= 8'ha4;
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= TX_S3;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        TX_S3:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= 8'h95;
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= IDLE;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        default:
            begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
