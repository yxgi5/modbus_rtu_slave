`timescale 1ns / 1ns
`define UD #1

module tx_crc #
(
    parameter           SADDR   = 8'h01
)
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low
    
    input               crc_start,
    
    input   [7:0]       func_code,
    input   [7:0]       tx_quantity,
    input   [15:0]      tx_data,
    
    output  reg [7:0]   tx_addr,
    
    output  reg [15:0]  crc_calc,
    output  reg         crc_done
);

reg [7:0] index;
reg [7:0] data_buf;
reg [7:0] ct_frame;
reg [3:0] ct_8bit;
reg [7:0] i;
reg [15:0] crc_reg;
reg FF;
always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        i <= `UD 7'd0;                     
        crc_done <= `UD 1'b0;           //校验完成，输出一个周期高电平
        ct_frame <= `UD 8'd0;
        ct_8bit <= `UD 4'd0;
        crc_reg <= `UD 16'b0;
        crc_done <= `UD 1'b0;
        crc_calc <= `UD 16'b0;
        data_buf <= `UD {(8){1'b0}} ;
        FF <= `UD 1'b1;
        index <= `UD 8'd0;
        tx_addr <= `UD 8'd0;
    end
    else
    begin
        case ( i )
        7'd0 :
        begin
            ct_frame <= `UD 8'd0;
            ct_8bit <= `UD 4'd0;
            if( crc_start )
                i <= `UD 7'd1;
            else
                i <= `UD 7'd0; 
        end 
        7'd1 :
        begin
            ///data_buf <= `UD data_in; //
            //crc_reg <= `UD 16'hffff;
            //i <= `UD 7'd2;
            if(FF)
            begin
                FF <= `UD 1'b0;
                case(index)
                8'd0:
                begin
                    data_buf <= `UD SADDR;
                    index <= `UD index+1;
                end
                8'd1:
                begin
                    data_buf <= `UD func_code;
                    index <= `UD index+1;
                end
                8'd2:
                begin
                    data_buf <= tx_quantity;
                    index <= `UD index+1;
                end
                8'd3:
                begin
                    index <= `UD index+1;
                    if(tx_addr < tx_quantity)
                    begin
                        data_buf <= `UD tx_data[15:8];
                        
                    end
                    else
                    begin
                        data_buf <= `UD 8'b0;
                    end
                end
                8'd4:
                begin
                    if(tx_addr < tx_quantity)
                    begin
                        data_buf <= `UD tx_data[7:0];
                        index <= `UD index-1;
                    end
                    else
                    begin
                        data_buf <= `UD 8'b0;
                        index <= `UD 8'd0;
                    end
                end
                default;
                endcase
            end
            else
            begin
                crc_reg <= `UD 16'hffff;
                i <= `UD 7'd2;
                FF <= `UD 1'b1;
            end
        end
        7'd2 :
        begin
            if( ct_frame < 2*tx_quantity+3 )
            begin
                ct_8bit <= `UD 4'd0;
                ct_frame <= `UD ct_frame + 8'd1;
                crc_reg[7:0] <= `UD data_buf[7:0] ^ crc_reg[7:0];
                i <= `UD 7'd3; 
            end 
            else
                i <= `UD 7'd5;
        end 
        7'd3 :  
        begin
            if( ct_8bit < 4'd8 )
            begin
                ct_8bit <= `UD ct_8bit + 4'd1;
                if( crc_reg[0] )
                begin
                    crc_reg <= `UD crc_reg >> 1;
                    i <= `UD 7'd4;
                end
                else
                begin
                    crc_reg <= `UD crc_reg >> 1;
                    i <= `UD 7'd3;
                end
            end 
            else 
            begin
                // data_buf <= `UD data_buf >> 8; //
                i <= `UD 7'd2;
                case(index)
                8'd0:
                begin
                    data_buf <= `UD SADDR;
                    index <= `UD index+1;
                end
                8'd1:
                begin
                    data_buf <= `UD func_code;
                    index <= `UD index+1;
                end
                8'd2:
                begin
                    data_buf <= tx_quantity;
                    index <= `UD index+1;
                end
                8'd3:
                begin
                    index <= `UD index+1;
                    if(tx_addr < tx_quantity)
                    begin
                        data_buf <= `UD tx_data[15:8];
                    end
                    else
                    begin
                        tx_addr <= `UD 8'b0;
                        data_buf <= `UD 8'b0;
                    end
                end
                8'd4:
                begin
                    if(tx_addr < tx_quantity)
                    begin
                        tx_addr <= `UD tx_addr+1'b1;
                        data_buf <= `UD tx_data[7:0];
                        index <= `UD index-1;
                    end
                    else
                    begin
                        tx_addr <= `UD 8'b0;
                        data_buf <= `UD 8'b0;
                        index <= `UD 8'd0;
                    end
                end
                default;
                endcase
                
            end 
        end 
        7'd4 :
        begin
            i <= `UD 7'd3;
            crc_reg <= `UD crc_reg ^ 16'hA001;
        end 
        7'd5 :
        begin
            crc_calc <= `UD crc_reg;
            crc_done <= `UD 1'b1;
            i <= `UD 7'd6;
        end
        7'd6 :
        begin
            crc_done <= `UD 1'b0;
            i <= `UD 7'd0;
        end 
        default;
        endcase
    end
end


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