`timescale 1ns / 1ns
`define UD #1

module frame_rx #
(
    parameter           ADDR = 8'h01
)
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low

    input               rx_drop_frame,  // 1.5T interval
    input               rx_new_frame,   // 3.5T interval
    input               rx_done,        // 
    input   [7:0]       rx_data,        //

    output  reg         rx_message_done,
    output  reg [7:0]   func_code,
    output  reg [15:0]  addr,
    output  reg [15:0]  data,
    output  reg [15:0]  crc_rx_code
);


reg rx_message_sig;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
        rx_message_sig <= `UD 1'b1;
    end
    else
    begin
        if(rx_new_frame)
        begin
            rx_message_sig <= `UD 1'b1;
        end
        else if(rx_done)
        begin
            rx_message_sig <= `UD 1'b0;
        end
    end
end


reg [6:0] i;
//reg rx_message_done;
//reg [7:0] func_code;
//reg [15:0] addr;
//reg [15:0] data;
//reg [15:0] crc_rx_code;
always@(posedge clk_in or negedge rst_n_in)
begin
    if(!rst_n_in)
    begin
        i <= `UD 7'd0;
        rx_message_done <= `UD 1'b0;
        func_code <= `UD 8'b0;
        addr <= `UD 16'b0;
        data <= `UD 16'b0;
        crc_rx_code <= `UD 16'b0;
    end
    else
    begin
        case(i)
        7'd0 : 
        begin
            if( rx_message_sig & rx_done )
                i <= `UD 7'd1;
            else if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                rx_message_done <= `UD 1'b0;
                func_code <= `UD 8'b0;
                addr <= `UD 16'b0;
                data <= `UD 16'b0;
                crc_rx_code <= `UD 16'b0;
            end
            else
                i <= `UD 7'd0;
        end 
        7'd1 :
        begin
            if( rx_drop_frame )
                i <= `UD 7'd0;
            else if( rx_data == ADDR )
              i <= `UD 7'd2;
            else 
              i <= `UD 7'd0;
        end
        7'd2 :
        begin
            if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                func_code <= `UD 8'b0;
            end
            else if( rx_done )                
            begin
               func_code <= `UD rx_data;
               i <= `UD 7'd3;
            end 
            else 
                i <= `UD 7'd2; 
        end
        7'd3 :
        begin
            if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                addr[15:0] <= `UD 16'b0;
            end
            else if( rx_done )
            begin
                addr[15:8] <= `UD rx_data;
                i <= `UD 7'd4;
            end 
            else 
                i <= `UD 7'd3;
        end
        7'd4 :  
        begin
            if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                addr[15:0] <= `UD 16'b0;
            end
            else if( rx_done )
            begin
                addr[7:0] <= `UD rx_data;
                i <= `UD 7'd5;
            end 
            else 
                i <= `UD 7'd4;
        end
        7'd5 :
        begin
            if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                data[15:0] <= `UD 16'b0;
            end
            else if( rx_done )
            begin
                data[15:8] <= `UD rx_data;
                i <= `UD 7'd6;
            end 
            else
                i <= `UD 7'd5;
        end
        7'd6 :
        begin
            if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                data[15:0] <= `UD 16'b0;
            end
            else if( rx_done )
            begin
                data[7:0] <= `UD rx_data;
                i <= `UD 7'd7;
            end 
            else
                i <= `UD 7'd6;
        end
        7'd7 :
        begin
            if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                crc_rx_code[15:0] <= `UD 16'b0;
            end
            else if( rx_done )
            begin
                crc_rx_code[15:8] <= `UD rx_data;
                i <= `UD 7'd8;
            end 
            else 
                i <= `UD 7'd7;   
        end
        7'd8 :
        begin
            if( rx_drop_frame )
            begin
                i <= `UD 7'd0;
                crc_rx_code[15:0] <= `UD 16'b0;
            end
            else if( rx_done )
            begin
                crc_rx_code[7:0] <= `UD rx_data;
                i <= `UD 7'd9;
            end 
            else 
                i <= `UD 7'd8;
        end
        7'd9 :
        begin
            rx_message_done <= `UD 1'b1;
            i <= `UD 7'd10;
        end
        7'd10 :
        begin
            rx_message_done <= `UD 1'b0;
            i <= `UD 7'd0;
        end 

        default;
        endcase
    end
end

endmodule
