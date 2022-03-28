`timescale 1ns / 1ns
`define UD #1

module uart_byte_tx #
(
    parameter       CLK_FREQ   = 'd50000000, // 50MHz
    parameter       BAUD_RATE  = 'd9600,
    parameter       SLICE_MODE = 1'b0
)
(
    input           clk_in,			// system clock
    input           rst_n_in,		// system reset, active low

    input           tx_start,       // start transfer with pos edge
    input   [7:0]	tx_data,		// data need to transfer

    output  reg     tx_state,       // sending duration
    output	reg     tx_done,        // pos-pulse for 1 tick indicates 1 byte transfer done
    output	reg		rs232_tx		// uart transfer pin
);


localparam START_BIT = 1'b0;
localparam STOP_BIT = 1'b1;
localparam BPS_PARAM = CLK_FREQ/BAUD_RATE;

reg tx_start_r;
wire tx_start_pos;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
        tx_start_r <= `UD 1'b0;
    end
    else
    begin
        tx_start_r <= `UD tx_start;
    end
end
assign tx_start_pos = ~tx_start_r & tx_start;

always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
	    tx_state <= 1'b0;
    end
    else 
    begin
        if(tx_start_pos)
        begin
	        tx_state <= 1'b1;
        end
        else if(tx_done)        // TODO: fixme
        begin
	        tx_state <= 1'b0;
        end
        else
        begin
	        tx_state <= tx_state;
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
        if(tx_state)
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
		bps_clk <= 1'b0;
    end
	else
    begin
        if(baud_rate_cnt == (SLICE_MODE ? (BPS_PARAM>>1) : 16'd1) )  // 0.5T or 0T
        begin
		    bps_clk <= 1'b1;	
        end
	    else 
        begin
		    bps_clk <= 1'b0;
        end
    end
end

//bps counter
reg [3:0] bps_cnt;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)	
    begin
	    bps_cnt <= 4'd0;
    end
    else
    begin
        if(tx_done)
        begin
	        bps_cnt <= 4'd0;
        end
        else if(bps_clk)
        begin
	        bps_cnt <= bps_cnt + 1'b1;
        end
        else
        begin
	        bps_cnt <= bps_cnt;
        end
    end
end

always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
	    tx_done <= 1'b0;
    end
    else if(bps_cnt == 4'd11)
    begin
	    tx_done <= 1'b1;
    end
    else
    begin
	    tx_done <= 1'b0;
    end
end

endmodule
