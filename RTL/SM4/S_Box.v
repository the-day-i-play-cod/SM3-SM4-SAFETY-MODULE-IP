`timescale 1ns / 1ps

module S_Box(
    input           i_clk       ,
    input           i_rst       ,
    input  [7 :0]   i_data      ,
    input           i_valid     ,
    output [7 :0]   o_s_data    ,
    output          o_s_valid   
);

reg  [7  :0]        ro_s_data       ;
reg                 ro_s_valid      ;
reg  [127:0]        r_s_Box[0 :15]  ;

wire [3  :0]        w_X             ;
wire [3  :0]        w_Y             ;


assign o_s_data = ro_s_data         ;
assign o_s_valid= ro_s_valid        ;
assign w_X      = i_data[7 :4]      ;
assign w_Y      = i_data[3 :0]      ;


always@(posedge i_clk,posedge i_rst)
begin
  if(i_rst) begin
        r_s_Box[0] = 128'hD690E9FECCE13DB716B614C228FB2C05;
        r_s_Box[1] = 128'h2B679A762ABE04C3AA44132649860699;
        r_s_Box[2] = 128'h9C4250F491EF987A33540B43EDCFAC62;
        r_s_Box[3] = 128'hE4B31CA9C908E89580DF94FA758F3FA6;
        r_s_Box[4] = 128'h4707A7FCF37317BA83593C19E6854FA8;
        r_s_Box[5] = 128'h686B81B27164DA8BF8EB0F4B70569D35;
        r_s_Box[6] = 128'h1E240E5E6358D1A225227C3B01217887;
        r_s_Box[7] = 128'hD40046579FD327524C3602E7A0C4C89E;
        r_s_Box[8] = 128'hEABF8AD240C738B5A3F7F2CEF96115A1;
        r_s_Box[9] = 128'hE0AE5DA49B341A55AD933230F58CB1E3;
        r_s_Box[10] = 128'h1DF6E22E8266CA60C02923AB0D534E6F;
        r_s_Box[11] = 128'hD5DB3745DEFD8E2F03FF6A726D6C5B51;
        r_s_Box[12] = 128'h8D1BAF92BBDDBC7F11D95C411F105AD8;
        r_s_Box[13] = 128'h0AC13188A5CD7BBD2D74D012B8E5B4B0;
        r_s_Box[14] = 128'h8969974A0C96777E65B9F109C56EC684;
        r_s_Box[15] = 128'h18F07DEC3ADC4D2079EE5F3ED7CB3948;
  end
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_s_valid <= 'd0;
    else 
        ro_s_valid <= i_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_s_data <= 'd0;
    else case(w_Y)
        0       :ro_s_data <= r_s_Box[w_X][127:120];
        1       :ro_s_data <= r_s_Box[w_X][119:112];
        2       :ro_s_data <= r_s_Box[w_X][111:104];
        3       :ro_s_data <= r_s_Box[w_X][103: 96];
        4       :ro_s_data <= r_s_Box[w_X][95 : 88];
        5       :ro_s_data <= r_s_Box[w_X][87 : 80];
        6       :ro_s_data <= r_s_Box[w_X][79 : 72];
        7       :ro_s_data <= r_s_Box[w_X][71 : 64];
        8       :ro_s_data <= r_s_Box[w_X][63 : 56];
        9       :ro_s_data <= r_s_Box[w_X][55 : 48];
        10      :ro_s_data <= r_s_Box[w_X][47 : 40];
        11      :ro_s_data <= r_s_Box[w_X][39 : 32];
        12      :ro_s_data <= r_s_Box[w_X][31 : 24];
        13      :ro_s_data <= r_s_Box[w_X][23 : 16];
        14      :ro_s_data <= r_s_Box[w_X][15 :  8];
        15      :ro_s_data <= r_s_Box[w_X][7  :  0];
    endcase 
end

endmodule
