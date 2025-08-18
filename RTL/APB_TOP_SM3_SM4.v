
module APB_TOP_SM3_SM4 (
  input  wire [11:0]   io_apb_PADDR,
  input  wire [0:0]    io_apb_PSEL,
  input  wire          io_apb_PENABLE,
  output wire          io_apb_PREADY,
  input  wire          io_apb_PWRITE,
  input  wire [31:0]   io_apb_PWDATA,
  output reg  [31:0]   io_apb_PRDATA,
  output wire          io_apb_PSLVERROR,
  output wire          io_SM3_interrupt,
  output wire          io_SM4_interrupt,
  input  wire          io_mainClk,
  input  wire          i_Reset

);

wire         w_ende_ready;
wire [127:0] w_ende_data;
wire         w_ende_valid;

reg        [31:0]    interruptCtrl_1_io_clears; 

wire reset ;
wire io_axiClk  =  io_mainClk;
assign reset=i_Reset;


    reg  [127:0]  ri_initial_data     ;
    reg  [  1:0]  ri_data_valid       ;
    reg  [127:0]  ri_initial_Key      ;
    reg  [  1:0]  ri_key_valid        ;
    wire          w_encrypt_ready     ;
    wire [127:0]  w_encrypt_data      ;
    wire          w_encrypt_valid     ;
    wire          w_decrypt_ready     ;
    wire [127:0]  w_decrypt_data      ;
    wire          w_decrypt_valid     ;


  reg  [ 1:0]        SM4_status		         ;
  reg  [31:0]        ri_initial_data_r0    ;
  reg  [31:0]        ri_initial_data_r1    ;
  reg  [31:0]        ri_initial_data_r2    ;
  reg  [31:0]        ri_initial_data_r3    ;
  reg  [ 1:0]        ri_data_valid_r       ;
 
 
  reg  [31:0]        ri_initial_Key_r0     ;
  reg  [31:0]        ri_initial_Key_r1     ;
  reg  [31:0]        ri_initial_Key_r2     ;
  reg  [31:0]        ri_initial_Key_r3     ;
  reg  [ 1:0]        ri_key_valid_r        ;
  
  wire			     io_SM4_interrupt      ;
  reg  [ 1:0]        ri_key_valid_r1        ;
 
 //===================SM3==========================
  wire			     io_SM3_interrupt      ;
  
  reg  [511:0]        ri_input_data        ;
  reg                 ri_input_valid       ;
  wire [255:0]        w_encrypt_data_sm3   ;
  wire                w_encrypt_valid_sm3  ;
  reg                 w_encrypt_valid_sm3_r;
 
reg     [ 2:0]       SM3_status_reg   ;
reg     [31:0]       SM3_datain0_reg  ;
reg     [31:0]       SM3_datain1_reg  ;
reg     [31:0]       SM3_datain2_reg  ;
reg     [31:0]       SM3_datain3_reg  ;
reg     [31:0]       SM3_datain4_reg  ;
reg     [31:0]       SM3_datain5_reg  ;
reg     [31:0]       SM3_datain6_reg  ;
reg     [31:0]       SM3_datain7_reg  ;
reg     [31:0]       SM3_datain8_reg  ;
reg     [31:0]       SM3_datain9_reg  ;
reg     [31:0]       SM3_dataina_reg  ;
reg     [31:0]       SM3_datainb_reg  ;
reg     [31:0]       SM3_datainc_reg  ;
reg     [31:0]       SM3_dataind_reg  ;
reg     [31:0]       SM3_datalen0_reg ;
reg     [31:0]       SM3_datalen1_reg ; 
reg     [31:0]       SM3_byte_nums_reg ; 


