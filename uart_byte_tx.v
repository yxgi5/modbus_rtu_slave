`timescale 1ns / 1ns
`define UD #1

module uart_byte_tx #
(
    parameter       CLK_FREQ   = 'd50000000,// 50MHz
    parameter       BAUD_RATE  = 'd9600    //
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

//start 8bit_data transfer operation
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
        else if(tx_done)
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
        if(baud_rate_cnt == 16'd1 )
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

reg [7:0] tx_data_r;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
	    tx_data_r <= 8'b0;
    end
    else
    begin
        if(tx_start_pos)
        begin
	        tx_data_r <= tx_data;
        end
        else
        begin
	        tx_data_r <= tx_data_r;
        end
    end
end

always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
	    rs232_tx <= 1'b1;
    end
    else begin
	    case(bps_cnt)
		    0:rs232_tx  <= 1'b1;            // idle hi

		    1:rs232_tx  <= START_BIT;       // start bit lo
		    2:rs232_tx  <= tx_data_r[0];    // LSB first
		    3:rs232_tx  <= tx_data_r[1];    //
		    4:rs232_tx  <= tx_data_r[2];    //
		    5:rs232_tx  <= tx_data_r[3];    //
		    6:rs232_tx  <= tx_data_r[4];    //
		    7:rs232_tx  <= tx_data_r[5];    //
		    8:rs232_tx  <= tx_data_r[6];    //
		    9:rs232_tx  <= tx_data_r[7];    // MSB last
                                            // No parity
		    10:rs232_tx <= STOP_BIT;        // stop bit hi

		    default:rs232_tx <= 1'b1;       // idle hi
	    endcase
    end
end	

endmodule
