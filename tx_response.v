`timescale 1ns / 1ns
`define UD #1

module tx_response #
(
    parameter           CLK_FREQ   = 'd50000000,// 50MHz
    parameter           BAUD_RATE  = 'd9600,   //
    parameter           SADDR      = 8'h01
)
(
    input               clk_in,			// system clock
    input               rst_n_in,		// system reset, active low
    
    input               tx_start,
    
    input   [7:0]       func_code,
    input   [7:0]       tx_quantity,
    input   [15:0]      tx_data,
    output  reg [7:0]   tx_addr,
    
    input   [7:0]       exception,
    input   [39:0]      exception_seq,
    
    input   [63:0]      code06_response,
    
    output  reg         response_done,
    output  wire        rs485_tx,
    output  reg         rs485_tx_en
);

localparam BPS_PARAM = (CLK_FREQ/BAUD_RATE);

reg tx_start_pos;

reg crc_start;
reg [7:0] index;
reg [7:0] data_buf;
reg [7:0] ct_frame;
reg [3:0] ct_8bit;
reg [7:0] i;
reg [15:0] crc_reg;
reg [15:0]  crc_calc;
reg         crc_done;

reg [5:0] bps_cnt;
reg cnt_en;
reg response_done_r;

reg [7:0]   rs485_tx_data;
reg         rs485_tx_start;
wire tx_done;

