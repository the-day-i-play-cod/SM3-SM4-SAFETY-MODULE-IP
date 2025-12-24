

module  sm3_top (	
    input               i_clk               ,
    input               i_rst               ,
    input     [511:0]   i_data              ,
    input               i_input_valid       ,
    input               i_multi_flag          ,  //need to keep until en finished or data in finished // //shold en finished in fact ,impact en new vars
    input     [5:0  ]   i_byte_nums         ,                                                       //,keep in apb module can end at no multi/data in and last en int out
    input               i_m_l_bflag         ,  //multi last batch flag
    output    [255:0]   o_hash_result         ,
    output              o_output_valid         //can be seen as int

); 

//and int judge I think judge by bytes nums and i_multi_flag outside then cnt en_valid nums yse!
//reg paddone1 recover 0 until en finished or cnt finished    
reg             r_pad_done1_flag;
reg             o_r_pad_done1;
reg             r_multi_flag_top;

reg [31:0]      r_o_batch_cnt;
reg [31:0]      count        ;
reg             r_o_output_valid;
reg             r_sel_encrypt_valid; // should output en_valid if 2Bs from pading ,can output when multi
assign          o_output_valid=r_sel_encrypt_valid;
always @(posedge i_clk,posedge i_rst) begin
    if(i_rst) r_multi_flag_top<=0;
    else if(r_pad_done1_flag| i_multi_flag )
    r_multi_flag_top<=1;
     else
     r_multi_flag_top<=0;
end


reg [31:0]   counter;
reg         count_done;

reg         keep_m_l_bflag;

always @(posedge i_clk, posedge i_rst) begin  //very simple 
    if (i_rst) begin
        keep_m_l_bflag <= 1'b0;
    end else begin
        if (o_output_valid) begin
            keep_m_l_bflag <= 1'b0;        // 最高优先级清零
        end else if (i_m_l_bflag) begin
            keep_m_l_bflag <= 1'b1;        // 单周期捕获
        end
    end
end

always @(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        counter <= 0;
    end else begin
        if (i_m_l_bflag&o_output_valid) begin
            counter <= 0;
        end else if ((!i_m_l_bflag)&&i_multi_flag ) begin            
        //end else if ((!i_m_l_bflag)&&(!keep_m_l_bflag)) begin
            if (i_input_valid) begin
                counter <= counter + 1;
            end
        end
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin          // 异步复位
        count <= 12'd0;
        count_done <= 1'b0;
    end else if (r_pad_done1_flag) begin
        if (count == 12'd1197) begin    // 达到阈�??
            count <= 12'd0;
            count_done <= 1'b1;       // 输出完成脉冲
        end
        else begin
            count <= count + 1;    // 正常计数
            count_done <= 1'b0;
        end
    end
    else begin
        count <= 0;               // 保持状�??
        count_done <= 1'b0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
     if(i_rst) 
        r_pad_done1_flag<=0;
     else if(o_r_pad_done1)
        r_pad_done1_flag<=1;
     else  if (count_done == 1'b1)// XX THEN go 0 many choices
        r_pad_done1_flag<=0;
     else r_pad_done1_flag<=r_pad_done1_flag;
end

reg     [511:0]             r_padded_data0;
reg     [511:0]             r_padded_data1;

reg     [511:0]             r_padded_data0_keep;
reg     [511:0]             r_batch1_keep;
reg     [511:0]             r_padded_data_en_in;
reg                         r_input_valid_en;

reg                         r_pad_done    ;

reg     [255:0]             encrypt_data ;
reg                         encrypt_valid;
reg                         rr_pad_done1;

assign o_hash_result=encrypt_data;
always @(posedge i_clk,posedge i_rst) begin
    if(i_rst) begin
        r_padded_data_en_in<=0;
        r_input_valid_en<=0;
        //r_sel_encrypt_valid<=0;
    end else if(i_multi_flag&&!i_m_l_bflag)begin
        r_padded_data_en_in <=i_data         ;  //as asume delay one cycle than input
        r_input_valid_en    <=i_input_valid  ; //?? or input_valid_flag
       // r_sel_encrypt_valid <=encrypt_valid  ;
    //end else if(i_multi_flag&&!i_m_l_bflag) begin
    end else if((i_multi_flag&i_m_l_bflag)||(!i_multi_flag)) begin

        if(!o_r_pad_done1&r_pad_done) begin
            r_padded_data_en_in<=r_padded_data0;
            r_input_valid_en<=1'b1;

        end else if(o_r_pad_done1) begin
            rr_pad_done1<=1'b1;
            r_batch1_keep<=r_padded_data1;
            r_padded_data_en_in<=r_padded_data0;
            r_input_valid_en<=1'b1;
        end else if(encrypt_valid&rr_pad_done1) begin
            r_padded_data_en_in<=r_batch1_keep;
            r_input_valid_en<=1'b1;
            rr_pad_done1<=1'b0;
        end
        else begin
            r_input_valid_en<=1'b0;
            r_padded_data_en_in<=r_padded_data_en_in;
            r_batch1_keep<=r_batch1_keep;
            //r_sel_encrypt_valid <=encrypt_valid;
        end        
    end
    else begin
        r_input_valid_en<=1'b0;
        r_padded_data_en_in<=r_padded_data_en_in;
        r_batch1_keep<=r_batch1_keep;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if(i_rst) r_sel_encrypt_valid <=0;
    else if(rr_pad_done1) begin
        if(r_o_batch_cnt<2) r_sel_encrypt_valid<=1'b0;
        else if (r_o_batch_cnt==2)
            r_sel_encrypt_valid <=encrypt_valid;
    end
    else r_sel_encrypt_valid <=encrypt_valid;
end



wire [31:0] bytes_multi;

assign      bytes_multi=(counter<<4)+i_byte_nums;

sm3_padding u_pad(
        .i_clk                 (i_clk),
        .i_rst                 (i_rst),
        .i_data_in             (i_data), //revise needed
        .i_data_valid_len      ({4'b0,i_byte_nums}),
        .i_bytes_multi         (bytes_multi),
        .i_m_l_bflag           (i_m_l_bflag), 
        .i_data_valid          ((i_input_valid&&(i_multi_flag&i_m_l_bflag))||(i_input_valid&(!i_multi_flag))),

        .o_padded_data0        (r_padded_data0),
        .o_padded_data1        (r_padded_data1),
        .o_pad_done            (r_pad_done),
        .o_pad_done1           (o_r_pad_done1)
);

sm3_encrypt u_sm3_en(
        .i_clk               (i_clk),  
        .i_rst               (i_rst),  
        .i_batch_data0       (r_padded_data_en_in),  
        .i_input_valid       (r_input_valid_en),   

        .o_Encrypt_Data      (encrypt_data ),  
        .o_Encrypt_Valid     (encrypt_valid),  

        .i_multi_flag        (r_multi_flag_top),
        .i_not_pad_multi_flag(i_multi_flag),
        .o_batch_cnt         (r_o_batch_cnt[0])
);

endmodule

