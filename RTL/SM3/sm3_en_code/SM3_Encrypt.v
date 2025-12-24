`timescale 1ns / 1ps

module sm3_encrypt(
    input                   i_clk               ,   //输入时钟
    input                   i_rst               ,   //输入复位

    input  [511:0]          i_batch_data0     ,   //输入待加密数�????????
    //input  [511:0]  i_batch_data1     , 
    input                   i_input_valid    ,   //输入有效->
    output [255:0]          o_Encrypt_Data      ,   //输出SM3摘要
    output                  o_Encrypt_Valid    ,     //输出有效

    //add
    input                   i_multi_flag       ,    //keep
    input                   i_not_pad_multi_flag,
    output                  o_batch_cnt
);

localparam          P_ITERATOR_CYCLE = 4;

reg  [511:0]        r_padding_data              ;
reg                 r_padding_valid             ;
reg                 r_extend_valid              ;
//reg  [4223:0]       r_extend_data               ;
reg  [255 :0]       r_iterator_V[0:2]          ;    
reg  [255 :0]       ro_Encrypt_Data             ;
reg                 ro_Encrypt_Valid            ;
reg  [15  :0]       r_out_cnt                   ;
reg  [63  :0]       r_cmp_valid                 ;

reg cmp0,cmp1,	 cmp2,	 cmp3,	 cmp4,	 cmp5,	 cmp6,	 cmp7,	 cmp8,	 cmp9,	 cmp10,	 cmp11,	 cmp12,	 cmp13,	 cmp14,	 cmp15,	 cmp16,	 cmp17,	 cmp18,	 cmp19,	 cmp20,	 cmp21,	 cmp22,	 cmp23,	 cmp24,	 cmp25,	 cmp26,	 cmp27,	 cmp28,	 cmp29,	 cmp30,	 cmp31,	 cmp32,	 cmp33,	 cmp34,	 cmp35,	 cmp36,	 cmp37,	 cmp38,	 cmp39,	 cmp40,	 cmp41,	 cmp42,	 cmp43,	 cmp44,	 cmp45,	 cmp46,	 cmp47,	 cmp48,	 cmp49,	 cmp50,	 cmp51,	 cmp52,	 cmp53,	 cmp54,	 cmp55,	 cmp56,	 cmp57,	 cmp58,	 cmp59,	 cmp60,	 cmp61,	 cmp62,	 cmp63,	 cmp64;


reg tmp1,	 tmp2,	 tmp3,	 tmp4,	 tmp5,	 tmp6,	 tmp7,	 tmp8,	 tmp9,	 tmp10,	 tmp11,	 tmp12,	 tmp13,	 tmp14,	 tmp15,	 tmp16,	 tmp17,	 tmp18,	 tmp19,	 tmp20,	 tmp21,	 tmp22,	 tmp23,	 tmp24,	 tmp25,	 tmp26,	 tmp27,	 tmp28,	 tmp29,	 tmp30,	 tmp31,	 tmp32,	 tmp33,	 tmp34,	 tmp35,	 tmp36,	 tmp37,	 tmp38,	 tmp39,	 tmp40,	 tmp41,	 tmp42,	 tmp43,	 tmp44,	 tmp45,	 tmp46,	 tmp47,	 tmp48,	 tmp49,	 tmp50,	 tmp51,	 tmp52,	 tmp53,	 tmp54,	 tmp55,	 tmp56,	 tmp57,	 tmp58,	 tmp59,	 tmp60,	 tmp61,	 tmp62,	 tmp63,	 tmp64;



//wire [4223:0]       w_extend_data               ;
wire                w_extend_valid              ;


assign o_Encrypt_Data  =    ro_Encrypt_Data     ;
assign o_Encrypt_Valid =    (!cmp64)&ro_Encrypt_Valid    ;

//multi part

reg r_multi_flag;

reg         r_input_valid;
reg [255:0] r_V_multi;
wire        w_for_V64_buffer;
reg [31:0]  r_batch_cnt=32'b0;

reg  [255:0]r_iter64;
wire                w_extend_valid  ,   wo_extend_valid          ;
reg  [7:0]          rd_addr0, rd_addr1; // addresses for Wj and W'j
// Raw outputs from Data_Extend
wire [31:0]         w_rd_data0_int, w_rd_data1_int;
// Registered copies with reset to 0 for safe initial values
reg  [31:0]         w_rd_data0, w_rd_data1;    
reg  [31:0]         w_Wj_q, w_Wjp_q;          // reserved (optional)
reg                 iter_data_valid;           // indicates read data is valid for compute

/*----Extend (RAM-based)-----*/
Data_Extend Data_Extend_u0(
    .i_clk              (i_clk              ),
    .i_rst              (i_rst              ),
    .i_padding_data     (r_padding_data     ),
    .i_padding_valid    (r_padding_valid    ),
    .i_rd_addr0         (rd_addr0           ),
    .i_rd_addr1         (rd_addr1           ),
    .o_rd_data0         (w_rd_data0_int     ),
    .o_rd_data1         (w_rd_data1_int     ),
    .o_extend_valid     (wo_extend_valid     )
);

reg r_extend_valid ;
// Register RAM read data; reset to 0
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        r_extend_valid<=0;
    end else begin
        r_extend_valid<=wo_extend_valid;
    end
end
assign w_extend_valid=wo_extend_valid&&(~r_extend_valid);

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) r_multi_flag  <= 'd0;  
    else r_multi_flag<=i_multi_flag;
end

reg r_i_not_pad_multi_flag;
wire fall_padm_flag,up_padm_flag;

reg r_for_V64_buffer;
always @(posedge i_clk,posedge i_rst)
begin
     if(i_rst) r_i_not_pad_multi_flag<=0;
     else r_i_not_pad_multi_flag<=i_not_pad_multi_flag;
end

assign      fall_padm_flag=r_i_not_pad_multi_flag&!i_not_pad_multi_flag;
assign      up_padm_flag=!r_i_not_pad_multi_flag&i_not_pad_multi_flag;
assign      o_batch_cnt=r_batch_cnt;
assign      w_for_V64_buffer=!r_input_valid&i_input_valid;



always @(posedge i_clk,posedge i_rst) begin
    if(i_rst) r_batch_cnt<=0;
    else if(i_multi_flag&!i_not_pad_multi_flag) begin
        if(r_for_V64_buffer&&r_batch_cnt!=2)
            r_batch_cnt<=r_batch_cnt+1;
        else if(r_batch_cnt==2)begin
            if(o_Encrypt_Valid==1'b1)
            r_batch_cnt<=0;
        end else r_batch_cnt<=r_batch_cnt;
    end else if(i_multi_flag&i_not_pad_multi_flag)begin
        if(up_padm_flag) r_batch_cnt<=1;
        else if(fall_padm_flag) r_batch_cnt<=0;
        else if(!up_padm_flag&!fall_padm_flag&r_for_V64_buffer) r_batch_cnt<=r_batch_cnt+1;
        else r_batch_cnt<=r_batch_cnt;
        
    end else r_batch_cnt<=0;
end


always @(posedge i_clk,posedge i_rst)
begin
     if(i_rst) begin 
        r_input_valid<=0;
        r_for_V64_buffer<=0;
     end else begin 
        r_input_valid<=i_input_valid;
        r_for_V64_buffer<=w_for_V64_buffer;
     end
end

always @(posedge i_clk,posedge i_rst) 
begin
    if(i_rst)  r_V_multi<=0;
    else if(r_batch_cnt>1) begin
        r_V_multi<=ro_Encrypt_Data;//r_iterator_V[64];  //no reset when multi en
        end
    else
        r_V_multi<=r_V_multi;      

    
end


reg [255:0] r_V_multi_d1;  // 第一�?
reg [255:0] r_V_multi_d2;  // 第二�?
reg [255:0] r_V_multi_d3;  // 第三�?
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
	    r_V_multi_d1 <= 256'b0;
        r_V_multi_d2 <= 256'b0;
        r_V_multi_d3 <= 256'b0;
    end else begin
        r_V_multi_d1 <= r_V_multi;    // 第一级采�?
        r_V_multi_d2 <= r_V_multi_d1; // 第二级传�?
        r_V_multi_d3 <= r_V_multi_d2; // 第三级传�?
    end
end        



always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_padding_data  <= 'd0;
        r_padding_valid <= 'd0;
    end else begin
        r_padding_data  <= i_batch_data0;
        r_padding_valid <= i_input_valid;
    end
end

/*
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_extend_valid <= 'd0;
        r_extend_data  <= 'd0;
    end else begin
        r_extend_valid <= w_extend_valid;
        r_extend_data  <= w_extend_data;
    end
end
*/
/*----Iteration-----*/
reg cmp0_r1,cmp0_r2,cmp0_r3,cmp0_r4,cmp0_r5;
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        cmp0_r1 <= 1'd0;
    else if(w_extend_valid) begin
        cmp0_r1<=1'b1;        
    end else if(tmp64==1'b1)
        cmp0_r1<=1'b0;              
     else cmp0_r1<=cmp0_r1;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        cmp0_r2<=1'b0;
        cmp0_r3<=1'b0;
        cmp0_r4<=1'b0;
        cmp0_r5<=1'b0;
        cmp0   <=1'b0;
    end else if(cmp0_r1==1'b1) begin
        cmp0_r2<=cmp0_r1;
        cmp0_r3<=cmp0_r2;
        cmp0_r4<=cmp0_r3;
        cmp0_r5<=cmp0_r4;
        cmp0   <=cmp0_r5;
      //rd_addr0 <= 0 ;
      //rd_addr1 <= 0+67 ;         
    end else if(tmp64==1'b1) begin
        cmp0_r2<=1'b0;
        cmp0_r3<=1'b0;
        cmp0_r4<=1'b0;
        cmp0_r5<=1'b0;
        cmp0   <=1'b0;
    end
end
/////////////////////////

wire [255:0] i_V;
//wire [4223:0] i_B;
wire [31:0] i_j;

//wire [31:0]                 w_Wj [0:67]     ;
//wire [31:0]                 w_Wj_[0:63]     ;

wire [31:0]                 w_Tj_y[0:63]    ;
wire [31:0]                 w_Tj            ;

//assign i_B=r_extend_data;

//genvar g_Wi;
//generate 
//    for(g_Wi = 0 ; g_Wi < 68 ; g_Wi = g_Wi + 1)
//    begin:Gen_Wj
//        assign w_Wj[g_Wi] = i_B[g_Wi*32 + 31:g_Wi*32];
//    end
//endgenerate

assign w_Tj_y[0]   =32'h79cc4519;
assign w_Tj_y[32] =32'h7a879d8a;


//assign w_Tj = Tj(i_j );

//genvar g_Wj;
//generate 
//    for(g_Wj = 0 ; g_Wj < 64 ; g_Wj = g_Wj + 1)
//    begin:Gen_Wj_0
//        assign w_Wj_[g_Wj] = i_B[2176 + g_Wj *32 + 31:2176 + g_Wj *32];      
//    end
//endgenerate

    wire [31:0]    Tj_0 = 32'h79cc4519;

    wire [31:0]    Tj_1 = 32'h7a879d8a;

genvar g0_Wj;
generate 

    for(g0_Wj = 0 ; g0_Wj < 16 ; g0_Wj = g0_Wj + 1)
    begin:Gen_Wj_1
     if(g0_Wj > 0 && g0_Wj <32)
            assign w_Tj_y[g0_Wj] = {Tj_0[31 - g0_Wj : 0],Tj_0[31:31 - (g0_Wj - 1)]};       
    end
endgenerate

genvar g1_Wj;
generate 
    
    for(g1_Wj = 16 ; g1_Wj < 64 ; g1_Wj = g1_Wj + 1)
    begin:Gen_Wj_
     if(g1_Wj > 0 && g1_Wj <32)
            assign w_Tj_y[g1_Wj] = {Tj_1[31 - g1_Wj : 0],Tj_1[31:31 - (g1_Wj - 1)]};
        else if(g1_Wj >32)
            assign w_Tj_y[g1_Wj] = {Tj_1[31 - (g1_Wj - 32) : 0],Tj_1[31:31 - ((g1_Wj - 32) - 1)]};
        
    end
endgenerate




function [31:0] P0;
    input [31 :0] X;
begin
    P0 = X ^ {X[22:0],X[31:23]} ^ {X[14:0],X[31:15]};
end
endfunction

function [31:0] FFj;
    input [31 :0] X;
    input [31 :0] Y;
    input [31 :0] Z;
    input [31 :0] j;    
begin
    if(j<16)
        FFj = X ^ Y ^ Z;
    else 
        FFj = (X & Y) | (X & Z) | (Y & Z);
end
endfunction

function [31:0] GGj;
    input [31 :0] X;
    input [31 :0] Y;
    input [31 :0] Z;
    input [31 :0] j;    
begin
    if(j<16)
        GGj = X ^ Y ^ Z;
    else 
        GGj = (X & Y) | (~X & Z);
end
endfunction

function [255:0]iterator;
    input  [255 :0]         i_V                 ;
    input  [31  :0]         i_j                 ;
    input  [31  :0]         w_Tj_y              ;
    input  [31  :0]         w_Wj                ;
    input  [31  :0]         w_Wj_               ;

    reg [31:0]                 w_ss1           ;
    reg [31:0]                 w_ss2           ;
    reg [31:0]                 w_tt1           ;
    reg [31:0]                 w_tt2           ;
    reg [31:0]                 w_A             ;
    reg [31:0]                 w_B             ;
    reg [31:0]                 w_C             ;
    reg [31:0]                 w_D             ;
    reg [31:0]                 w_E             ;
    reg [31:0]                 w_F             ;
    reg [31:0]                 w_G             ;
    reg [31:0]                 w_H             ;
    reg [31:0]                 w_A_            ;
    reg [31:0]                 w_B_            ;
    reg [31:0]                 w_C_            ;
    reg [31:0]                 w_D_            ;
    reg [31:0]                 w_E_            ;
    reg [31:0]                 w_F_            ;
    reg [31:0]                 w_G_            ;
    reg [31:0]                 w_H_            ;
    reg [31:0]                 w_ss1_mid0      ;
    begin
         w_H = i_V[31 :  0];
         w_G = i_V[63 : 32];
         w_F = i_V[95 : 64];
         w_E = i_V[127: 96];
         w_D = i_V[159:128];
         w_C = i_V[191:160];
         w_B = i_V[223:192];
         w_A = i_V[255:224];
        //assign w_Tj = Tj(i_j);
         w_ss1_mid0 = {w_A[19:0],w_A[31:20]} + w_E + w_Tj_y;//w_Tj_y[i_j]


         w_ss1 = {w_ss1_mid0[24:0],w_ss1_mid0[31:25]};
         w_ss2 = w_ss1 ^ {w_A[19:0],w_A[31:20]};
         w_tt1 = FFj(w_A,w_B,w_C,i_j) + w_D + w_ss2 + w_Wj_;//w_Wj_[i_j]
         w_tt2 = GGj(w_E,w_F,w_G,i_j) + w_H + w_ss1 + w_Wj;//w_Wj[i_j] W'
         w_D_  = w_C;
         w_C_  = {w_B[22:0],w_B[31:23]};
         w_B_  = w_A;
         w_A_  = w_tt1;
         w_H_  = w_G;
         w_G_  = {w_F[12:0],w_F[31:13]};
         w_F_  = w_E;
         w_E_  = P0(w_tt2);

        iterator = {w_A_,w_B_,w_C_,w_D_,w_E_,w_F_,w_G_,w_H_};
    end
endfunction

reg  [7:0] addr_idx;
wire       addr_advance;

// Detect rising edge on any cmp1..cmp63 to advance address (one-cycle pulse)
wire [63:0] cmp_bus = {cmp63,cmp62,cmp61,cmp60,cmp59,cmp58,cmp57,cmp56,
                       cmp55,cmp54,cmp53,cmp52,cmp51,cmp50,cmp49,cmp48,
                       cmp47,cmp46,cmp45,cmp44,cmp43,cmp42,cmp41,cmp40,
                       cmp39,cmp38,cmp37,cmp36,cmp35,cmp34,cmp33,cmp32,
                       cmp31,cmp30,cmp29,cmp28,cmp27,cmp26,cmp25,cmp24,
                       cmp23,cmp22,cmp21,cmp20,cmp19,cmp18,cmp17,cmp16,
                       cmp15,cmp14,cmp13,cmp12,cmp11,cmp10,cmp9, cmp8,
                       cmp7, cmp6, cmp5, cmp4, cmp3, cmp2, cmp1,cmp0};
reg  [63:0] cmp_bus_d;
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) cmp_bus_d <= {64{1'b0}};
    else       cmp_bus_d <= cmp_bus;
end
wire addr_advance_pulse = |(cmp_bus & ~cmp_bus_d);
assign addr_advance = addr_advance_pulse && (tmp64 != 1'b1);
reg r_addr_advance;
always @(posedge i_clk,posedge i_rst) begin
    if(i_rst) r_addr_advance<=0;
    else r_addr_advance<=addr_advance;
end
always @(posedge i_clk,posedge i_rst) begin
    if(i_rst) begin
        addr_idx <= 8'd0;
        rd_addr0 <= 8'd0;
        rd_addr1 <= 8'd0;
    end else if(tmp64==1'b1) begin
        addr_idx <= 8'd0;
        rd_addr0 <= 8'd0;
        rd_addr1 <= 8'd0;
    end else if(addr_advance) begin
        if(cmp0&&(!cmp1))begin
            rd_addr0<=0;
            rd_addr1<=68;            
        end else begin
            addr_idx <= addr_idx + 8'd1;
            rd_addr0 <= addr_idx + 8'd1;
            rd_addr1 <= addr_idx + 8'd1 + 8'd68;
        end
    end
end
reg [255:0] a_iter_V , b_iter_V , final_V;
// Single sequential writeback for iteration state to avoid multi-driver
reg [6:0]   round_idx;
reg [255:0] iter_state;
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        round_idx  <= 7'd0;
        a_iter_V   <= 256'd0;
        b_iter_V   <= 256'd0;
        final_V    <= 256'd0;
        iter_state <= 256'd0;
    end else if (tmp64 == 1'b1) begin
        round_idx  <= 7'd0;
    end else if (r_addr_advance) begin
        if (round_idx == 7'd0) begin
            iter_state <= iterator(
                r_iterator_V[0],
                32'd0,
                w_Tj_y[0],
                w_rd_data0_int,
                w_rd_data1_int
            );
           // b_iter_V   <= iter_state; // j=0 writes b_iter_V
        end else begin
            iter_state <= iterator(
                iter_state,//(round_idx[0] ? b_iter_V : a_iter_V),
                {25'd0, round_idx},
                w_Tj_y[round_idx],
                w_rd_data0_int,
                w_rd_data1_int
            );
         // if (round_idx[0])
         //     a_iter_V <= iter_state; // odd j writes a_iter_V
         // else
         //     b_iter_V <= iter_state; // even j writes b_iter_V
        end
        round_idx <= round_idx + 7'd1;
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) final_V<=0;
    else if(round_idx == 7'd64)
            final_V <= iter_state;
end
reg f1 ;
always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp1<=1'b0;
        f1<=0;
    end
    else if(cmp0==1'b1)
    begin

        if(f1==0) f1<=1;
        else if(f1==1)cmp1<=1'b1;

    end else if(tmp64==1'b1)begin
        cmp1<=1'b0;
        f1<=0;
    end
    else cmp1<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp1<=1'b0;
    else if(cmp1==1'b1&&tmp64!=1'b1)
        tmp1<=1'b1;
    else if(tmp64==1'b1)
        tmp1<=1'b0;
    else tmp1<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp2<=1'b0;
    end
    else if(tmp1==1'b1)
    begin
    cmp2<=1'b1;
    end else if(tmp64==1'b1)
        cmp2<=1'b0;
    else cmp2<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp2<=1'b0;
    else if(cmp2==1'b1&&tmp64!=1'b1)
        tmp2<=1'b1;
    else if(tmp64==1'b1)
        tmp2<=1'b0;
    else tmp2<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp3<=1'b0;
    end
    else if(tmp2==1'b1)
    begin
    cmp3<=1'b1;
    end else if(tmp64==1'b1)
        cmp3<=1'b0;
    else cmp3<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp3<=1'b0;
    else if(cmp3==1'b1&&tmp64!=1'b1)
        tmp3<=1'b1;
    else if(tmp64==1'b1)
        tmp3<=1'b0;
    else tmp3<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp4<=1'b0;
    end
    else if(tmp3==1'b1)
    begin
    cmp4<=1'b1;
    end else if(tmp64==1'b1)
        cmp4<=1'b0;
    else cmp4<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp4<=1'b0;
    else if(cmp4==1'b1&&tmp64!=1'b1)
        tmp4<=1'b1;
    else if(tmp64==1'b1)
        tmp4<=1'b0;
    else tmp4<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp5<=1'b0;
    end
    else if(tmp4==1'b1)
    begin
    cmp5<=1'b1;
    end else if(tmp64==1'b1)
        cmp5<=1'b0;
    else cmp5<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp5<=1'b0;
    else if(cmp5==1'b1&&tmp64!=1'b1)
        tmp5<=1'b1;
    else if(tmp64==1'b1)
        tmp5<=1'b0;
    else tmp5<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp6<=1'b0;
    end
    else if(tmp5==1'b1)
    begin
    cmp6<=1'b1;
    end else if(tmp64==1'b1)
        cmp6<=1'b0;
    else cmp6<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp6<=1'b0;
    else if(cmp6==1'b1&&tmp64!=1'b1)
        tmp6<=1'b1;
    else if(tmp64==1'b1)
        tmp6<=1'b0;
    else tmp6<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp7<=1'b0;
    end
    else if(tmp6==1'b1)
    begin
    cmp7<=1'b1;
    end else if(tmp64==1'b1)
        cmp7<=1'b0;
    else cmp7<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp7<=1'b0;
    else if(cmp7==1'b1&&tmp64!=1'b1)
        tmp7<=1'b1;
    else if(tmp64==1'b1)
        tmp7<=1'b0;
    else tmp7<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp8<=1'b0;
    end
    else if(tmp7==1'b1)
    begin
    cmp8<=1'b1;
    end else if(tmp64==1'b1)
        cmp8<=1'b0;
    else cmp8<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp8<=1'b0;
    else if(cmp8==1'b1&&tmp64!=1'b1)
        tmp8<=1'b1;
    else if(tmp64==1'b1)
        tmp8<=1'b0;
    else tmp8<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp9<=1'b0;
    end
    else if(tmp8==1'b1)
    begin
    cmp9<=1'b1;
    end else if(tmp64==1'b1)
        cmp9<=1'b0;
    else cmp9<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp9<=1'b0;
    else if(cmp9==1'b1&&tmp64!=1'b1)
        tmp9<=1'b1;
    else if(tmp64==1'b1)
        tmp9<=1'b0;
    else tmp9<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp10<=1'b0;
    end
    else if(tmp9==1'b1)
    begin
    cmp10<=1'b1;
    end else if(tmp64==1'b1)
        cmp10<=1'b0;
    else cmp10<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp10<=1'b0;
    else if(cmp10==1'b1&&tmp64!=1'b1)
        tmp10<=1'b1;
    else if(tmp64==1'b1)
        tmp10<=1'b0;
    else tmp10<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp11<=1'b0;
    end
    else if(tmp10==1'b1)
    begin
    cmp11<=1'b1;
    end else if(tmp64==1'b1)
        cmp11<=1'b0;
    else cmp11<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp11<=1'b0;
    else if(cmp11==1'b1&&tmp64!=1'b1)
        tmp11<=1'b1;
    else if(tmp64==1'b1)
        tmp11<=1'b0;
    else tmp11<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp12<=1'b0;
    end
    else if(tmp11==1'b1)
    begin
    cmp12<=1'b1;
    end else if(tmp64==1'b1)
        cmp12<=1'b0;
    else cmp12<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp12<=1'b0;
    else if(cmp12==1'b1&&tmp64!=1'b1)
        tmp12<=1'b1;
    else if(tmp64==1'b1)
        tmp12<=1'b0;
    else tmp12<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp13<=1'b0;
    end
    else if(tmp12==1'b1)
    begin
    cmp13<=1'b1;
    end else if(tmp64==1'b1)
        cmp13<=1'b0;
    else cmp13<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp13<=1'b0;
    else if(cmp13==1'b1&&tmp64!=1'b1)
        tmp13<=1'b1;
    else if(tmp64==1'b1)
        tmp13<=1'b0;
    else tmp13<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp14<=1'b0;
    end
    else if(tmp13==1'b1)
    begin
    cmp14<=1'b1;
    end else if(tmp64==1'b1)
        cmp14<=1'b0;
    else cmp14<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp14<=1'b0;
    else if(cmp14==1'b1&&tmp64!=1'b1)
        tmp14<=1'b1;
    else if(tmp64==1'b1)
        tmp14<=1'b0;
    else tmp14<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp15<=1'b0;
    end
    else if(tmp14==1'b1)
    begin
    cmp15<=1'b1;
    end else if(tmp64==1'b1)
        cmp15<=1'b0;
    else cmp15<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp15<=1'b0;
    else if(cmp15==1'b1&&tmp64!=1'b1)
        tmp15<=1'b1;
    else if(tmp64==1'b1)
        tmp15<=1'b0;
    else tmp15<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp16<=1'b0;
    end
    else if(tmp15==1'b1)
    begin
    cmp16<=1'b1;
    end else if(tmp64==1'b1)
        cmp16<=1'b0;
    else cmp16<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp16<=1'b0;
    else if(cmp16==1'b1&&tmp64!=1'b1)
        tmp16<=1'b1;
    else if(tmp64==1'b1)
        tmp16<=1'b0;
    else tmp16<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp17<=1'b0;
    end
    else if(tmp16==1'b1)
    begin
    cmp17<=1'b1;
    end else if(tmp64==1'b1)
        cmp17<=1'b0;
    else cmp17<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp17<=1'b0;
    else if(cmp17==1'b1&&tmp64!=1'b1)
        tmp17<=1'b1;
    else if(tmp64==1'b1)
        tmp17<=1'b0;
    else tmp17<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp18<=1'b0;
    end
    else if(tmp17==1'b1)
    begin
    cmp18<=1'b1;
    end else if(tmp64==1'b1)
        cmp18<=1'b0;
    else cmp18<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp18<=1'b0;
    else if(cmp18==1'b1&&tmp64!=1'b1)
        tmp18<=1'b1;
    else if(tmp64==1'b1)
        tmp18<=1'b0;
    else tmp18<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp19<=1'b0;
    end
    else if(tmp18==1'b1)
    begin
    cmp19<=1'b1;
    end else if(tmp64==1'b1)
        cmp19<=1'b0;
    else cmp19<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp19<=1'b0;
    else if(cmp19==1'b1&&tmp64!=1'b1)
        tmp19<=1'b1;
    else if(tmp64==1'b1)
        tmp19<=1'b0;
    else tmp19<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp20<=1'b0;
    end
    else if(tmp19==1'b1)
    begin
    cmp20<=1'b1;
    end else if(tmp64==1'b1)
        cmp20<=1'b0;
    else cmp20<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp20<=1'b0;
    else if(cmp20==1'b1&&tmp64!=1'b1)
        tmp20<=1'b1;
    else if(tmp64==1'b1)
        tmp20<=1'b0;
    else tmp20<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp21<=1'b0;
    end
    else if(tmp20==1'b1)
    begin
    cmp21<=1'b1;
    end else if(tmp64==1'b1)
        cmp21<=1'b0;
    else cmp21<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp21<=1'b0;
    else if(cmp21==1'b1&&tmp64!=1'b1)
        tmp21<=1'b1;
    else if(tmp64==1'b1)
        tmp21<=1'b0;
    else tmp21<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp22<=1'b0;
    end
    else if(tmp21==1'b1)
    begin
    cmp22<=1'b1;
    end else if(tmp64==1'b1)
        cmp22<=1'b0;
    else cmp22<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp22<=1'b0;
    else if(cmp22==1'b1&&tmp64!=1'b1)
        tmp22<=1'b1;
    else if(tmp64==1'b1)
        tmp22<=1'b0;
    else tmp22<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp23<=1'b0;
    end
    else if(tmp22==1'b1)
    begin
    cmp23<=1'b1;
    end else if(tmp64==1'b1)
        cmp23<=1'b0;
    else cmp23<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp23<=1'b0;
    else if(cmp23==1'b1&&tmp64!=1'b1)
        tmp23<=1'b1;
    else if(tmp64==1'b1)
        tmp23<=1'b0;
    else tmp23<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp24<=1'b0;
    end
    else if(tmp23==1'b1)
    begin
    cmp24<=1'b1;
    end else if(tmp64==1'b1)
        cmp24<=1'b0;
    else cmp24<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp24<=1'b0;
    else if(cmp24==1'b1&&tmp64!=1'b1)
        tmp24<=1'b1;
    else if(tmp64==1'b1)
        tmp24<=1'b0;
    else tmp24<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp25<=1'b0;
    end
    else if(tmp24==1'b1)
    begin
    cmp25<=1'b1;
    end else if(tmp64==1'b1)
        cmp25<=1'b0;
    else cmp25<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp25<=1'b0;
    else if(cmp25==1'b1&&tmp64!=1'b1)
        tmp25<=1'b1;
    else if(tmp64==1'b1)
        tmp25<=1'b0;
    else tmp25<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp26<=1'b0;
    end
    else if(tmp25==1'b1)
    begin
    cmp26<=1'b1;
    end else if(tmp64==1'b1)
        cmp26<=1'b0;
    else cmp26<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp26<=1'b0;
    else if(cmp26==1'b1&&tmp64!=1'b1)
        tmp26<=1'b1;
    else if(tmp64==1'b1)
        tmp26<=1'b0;
    else tmp26<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp27<=1'b0;
    end
    else if(tmp26==1'b1)
    begin
    cmp27<=1'b1;
    end else if(tmp64==1'b1)
        cmp27<=1'b0;
    else cmp27<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp27<=1'b0;
    else if(cmp27==1'b1&&tmp64!=1'b1)
        tmp27<=1'b1;
    else if(tmp64==1'b1)
        tmp27<=1'b0;
    else tmp27<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp28<=1'b0;
    end
    else if(tmp27==1'b1)
    begin
    cmp28<=1'b1;
    end else if(tmp64==1'b1)
        cmp28<=1'b0;
    else cmp28<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp28<=1'b0;
    else if(cmp28==1'b1&&tmp64!=1'b1)
        tmp28<=1'b1;
    else if(tmp64==1'b1)
        tmp28<=1'b0;
    else tmp28<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp29<=1'b0;
    end
    else if(tmp28==1'b1)
    begin
    cmp29<=1'b1;
    end else if(tmp64==1'b1)
        cmp29<=1'b0;
    else cmp29<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp29<=1'b0;
    else if(cmp29==1'b1&&tmp64!=1'b1)
        tmp29<=1'b1;
    else if(tmp64==1'b1)
        tmp29<=1'b0;
    else tmp29<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp30<=1'b0;
    end
    else if(tmp29==1'b1)
    begin
    cmp30<=1'b1;
    end else if(tmp64==1'b1)
        cmp30<=1'b0;
    else cmp30<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp30<=1'b0;
    else if(cmp30==1'b1&&tmp64!=1'b1)
        tmp30<=1'b1;
    else if(tmp64==1'b1)
        tmp30<=1'b0;
    else tmp30<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp31<=1'b0;
    end
    else if(tmp30==1'b1)
    begin
    cmp31<=1'b1;
    end else if(tmp64==1'b1)
        cmp31<=1'b0;
    else cmp31<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp31<=1'b0;
    else if(cmp31==1'b1&&tmp64!=1'b1)
        tmp31<=1'b1;
    else if(tmp64==1'b1)
        tmp31<=1'b0;
    else tmp31<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp32<=1'b0;
    end
    else if(tmp31==1'b1)
    begin
    cmp32<=1'b1;
    end else if(tmp64==1'b1)
        cmp32<=1'b0;
    else cmp32<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp32<=1'b0;
    else if(cmp32==1'b1&&tmp64!=1'b1)
        tmp32<=1'b1;
    else if(tmp64==1'b1)
        tmp32<=1'b0;
    else tmp32<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp33<=1'b0;
    end
    else if(tmp32==1'b1)
    begin
    cmp33<=1'b1;
    end else if(tmp64==1'b1)
        cmp33<=1'b0;
    else cmp33<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp33<=1'b0;
    else if(cmp33==1'b1&&tmp64!=1'b1)
        tmp33<=1'b1;
    else if(tmp64==1'b1)
        tmp33<=1'b0;
    else tmp33<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp34<=1'b0;
    end
    else if(tmp33==1'b1)
    begin
    cmp34<=1'b1;
    end else if(tmp64==1'b1)
        cmp34<=1'b0;
    else cmp34<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp34<=1'b0;
    else if(cmp34==1'b1&&tmp64!=1'b1)
        tmp34<=1'b1;
    else if(tmp64==1'b1)
        tmp34<=1'b0;
    else tmp34<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp35<=1'b0;
    end
    else if(tmp34==1'b1)
    begin
    cmp35<=1'b1;
    end else if(tmp64==1'b1)
        cmp35<=1'b0;
    else cmp35<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp35<=1'b0;
    else if(cmp35==1'b1&&tmp64!=1'b1)
        tmp35<=1'b1;
    else if(tmp64==1'b1)
        tmp35<=1'b0;
    else tmp35<=1'b0;        
    end

always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp36<=1'b0;
    end
    else if(tmp35==1'b1)
    begin
        cmp36<=1'b1;
    end else if(tmp64==1'b1)
        cmp36<=1'b0;
    else cmp36<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp36<=1'b0;
    else if(cmp36==1'b1&&tmp64!=1'b1)
        tmp36<=1'b1;
    else if(tmp64==1'b1)
        tmp36<=1'b0;
    else tmp36<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp37<=1'b0;
    end
    else if(tmp36==1'b1)
    begin
    cmp37<=1'b1;
    end else if(tmp64==1'b1)
        cmp37<=1'b0;
    else cmp37<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp37<=1'b0;
    else if(cmp37==1'b1&&tmp64!=1'b1)
        tmp37<=1'b1;
    else if(tmp64==1'b1)
        tmp37<=1'b0;
    else tmp37<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp38<=1'b0;
    end
    else if(tmp37==1'b1)
    begin
    cmp38<=1'b1;
    end else if(tmp64==1'b1)
        cmp38<=1'b0;
    else cmp38<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp38<=1'b0;
    else if(cmp38==1'b1&&tmp64!=1'b1)
        tmp38<=1'b1;
    else if(tmp64==1'b1)
        tmp38<=1'b0;
    else tmp38<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp39<=1'b0;
    end
    else if(tmp38==1'b1)
    begin
    cmp39<=1'b1;
    end else if(tmp64==1'b1)
        cmp39<=1'b0;
    else cmp39<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp39<=1'b0;
    else if(cmp39==1'b1&&tmp64!=1'b1)
        tmp39<=1'b1;
    else if(tmp64==1'b1)
        tmp39<=1'b0;
    else tmp39<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp40<=1'b0;
    end
    else if(tmp39==1'b1)
    begin
    cmp40<=1'b1;
    end else if(tmp64==1'b1)
        cmp40<=1'b0;
    else cmp40<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp40<=1'b0;
    else if(cmp40==1'b1&&tmp64!=1'b1)
        tmp40<=1'b1;
    else if(tmp64==1'b1)
        tmp40<=1'b0;
    else tmp40<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp41<=1'b0;
    end
    else if(tmp40==1'b1)
    begin
    cmp41<=1'b1;
    end else if(tmp64==1'b1)
        cmp41<=1'b0;
    else cmp41<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp41<=1'b0;
    else if(cmp41==1'b1&&tmp64!=1'b1)
        tmp41<=1'b1;
    else if(tmp64==1'b1)
        tmp41<=1'b0;
    else tmp41<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp42<=1'b0;
    end
    else if(tmp41==1'b1)
    begin
    cmp42<=1'b1;
    end else if(tmp64==1'b1)
        cmp42<=1'b0;
    else cmp42<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp42<=1'b0;
    else if(cmp42==1'b1&&tmp64!=1'b1)
        tmp42<=1'b1;
    else if(tmp64==1'b1)
        tmp42<=1'b0;
    else tmp42<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp43<=1'b0;
    end
    else if(tmp42==1'b1)
    begin
    cmp43<=1'b1;
    end else if(tmp64==1'b1)
        cmp43<=1'b0;
    else cmp43<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp43<=1'b0;
    else if(cmp43==1'b1&&tmp64!=1'b1)
        tmp43<=1'b1;
    else if(tmp64==1'b1)
        tmp43<=1'b0;
    else tmp43<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp44<=1'b0;
    end
    else if(tmp43==1'b1)
    begin
    cmp44<=1'b1;
    end else if(tmp64==1'b1)
        cmp44<=1'b0;
    else cmp44<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp44<=1'b0;
    else if(cmp44==1'b1&&tmp64!=1'b1)
        tmp44<=1'b1;
    else if(tmp64==1'b1)
        tmp44<=1'b0;
    else tmp44<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp45<=1'b0;
    end
    else if(tmp44==1'b1)
    begin
    cmp45<=1'b1;
    end else if(tmp64==1'b1)
        cmp45<=1'b0;
    else cmp45<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp45<=1'b0;
    else if(cmp45==1'b1&&tmp64!=1'b1)
        tmp45<=1'b1;
    else if(tmp64==1'b1)
        tmp45<=1'b0;
    else tmp45<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp46<=1'b0;
    end
    else if(tmp45==1'b1)
    begin
    cmp46<=1'b1;
    end else if(tmp64==1'b1)
        cmp46<=1'b0;
    else cmp46<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp46<=1'b0;
    else if(cmp46==1'b1&&tmp64!=1'b1)
        tmp46<=1'b1;
    else if(tmp64==1'b1)
        tmp46<=1'b0;
    else tmp46<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp47<=1'b0;
    end
    else if(tmp46==1'b1)
    begin
    cmp47<=1'b1;
    end else if(tmp64==1'b1)
        cmp47<=1'b0;
    else cmp47<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp47<=1'b0;
    else if(cmp47==1'b1&&tmp64!=1'b1)
        tmp47<=1'b1;
    else if(tmp64==1'b1)
        tmp47<=1'b0;
    else tmp47<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp48<=1'b0;
    end
    else if(tmp47==1'b1)
    begin
    cmp48<=1'b1;
    end else if(tmp64==1'b1)
        cmp48<=1'b0;
    else cmp48<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp48<=1'b0;
    else if(cmp48==1'b1&&tmp64!=1'b1)
        tmp48<=1'b1;
    else if(tmp64==1'b1)
        tmp48<=1'b0;
    else tmp48<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp49<=1'b0;
    end
    else if(tmp48==1'b1)
    begin
    cmp49<=1'b1;
    end else if(tmp64==1'b1)
        cmp49<=1'b0;
    else cmp49<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp49<=1'b0;
    else if(cmp49==1'b1&&tmp64!=1'b1)
        tmp49<=1'b1;
    else if(tmp64==1'b1)
        tmp49<=1'b0;
    else tmp49<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp50<=1'b0;
    end
    else if(tmp49==1'b1)
    begin
    cmp50<=1'b1;
    end else if(tmp64==1'b1)
        cmp50<=1'b0;
    else cmp50<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp50<=1'b0;
    else if(cmp50==1'b1&&tmp64!=1'b1)
        tmp50<=1'b1;
    else if(tmp64==1'b1)
        tmp50<=1'b0;
    else tmp50<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp51<=1'b0;
    end
    else if(tmp50==1'b1)
    begin
    cmp51<=1'b1;
    end else if(tmp64==1'b1)
        cmp51<=1'b0;
    else cmp51<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp51<=1'b0;
    else if(cmp51==1'b1&&tmp64!=1'b1)
        tmp51<=1'b1;
    else if(tmp64==1'b1)
        tmp51<=1'b0;
    else tmp51<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp52<=1'b0;
    end
    else if(tmp51==1'b1)
    begin
    cmp52<=1'b1;
    end else if(tmp64==1'b1)
        cmp52<=1'b0;
    else cmp52<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp52<=1'b0;
    else if(cmp52==1'b1&&tmp64!=1'b1)
        tmp52<=1'b1;
    else if(tmp64==1'b1)
        tmp52<=1'b0;
    else tmp52<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp53<=1'b0;
    end
    else if(tmp52==1'b1)
    begin
    cmp53<=1'b1;
    end else if(tmp64==1'b1)
        cmp53<=1'b0;
    else cmp53<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp53<=1'b0;
    else if(cmp53==1'b1&&tmp64!=1'b1)
        tmp53<=1'b1;
    else if(tmp64==1'b1)
        tmp53<=1'b0;
    else tmp53<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp54<=1'b0;
    end
    else if(tmp53==1'b1)
    begin
    cmp54<=1'b1;
    end else if(tmp64==1'b1)
        cmp54<=1'b0;
    else cmp54<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp54<=1'b0;
    else if(cmp54==1'b1&&tmp64!=1'b1)
        tmp54<=1'b1;
    else if(tmp64==1'b1)
        tmp54<=1'b0;
    else tmp54<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp55<=1'b0;
    end
    else if(tmp54==1'b1)
    begin
    cmp55<=1'b1;
    end else if(tmp64==1'b1)
        cmp55<=1'b0;
    else cmp55<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp55<=1'b0;
    else if(cmp55==1'b1&&tmp64!=1'b1)
        tmp55<=1'b1;
    else if(tmp64==1'b1)
        tmp55<=1'b0;
    else tmp55<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp56<=1'b0;
    end
    else if(tmp55==1'b1)
    begin
    cmp56<=1'b1;
    end else if(tmp64==1'b1)
        cmp56<=1'b0;
    else cmp56<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp56<=1'b0;
    else if(cmp56==1'b1&&tmp64!=1'b1)
        tmp56<=1'b1;
    else if(tmp64==1'b1)
        tmp56<=1'b0;
    else tmp56<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp57<=1'b0;
    end
    else if(tmp56==1'b1)
    begin
    cmp57<=1'b1;
    end else if(tmp64==1'b1)
        cmp57<=1'b0;
    else cmp57<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp57<=1'b0;
    else if(cmp57==1'b1&&tmp64!=1'b1)
        tmp57<=1'b1;
    else if(tmp64==1'b1)
        tmp57<=1'b0;
    else tmp57<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp58<=1'b0;
    end
    else if(tmp57==1'b1)
    begin
    cmp58<=1'b1;
    end else if(tmp64==1'b1)
        cmp58<=1'b0;
    else cmp58<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp58<=1'b0;
    else if(cmp58==1'b1&&tmp64!=1'b1)
        tmp58<=1'b1;
    else if(tmp64==1'b1)
        tmp58<=1'b0;
    else tmp58<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp59<=1'b0;
    end
    else if(tmp58==1'b1)
    begin
    cmp59<=1'b1;
    end else if(tmp64==1'b1)
        cmp59<=1'b0;
    else cmp59<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp59<=1'b0;
    else if(cmp59==1'b1&&tmp64!=1'b1)
        tmp59<=1'b1;
    else if(tmp64==1'b1)
        tmp59<=1'b0;
    else tmp59<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp60<=1'b0;
    end
    else if(tmp59==1'b1)
    begin
    cmp60<=1'b1;
    end else if(tmp64==1'b1)
        cmp60<=1'b0;
    else cmp60<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp60<=1'b0;
    else if(cmp60==1'b1&&tmp64!=1'b1)
        tmp60<=1'b1;
    else if(tmp64==1'b1)
        tmp60<=1'b0;
    else tmp60<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp61<=1'b0;
    end
    else if(tmp60==1'b1)
    begin
    cmp61<=1'b1;
    end else if(tmp64==1'b1)
        cmp61<=1'b0;
    else cmp61<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp61<=1'b0;
    else if(cmp61==1'b1&&tmp64!=1'b1)
        tmp61<=1'b1;
    else if(tmp64==1'b1)
        tmp61<=1'b0;
    else tmp61<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp62<=1'b0;
    end
    else if(tmp61==1'b1)
    begin
    cmp62<=1'b1;
    end else if(tmp64==1'b1)
        cmp62<=1'b0;
    else cmp62<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp62<=1'b0;
    else if(cmp62==1'b1&&tmp64!=1'b1)
        tmp62<=1'b1;
    else if(tmp64==1'b1)
        tmp62<=1'b0;
    else tmp62<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp63<=1'b0;
    end
    else if(tmp62==1'b1)
    begin
    cmp63<=1'b1;
    end else if(tmp64==1'b1)
        cmp63<=1'b0;
    else cmp63<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp63<=1'b0;
    else if(cmp63==1'b1&&tmp64!=1'b1)
        tmp63<=1'b1;
    else if(tmp64==1'b1)
        tmp63<=1'b0;
    else tmp63<=1'b0;        
    end


always@(posedge i_clk,posedge i_rst) begin
    if(i_rst)begin
        cmp64<=1'b0;
    end
    else if(tmp63==1'b1)
    begin
    cmp64<=1'b1;
    end else if(tmp64==1'b1)
        cmp64<=1'b0;
    else cmp64<=1'b0;
end

always @(posedge i_clk) begin
    if(i_rst)
        tmp64<=1'b0;
    else if(cmp64==1'b1)
        tmp64<=1'b1;
    else tmp64<=0;
    
    end



always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_iterator_V[0] <= 256'h7380166f4914b2b9172442d7da8a0600_a96f30bc163138aae38dee4db0fb0e4e;
    else if(!r_multi_flag)
        r_iterator_V[0] <= 256'h7380166f4914b2b9172442d7da8a0600_a96f30bc163138aae38dee4db0fb0e4e;
    else if(r_multi_flag&&r_batch_cnt>1) begin//cnt>0 after the second data in, this code works then always work
        r_iterator_V[0] <= r_V_multi_d3;
    end
end

reg f2;
/*----output----*/  
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ro_Encrypt_Data  <= 'd0;
        f2<= 0 ;
    end else if(cmp64&!tmp64) begin
        if(f2==0)begin
            f2<=1;
        end else begin
            f2<=0;
        end
    end else if(f2==1)begin
        ro_Encrypt_Data  <= final_V ^ r_iterator_V[0];
        f2<= 0 ;
    end else
        ro_Encrypt_Data<=ro_Encrypt_Data;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_Encrypt_Valid <= 'd0;
    else if(cmp64==1'b1)
        ro_Encrypt_Valid <= 'd1;
    else ro_Encrypt_Valid <= 'd0;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_out_cnt <= 'd0;
    else if(r_out_cnt == P_ITERATOR_CYCLE - 1)
        r_out_cnt <= 'd0;
    else if(w_extend_valid | r_out_cnt)
        r_out_cnt <= r_out_cnt + 1;
    else 
        r_out_cnt <= r_out_cnt;
end


endmodule


