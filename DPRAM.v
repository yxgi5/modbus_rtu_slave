module DPRAM # 
( 
	parameter   A_WIDTH     = 4,
    parameter   D_WIDTH     = 16
) 
(      
    CLKA,
    CLKB,
    ENA,
    ENB,
    WEA,
    WEB,
    ADDRA,
    ADDRB,
    DIA,
    DIB,
    DOA,
    DOB,
);

input                       CLKA;
input                       CLKB;
input                       ENA;
input                       ENB;
input                       WEA;
input                       WEB;
input   [A_WIDTH-1:0]       ADDRA;
input   [A_WIDTH-1:0]       ADDRB;
input   [D_WIDTH-1:0]       DIA;
input   [D_WIDTH-1:0]       DIB;
output  [D_WIDTH-1:0]       DOA;
output  [D_WIDTH-1:0]       DOB;

reg     [D_WIDTH-1:0]       DOA;
reg     [D_WIDTH-1:0]       DOB;


reg [D_WIDTH-1:0] RAM [0:2**A_WIDTH-1];

//--------------------------------------------------------------------------------
//-- Schreiben/Lesen Port A
//--------------------------------------------------------------------------------
always @(posedge CLKA)
begin
    if (ENA == 1'b1) 
    begin
        if (WEA == 1'b1)
        begin
            RAM[ADDRA] = DIA;
        end
        //else
        //begin
            //DOA <= RAM[ADDRA];
        //end
        DOA = RAM[ADDRA];
    end
end

//--------------------------------------------------------------------------------
//-- Schreiben/Lesen Port B
//--------------------------------------------------------------------------------
always @(posedge CLKB)
begin
    if (ENB == 1'b1) 
    begin
        if (WEB == 1'b1)
        begin
            RAM[ADDRB] = DIB;
        end
        //else
        //begin
            //DOB <= RAM[ADDRB];
        //end
        DOB = RAM[ADDRB];
    end
end

endmodule
/*
always @(posedge CLOCK)
begin
    if (RESET == 1'b1) 
    begin
    end
    else
    begin
    end
end
*/

