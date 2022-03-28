`timescale 1ns / 1ns
`define UD #1

module ct_35t_gen #
(
    parameter           CLK_FREQ   = 'd50000000,// 50MHz
    parameter           BAUD_RATE  = 'd9600    //
)
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low

    input               rx_done,        // pos-pulse for 1 tick indicates 1 byte transfer done

    output  reg         rx_new_frame       // if intervel >3.5T == 1
);


endmodule
