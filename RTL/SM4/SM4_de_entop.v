`timescale 1ns / 1ps

module SM4_de_entop(
    input           i_clk           ,
    input           i_rst           ,
    input  [127:0]  i_init_Key   ,
    input           i_init_valid ,
    input  [  1:0]  i_mode     ,
    input  [127:0]  i_data     ,
    input           i_valid_top    ,
    output          o_ready    ,      
    output [127:0]  o_data     ,
    output          o_valid    
);

reg  [127:0]        r_Initial_key[0 :32]    ;
reg                 r_Initial_valid[0 :32]  ;
reg  [31 :0]        r_rK[0 :31]             ;
reg  [127:0]        ri_axis_data            ;
reg                 ri_axis_valid           ;
reg  [127:0]        r_round_data[0:32]      ;
reg  [127:0]        r_round_data_old        ;
reg                 r_round_valid[0:32]     ;
reg                 ro_axis_ready           ;
reg  [127:0]        ro_axim_data            ;
reg                 ro_axim_valid           ;
reg  [31 :0]        r_round_result28[0:17]  ;
reg  [31 :0]        r_round_result29[0:11]  ;
reg  [31 :0]        r_round_result30[0:5]   ;

wire [31:0]         w_Encrypt_Key[0 :31]    ;
wire                w_Encrypt_valid[0 :31]  ;
wire [31:0]         w_round_data[0:31]      ;//31 30  29 28
wire                w_round_valid[0:31]     ;
wire [31:0]         w_round_data_encrypt[0:31]      ;//31 30  29 28
wire                w_round_valid_encrypt[0:31]     ;
wire [31:0]         w_round_data_decrypt[0:31]      ;//31 30  29 28
wire                w_round_valid_decrypt[0:31]     ;
wire                w_axis_active           ;
wire [127:0]        w_K[0:31]               ;    //round key
wire [127:0]        w_round_next_data_encrypt[0:63] ;
wire [127:0]        w_round_next_data_decrypt[0:63] ;
reg  [127:0]        r_round_data_encrypt[0:32]      ;
reg  [127:0]        r_round_data_old_encrypt        ;
reg                 r_round_valid_encrypt[0:32]     ;
reg  [127:0]        r_round_data_decrypt[0:32]      ;
reg  [127:0]        r_round_data_old_decrypt        ;
reg                 r_round_valid_decrypt[0:32]     ;

reg                 flag ;
always@(posedge i_clk,posedge i_rst)begin
    if(i_rst)
        flag <= 1'b0;
    else if(i_valid_top)
        flag <= 1'b1;
    else
        flag <= flag;
end


assign o_ready = ro_axis_ready         ;
assign w_axis_active = i_valid_top & o_ready;  
assign o_data  = ro_axim_data          ;
assign o_valid = ro_axim_valid         ;

genvar i;
generate 
    for(i = 0 ; i < 32 ; i = i + 1)
    begin:Gen_Key
	wire [7:0] my_i;
	assign my_i = i;
        Key_Extending Key_Extending_ux(
            .i_clk               (i_clk                     ),
            .i_rst               (i_rst | i_init_valid   ),
            .i_i                 (my_i                      ),
            .i_Initial_Key       (r_Initial_key[i]          ),
            .i_Initial_valid     (r_Initial_valid[i]        ),
            .o_Encrypt_Key       (w_Encrypt_Key[i]          ),
            .o_Encrypt_valid     (w_Encrypt_valid[i]        ),
            .o_K                 (w_K[i]                    )
        );
    

    
    always@(posedge i_clk,posedge i_rst)
    begin
        if(i_rst)
            r_rK[i] <= 'd0;
        else 
            r_rK[i] <= w_Encrypt_Key[i];
    end

    if(i > 0) begin
        always@(posedge i_clk,posedge i_rst)
        begin
            if(i_rst) begin
                r_Initial_key[i]   <= 'd0;
                r_Initial_valid[i] <= 'd0;
            end else if(i_init_valid) begin
                r_Initial_key[i]   <= 'd0;
                r_Initial_valid[i] <= 'd0;
            end else begin
                r_Initial_key[i]   <= w_K[i - 1];
                r_Initial_valid[i] <= w_Encrypt_valid[i - 1]    ;
            end
        end
    end
    
    end
    
endgenerate

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_Initial_key[0]   <= 128'h0;
        r_Initial_valid[0] <= 'd0;
    end else if(i_init_valid) begin
        r_Initial_key[0]   <= i_init_Key;
        r_Initial_valid[0] <= 'd1;
    end else begin
        r_Initial_key[0]   <= r_Initial_key[0]      ;
        r_Initial_valid[0] <= 'd1;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_Initial_key[32]   <= 'd0;
        r_Initial_valid[32] <= 'd0;
    end else if(i_init_valid) begin 
        r_Initial_key[32]   <= 'd0;
        r_Initial_valid[32] <= 'd0;
    end else begin
        r_Initial_key[32]   <= w_K[31];
        r_Initial_valid[32] <= w_Encrypt_valid[31];
    end
end
/*----data encrypt----*/

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_round_result28[0]<= 'd0;
        r_round_result29[0]<= 'd0;
        r_round_result30[0]<= 'd0;
    end else if(i_mode==2'b01) begin
        r_round_result28[0]<= w_round_data_encrypt[28];
        r_round_result29[0]<= w_round_data_encrypt[29];
        r_round_result30[0]<= w_round_data_encrypt[30];
    end else if(i_mode==2'b10) begin
        r_round_result28[0]<= w_round_data_decrypt[28];
        r_round_result29[0]<= w_round_data_decrypt[29];
        r_round_result30[0]<= w_round_data_decrypt[30];
    end else begin
        r_round_result28[0]<= r_round_result28[0];
        r_round_result29[0]<= r_round_result29[0];
        r_round_result30[0]<= r_round_result30[0];
    end
end

genvar G_i;
generate
    for(G_i = 1 ; G_i < 6 ; G_i = G_i + 1)
    begin:Gen_30
        always@(posedge i_clk)
            r_round_result30[G_i] <= r_round_result30[G_i - 1];
    end

    for(G_i = 1 ; G_i < 12 ; G_i = G_i + 1)
    begin:Gen_29
        always@(posedge i_clk)
            r_round_result29[G_i] <= r_round_result29[G_i - 1];
    end

    for(G_i = 1 ; G_i < 18 ; G_i = G_i + 1)
    begin:Gen_28
        always@(posedge i_clk)
            r_round_result28[G_i] <= r_round_result28[G_i - 1];
    end

endgenerate

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        ro_axis_ready <= 'd0;
    else if(i_init_valid)
        ro_axis_ready <= 'd0;
    else if(r_Initial_valid[32])
        ro_axis_ready <= 'd1;
    else 
        ro_axis_ready <= ro_axis_ready;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ri_axis_data  <= 'd0;
        ri_axis_valid <= 'd0;
    end else if(w_axis_active) begin
        ri_axis_data  <= i_data ;
        ri_axis_valid <= 'd1;
    end else begin
        ri_axis_data  <= ri_axis_data ;
        ri_axis_valid <= 'd0;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_round_data_encrypt[0]  <= 'd0;
        r_round_valid_encrypt[0] <= 'd0;
        r_round_data_decrypt[0]  <= 'd0;
        r_round_valid_decrypt[0] <= 'd0;
    end else if(w_axis_active) begin
        r_round_data_encrypt[0]  <= i_data;
        r_round_valid_encrypt[0] <= 'd1;
        r_round_data_decrypt[0]  <= i_data;
        r_round_valid_decrypt[0] <= 'd1;        
    end else begin
        r_round_data_encrypt[0]  <= r_round_data_encrypt[0];
        r_round_valid_encrypt[0] <= 'd0;
        r_round_data_decrypt[0]  <= r_round_data_decrypt[0];
        r_round_valid_decrypt[0] <= 'd0;
    end
end

genvar j;
generate 
    for(j = 0;j < 32;j = j + 1)
    begin:Gen_Round
	wire [7:0] my_j;
	assign my_j = j;
        Round_Function Round_Function_Encrypt(
            .i_clk       (i_clk                         ),
            .i_rst       (i_rst                         ),
            .i_i         (my_j                             ),
            .i_rk        (r_rK[j]                       ),
            .i_data      (r_round_data_encrypt[j]       ),
            .i_valid     ((r_round_valid_encrypt[j]&&(i_mode==2'b01))),
            .o_data      (w_round_data_encrypt[j]       ),
            .o_valid     (w_round_valid_encrypt[j]      ),
            .o_next_data (w_round_next_data_encrypt[j]  )
        );
        Round_Function Round_Function_Decrypt(
            .i_clk       (i_clk                         ),
            .i_rst       (i_rst                         ),
            .i_i         (my_j                             ),
            .i_rk        (r_rK[31-j]                    ),
            .i_data      (r_round_data_decrypt[j]       ),
            .i_valid     ((r_round_valid_decrypt[j]&&(i_mode==2'b10))),
            .o_data      (w_round_data_decrypt[j]       ),
            .o_valid     (w_round_valid_decrypt[j]      ),
            .o_next_data (w_round_next_data_decrypt[j]  )
        );        
            always@(posedge i_clk,posedge i_rst)
            begin
                if(i_rst) begin
                    r_round_data_decrypt[j + 1]  <= 'd0;
                    r_round_valid_decrypt[j + 1] <= 'd0;
                end else if(w_round_valid_decrypt[j]) begin
                    r_round_data_decrypt[j + 1]  <= w_round_next_data_decrypt[j];
                    r_round_valid_decrypt[j + 1] <= w_round_valid_decrypt[j];
                end else begin
                    r_round_data_decrypt[j + 1]  <= r_round_data_decrypt[j + 1];
                    r_round_valid_decrypt[j + 1] <= 'd0;
                end
            end
            always@(posedge i_clk,posedge i_rst)
            begin
                if(i_rst) begin
                    r_round_data_encrypt[j + 1]  <= 'd0;
                    r_round_valid_encrypt[j + 1] <= 'd0;
                end else if(w_round_valid_encrypt[j]) begin
                    r_round_data_encrypt[j + 1]  <= w_round_next_data_encrypt[j];
                    r_round_valid_encrypt[j + 1] <= w_round_valid_encrypt[j];
                end else begin
                    r_round_data_encrypt[j + 1]  <= r_round_data_encrypt[j + 1];
                    r_round_valid_encrypt[j + 1] <= 'd0;
                end
            end
    end
endgenerate

/*----output data----*/

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
    begin
        ro_axim_data  <= 'd0;
        ro_axim_valid <= 'd0;
    end else if((flag==1'b1)&&(i_mode==2'b01)) 
    begin
        ro_axim_data  <= {w_round_data_encrypt[31],r_round_result30[5],r_round_result29[11],r_round_result28[17]};
        ro_axim_valid <=  w_round_valid_encrypt[31];
    end else if((flag==1'b1)&&(i_mode==2'b10)) 
    begin
        ro_axim_data  <= {w_round_data_decrypt[31],r_round_result30[5],r_round_result29[11],r_round_result28[17]};
        ro_axim_valid <=  w_round_valid_decrypt[31];
    end
    else begin
        ro_axim_data  <= ro_axim_data;
        ro_axim_valid <= 'd0;
    end
end

endmodule
