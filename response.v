`timescale 1ns / 1ns
`define UD #1

module response #
(
    parameter           CLK_FREQ   = 'd50000000,// 50MHz
    parameter           BAUD_RATE  = 'd9600    //
)
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low
    
    input               tx_start,
    input   [7:0]       func_code,
    input   [7:0]       tx_quantity,
    input   [15:0]      crc_code,
    input   [15:0]      tx_data,
    
    output  reg [7:0]   tx_addr,
    
    output  reg         response_done,
    output  wire        rs485_tx,
    output  reg         rs485_tx_en
);

localparam BPS_PARAM = (CLK_FREQ/BAUD_RATE);

reg tx_start_r0;
reg tx_start_r1;
wire tx_start_pos;
always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        tx_start_r0 <= `UD 1'b0;
        tx_start_r1 <= `UD 1'b0;
    end
    else
    begin
        tx_start_r1 <= `UD tx_start_r0;
        tx_start_r0 <= `UD tx_start;
    end
end
assign tx_start_pos = ~tx_start_r1&tx_start_r0;


reg [5:0] bps_cnt;
reg cnt_en;
reg response_done_r;

always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
        cnt_en <= `UD 1'b0;
    end
    else
    begin
        if(tx_start_pos||response_done_r)
        begin
            cnt_en <= `UD 1'b1;
        end
        else if(bps_cnt>=6'd10)
        begin
            cnt_en <= `UD 1'b0;
        end
    end
end

reg [15:0]  baud_rate_cnt;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
        baud_rate_cnt <= `UD 16'd0;
    end
    else
    begin
        if(cnt_en)
        begin
            if(baud_rate_cnt >= BPS_PARAM - 1)
            begin
                baud_rate_cnt <= `UD 16'd0;
            end
            else
            begin
                baud_rate_cnt <= `UD baud_rate_cnt + 1'b1;
            end
        end
        else
        begin
            baud_rate_cnt <= `UD 16'd0;
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
        if(baud_rate_cnt >= BPS_PARAM - 1 )
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
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)	
    begin
	    bps_cnt <= `UD 6'd0;
    end
    else
    begin
        if(bps_cnt>=6'd15)
        begin
	        bps_cnt <= `UD 6'd0;
        end
        else
        begin
            if(cnt_en)
            begin
                if(bps_clk)
                begin
	                bps_cnt <= `UD bps_cnt + 1'b1;
                end
                else
                begin
	                bps_cnt <= `UD bps_cnt;
                end
            end
            else
            begin
                bps_cnt <= `UD 6'd0;
            end
        end
    end
end

reg [2:0] tx_state;
reg FF;
reg [7:0]   rs485_tx_data;
reg         rs485_tx_start;
wire tx_done;
always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        tx_state <= `UD 2'b0;
        FF <= `UD 1'b1;
        tx_addr <= `UD 8'h0;
        rs485_tx_data <= `UD 8'h0;
        rs485_tx_start <= `UD 1'b0;
        response_done_r <= `UD 1'b0;
        rs485_tx_en <= `UD 1'b0;
        response_done <= `UD 1'b0;
    end
    else
    begin
        case(tx_state)
        3'd0:
        begin
            if(tx_start_pos)
            begin
                tx_state <= `UD 3'd1;
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
                rs485_tx_en <= `UD 1'b1;
            end
            else
            begin
                tx_state <= `UD 3'd0;
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
                response_done <= `UD 1'b0;
            end
        end
        
        3'd1:
        begin
            if(bps_cnt>=6'd10)
            begin
                tx_state <= `UD 3'd2;
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
            end
            else
            begin
                tx_state <= `UD 3'd1;
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
            end
        end
        
        3'd2:
        begin
            if(FF)
            begin
                if(tx_addr < tx_quantity)
                begin
                    //rs485_tx_data <= `UD tx_data[15:8];
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
                else
                begin
                    response_done_r <= `UD 1'b1;
                    tx_state <= `UD 3'd5;
                    FF <= `UD 1'b1;
                end
            end
            else
            begin
                rs485_tx_data <= `UD tx_data[15:8];
                //rs485_tx_start <= `UD 1'b1;
                tx_state <= `UD 3'd3;
                FF <= `UD 1'b1;
            end
        end
        
        3'd3:
        begin
            if(FF)
            begin
                rs485_tx_start <= `UD 1'b1;
                FF <= `UD 1'b0;
            end
            else
            begin
                if(tx_done)
                begin
                    tx_state <= `UD 3'd4;
                    FF <= `UD 1'b1;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        
        3'd4:
        begin
            if(FF)
            begin
                if(tx_addr < tx_quantity)
                begin
                    rs485_tx_data <= `UD tx_data[7:0];
                    rs485_tx_start <= `UD 1'b1;
                    FF <= `UD 1'b0;
                end
            end
            else
            begin
                rs485_tx_start <= `UD 1'b0;
                if(tx_done)
                begin
                    if(tx_addr < tx_quantity)
                    begin
                        tx_addr <= `UD tx_addr + 1'b1;
                        tx_state <= `UD 3'd2;
                    end
                    else
                    begin
                        tx_state <= `UD 3'd5;
                    end
                    FF <= `UD 1'b1;
                end
            end
        end
        
        3'd5:
        begin
            if(bps_cnt>=6'd10)
            begin
                tx_state <= `UD 3'd0;
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
                rs485_tx_en <= `UD 1'b0;
                response_done <= `UD 1'b1;
            end
            else
            begin
                tx_state <= `UD 3'd5;
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
            end
        end
        
        default:
        begin
            tx_state <= `UD 3'd0;
            FF <= `UD 1'b1;
            tx_addr <= `UD 8'h0;
            rs485_tx_data <= `UD 8'h0;
            rs485_tx_start <= `UD 1'b0;
            response_done_r <= `UD 1'b0;
        end
        
        endcase
    end
end

uart_byte_tx #
(
    .CLK_FREQ       (CLK_FREQ       ),  // 50MHz system clock
    .BAUD_RATE      (BAUD_RATE      )
)uart_byte_tx_inst0
(
    .clk_in         (clk_in         ),  // system clock
    .rst_n_in       (rst_n_in       ),  // system reset, active low
    .tx_start       (rs485_tx_start ),	// start with pos edge
    .tx_data        (rs485_tx_data  ),	// data need to transfer
    .tx_done        (tx_done        ),  // transfer done
    .tx_state       (               ),  // sending duration
    .rs232_tx       (rs485_tx		)	// uart transfer pin
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