`timescale 1ns / 1ns
`define UD #1

module exceptions
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low
    
    input               rx_message_done,
    input   [7:0]       func_code,
    input   [15:0]      addr,
    input   [15:0]      data,
    input   [15:0]      crc_rx_code,
    
    input               crc_done,
    input   [15:0]      crc_rx_calc,
    
    output  reg         exception_done,
    output  reg [7:0]   exception
);

reg [7:0]   func_code_r;
reg [15:0]  addr_r;
reg [15:0]  data_r;
reg [15:0]  crc_rx_code_r;
reg [15:0]  crc_rx_calc_r;
reg         crc_done_r;
reg         exception_done_r;

always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        crc_done_r <= `UD 1'b0;
        exception_done_r <= `UD 1'b0;
    end
    else
    begin
        crc_done_r <= `UD crc_done;
        exception_done_r <= `UD exception_done;
    end
end

always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        func_code_r     <= `UD 8'b0;
        addr_r          <= `UD 16'b0;
        data_r          <= `UD 16'b0;
        crc_rx_code_r   <= `UD 16'b0;
    end
    else
    begin
        if(rx_message_done)
        begin
            func_code_r     <= `UD func_code;
            addr_r          <= `UD addr;
            data_r          <= `UD data;
            crc_rx_code_r   <= `UD crc_rx_code;
        end
        else if(exception_done)
        begin
            func_code_r     <= `UD 8'b0;
            addr_r          <= `UD 16'b0;
            data_r          <= `UD 16'b0;
            crc_rx_code_r   <= `UD 16'b0;
        end
    end
end


always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        crc_rx_calc_r <= `UD 16'b0;
    end
    else
    begin
        if(crc_done)
        begin
            crc_rx_calc_r <= `UD crc_rx_calc;
        end
        else if(exception_done)
        begin
            crc_rx_calc_r <= `UD 16'b0;
        end
    end
end

always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        exception_done <= `UD 1'b0;
        exception <= `UD 8'h00;
    end
    else
    begin
        if((crc_rx_calc_r == crc_rx_code_r)&&(crc_done_r))
        begin
            if((func_code_r!=8'h03)&&(func_code_r!=8'h04)&&(func_code_r!=8'h06))
            begin
                exception_done <= `UD 1'b1;
                exception <= `UD 8'h01;
            end
            else
            begin
                if(func_code_r==8'h03)
                begin
                    if(addr==16'h0001)
                    begin
                        if(data>16'h0001)
                        begin
                            exception_done <= `UD 1'b1;
                            exception <= `UD 8'h03;
                        end
                        else
                        begin
                            exception_done <= `UD 1'b1;
                            exception <= `UD 8'h0;
                        end
                    end
                    else
                    begin
                        exception_done <= `UD 1'b1;
                        exception <= `UD 8'h02;
                    end
                end
                else if(func_code_r==8'h04)
                begin
                    if(addr+data<=16'h0005)
                    begin
                        exception_done <= `UD 1'b1;
                        exception <= `UD 8'h0;
                    end
                    else if(addr>16'h0004)
                    begin
                        exception_done <= `UD 1'b1;
                        exception <= `UD 8'h02;
                    end
                    else if(data>16'h0004)
                    begin
                        exception_done <= `UD 1'b1;
                        exception <= `UD 8'h03;
                    end
                end
                else if(func_code_r==8'h06)
                begin
                    if(addr==16'h0001)
                    begin
                        if(data>16'h18)
                        begin
                            exception_done <= `UD 1'b1;
                            exception <= `UD 8'h03;
                        end
                        else
                        begin
                            exception_done <= `UD 1'b1;
                            exception <= `UD 8'h0;
                        end
                    end
                    else
                    begin
                        exception_done <= `UD 1'b1;
                        exception <= `UD 8'h02;
                    end
                end
            end
        end
        
        if(exception_done==1'b1)
        begin
            exception_done <= `UD 1'b0;
        end
        
        if(exception_done_r==1'b1)
        begin
            exception <= `UD 8'h00;
        end
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