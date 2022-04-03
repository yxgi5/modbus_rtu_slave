`timescale 1ns / 1ns
`define UD #1

module modbus_rtu_slave_top #
(
    parameter           CLK_FREQ   = 'd50000000, // 50MHz
    parameter           BAUD_RATE  = 'd115200,    //
    parameter           SADDR      = 8'h01
)
(
    input                   clk_in,			// system clock
    input                   rst_n_in,		// system reset, active low
    
    input   [15:0]          read_04_01,
    input   [15:0]          read_04_02,
    input   [15:0]          read_04_03,
    input   [15:0]          read_04_04,
    
    output  wire    [15:0]  reg_03_01_o,
    output  wire            reg_03_01_update,
    
    input                   rs485_rx,
    output  wire            rs485_tx,
    output  wire            rs485_oe,
    
    output  wire            response_done   // for debug
);

wire [7:0] rx_data;
wire rx_done;
wire rx_state;

uart_byte_rx #
(
    .CLK_FREQ       (CLK_FREQ       ),  // 50MHz system clock
    .BAUD_RATE      (BAUD_RATE      )
)uart_byte_rx_inst0
(
    .clk_in         (clk_in         ),  // system clock
    .rst_n_in       (rst_n_in       ),  // system reset, active low
    .rx_data        (rx_data        ),	// data need to transfer
    .rx_done        (rx_done        ),  // transfer done
    .rx_state       (rx_state       ),  // sending duration
    .rs232_rx       (rs485_rx		)	// uart transfer pin
);

wire rx_new_frame;
ct_35t_gen #
(
    .CLK_FREQ       (CLK_FREQ       ),  // 50MHz system clock
    .BAUD_RATE      (BAUD_RATE      )
)ct_35t_gen_inst0
(
    .clk_in         (clk_in         ),  // system clock
    .rst_n_in       (rst_n_in       ),  // system reset, active low
    .rx_done        (rx_done        ),  // transfer done
    .rx_state       (rx_state       ),  // sending duration
    .rx_new_frame   (rx_new_frame   )
);

wire rx_drop_frame;
ct_15t_gen #
(
    .CLK_FREQ       (CLK_FREQ       ),  // 50MHz system clock
    .BAUD_RATE      (BAUD_RATE      )
)ct_15t_gen_inst0
(
    .clk_in         (clk_in         ),  // system clock
    .rst_n_in       (rst_n_in       ),  // system reset, active low
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
    .ADDR           (SADDR          )
)frame_rx_inst0
(
    .clk_in         (clk_in         ), // system clock
    .rst_n_in       (rst_n_in       ), // system reset, active low
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
    .clk_in         (clk_in         ), // system clock
    .rst_n_in       (rst_n_in       ), // system reset, active low
    .data_in        ({data[7:0],data[15:8],addr[7:0],addr[15:8],func_code,SADDR}),
    .rx_message_done(rx_message_done),
    .crc_done       (crc_done       ),
    .crc_out        (crc_rx_calc    )
);

