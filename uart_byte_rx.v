`timescale 1ns / 1ns
`define UD #1

module uart_byte_rx #
(
    parameter           CLK_FREQ   = 'd50000000,// 50MHz
    parameter           BAUD_RATE  = 'd9600    //
)
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low

    output  reg [7:0]   rx_data,		// data need to transfer
    output  reg         rx_state,       // recieving duration
    output	reg         rx_done,        // pos-pulse for 1 tick indicates 1 byte transfer done
    output	reg		    rs232_rx		// uart transfer pin
);

localparam BPS_PARAM = CLK_FREQ/BAUD_RATE;

reg	rs232_rx0,rs232_rx1,rs232_rx2;	
//Detect negedge of rs232_rx
always @ (posedge clk_in or negedge rst_n_in) begin
	if(!rst_n_in) begin
		rs232_rx0 <= 1'b0;
		rs232_rx1 <= 1'b0;
		rs232_rx2 <= 1'b0;
	end else begin
		rs232_rx0 <= rs232_rx;
		rs232_rx1 <= rs232_rx0;
		rs232_rx2 <= rs232_rx1;
	end
end

wire	neg_rs232_rx = rs232_rx2 & rs232_rx1 & (~rs232_rx0) & (~rs232_rx);	

always@(posedge clk_in or negedge rst_n_in)
begin
	if(!rst_n_in)
    begin
		rx_state <= 1'b0;
    end
	else
    begin
        if(neg_rs232_rx)
        begin
            rx_state <= 1'b1;
        end
	    else if(rx_done) // TODO: fixme
        begin
		    rx_state <= 1'b0;
        end
	    else
        begin
		    rx_state <= rx_state;
        end
    end
end


endmodule
