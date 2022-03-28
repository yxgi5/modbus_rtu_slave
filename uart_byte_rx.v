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
    input		        rs232_rx		// uart transfer pin
);

localparam BPS_PARAM = (CLK_FREQ/BAUD_RATE)>>4; // oversample by x16

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

reg [15:0]  baud_rate_cnt;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
        baud_rate_cnt <= 16'd0;
    end
    else
    begin
        if(rx_state)
        begin
            if(baud_rate_cnt >= BPS_PARAM - 1)
            begin
                baud_rate_cnt <= 16'd0;
            end
            else
            begin
                baud_rate_cnt <= baud_rate_cnt + 1'b1;
            end
        end
        else
        begin
            baud_rate_cnt <= 16'd0;
        end
    end
end
    
// generate bps_clk signal
reg bps_clk;
always @ (posedge clk_in or negedge rst_n_in)
begin
	if(!rst_n_in) 
    begin
		bps_clk <= `UD 1'b0;
    end
	else
    begin
        if(baud_rate_cnt == 16'd1 )
        begin
		    bps_clk <= `UD 1'b1;	
        end
	    else 
        begin
		    bps_clk <= `UD 1'b0;
        end
    end
end

//bps counter
reg [7:0] bps_cnt;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)	
    begin
	    bps_cnt <= `UD 8'd0;
    end
    else
    begin
        if(bps_cnt>=8'd160-8'd1)        // TODO: fixme
        begin
	        bps_cnt <= `UD 4'd0;
        end
        else if(bps_clk)
        begin
	        bps_cnt <= `UD bps_cnt + 1'b1;
        end
        else
        begin
	        bps_cnt <= `UD bps_cnt;
        end
    end
end

always@(posedge clk_in or negedge rst_n_in)
begin
	if(!rst_n_in)
    begin
		rx_done <= 1'b0;
    end
	else
    begin
        if(bps_cnt == 8'd159)
        begin
		    rx_done <= 1'b1;
        end
	    else
        begin
		    rx_done <= 1'b0;
        end
    end
end

endmodule
