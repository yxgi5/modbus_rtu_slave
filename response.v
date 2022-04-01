`timescale 1ns / 1ns
`define UD #1

module response
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low
    
    input               tx_start,
    input   [7:0]       func_code,
    input   [7:0]       tx_quantity,
    input   [15:0]      tx_data,
    
    output  reg [7:0]   tx_addr,
    
    output  reg         response_done,
    output  wire        rs485_tx,
    output  reg         rs485_tx_en
);

reg tx_start_r0;
reg tx_start_r1;
wire tx_start_pos;
always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        tx_start_r0 <= 1'b0;
        tx_start_r1 <= 1'b0;
    end
    else
    begin
        tx_start_r1 <= tx_start_r0;
        tx_start_r0 <= tx_start;
    end
end
assign tx_start_pos = ~tx_start_r1&tx_start_r0;

reg [1:0] tx_state;
reg FF;
reg [7:0]   rs485_tx_data;
reg         rs485_tx_start;
wire tx_done;
always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        tx_state <= 2'b0;
        FF <= 1'b1;
        tx_addr <= 8'h0;
        rs485_tx_data <= 8'h0;
        rs485_tx_start <= 1'b0;
        response_done <= 1'b0;
    end
    else
    begin
        case(tx_state)
        2'd0:
        begin
            if(tx_start_pos)
            begin
                tx_state <= 2'd1;
                FF <= 1'b1;
                tx_addr <= 8'h0;
                tx_addr <= 8'h0;
                rs485_tx_data <= 8'h0;
                rs485_tx_start <= 1'b0;
                response_done <= 1'b0;
            end
            else
            begin
                tx_state <= 2'd0;
                FF <= 1'b1;
                tx_addr <= 8'h0;
                rs485_tx_data <= 8'h0;
                rs485_tx_start <= 1'b0;
                response_done <= 1'b0;
            end
        end
        
        2'd1:
        begin
            if(FF)
            begin
                if(tx_addr < tx_quantity)
                begin
                    //rs485_tx_data <= tx_data[15:8];
                    rs485_tx_start <= 1'b0;
                    FF <= 1'b0;
                end
                else
                begin
                    response_done <= 1'b1;
                    tx_state <= 2'd0;
                    FF <= 1'b1;
                end
            end
            else
            begin
                rs485_tx_data <= tx_data[15:8];
                //rs485_tx_start <= 1'b1;
                tx_state <= 2'd2;
                FF <= 1'b1;
            end
        end
        
        2'd2:
        begin
            if(FF)
            begin
                rs485_tx_start <= 1'b1;
                FF <= 1'b0;
            end
            else
            begin
                if(tx_done)
                begin
                    tx_state <= 2'd3;
                    FF <= 1'b1;
                end
                else
                begin
                    rs485_tx_start <= 1'b0;
                    FF <= 1'b1;
                end
            end
        end
        
        2'd3:
        begin
            if(FF)
            begin
                if(tx_addr < tx_quantity)
                begin
                    rs485_tx_data <= tx_data[7:0];
                    rs485_tx_start <= 1'b1;
                    FF <= 1'b0;
                end
            end
            else
            begin
                rs485_tx_start <= 1'b0;
                if(tx_done)
                begin
                    if(tx_addr < tx_quantity)
                    begin
                        tx_addr <= tx_addr + 1'b1;
                        tx_state <= 2'd1;
                    end
                    else
                    begin
                        tx_state <= 2'd0;
                    end
                    FF <= 1'b1;
                end
            end
        end
        
        default:
        begin
            tx_state <= 2'd0;
            FF <= 1'b1;
            tx_addr <= 8'h0;
            rs485_tx_data <= 8'h0;
            rs485_tx_start <= 1'b0;
            response_done <= 1'b0;
        end
        
        endcase
    end
end

uart_byte_tx #
(
    .CLK_FREQ       ('d50000000     ),  // 50MHz system clock
    .BAUD_RATE      ('d115200       )
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