wire    exception_done;
wire    [7:0]   exception;
exceptions exceptions_inst0
(
    .clk_in         (clk_in         ), // system clock
    .rst_n_in       (rst_n_in       ), // system reset, active low
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
wire [7:0]   exception_out;
wire [7:0]   func_code_r;
wire [15:0]  addr_r;
wire [15:0]  data_r;
wire [15:0]  crc_rx_code_r;
wire         reg_wen;
wire [15:0]  reg_wdat;
reg          reg_w_done;
reg          reg_w_status;
reg [15:0]   read_03_01_r;
func_hander #
(
    .SADDR          (SADDR          )
)func_handler_inst0
(
    .clk_in         (clk_in         ), // system clock
    .rst_n_in       (rst_n_in       ), // system reset, active low
    .rx_message_done(rx_message_done),
    .func_code      (func_code      ),
    .addr           (addr           ),
    .data           (data           ),
    .crc_rx_code    (crc_rx_code    ),
    .exception_done (exception_done ),
    .exception_in   (exception      ),
    .read_03_01     (read_03_01_r   ),  // TODO:
    .read_04_01     (read_04_01     ),
    .read_04_02     (read_04_02     ),
    .read_04_03     (read_04_03     ),
    .read_04_04     (read_04_04     ),
    .tx_quantity    (tx_quantity    ),
    .func_code_r    (func_code_r    ),
    .addr_r         (addr_r         ),
    .data_r         (data_r         ),
    .crc_rx_code_r  (crc_rx_code_r  ),
    .exception_out  (exception_out  ),
    .dpram_wen      (wea            ),
    .dpram_addr     (addra          ),
    .dpram_wdata    (dia            ),
    .reg_wen        (reg_wen        ),
    .reg_wdat       (reg_wdat       ),
    .reg_w_done     (reg_w_done     ),
    .reg_w_status   (reg_w_status   ),
    .handler_done   (handler_done   )
);


always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        read_03_01_r <= `UD 16'h0;// modify if needed
        reg_w_done <= `UD 1'b0;
        reg_w_status <= `UD 1'b0;
    end
    else
    begin
        if(reg_wen)
        begin
            read_03_01_r <= `UD reg_wdat;
            reg_w_done <= `UD 1'b1;
            reg_w_status <= `UD 1'b0;
        end
        else
        begin
            read_03_01_r <= `UD read_03_01_r;
            reg_w_done <= `UD 1'b0;
            reg_w_status <= `UD 1'b0;
        end
    end
end
assign reg_03_01_o = read_03_01_r;
assign reg_03_01_update = reg_w_done;

wire [15:0] tx_data_b;
wire [7:0]  tx_addr;
DPRAM
#(
    .A_WIDTH    ('d8),
    .D_WIDTH    ('d16)
)DPRAM_inst0
(
    .CLKA        (clk_in),
    .CLKB        (clk_in),
    .ENA         (1'd1),
    .ENB         (1'd1),
    .WEA         (wea),
    .WEB         (1'd0),
    .ADDRA       (addra),
    .ADDRB       (tx_addr),
    .DIA         (dia),
    .DIB         (16'b0),
    .DOA         (),
    .DOB         (tx_data_b)
);

wire        tx485_start;
wire    [39:0]      exception_seq;
wire    [63:0]      code06_response;
tx_handler #
(
    .SADDR          (SADDR          )
)tx_handler_inst0
(
    .clk_in         (clk_in         ), // system clock
    .rst_n_in       (rst_n_in       ), // system reset, active low
    
    .handler_done   (handler_done   ),
    .exception      (exception_out  ),
    
    .func_code      (func_code_r    ),
    .addr           (addr_r         ),
    .data           (data_r         ),
    .crc_code       (crc_rx_code_r  ),
    
    .tx_quantity    (tx_quantity    ),
    
    .tx_start       (tx485_start    ),
    .exception_seq  (exception_seq  ),
    .code06_response(code06_response)
);

wire [7:0] rs485_tx_data;
tx_response #
(
    .CLK_FREQ       (CLK_FREQ       ),  // 50MHz system clock
    .BAUD_RATE      (BAUD_RATE      ),
    .SADDR          (SADDR          )
)tx_response_inst0
(
    .clk_in         (clk_in         ), // system clock
    .rst_n_in       (rst_n_in       ), // system reset, active low
    .tx_start       (tx485_start    ),
    .func_code      (func_code_r    ),
    .tx_quantity    (tx_quantity    ),
    .tx_data        (tx_data_b      ),
    .tx_addr        (tx_addr        ),
    
    .exception      (exception_out  ),
    .exception_seq  (exception_seq  ),
    
    .code06_response(code06_response),
    
    .rs485_tx_data  (rs485_tx_data  ),
    .response_done  (response_done  ),
    .rs485_tx       (rs485_tx       ),
    .rs485_tx_en    (rs485_oe       )
);
/*
always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        
    end
    else
    begin
        
    end
end
*/
endmodule