reg     [31:0]       SM3_dataout0_reg ;
reg     [31:0]       SM3_dataout1_reg ;
reg     [31:0]       SM3_dataout2_reg ;
reg     [31:0]       SM3_dataout3_reg ;
reg     [31:0]       SM3_dataout4_reg ;
reg     [31:0]       SM3_dataout5_reg ;
reg     [31:0]       SM3_dataout6_reg ;
reg     [31:0]       SM3_dataout7_reg ;




  assign busCtrl_readErrorFlag  = 1'b0;
  assign busCtrl_writeErrorFlag = 1'b0;
  assign io_apb_PREADY = 1'b1;
  
  reg [31:0] sm4_ready_reg;

  always@(posedge io_axiClk or posedge reset) begin

        if (reset)sm4_ready_reg<=0;
        else sm4_ready_reg[0]<=w_ende_ready;

  end
  
  always @(*) begin
    io_apb_PRDATA = 32'h0;
    case(io_apb_PADDR)
      
      12'h10 : begin
        io_apb_PRDATA[31: 0] = sm4_ready_reg;
      end

	  12'h100: io_apb_PRDATA[ 1 : 0] = SM4_status[1:0];
	  12'h118: io_apb_PRDATA[31 : 0] = w_encrypt_data[127: 96];
	  12'h11c: io_apb_PRDATA[31 : 0] = w_encrypt_data[ 95: 64];
	  12'h120: io_apb_PRDATA[31 : 0] = w_encrypt_data[ 63: 32];
	  12'h124: io_apb_PRDATA[31 : 0] = w_encrypt_data[ 31:  0];
	  12'h128: io_apb_PRDATA[31 : 0] = w_decrypt_data[127: 96];
	  12'h12c: io_apb_PRDATA[31 : 0] = w_decrypt_data[ 95: 64];
	  12'h130: io_apb_PRDATA[31 : 0] = w_decrypt_data[ 63: 32];
	  12'h134: io_apb_PRDATA[31 : 0] = w_decrypt_data[ 31:  0];

	  12'h248: io_apb_PRDATA[31 : 0] = SM3_dataout0_reg[31 : 0];
	  12'h24c: io_apb_PRDATA[31 : 0] = SM3_dataout1_reg[31 : 0];
	  12'h250: io_apb_PRDATA[31 : 0] = SM3_dataout2_reg[31 : 0];
	  12'h254: io_apb_PRDATA[31 : 0] = SM3_dataout3_reg[31 : 0];
	  12'h258: io_apb_PRDATA[31 : 0] = SM3_dataout4_reg[31 : 0];
	  12'h25c: io_apb_PRDATA[31 : 0] = SM3_dataout5_reg[31 : 0];
	  12'h260: io_apb_PRDATA[31 : 0] = SM3_dataout6_reg[31 : 0];
	  12'h264: io_apb_PRDATA[31 : 0] = SM3_dataout7_reg[31 : 0];
      default : begin
      end
    endcase
  end

  assign busCtrl_askWrite = ((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PWRITE);
  assign busCtrl_askRead  = ((io_apb_PSEL[0] && io_apb_PENABLE) && (! io_apb_PWRITE));
  assign busCtrl_doWrite  = (((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PREADY) && io_apb_PWRITE);
  assign busCtrl_doRead   = (((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PREADY) && (! io_apb_PWRITE));
  assign io_apb_PSLVERROR = ((busCtrl_doWrite && busCtrl_writeErrorFlag) || (busCtrl_doRead && busCtrl_readErrorFlag));

  always @(*) begin
    if(i_Reset)
    interruptCtrl_1_io_clears = 32'b00;
    else begin
    case(io_apb_PADDR)
      12'h10 : begin
        if(busCtrl_doWrite) begin
          interruptCtrl_1_io_clears = io_apb_PWDATA[31 : 0];
        end
      end
      default : begin
      end
    endcase
    end
  end


  

//==================================================================SM4



wire          ctrl_doWrite;
wire          ctrl_doRead;

reg       [3:0  ]       ri_sm4_mode ;
reg       [6:0  ]       ri_key_num  ;
reg                     ri_init_flag;
reg       [127:0]       ri_init_Key ;
reg                     ri_work_flag;
reg       [127:0]       ri_data     ;
reg                     ro_ready    ;
reg       [127:0]       ro_data     ;
reg                     ro_valid    ;

  assign ctrl_doWrite = ((io_apb_PSEL[0] && io_apb_PENABLE) && io_apb_PWRITE);
  assign ctrl_doRead  = ((io_apb_PSEL[0] && io_apb_PENABLE) && (!io_apb_PWRITE));

  //==============================================================================  
    always@(posedge io_axiClk or posedge reset)
  begin
    if (reset) begin
		ri_initial_data_r0 <= 32'b0;
		ri_initial_data_r1 <= 32'b0;
		ri_initial_data_r2 <= 32'b0;
		ri_initial_data_r3 <= 32'b0;
    ri_sm4_mode        <= 4'b0;
    ri_key_num         <= 7'b0;
		ri_initial_Key_r0  <= 32'b0;
		ri_initial_Key_r1  <= 32'b0;
		ri_initial_Key_r2  <= 32'b0;
		ri_initial_Key_r3  <= 32'b0;
    end else begin
        if(ctrl_doWrite)
		begin
          case(io_apb_PADDR)
             12'h104:ri_initial_data_r0        <= io_apb_PWDATA[31 : 0];
             12'h108:ri_initial_data_r1        <= io_apb_PWDATA[31 : 0];
             12'h10c:ri_initial_data_r2        <= io_apb_PWDATA[31 : 0];
             12'h110:ri_initial_data_r3        <= io_apb_PWDATA[31 : 0];
             12'h14c:ri_sm4_mode               <= io_apb_PWDATA[3 : 0 ];
             12'h150:ri_key_num                <= io_apb_PWDATA[6 : 0 ];
             12'h138:ri_initial_Key_r0         <= io_apb_PWDATA[31 : 0];
             12'h13c:ri_initial_Key_r1         <= io_apb_PWDATA[31 : 0];
             12'h140:ri_initial_Key_r2         <= io_apb_PWDATA[31 : 0];
             12'h144:ri_initial_Key_r3         <= io_apb_PWDATA[31 : 0];
             default:begin  end
		  endcase
        end
      end
  end
  //==============================================================================




  reg [1:0]  sm4_vaild_en;

  assign io_SM4_interrupt = (SM4_status!=2'b00) ;

	reg     r_ri_work_flag;
      always@(posedge io_axiClk or posedge reset)
  begin
    if (reset) begin
		ri_data       <=128'b0;
		ri_work_flag  <=  1'b0;
        r_ri_work_flag<=  1'b0;
	end else if(ctrl_doWrite&&io_apb_PADDR==12'h114)begin
	    ri_data  <=  ri_data;
        r_ri_work_flag  <=  io_apb_PWDATA[ 0 : 0];
    end else if(r_ri_work_flag&& w_ende_ready) begin
		ri_data  <= {ri_initial_data_r3,ri_initial_data_r2,ri_initial_data_r1,ri_initial_data_r0};
		ri_work_flag    <=  1;
        r_ri_work_flag  <=  0;
    end else begin
        ri_data  <= ri_data;
        ri_work_flag  <= 1'b0;    
        r_ri_work_flag<= 1'b0;    
	end
  end


  always@(posedge io_axiClk or posedge reset)
  begin
    if (reset) begin
		ri_init_Key  <=128'b0;
		ri_init_flag  <=  2'b0;
	end else if(ctrl_doWrite&&io_apb_PADDR==12'h148)begin
		    ri_init_Key  <= {ri_initial_Key_r3,ri_initial_Key_r2,ri_initial_Key_r1,ri_initial_Key_r0};
        ri_init_flag  <=  io_apb_PWDATA[ 0 : 0];
    end else if(ri_init_flag) begin
		ri_init_flag  <=  0;
    end else begin
        ri_init_Key  <= ri_init_Key;
        ri_init_flag  <= 1'b0;        
	end
  end	


reg [1:0] w_decrypt_valid_r;
reg [1:0] w_encrypt_valid_r;

always@(posedge io_axiClk or posedge reset)begin
 if(reset)
 begin
    w_decrypt_valid_r <= 2'b0;
 end
 else 
 begin
    w_decrypt_valid_r[0] <= w_decrypt_valid;
    w_decrypt_valid_r[1] <=w_decrypt_valid_r[0];  
 end
end
always@(posedge io_axiClk or posedge reset)begin
 if(reset)
 begin
    w_encrypt_valid_r <= 2'b0;
 end
 else 
 begin
    w_encrypt_valid_r[0] <= w_encrypt_valid;
    w_encrypt_valid_r[1] <=w_encrypt_valid_r[0];  
 end
end
 always@(posedge io_axiClk or posedge reset)begin
    if(reset)
    begin
        sm4_vaild_en[0] <= 1'b0;
    end
    else if((w_decrypt_valid||w_encrypt_valid)&&(sm4_vaild_en[0]==1'b0))begin
        sm4_vaild_en[0] <= 1'b1;
    end
    else 
    begin
        sm4_vaild_en[0] <= sm4_vaild_en[0];
    end
 end
 always@(posedge io_axiClk or posedge reset)begin
    if(reset)
    begin
        sm4_vaild_en[1] <= 1'b0;
    end
    else if(sm4_vaild_en[0]==1'b1)begin
        sm4_vaild_en[1] <= 1'b1;
    end
    else 
    begin
        sm4_vaild_en[1] <= sm4_vaild_en[1];
    end
 end

  always@(posedge io_axiClk or posedge reset)begin
  if(reset)
  begin
    SM4_status[1:0] <= 2'b00;
  end 
  else if(ctrl_doWrite&&io_apb_PADDR==12'h100)
  begin
   SM4_status[1:0] <= io_apb_PWDATA[ 1 : 0];
  end 
  else
   begin
   SM4_status[1:0] <= {((!w_decrypt_valid_r[1])&&(w_decrypt_valid_r[0])),((!w_encrypt_valid_r[1])&&(w_encrypt_valid_r[0]))};
  end
end  



assign w_encrypt_data  =  w_ende_data  ;  
assign w_decrypt_data  =  w_ende_data  ;  
assign w_encrypt_valid =  w_ende_valid ;  
assign w_decrypt_valid =  w_ende_valid ;

  always@(posedge io_axiClk or posedge reset)
  begin
      if (reset) begin
		ri_key_valid_r1  <= 2'b00;
    end else begin
        ri_key_valid_r1  <= ri_key_valid_r;
    end
  end


SM4_TOP usm4top
(
.i_clk                  (io_axiClk),
.i_rst                  (reset),
.i_sm4_mode             (ri_sm4_mode ),
.i_key_num              (ri_key_num  ),
.i_init_flag            (ri_init_flag),
.i_init_Key             (ri_init_Key ),
.i_work_flag            (ri_work_flag),
.i_data                 (ri_data     ),
.o_ready                (w_ende_ready    ),
.o_data                 (w_ende_data     ),
.o_valid                (w_ende_valid  )
);

//=====================SM3=========================

assign io_SM3_interrupt = w_encrypt_valid_sm3_r;

reg               r_multi_flag  ;
reg               r_i_m_l_bflag ;

always @(posedge io_axiClk or posedge reset) begin
    if(reset)begin
        SM3_datain0_reg  <=32'b0;
        SM3_datain1_reg  <=32'b0;
        SM3_datain2_reg  <=32'b0;
        SM3_datain3_reg  <=32'b0;
        SM3_datain4_reg  <=32'b0;
        SM3_datain5_reg  <=32'b0;
        SM3_datain6_reg  <=32'b0;
        SM3_datain7_reg  <=32'b0;
        SM3_datain8_reg  <=32'b0;
        SM3_datain9_reg  <=32'b0;
        SM3_dataina_reg  <=32'b0;
        SM3_datainb_reg  <=32'b0;
        SM3_datainc_reg  <=32'b0;
        SM3_dataind_reg  <=32'b0;  
        SM3_datalen0_reg <=32'b0;
        SM3_datalen1_reg <=32'b0;           
    end
    else if(ctrl_doWrite==1)begin
	   case(io_apb_PADDR)
	        12'h204:SM3_datain0_reg [31:0]  <= io_apb_PWDATA[31 : 0];
	        12'h208:SM3_datain1_reg [31:0]  <= io_apb_PWDATA[31 : 0];
	        12'h20c:SM3_datain2_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h210:SM3_datain3_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h214:SM3_datain4_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h218:SM3_datain5_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h21c:SM3_datain6_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h220:SM3_datain7_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h224:SM3_datain8_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h228:SM3_datain9_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h22c:SM3_dataina_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h230:SM3_datainb_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h234:SM3_datainc_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h238:SM3_dataind_reg [31:0]  <= io_apb_PWDATA[31 : 0];
          12'h23c:SM3_datalen0_reg [31:0] <= io_apb_PWDATA[31 : 0];
          12'h240:SM3_datalen1_reg [31:0] <= io_apb_PWDATA[31 : 0];
          12'h244:SM3_byte_nums_reg[31:0] <= io_apb_PWDATA[31 : 0];
          default:;
          endcase
    end else if(w_encrypt_valid_sm3_r) begin
          SM3_datain0_reg [31:0]  <= 32'b0;
          SM3_datain1_reg [31:0]  <= 32'b0;
          SM3_datain2_reg [31:0]  <= 32'b0;
          SM3_datain3_reg [31:0]  <= 32'b0;
          SM3_datain4_reg [31:0]  <= 32'b0;
          SM3_datain5_reg [31:0]  <= 32'b0;
          SM3_datain6_reg [31:0]  <= 32'b0;
          SM3_datain7_reg [31:0]  <= 32'b0;
          SM3_datain8_reg [31:0]  <= 32'b0;
          SM3_datain9_reg [31:0]  <= 32'b0;
          SM3_dataina_reg [31:0]  <= 32'b0;
          SM3_datainb_reg [31:0]  <= 32'b0;
          SM3_datainc_reg [31:0]  <= 32'b0;
          SM3_dataind_reg [31:0]  <= 32'b0;
          SM3_datalen0_reg [31:0] <= 32'b0;
          SM3_datalen1_reg [31:0] <= 32'b0;
          SM3_byte_nums_reg[31:0] <= 32'b0;     
    end else begin
          SM3_datain0_reg [31:0] <=SM3_datain0_reg [31:0] ;
          SM3_datain1_reg [31:0] <=SM3_datain1_reg [31:0] ;
          SM3_datain2_reg [31:0] <=SM3_datain2_reg [31:0] ;
          SM3_datain3_reg [31:0] <=SM3_datain3_reg [31:0] ;
          SM3_datain4_reg [31:0] <=SM3_datain4_reg [31:0] ;
          SM3_datain5_reg [31:0] <=SM3_datain5_reg [31:0] ;
          SM3_datain6_reg [31:0] <=SM3_datain6_reg [31:0] ;
          SM3_datain7_reg [31:0] <=SM3_datain7_reg [31:0] ;
          SM3_datain8_reg [31:0] <=SM3_datain8_reg [31:0] ;
          SM3_datain9_reg [31:0] <=SM3_datain9_reg [31:0] ;
          SM3_dataina_reg [31:0] <=SM3_dataina_reg [31:0] ;
          SM3_datainb_reg [31:0] <=SM3_datainb_reg [31:0] ;
          SM3_datainc_reg [31:0] <=SM3_datainc_reg [31:0] ;
          SM3_dataind_reg [31:0] <=SM3_dataind_reg [31:0] ;
          SM3_datalen0_reg [31:0]<=SM3_datalen0_reg [31:0];
          SM3_datalen1_reg [31:0] <=SM3_datalen1_reg [31:0];
          SM3_byte_nums_reg[31:0]<=SM3_byte_nums_reg[31:0];
    end     
 end


always@(posedge io_axiClk or posedge reset)begin
    if(reset) begin
        r_multi_flag <=0;
        r_i_m_l_bflag<=0;
    end else begin
        r_multi_flag  <= SM3_status_reg[2];
        r_i_m_l_bflag <= SM3_status_reg[1];   
    end 
end

always@(posedge io_axiClk or posedge reset)begin
    if(reset)
        SM3_status_reg <= 3'b0;
    else if(SM3_status_reg[0]==1)   
        SM3_status_reg[0] <= 0;  
    else if((ctrl_doWrite==1'b1)&&(io_apb_PADDR==12'h200))
        SM3_status_reg[2:0] <= io_apb_PWDATA[ 2 : 0]; 
    else
        SM3_status_reg <= SM3_status_reg;                       
end

always@(posedge io_axiClk or posedge reset)begin
    if(reset)
        ri_input_valid <= 1'b0;
    else if(ri_input_valid==1'b1)   
        ri_input_valid <= 1'b0;  
    else if(SM3_status_reg[0]==1'b1)
        ri_input_valid <= 1'b1; 
    else
        ri_input_valid <= ri_input_valid;                       
end


always@(posedge io_axiClk or posedge reset)begin
    if(reset)
        ri_input_data <= 512'b0;
    else if(SM3_status_reg[0]==1'b1)
        ri_input_data <= {
                             SM3_datain0_reg,SM3_datain1_reg,SM3_datain2_reg, SM3_datain3_reg,   
                             SM3_datain4_reg,SM3_datain5_reg,SM3_datain6_reg, SM3_datain7_reg,  
                             SM3_datain8_reg,SM3_datain9_reg,SM3_dataina_reg, SM3_datainb_reg, 
                             SM3_datainc_reg,SM3_dataind_reg,SM3_datalen0_reg,SM3_datalen1_reg                       
                             }; 
    else
        ri_input_data <= ri_input_data;                       
end

    always@(w_encrypt_valid_sm3)begin
      SM3_dataout0_reg[31 : 0] <= w_encrypt_data_sm3[ 31:  0];
      SM3_dataout1_reg[31 : 0] <= w_encrypt_data_sm3[ 63: 32];
      SM3_dataout2_reg[31 : 0] <= w_encrypt_data_sm3[ 95: 64];
      SM3_dataout3_reg[31 : 0] <= w_encrypt_data_sm3[127: 96];
      SM3_dataout4_reg[31 : 0] <= w_encrypt_data_sm3[159:128];
      SM3_dataout5_reg[31 : 0] <= w_encrypt_data_sm3[191:160];
      SM3_dataout6_reg[31 : 0] <= w_encrypt_data_sm3[223:192];
      SM3_dataout7_reg[31 : 0] <= w_encrypt_data_sm3[255:224];   
    end

always@(posedge io_axiClk or posedge reset)begin
    if(reset)                      w_encrypt_valid_sm3_r <= 1'b0;
    else if(w_encrypt_valid_sm3_r) w_encrypt_valid_sm3_r <= 1'b0;
    else                           w_encrypt_valid_sm3_r <= w_encrypt_valid_sm3;
end


sm3_top usm3(
		.i_clk             (io_axiClk               ),
		.i_rst             (reset                   ),
		.i_data            (ri_input_data           ),
		.i_input_valid     (ri_input_valid          ),
		.o_hash_result     (w_encrypt_data_sm3      ),
		.o_output_valid    (w_encrypt_valid_sm3     ),
    .i_multi_flag      (r_multi_flag            ),
    .i_byte_nums       (SM3_byte_nums_reg[5:0]  ),
    .i_m_l_bflag       (r_i_m_l_bflag           )
		);     
		

endmodule


