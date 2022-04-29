`timescale 1ns/1ns
                
module crc_16_tb();
//激励信号定义 
reg				tb_clk  	;
reg				tb_rst_n	;
reg				crc_en		;
reg			clear		;
reg		[7:0]	data_in		;
reg [3:0] byte_cnt;
//输出信号定义	 
wire	[15:0]	crc_out	;
                                          
//时钟周期参数定义					        
    parameter		CLOCK_CYCLE = 20;    

parameter   CHECK_BYTES = 48'hf00300010001;

crc_16  u_crc_16(
/*input              */.clk     (tb_clk),
/*input              */.rst_n   (tb_rst_n),
/*input              */.crc_en  (crc_en),
/*input              */.crc_clr (clear),
/*input      [7:0]  */.data_in (data_in),
/*output reg [15:0]  */.crc_out (crc_out)
);
//产生时钟							       	
initial 		tb_clk = 1'b0;		       		
always #(CLOCK_CYCLE/2) tb_clk = ~tb_clk;  	
                                                   
//产生激励							       	
initial  begin						       	
    tb_rst_n = 1'b1;															
    #(CLOCK_CYCLE*2);				            
    tb_rst_n = 1'b0;							
    #(CLOCK_CYCLE*20);				            
    tb_rst_n = 1'b1;
    #(CLOCK_CYCLE*200);

    $stop;					                                                                                                   
end 				

always @(posedge tb_clk or negedge tb_rst_n)begin 
    if(!tb_rst_n)begin
        crc_en <= 1'b0;
        clear <= 1'b0;
        data_in <= 0;
        byte_cnt <= 0;
    end 
    else if(byte_cnt <= 5) begin 
        crc_en <= 1'b1;
        byte_cnt <= byte_cnt + 1;
        data_in <= CHECK_BYTES[(47 - byte_cnt*8) -:8];        
    end 
    else begin 
        clear <= 1'b1;
        crc_en <= 1'b0;
        data_in <= CHECK_BYTES;
    end 
end

endmodule 									       	