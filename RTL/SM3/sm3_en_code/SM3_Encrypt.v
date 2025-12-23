`timescale 1ns / 1ps

module sm3_encrypt(
    input                   i_clk               ,   //输入时钟
    input                   i_rst               ,   //输入复位

    input  [511:0]          i_batch_data0     ,   //输入待加密数�???????
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
// message schedule is now read from RAM in Data_Extend
// 使用三寄存器替代 65 深度迭代数组
reg  [255:0]        r_V_init;     // 初始值（原 r_iterator_V[0]）
reg  [255:0]        r_V_a;        // 迭代寄存器 A（当前轮）
reg  [255:0]        r_V_b;        // 迭代寄存器 B（上一轮）
reg  [255:0]        iter_result;  // 第64轮运算后的最终值（原 r_iterator_V[64]）
reg  [255:0]        next_V;       // 迭代中间值
reg  [6:0]          round_cnt;    // 迭代轮数 0..64
reg                  iter_active;  // 迭代使能

// 仅保留用到的两个值的别名，替代原 [0:64] 大数组
wire [255:0]        V0  = r_V_init;      // 原 r_iterator_V[0]
wire [255:0]        V64 = iter_result;   // 原 r_iterator_V[64]
reg  [255 :0]       ro_Encrypt_Data             ;
reg                 ro_Encrypt_Valid            ;
reg  [15  :0]       r_out_cnt                   ;
reg  [63  :0]       r_cmp_valid                 ;

reg cmp0,cmp1,	 cmp2,	 cmp3,	 cmp4,	 cmp5,	 cmp6,	 cmp7,	 cmp8,	 cmp9,	 cmp10,	 cmp11,	 cmp12,	 cmp13,	 cmp14,	 cmp15,	 cmp16,	 cmp17,	 cmp18,	 cmp19,	 cmp20,	 cmp21,	 cmp22,	 cmp23,	 cmp24,	 cmp25,	 cmp26,	 cmp27,	 cmp28,	 cmp29,	 cmp30,	 cmp31,	 cmp32,	 cmp33,	 cmp34,	 cmp35,	 cmp36,	 cmp37,	 cmp38,	 cmp39,	 cmp40,	 cmp41,	 cmp42,	 cmp43,	 cmp44,	 cmp45,	 cmp46,	 cmp47,	 cmp48,	 cmp49,	 cmp50,	 cmp51,	 cmp52,	 cmp53,	 cmp54,	 cmp55,	 cmp56,	 cmp57,	 cmp58,	 cmp59,	 cmp60,	 cmp61,	 cmp62,	 cmp63,	 cmp64;


reg tmp1,	 tmp2,	 tmp3,	 tmp4,	 tmp5,	 tmp6,	 tmp7,	 tmp8,	 tmp9,	 tmp10,	 tmp11,	 tmp12,	 tmp13,	 tmp14,	 tmp15,	 tmp16,	 tmp17,	 tmp18,	 tmp19,	 tmp20,	 tmp21,	 tmp22,	 tmp23,	 tmp24,	 tmp25,	 tmp26,	 tmp27,	 tmp28,	 tmp29,	 tmp30,	 tmp31,	 tmp32,	 tmp33,	 tmp34,	 tmp35,	 tmp36,	 tmp37,	 tmp38,	 tmp39,	 tmp40,	 tmp41,	 tmp42,	 tmp43,	 tmp44,	 tmp45,	 tmp46,	 tmp47,	 tmp48,	 tmp49,	 tmp50,	 tmp51,	 tmp52,	 tmp53,	 tmp54,	 tmp55,	 tmp56,	 tmp57,	 tmp58,	 tmp59,	 tmp60,	 tmp61,	 tmp62,	 tmp63,	 tmp64;


reg [255:0]r_iter64;
wire                w_extend_valid              ;
reg  [6:0]          rd_addr0, rd_addr1; // addresses for Wj and W'j
wire [31:0]         w_rd_data0, w_rd_data1;    // read data from Data_Extend RAM
reg  [31:0]         w_Wj_q, w_Wjp_q;          // registered Wj and W'j used by iterator
reg                 iter_data_valid;           // indicates read data is valid for compute
reg  [6:0]          addr_cnt;                  // address pointer for reading schedule
//wire [255 :0]       w_iterator_in_V[0:63]       ;
//wire [255 :0]       w_iteratot_out_V[0:63]      ;  

assign o_Encrypt_Data  =    ro_Encrypt_Data     ;
assign o_Encrypt_Valid =    (!cmp64)&ro_Encrypt_Valid    ;

//multi part

reg r_multi_flag;

reg         r_input_valid;
reg [255:0] r_V_multi;
wire        w_for_V64_buffer;
reg [31:0]  r_batch_cnt=32'b0;



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
// 后续各轮逻辑由统一迭代 always 块控制

    
end


reg [255:0] r_V_multi_d1;  // 第一拍
reg [255:0] r_V_multi_d2;  // 第二拍
reg [255:0] r_V_multi_d3;  // 第三拍
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
	    r_V_multi_d1 <= 256'b0;
        r_V_multi_d2 <= 256'b0;
        r_V_multi_d3 <= 256'b0;
    end else begin
        r_V_multi_d1 <= r_V_multi;    // 第一级采样
        r_V_multi_d2 <= r_V_multi_d1; // 第二级传递
        r_V_multi_d3 <= r_V_multi_d2; // 第三级传递
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

/*----Extend (RAM-based)-----*/
Data_Extend Data_Extend_u0(
    .i_clk              (i_clk              ),
    .i_rst              (i_rst              ),
    .i_padding_data     (r_padding_data     ),
    .i_padding_valid    (r_padding_valid    ),
    .i_rd_addr0         (rd_addr0           ),
    .i_rd_addr1         (rd_addr1           ),
    .o_rd_data0         (w_rd_data0         ),
    .o_rd_data1         (w_rd_data1         ),
    .o_extend_valid     (w_extend_valid     )
);

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_extend_valid <= 'd0;
        w_Wj_q         <= 32'd0;
        w_Wjp_q        <= 32'd0;
    end else begin
        r_extend_valid <= w_extend_valid;
        // capture RAM read outputs each cycle
        w_Wj_q  <= w_rd_data0;
        w_Wjp_q <= w_rd_data1;
    end
end

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
wire [31:0]  i_j;

wire [31:0]                 w_Tj_y[0:63]    ;
wire [31:0]                 w_Tj            ;

// Wj/W'j fetched from Data_Extend RAM via rd_addr ports

assign w_Tj_y[0]   =32'h79cc4519;
assign w_Tj_y[32] =32'h7a879d8a;


//assign w_Tj = Tj(i_j );

// W'j is provided by second read port (w_Wjp_q)

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

/*
// 旧的分散轮次 always 块整体注释，改为统一迭代实现
*/
// 统一迭代 always 块：用 A/B 两寄存器交替迭代 64 轮
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        r_V_a       <= 256'b0;
        r_V_b       <= 256'b0;
        next_V      <= 256'b0;
        round_cnt   <= 7'd0;
        iter_active <= 1'b0;
        iter_result <= 256'b0;
        iter_data_valid <= 1'b0;
        addr_cnt        <= 7'd0;
        rd_addr0        <= 7'd0;
        rd_addr1        <= 7'd68;
    end else begin
        // 当扩展完成后启动迭代（沿用原始 cmp0 作为启动条件）
        if (cmp0 == 1'b1 && !iter_active) begin
            // 启动：先发起对 round 0 的 W/W' 读请求，一拍后再计算
            iter_active     <= 1'b1;
            round_cnt       <= 7'd0;
            addr_cnt        <= 7'd0;
            rd_addr0        <= 7'd0;
            rd_addr1        <= 7'd68;
            iter_data_valid <= 1'b0; // 数据一拍后有效
        end else if (iter_active && tmp64 != 1'b1) begin
            // 发起下一轮地址请求（每拍发起一次），同时用上一拍读出的数据计算当前轮
            rd_addr0 <= addr_cnt;
            rd_addr1 <= 7'd68 + addr_cnt;
            addr_cnt <= addr_cnt + 7'd1;

            if (!iter_data_valid) begin
                // 第一拍用于对 round 0 读取，不计算
                iter_data_valid <= 1'b1;
            end else if (round_cnt < 7'd64) begin
                if (round_cnt[0] == 1'b0) begin
                    // 偶数轮：由 A -> B
                    next_V  <= iterator(r_V_a, round_cnt, w_Tj_y[round_cnt], w_Wj_q, w_Wjp_q);
                    r_V_b   <= iterator(r_V_a, round_cnt, w_Tj_y[round_cnt], w_Wj_q, w_Wjp_q);
                end else begin
                    // 奇数轮：由 B -> A
                    next_V  <= iterator(r_V_b, round_cnt, w_Tj_y[round_cnt], w_Wj_q, w_Wjp_q);
                    r_V_a   <= iterator(r_V_b, round_cnt, w_Tj_y[round_cnt], w_Wj_q, w_Wjp_q);
                end
                // 在第 63 轮计算完成后锁存最终结果（对应原 r_iterator_V[64]）
                if (round_cnt == 7'd63) begin
                    iter_result <= next_V;
                end
                round_cnt <= round_cnt + 7'd1;
            end
        end

        // 迭代结束复位 iter_active（与 tmp64 配合由外部时序控制）
        if (round_cnt == 7'd64) begin
            iter_active <= 1'b0;
        end
    end
end
    /* 原 3..63 轮分散 always 逻辑已移除，统一由上方迭代 always 控制 */
    always@(posedge i_clk,posedge i_rst) begin
        if(i_rst) begin
            cmp64 <= 1'b0;
        end else begin
            // 在 round_cnt 计满 64 时，产生 cmp64 脉冲，配合下游 tmp64 与输出锁存
            if(round_cnt == 7'd64)
                cmp64 <= 1'b1;
            else
                cmp64 <= 1'b0;
        end
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
        /* removed legacy: r_iterator_V[5]<=iterator(
            r_iterator_V[4], 
            32'd4,
            w_Tj_y[4],
            w_Wj[4],
            w_Wj_[4]
                ); */
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
        /* removed legacy: r_iterator_V[6]<=iterator(
            r_iterator_V[5], 
            32'd5,
            w_Tj_y[5],
            w_Wj[5],
            w_Wj_[5]
                ); */
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
        /* removed legacy: r_iterator_V[7]<=iterator(
            r_iterator_V[6], 
            32'd6,
            w_Tj_y[6],
            w_Wj[6],
            w_Wj_[6]
                ); */
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
        /* removed legacy: r_iterator_V[8]<=iterator(
            r_iterator_V[7], 
            32'd7,
            w_Tj_y[7],
            w_Wj[7],
            w_Wj_[7]
                ); */
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
        /* removed legacy: r_iterator_V[9]<=iterator(
            r_iterator_V[8], 
            32'd8,
            w_Tj_y[8],
            w_Wj[8],
            w_Wj_[8]
                ); */
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
        /* removed legacy: r_iterator_V[10]<=iterator(
            r_iterator_V[9], 
            32'd9,
            w_Tj_y[9],
            w_Wj[9],
            w_Wj_[9]
                ); */
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
        /* removed legacy: r_iterator_V[11]<=iterator(
            r_iterator_V[10], 
            32'd10,
            w_Tj_y[10],
            w_Wj[10],
            w_Wj_[10]
                ); */
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
        /* removed legacy: r_iterator_V[12]<=iterator(
            r_iterator_V[11], 
            32'd11,
            w_Tj_y[11],
            w_Wj[11],
            w_Wj_[11]
                ); */
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
        /* removed legacy: r_iterator_V[13]<=iterator(
            r_iterator_V[12], 
            32'd12,
            w_Tj_y[12],
            w_Wj[12],
            w_Wj_[12]
                ); */
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
        /* removed legacy: r_iterator_V[14]<=iterator(
            r_iterator_V[13], 
            32'd13,
            w_Tj_y[13],
            w_Wj[13],
            w_Wj_[13]
                ); */
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
        /* removed legacy:
        r_iterator_V[15]<=iterator(
            r_iterator_V[14], 
            32'd14,
            w_Tj_y[14],
            w_Wj[14],
            w_Wj_[14]
                );
        */
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
        /* removed legacy:
        r_iterator_V[16]<=iterator(
            r_iterator_V[15], 
            32'd15,
            w_Tj_y[15],
            w_Wj[15],
            w_Wj_[15]
                );
        */
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
        /* removed legacy:
        r_iterator_V[17]<=iterator(
            r_iterator_V[16], 
            32'd16,
            w_Tj_y[16],
            w_Wj[16],
            w_Wj_[16]
                );
        */
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
        /* removed legacy:
        r_iterator_V[18]<=iterator(
            r_iterator_V[17], 
            32'd17,
            w_Tj_y[17],
            w_Wj[17],
            w_Wj_[17]
                );
        */
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
        /* removed legacy:
        r_iterator_V[19]<=iterator(
            r_iterator_V[18], 
            32'd18,
            w_Tj_y[18],
            w_Wj[18],
            w_Wj_[18]
                );
        */
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
        /* removed legacy:
        r_iterator_V[20]<=iterator(
            r_iterator_V[19], 
            32'd19,
            w_Tj_y[19],
            w_Wj[19],
            w_Wj_[19]
                );
        */
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
        /* removed legacy:
        r_iterator_V[21]<=iterator(
            r_iterator_V[20], 
            32'd20,
            w_Tj_y[20],
            w_Wj[20],
            w_Wj_[20]
                );
        */
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
        /* removed legacy:
        r_iterator_V[22]<=iterator(
            r_iterator_V[21], 
            32'd21,
            w_Tj_y[21],
            w_Wj[21],
            w_Wj_[21]
                );
        */
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
        /* removed legacy:
        r_iterator_V[23]<=iterator(
            r_iterator_V[22], 
            32'd22,
            w_Tj_y[22],
            w_Wj[22],
            w_Wj_[22]
                );
        */
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
        /* removed legacy:
        r_iterator_V[24]<=iterator(
            r_iterator_V[23], 
            32'd23,
            w_Tj_y[23],
            w_Wj[23],
            w_Wj_[23]
                );
        */
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
        /* removed legacy:
        r_iterator_V[25]<=iterator(
            r_iterator_V[24], 
            32'd24,
            w_Tj_y[24],
            w_Wj[24],
            w_Wj_[24]
                );
        */
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
        /* removed legacy:
        r_iterator_V[26]<=iterator(
            r_iterator_V[25], 
            32'd25,
            w_Tj_y[25],
            w_Wj[25],
            w_Wj_[25]
                );
        */
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
        /* removed legacy:
        r_iterator_V[27]<=iterator(
            r_iterator_V[26], 
            32'd26,
            w_Tj_y[26],
            w_Wj[26],
            w_Wj_[26]
                );
        */
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
        /* removed legacy:
        r_iterator_V[28]<=iterator(
            r_iterator_V[27], 
            32'd27,
            w_Tj_y[27],
            w_Wj[27],
            w_Wj_[27]
                );
        */
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
        /* removed legacy:
        r_iterator_V[29]<=iterator(
            r_iterator_V[28], 
            32'd28,
            w_Tj_y[28],
            w_Wj[28],
            w_Wj_[28]
                );
        */
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
        /* removed legacy:
        r_iterator_V[30]<=iterator(
            r_iterator_V[29], 
            32'd29,
            w_Tj_y[29],
            w_Wj[29],
            w_Wj_[29]
                );
        */
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
        /* removed legacy:
        r_iterator_V[31]<=iterator(
            r_iterator_V[30], 
            32'd30,
            w_Tj_y[30],
            w_Wj[30],
            w_Wj_[30]
                );
        */
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
        /* removed legacy:
        r_iterator_V[32]<=iterator(
            r_iterator_V[31], 
            32'd31,
            w_Tj_y[31],
            w_Wj[31],
            w_Wj_[31]
                );
        */
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
        /* removed legacy:
        r_iterator_V[33]<=iterator(
            r_iterator_V[32], 
            32'd32,
            w_Tj_y[32],
            w_Wj[32],
            w_Wj_[32]
                );
        */
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
        /* removed legacy:
        r_iterator_V[34]<=iterator(
            r_iterator_V[33], 
            32'd33,
            w_Tj_y[33],
            w_Wj[33],
            w_Wj_[33]
                );
        */
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
        /* removed legacy:
        r_iterator_V[35]<=iterator(
            r_iterator_V[34], 
            32'd34,
            w_Tj_y[34],
            w_Wj[34],
            w_Wj_[34]
                );
        */
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
        /* removed legacy:
        r_iterator_V[36]<=iterator(
            r_iterator_V[35], 
            32'd35,
            w_Tj_y[35],
            w_Wj[35],
            w_Wj_[35]
                );
        */
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
        /* removed legacy:
        r_iterator_V[37]<=iterator(
            r_iterator_V[36], 
            32'd36,
            w_Tj_y[36],
            w_Wj[36],
            w_Wj_[36]
                );
        */
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
        /* removed legacy:
        r_iterator_V[38]<=iterator(
            r_iterator_V[37], 
            32'd37,
            w_Tj_y[37],
            w_Wj[37],
            w_Wj_[37]
                );
        */
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
        /* removed legacy:
        r_iterator_V[39]<=iterator(
            r_iterator_V[38], 
            32'd38,
            w_Tj_y[38],
            w_Wj[38],
            w_Wj_[38]
                );
        */
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
        /* removed legacy:
        r_iterator_V[40]<=iterator(
            r_iterator_V[39], 
            32'd39,
            w_Tj_y[39],
            w_Wj[39],
            w_Wj_[39]
                );
        */
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
        /* removed legacy:
        r_iterator_V[41]<=iterator(
            r_iterator_V[40], 
            32'd40,
            w_Tj_y[40],
            w_Wj[40],
            w_Wj_[40]
                );
        */
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
        /* removed legacy:
        r_iterator_V[42]<=iterator(
            r_iterator_V[41], 
            32'd41,
            w_Tj_y[41],
            w_Wj[41],
            w_Wj_[41]
                );
        */
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
        /* removed legacy:
        r_iterator_V[43]<=iterator(
            r_iterator_V[42], 
            32'd42,
            w_Tj_y[42],
            w_Wj[42],
            w_Wj_[42]
                );
        */
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
        /* removed legacy:
        r_iterator_V[44]<=iterator(
            r_iterator_V[43], 
            32'd43,
            w_Tj_y[43],
            w_Wj[43],
            w_Wj_[43]
                );
        */
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
        /* removed legacy:
        r_iterator_V[45]<=iterator(
            r_iterator_V[44], 
            32'd44,
            w_Tj_y[44],
            w_Wj[44],
            w_Wj_[44]
                );
        */
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
        /* removed legacy:
        r_iterator_V[46]<=iterator(
            r_iterator_V[45], 
            32'd45,
            w_Tj_y[45],
            w_Wj[45],
            w_Wj_[45]
                );
        */
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
        /* removed legacy:
        r_iterator_V[47]<=iterator(
            r_iterator_V[46], 
            32'd46,
            w_Tj_y[46],
            w_Wj[46],
            w_Wj_[46]
                );
        */
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
        /* removed legacy:
        r_iterator_V[48]<=iterator(
            r_iterator_V[47], 
            32'd47,
            w_Tj_y[47],
            w_Wj[47],
            w_Wj_[47]
                );
        */
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
        /* removed legacy:
        r_iterator_V[49]<=iterator(
            r_iterator_V[48], 
            32'd48,
            w_Tj_y[48],
            w_Wj[48],
            w_Wj_[48]
                );
        */
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
        /* removed legacy:
        r_iterator_V[50]<=iterator(
            r_iterator_V[49], 
            32'd49,
            w_Tj_y[49],
            w_Wj[49],
            w_Wj_[49]
                );
        */
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
        /* removed legacy:
        r_iterator_V[51]<=iterator(
            r_iterator_V[50], 
            32'd50,
            w_Tj_y[50],
            w_Wj[50],
            w_Wj_[50]
                );
        */
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
        /* removed legacy:
        r_iterator_V[52]<=iterator(
            r_iterator_V[51], 
            32'd51,
            w_Tj_y[51],
            w_Wj[51],
            w_Wj_[51]
                );
        */
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
        /* removed legacy:
        r_iterator_V[53]<=iterator(
            r_iterator_V[52], 
            32'd52,
            w_Tj_y[52],
            w_Wj[52],
            w_Wj_[52]
                );
        */
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
        /* removed legacy:
        r_iterator_V[54]<=iterator(
            r_iterator_V[53], 
            32'd53,
            w_Tj_y[53],
            w_Wj[53],
            w_Wj_[53]
                );
        */
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
        /* removed legacy:
        r_iterator_V[55]<=iterator(
            r_iterator_V[54], 
            32'd54,
            w_Tj_y[54],
            w_Wj[54],
            w_Wj_[54]
                );
        */
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
        /* removed legacy:
        r_iterator_V[56]<=iterator(
            r_iterator_V[55], 
            32'd55,
            w_Tj_y[55],
            w_Wj[55],
            w_Wj_[55]
                );
        */
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
        /* removed legacy:
        r_iterator_V[57]<=iterator(
            r_iterator_V[56], 
            32'd56,
            w_Tj_y[56],
            w_Wj[56],
            w_Wj_[56]
                );
        */
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
        /* removed legacy:
        r_iterator_V[58]<=iterator(
            r_iterator_V[57], 
            32'd57,
            w_Tj_y[57],
            w_Wj[57],
            w_Wj_[57]
                );
        */
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
        r_iterator_V[59]<=iterator(
                r_iterator_V[58], 
                32'd58,
                w_Tj_y[58],
                w_Wj[58],
                w_Wj_[58]
                        );
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
        /* removed legacy:
        r_iterator_V[60]<=iterator(
            r_iterator_V[59], 
            32'd59,
            w_Tj_y[59],
            w_Wj[59],
            w_Wj_[59]
                );
        */
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
        /* removed legacy:
        r_iterator_V[61]<=iterator(
            r_iterator_V[60], 
            32'd60,
            w_Tj_y[60],
            w_Wj[60],
            w_Wj_[60]
                );
        */
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
        /* removed legacy:
        r_iterator_V[62]<=iterator(
            r_iterator_V[61], 
            32'd61,
            w_Tj_y[61],
            w_Wj[61],
            w_Wj_[61]
                );
        */
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
        /* removed legacy:
        r_iterator_V[63]<=iterator(
            r_iterator_V[62], 
            32'd62,
            w_Tj_y[62],
            w_Wj[62],
            w_Wj_[62]
                );
        */
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



*/
always@(posedge i_clk,posedge i_rst) begin
    if(i_rst) begin
        cmp64 <= 1'b0;
    end else begin
        // 在 round_cnt 计满 64 时，产生 cmp64 脉冲，配合下游 tmp64 与输出锁存
        if(round_cnt == 7'd64)
            cmp64 <= 1'b1;
        else
            cmp64 <= 1'b0;
    end
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
        r_V_init <= 256'h7380166f4914b2b9172442d7da8a0600_a96f30bc163138aae38dee4db0fb0e4e;
    else if(!r_multi_flag)
        r_V_init <= 256'h7380166f4914b2b9172442d7da8a0600_a96f30bc163138aae38dee4db0fb0e4e;
    else if(r_multi_flag&&r_batch_cnt>1) begin//cnt>0 after the second data in, this code works then always work
        r_V_init <= r_V_multi_d3;
    end
end

/*----output----*/  
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ro_Encrypt_Data  <= 'd0;
    end else if(cmp64&!tmp64) begin
        ro_Encrypt_Data  <= V64 ^ V0;
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


