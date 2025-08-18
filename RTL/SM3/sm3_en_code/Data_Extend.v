
`timescale 1ns / 1ps

module Data_Extend(
    input               i_clk           ,
    input               i_rst           ,
    input  [511 :0]     i_padding_data  ,
    input               i_padding_valid ,
    output [4223:0]     o_extend_data   ,
    output              o_extend_valid  
);

function [31:0] P1;
    input [31 :0] X;
begin
    P1 = X ^ {X[16:0],X[31:17]} ^ {X[8:0],X[31:9]};
end
endfunction

reg  [511 :0]           ri_padding_data         ;
reg                     ri_padding_valid        ;
reg                     ri_padding_valid_1d     ;
reg  [31  :0]           ro_extend_data[0:131]   ;
reg  [31  :0]           ro_extend_data_1d[0:131];
reg                     ro_extend_valid         ;

wire [511:0]            w_padding_data_f        ;
reg [31 :0]            w_P1_X[0:67]            ;
reg [31 :0]            w_P1[0:67]              ;
reg [31 :0]            w_word2_mid0[0:67]      ;
reg [31 :0]            w_word2_mid1[0:67]      ;

assign o_extend_valid = ro_extend_valid ;


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ri_padding_data  <= 'd0;
        ri_padding_valid <= 'd0;
        ri_padding_valid_1d <= 'd0;
    end else begin
        ri_padding_data  <= i_padding_data ;
        ri_padding_valid <= i_padding_valid;
        ri_padding_valid_1d <= ri_padding_valid;
    end
end

//W0-W15
genvar g_i;
generate
    for(g_i = 0 ; g_i < 16 ; g_i = g_i + 1)
    begin:Encode
        assign w_padding_data_f[g_i*32 +31 : g_i*32] = ri_padding_data[511 - g_i*32 : 511 - 31 - g_i*32];
    end
endgenerate


//output assign reg arrays -> whole wire
genvar g_outi;
generate
    for(g_outi = 0 ; g_outi < 132 ; g_outi = g_outi + 1)
    begin:Word_Out
        assign o_extend_data[(g_outi*32) + 31 : g_outi*32] = ro_extend_data_1d[g_outi];
    end
endgenerate


//assign W0-W16
genvar g_exi;
generate
    for(g_exi = 0 ; g_exi < 16 ; g_exi = g_exi + 1)
    begin:Extend_Word1
        always@(*)
        begin
            if(i_rst)
                ro_extend_data[g_exi] <= 'd0;
            else 
                ro_extend_data[g_exi] <= w_padding_data_f[(g_exi * 32) + 31:g_exi * 32];
        end
    end
endgenerate

//W16-W67
	genvar g_exj;
generate
    for(g_exj = 16 ; g_exj < 68 ; g_exj = g_exj + 1)
    begin:Extend_Word2
        always @(posedge i_clk, posedge i_rst) begin
            if (i_rst) begin
                w_P1_X[g_exj] <= 32'd0;
                w_P1[g_exj] <= 32'd0;
                w_word2_mid1[g_exj] <= 32'd0;
                ro_extend_data[g_exj] <= 'd0;
            end else begin
                // 1. 计算w_P1_X（含异或和移位）
                w_P1_X[g_exj] <= ro_extend_data[g_exj-16] ^ ro_extend_data[g_exj-9] ^ 
                                {ro_extend_data[g_exj-3][16:0], ro_extend_data[g_exj-3][31:17]}; // 左移15位
                
                // 2. 计算w_P1（调用P1函数）
                w_P1[g_exj] <= P1(w_P1_X[g_exj]); // P1(X) = X ^ (X<<15) ^ (X<<23)
                
                // 3. 计算w_word2_mid1（移位操作）
                w_word2_mid1[g_exj] <= {ro_extend_data[g_exj - 13][24:0], ro_extend_data[g_exj - 13][31:25]}; // 左移7位


                ro_extend_data[g_exj] <= w_P1[g_exj] ^ 
                         w_word2_mid1[g_exj]^
                         ro_extend_data[g_exj - 6];
            end
        end
     
    end
endgenerate

//W'0-W'67
genvar g_exk;
generate
    for(g_exk = 0 ; g_exk < 64 ; g_exk = g_exk + 1)
    begin:Extend_Word3
        always@(posedge i_clk,posedge i_rst)
        begin
            if(i_rst)
                ro_extend_data[g_exk + 68] <= 'd0;
            else
                ro_extend_data[g_exk + 68] <= ro_extend_data[g_exk] ^ ro_extend_data[g_exk + 4];
        end
    end
endgenerate

//regi
genvar g_ddi;
generate 
    for(g_ddi = 0 ; g_ddi < 132 ; g_ddi = g_ddi + 1)
    begin:reg_1d
        always@(posedge i_clk,posedge i_rst)
        begin
            if(i_rst)
                ro_extend_data_1d[g_ddi] <= 'd0;
            else //if(ri_padding_valid)
                ro_extend_data_1d[g_ddi] <= ro_extend_data[g_ddi];
        //  else 
        //      ro_extend_data_1d[g_ddi] <= ro_extend_data_1d[g_ddi];
        end
    end
endgenerate




reg [66:0] valid_delay_chain;  
always@(posedge i_clk, posedge i_rst) begin
    if(i_rst) begin
        valid_delay_chain <= 67'd0;
    end else begin
        valid_delay_chain <= {valid_delay_chain[65:0], ri_padding_valid_1d};
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_extend_valid <= 'd0;
    else 
        ro_extend_valid <= valid_delay_chain[66]; 
end

endmodule
