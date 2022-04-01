// clk_div_5_5_tb.v
// Testbench

`timescale 1ns/ 1ns
//`define CheckByteNum 6000
//`ifndef xx
//`define xx yy // or parameter xx = yy;
//`endif
//`undef XX

module DPRAM_tb();

reg     clka;   // 180MHz sampling clock
reg     clkb;
reg     ena;
reg     enb;
reg     wea;
reg     web;


parameter A_WIDTH = 4;
parameter D_WIDTH = 16;

reg  [A_WIDTH-1:0]   addra;
reg  [A_WIDTH-1:0]   addrb;
reg  [D_WIDTH-1:0]   dia;
reg  [D_WIDTH-1:0]   dib;
wire [D_WIDTH-1:0]   doa;
wire [D_WIDTH-1:0]   dob;

DPRAM
#(
    .A_WIDTH    (A_WIDTH),
    .D_WIDTH    (D_WIDTH)
)UUT
(
    .CLKA        (clka),
    .CLKB        (clkb),
    .ENA         (ena),
    .ENB         (enb),
    .WEA         (wea),
    .WEB         (web),
    .ADDRA       (addra),
    .ADDRB       (addrb),
    .DIA         (dia),
    .DIB         (dib),
    .DOA         (doa),
    .DOB         (dob)
);

initial
begin
    clka = 1'b1;
    clkb = 1'b1;
    ena = 1'b1;
    enb = 1'b1;
    wea = 1'b0;
    web = 1'b0;
    addra = 4'b0;
    addrb = 4'b0;
    dia = 16'h0000;
    dib = 16'h0000;

// A向地址2写0x1235
    #(10*15 - 6);
    wea = 1'b1;
    addra = 4'b0010;
    dia = 16'h1235;
    
    #30;
    #30;
    wea = 1'b0;
    addra = 4'b0000;
    dia = 16'h0000;

// B向地址3写0xc1a1
    web = 1'b1;
    addrb = 4'b0011;
    dib = 16'hc1a1;
    #30;
    #30;
    web = 1'b0;
    addrb = 4'b0000;
    dib = 16'h00;
    #30;
    #30;
    #30;
    #30;
    #30;
    #30;
    #30;
    #30;
    #30;

// A读地址3
    wea = 1'b0;
    addra = 4'b0011;
    dia = 16'h0000;
    #30;
    #30;
    wea = 1'b0;
    addra = 4'b0000;
    dia = 16'h0000;
    #30;
    #30;
    #30;
    #30;
    #30;
    #30;

end

always
begin
    #15 clka = ~clka;
end
always
begin
    #22 clkb = ~clkb;
end

endmodule


