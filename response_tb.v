`timescale 1ns / 1ns
`define clk_period 20

module response_tb;

reg sys_clk;
reg reset_n;

wire rs485_tx;
wire rs485_tx_en;

reg tx_start;
wire [15:0] tx_data;
wire [7:0] tx_addr;
wire response_done;
response
#(
    .CLK_FREQ       ('d50000000     ),
    .BAUD_RATE      ('d115200       )
)response_inst0
(
    .clk_in         (sys_clk        ),  // system clock
    .rst_n_in       (reset_n        ),  // system reset, active low
    .tx_start       (tx_start       ),
    .func_code      (8'h04          ),
    .tx_quantity    (8'h04          ),
    .tx_data        (tx_data        ),
    .tx_addr        (tx_addr        ),
    .response_done  (response_done  ),
    .rs485_tx       (rs485_tx       ),
    .rs485_tx_en    (rs485_tx_en    )
);


reg [15:0]  dia;
reg         wea;
reg [7:0]   addra;
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
    .ADDRB       (tx_addr),
    .DIA         (dia),
    .DIB         (16'b0),
    .DOA         (),
    .DOB         (tx_data)
);

initial sys_clk = 1;
always #(`clk_period/2) sys_clk = ~sys_clk;

initial reset_n = 0;
always #(`clk_period*50) reset_n = 1'b1;


initial
begin
    wea = 1'b0;
    addra = 8'b0;
    dia = 16'h0000;
    tx_start = 1'b0;
    
    #(`clk_period*50)
    wea = 1'b1;
    addra = 8'h00;
    dia = 16'h1235;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h01;
    dia = 16'h2351;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h02;
    dia = 16'h3516;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h03;
    dia = 16'haaaa;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h04;
    dia = 16'h5555;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h05;
    dia = 16'h7654;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h06;
    dia = 16'h4567;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h07;
    dia = 16'h9776;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h08;
    dia = 16'h1235;
    #(`clk_period*1)
    wea = 1'b1;
    addra = 8'h09;
    dia = 16'h4782;
    
    #(`clk_period*15)
    tx_start = 1'b1;
    #(`clk_period*1)
    tx_start = 1'b0;
end


endmodule