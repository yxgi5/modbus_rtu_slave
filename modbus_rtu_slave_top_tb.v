`timescale 1ns / 1ns
`define clk_period 20

module modbus_rtu_slave_top_tb;

reg sys_clk;
reg reset_n;

wire rs485_rx;
wire rs485_tx;
wire rs485_oe;

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
    .rs232_tx       (rs485_rx       )	// uart transfer pin
);

wire    [15:0]  reg_03_01_o;
wire            reg_03_01_update;
wire            response_done;
modbus_rtu_slave_top #
(
    .CLK_FREQ       ('d50000000     ),  // 50MHz system clock
    .BAUD_RATE      ('d115200       ),
    .SADDR          (8'h01          )
)modbus_rtu_slave_top_inst0
(
    .clk_in                 (sys_clk            ),			// system clock
    .rst_n_in               (reset_n            ),		// system reset, active low
    
    .read_04_01             (16'h5347           ),
    .read_04_02             (16'h7414           ),
    .read_04_03             (16'h2021           ),
    .read_04_04             (16'h0402           ),

    .reg_03_01_o            (reg_03_01_o        ),
    .reg_03_01_update       (reg_03_01_update   ),
    
    .rs485_rx               (rs485_rx           ),
    .rs485_tx               (rs485_tx           ),
    .rs485_oe               (rs485_oe           ),
    
    .response_done          (response_done      )
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

    @(posedge response_done)
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
    
    @(posedge response_done)
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
    
    @(posedge response_done)
    #(`clk_period*20000)
    FRAME[0] = 8'h01;
    FRAME[1] = 8'h06;
    FRAME[2] = 8'h00;
    FRAME[3] = 8'h01;
    FRAME[4] = 8'h00;
    FRAME[5] = 8'h03;
    FRAME[6] = 8'h98;
    FRAME[7] = 8'h0b;
    test = 1;
    #(`clk_period*1)
    test = 0;
    
    @(posedge response_done)
    #(`clk_period*20000)
    FRAME[0] = 8'h01;
    FRAME[1] = 8'h06;
    FRAME[2] = 8'h00;
    FRAME[3] = 8'h01;
    FRAME[4] = 8'h00;
    FRAME[5] = 8'h07;
    FRAME[6] = 8'h99;
    FRAME[7] = 8'hc8;
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