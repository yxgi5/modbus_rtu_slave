`timescale 1ns / 1ns
`define clk_period 20

module func_handler_tb;

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

wire rx_new_frame;
ct_35t_gen #
(
    .CLK_FREQ       ('d50000000     ),  // 50MHz system clock
    .BAUD_RATE      ('d115200       )
)ct_35t_gen_inst0
(
    .clk_in         (sys_clk        ),  // system clock
    .rst_n_in       (reset_n        ),  // system reset, active low
    .rx_done        (rx_done        ),  // transfer done
    .rx_state       (rx_state       ),  // sending duration
    .rx_new_frame   (rx_new_frame   )
);

wire rx_drop_frame;
ct_15t_gen #
(
    .CLK_FREQ       ('d50000000     ),  // 50MHz system clock
    .BAUD_RATE      ('d115200       )
)ct_15t_gen_inst0
(
    .clk_in         (sys_clk        ),  // system clock
    .rst_n_in       (reset_n        ),  // system reset, active low
    .rx_done        (rx_done        ),  // transfer done
    .rx_state       (rx_state       ),  // sending duration
    .rx_drop_frame  (rx_drop_frame  )
);

wire rx_message_done; 
wire [7:0] func_code;
wire [15:0] addr;
wire [15:0] data;
wire [15:0] crc_rx_code;
frame_rx #
(
    .ADDR           (8'h01          )
)frame_rx_inst0
(
    .clk_in         (sys_clk        ), // system clock
    .rst_n_in       (reset_n        ), // system reset, active low
    .rx_drop_frame  (rx_drop_frame  ), // 1.5T interval
    .rx_new_frame   (rx_new_frame   ), // 3.5T interval
    .rx_done        (rx_done        ), // 
    .rx_data        (rx_data        ), //
    .rx_message_done(rx_message_done),
    .func_code      (func_code      ),
    .addr           (addr           ),
    .data           (data           ),
    .crc_rx_code    (crc_rx_code    )
);

wire [15:0] crc_rx_calc;
modbus_crc modbus_crc_inst0
(
    .clk_in         (sys_clk        ), // system clock
    .rst_n_in       (reset_n        ), // system reset, active low
    .data_in        ({data[7:0],data[15:8],addr[7:0],addr[15:8],func_code,8'h01}),
    .rx_message_done(rx_message_done),
    .crc_done       (crc_done       ),
    .crc_out        (crc_rx_calc    )
);

wire    exception_done;
wire    [7:0]   exception;
exceptions exceptions_inst0
(
    .clk_in         (sys_clk        ), // system clock
    .rst_n_in       (reset_n        ), // system reset, active low
    .rx_message_done(rx_message_done),
    .func_code      (func_code      ),
    .addr           (addr           ),
    .data           (data           ),
    .crc_rx_code    (crc_rx_code    ),
    .crc_done       (crc_done       ),
    .crc_rx_calc    (crc_rx_calc    ),
    .exception_done (exception_done ),
    .exception      (exception      )
);

wire    handler_done;
wire [15:0]  dia;
wire         wea;
wire [7:0]   addra;
wire [7:0]   tx_quantity;
//wire         tx485_start;
wire [7:0]   exception_out;
wire [7:0]   func_code_r;
wire [15:0]  addr_r;
wire [15:0]  data_r;
wire [15:0]  crc_rx_code_r;
func_hander #
(
    .SADDR           (8'h01          )
)func_handler_inst0
(
    .clk_in         (sys_clk        ), // system clock
    .rst_n_in       (reset_n        ), // system reset, active low
    .rx_message_done(rx_message_done),
    .func_code      (func_code      ),
    .addr           (addr           ),
    .data           (data           ),
    .crc_rx_code    (crc_rx_code    ),
    .exception_done (exception_done ),
    .exception_in   (exception      ),
    .read_03_01     (16'h0451       ),
    .read_04_01     (16'h5347       ),
    .read_04_02     (16'h7414       ),
    .read_04_03     (16'h2021       ),
    .read_04_04     (16'h0402       ),
    .tx_quantity    (tx_quantity    ),
//    .tx_start       (tx485_start    ),
    .func_code_r    (func_code_r    ),
    .addr_r         (addr_r         ),
    .data_r         (data_r         ),
    .crc_rx_code_r  (crc_rx_code_r  ),
    .exception_out  (exception_out  ),
    .dpram_wen      (wea            ),
    .dpram_addr     (addra          ),
    .dpram_wdata    (dia            ),
    .handler_done   (handler_done   )
);

DPRAM
#(
    .A_WIDTH    ('d8),
    .D_WIDTH    ('d16)
)DPRAM_inst0
(
    .CLKA        (sys_clk),
    .CLKB        (sys_clk),
    .ENA         (1'd1),
    .ENB         (1'd1),
    .WEA         (wea),
    .WEB         (1'd0),
    .ADDRA       (addra),
    .ADDRB       (),
    .DIA         (dia),
    .DIB         (16'b0),
    .DOA         (),
    .DOB         ()
);

initial sys_clk = 1;
always #(`clk_period/2) sys_clk = ~sys_clk;

initial reset_n = 0;
always #(`clk_period*50) reset_n = 1'b1;

reg [7:0]  FRAME   [0:7];
reg TT;
initial
begin
    tx_start = 0;
    tx_data = 8'h0;
    test = 0;
    
    #(`clk_period*50)
    FRAME[0] = 8'h01;
    FRAME[1] = 8'h03;
    FRAME[2] = 8'h00;
    FRAME[3] = 8'h01;
    FRAME[4] = 8'h00;
    FRAME[5] = 8'h01;
    FRAME[6] = 8'hd5;
    FRAME[7] = 8'hca;
    test = 1;
    #(`clk_period*1)
    test = 0;

    @(posedge TT)
    #(`clk_period*20000)
//    FRAME[0] = 8'h01;
//    FRAME[1] = 8'h06;
//    FRAME[2] = 8'h00;
//    FRAME[3] = 8'h01;
//    FRAME[4] = 8'h00;
//    FRAME[5] = 8'h05;
//    FRAME[6] = 8'h18;
//    FRAME[7] = 8'h09;
    FRAME[0] = 8'h01;
    FRAME[1] = 8'h06;
    FRAME[2] = 8'h00;
    FRAME[3] = 8'h02; // illegal
    FRAME[4] = 8'h00;
    FRAME[5] = 8'h05;
    FRAME[6] = 8'he8;
    FRAME[7] = 8'h09;
    test = 1;
    #(`clk_period*1)
    test = 0;
    
    @(posedge TT)
    #(`clk_period*20000)
    FRAME[0] = 8'h01;
    FRAME[1] = 8'h04;
    FRAME[2] = 8'h00;
    FRAME[3] = 8'h01;
    FRAME[4] = 8'h00;
    FRAME[5] = 8'h04;
    FRAME[6] = 8'ha0;
    FRAME[7] = 8'h09;
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

parameter   IDLE    = 8'b0000_0000;
parameter   TX_S0   = 8'b0000_0001;
parameter   TX_S1   = 8'b0000_0010;
parameter   TX_S2   = 8'b0000_0100;
parameter   TX_S3   = 8'b0000_1000;
parameter   TX_S4   = 8'b0001_0000;
parameter   TX_S5   = 8'b0010_0000;
parameter   TX_S6   = 8'b0100_0000;
parameter   TX_S7   = 8'b1000_0000;
reg [7:0]   state;
reg FF;

always @(posedge sys_clk or negedge reset_n)
begin
    if(!reset_n)
    begin
        state<=IDLE;
        FF<=1'b1;
        TT<=1'b0;
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
                    TT<=1'b0;
                end
                else
                begin
                    state <= IDLE;
                    FF<=1'b1;
                    TT<=1'b0;
                end
            end
        TX_S0:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= FRAME[0];
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
                    tx_data <= FRAME[1];
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
                    tx_data <= FRAME[2];
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
                    tx_data <= FRAME[3];
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= TX_S4;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        TX_S4:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= FRAME[4];
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= TX_S5;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        TX_S5:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= FRAME[5];
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= TX_S6;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        TX_S6:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= FRAME[6];
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= TX_S7;
                    FF<=1'b1;
                end
                else
                begin
                    tx_start <= 1'b0;
                end
            end
        TX_S7:
            begin
                if(FF)
                begin
                    tx_start <= 1'b1;
                    tx_data <= FRAME[7];
                    FF<=1'b0;
                end
                else if(tx_done)
                begin
                    state <= IDLE;
                    FF<=1'b1;
                    TT<=1'b1;
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