reg [7:0]   op_state;
reg FF;
always@(posedge clk_in or negedge rst_n_in)
begin
    if( !rst_n_in )
    begin
        op_state <= `UD 8'd0;
        FF <= `UD 1'b1;
        
        i <= `UD 7'd0;                     
        crc_done <= `UD 1'b0;           //校验完成，输出一个周期高电平
        ct_frame <= `UD 8'd0;
        ct_8bit <= `UD 4'd0;
        crc_reg <= `UD 16'b0;
        crc_done <= `UD 1'b0;
        crc_calc <= `UD 16'b0;
        data_buf <= `UD {(8){1'b0}} ;
        index <= `UD 8'd0;
        tx_addr <= `UD 8'd0;
        
        rs485_tx_data <= `UD 8'h0;
        rs485_tx_start <= `UD 1'b0;
        response_done_r <= `UD 1'b0;
        rs485_tx_en <= `UD 1'b0;
        response_done <= `UD 1'b0;
        
        tx_start_pos <= `UD 1'b0;
        crc_start <= `UD 1'b0;
    end
    else
    begin
        case(op_state)
        8'd0:
        begin
            if(tx_start)
            begin
                rs485_tx_en <= `UD 1'b1;
                if(exception!=8'h00)
                begin
                    op_state <= `UD 8'd3;
                    FF <= `UD 1'b1;
                end
                else if(func_code==8'h06)
                begin
                    op_state <= `UD 8'd2;
                    FF <= `UD 1'b1;
                end
                else
                begin // func_code==8'h03||func_code==8'h04
                    op_state <= `UD 8'd1;
                    FF <= `UD 1'b1;
                    i <= `UD 7'd0; 
                    crc_start <= `UD 1'b1;
                end
            end
            else
            begin
                op_state <= `UD 8'd0;
                FF <= `UD 1'b1;
                
                i <= `UD 7'd0;                     
                crc_done <= `UD 1'b0;           //校验完成，输出一个周期高电平
                ct_frame <= `UD 8'd0;
                ct_8bit <= `UD 4'd0;
                crc_reg <= `UD 16'b0;
                crc_done <= `UD 1'b0;
                crc_calc <= `UD 16'b0;
                data_buf <= `UD {(8){1'b0}} ;
                index <= `UD 8'd0;
                tx_addr <= `UD 8'd0;

                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
                rs485_tx_en <= `UD 1'b0;
                response_done <= `UD 1'b0;
                
                tx_start_pos <= `UD 1'b0;
                crc_start <= `UD 1'b0;
            end
        end
        8'd1:
        begin
            case ( i )
            7'd0 :
            begin
                crc_start <= `UD 1'b0;
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
                op_state <= `UD 8'd4;
                FF <= `UD 1'b1;
            end 
            default;
            endcase
        end
        
        8'd2:
        begin
            if(FF)
            begin
                tx_start_pos <= `UD 1'b1;
                FF <= `UD 1'b0;
            end
            else
            begin
                tx_start_pos <= `UD 1'b0;
                if(bps_cnt>=6'd10)
                begin
                    rs485_tx_data <= `UD code06_response[63:56];
                    FF <= `UD 1'b1;
                    op_state <= `UD 8'd19;
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd3:
        begin
            if(FF)
            begin
                tx_start_pos <= `UD 1'b1;
                FF <= `UD 1'b0;
            end
            else
            begin
                tx_start_pos <= `UD 1'b0;
                if(bps_cnt>=6'd10)
                begin
                    rs485_tx_data <= `UD exception_seq[39:32];
                    FF <= `UD 1'b1;
                    op_state <= `UD 8'd15;
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd4: // start delay for 458 tx enable
        begin
            tx_start_pos <= `UD 1'b1;
            op_state <= `UD 8'd5;
        end
        8'd5:
        begin
            tx_start_pos <= `UD 1'b0;
            if(bps_cnt>=6'd10)
            begin
                op_state <= `UD 8'd6;
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD SADDR;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
            end
            else
            begin
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
            end
        end
        8'd6:
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
                    op_state <= `UD 8'd7;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD func_code;
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        
        8'd7:
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
                    op_state <= `UD 8'd8;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD tx_quantity;
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        
        8'd8:
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
                    op_state <= `UD 8'd9;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD 8'h0;
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        
        8'd9:
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
                    rs485_tx_data <= `UD crc_calc[7:0];
                    op_state <= `UD 8'd12;
                    FF <= `UD 1'b1;
                end
            end
            else
            begin
                rs485_tx_data <= `UD tx_data[15:8];
                //rs485_tx_start <= `UD 1'b1;
                op_state <= `UD 8'd10;
                FF <= `UD 1'b1;
            end
        end
        
        8'd10:
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
                    op_state <= `UD 8'd11;
                    FF <= `UD 1'b1;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd11:
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
                        op_state <= `UD 8'd9;
                    end
                    else
                    begin
                        op_state <= `UD 8'd12;
                        rs485_tx_data <= `UD crc_calc[7:0];
                    end
                    FF <= `UD 1'b1;
                end
            end
        end
        
        8'd12:
        begin
            if(FF)
            begin
                FF <= `UD 1'b0;
                rs485_tx_start <= `UD 1'b1;
            end
            else
            begin
                if(tx_done)
                begin
                    op_state <= `UD 8'd13;
                    rs485_tx_data <= `UD crc_calc[15:8];
                    FF <= `UD 1'b1;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd13:
        begin
            if(FF)
            begin
                FF <= `UD 1'b0;
                rs485_tx_start <= `UD 1'b1;
            end
            else
            begin
                if(tx_done)
                begin
                    op_state <= `UD 8'd14;
                    rs485_tx_data <= `UD 8'h0;
                    response_done_r <= `UD 1'b1;
                    FF <= `UD 1'b1;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd14:
        begin
            if(bps_cnt>=6'd10)
            begin
                op_state <= `UD 8'd0;
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
                FF <= `UD 1'b1;
                tx_addr <= `UD 8'h0;
                rs485_tx_data <= `UD 8'h0;
                rs485_tx_start <= `UD 1'b0;
                response_done_r <= `UD 1'b0;
            end
        end
        8'd15:
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
                    op_state <= `UD 8'd16;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD exception_seq[31:24];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd16:
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
                    op_state <= `UD 8'd17;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD exception_seq[23:16];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd17:
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
                    op_state <= `UD 8'd18;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD exception_seq[15:8];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd18:
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
                    op_state <= `UD 8'd13;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD exception_seq[7:0];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        
        8'd19:
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
                    op_state <= `UD 8'd20;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD code06_response[55:48];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd20:
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
                    op_state <= `UD 8'd21;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD code06_response[47:40];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd21:
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
                    op_state <= `UD 8'd22;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD code06_response[39:32];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd22:
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
                    op_state <= `UD 8'd23;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD code06_response[31:24];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd23:
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
                    op_state <= `UD 8'd24;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD code06_response[23:16];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd24:
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
                    op_state <= `UD 8'd25;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD code06_response[15:8];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        8'd25:
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
                    op_state <= `UD 8'd13;
                    FF <= `UD 1'b1;
                    tx_addr <= `UD 8'h0;
                    tx_addr <= `UD 8'h0;
                    rs485_tx_data <= `UD code06_response[7:0];
                    rs485_tx_start <= `UD 1'b0;
                    response_done_r <= `UD 1'b0;
                end
                else
                begin
                    rs485_tx_start <= `UD 1'b0;
                    FF <= `UD 1'b0;
                end
            end
        end
        
        default:
        begin
            
        end
        endcase
    end
end

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