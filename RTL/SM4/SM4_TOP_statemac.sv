
module SM4_TOP (
    input           i_clk           ,
    input           i_rst           ,
    input  [3:0  ]  i_sm4_mode      ,// 4-1: en,3-1:de,2:use key_rom,1:use new gen key 
    input  [6:0  ]  i_key_num       ,
    input           i_init_flag     ,
    input  [127:0]  i_init_Key      ,
    input           i_work_flag     , //en or de mode ,only keep one cycle
    input  [127:0]  i_data          ,
    output          o_ready         ,      
    output [127:0]  o_data          ,
    output          o_valid  
);
    
localparam idle =1   ; //judge init_flag
localparam gen_key =2; //gen new ron key
localparam decrypt =3;
localparam encrypt =4;
localparam fetch_key =5;
localparam init_key =6;

reg [3:0] r_sm4_mode;
reg [3:0] state;
reg [6:0] r_key_num;
reg       r_init_flag;
reg [127:0] r_init_Key;
reg         r_work_flag; 
//uut

reg                 ri_keygen_en;
wire [127:0]        wo_key;

reg                 ri_ren;        
reg                 ri_wen;        
reg      [6:0]      ri_addr;       
reg      [127:0]    ri_wdata;      
wire     [127:0]    wo_key_out;    
wire                wo_valid;      
wire                wo_write_ack;  

reg [127:0]  ri_init_Key   ;
reg          ri_init_valid ;
reg [  1:0]  ri_mode     ;
reg [127:0]  ri_data     ;
reg          ri_valid    ;
reg          ro_ready    ;
reg [127:0]  ro_data     ;
reg          ro_valid    ;

assign o_data  = ro_data ;
assign o_valid = ro_valid;

assign      o_ready=ro_ready;
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst)  begin 
        r_sm4_mode<=0;
        ri_addr<=  0;
        r_init_Key<=0;
        ri_data<=0;
        r_init_flag<=0;
        r_work_flag<=0;
    end
    else begin 
        r_sm4_mode<=i_sm4_mode;
        r_init_flag<=i_init_flag;
        ri_addr<= i_key_num;
        r_init_Key<= i_init_Key;
        ri_data<=i_data;
        r_work_flag<=i_work_flag;
    end
end

reg           cnt3_valid;
reg           cnt3_en;
reg     [5:0] r_cnt3er ;
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst)  r_cnt3er<=0;
    else if(cnt3_en)begin
        r_cnt3er<=r_cnt3er+1;
        if(r_cnt3er==3) cnt3_valid<=1'b1;
    end else begin
        r_cnt3er<=0;
        cnt3_valid<=0;
    end
end

reg r_ri_ren;
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) r_ri_ren<=0;
    else r_ri_ren<= ri_ren;
end


//state machine
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        ri_mode         <=0;
        ri_valid        <=0;
        ri_init_Key     <=0;
        ri_init_Key     <=0;
        ri_init_valid   <=0;
        cnt3_en         <=0;
        state           <=1;
        ri_keygen_en    <=0;
    end else begin
case(state)
    idle :begin
        ri_valid        <=0;
        ri_init_Key     <=0;
        ri_init_valid   <=0;
        cnt3_en         <=0;
        ri_keygen_en    <=0;
        ri_wen          <=0;
        ri_ren          <=0;

        if(r_init_flag)begin
            if((r_sm4_mode[1])&&(!r_sm4_mode[0]))begin
                ri_ren <= 1'b1;
                state<=fetch_key;  //change next cycle
            end else if((!r_sm4_mode[1])&&(r_sm4_mode[0])) begin
                state<=gen_key;
            end else if((!r_sm4_mode[1])&&(!r_sm4_mode[0]))begin
                ri_init_Key   <= r_init_Key;
                state<=init_key;
            end
        end
        else if(r_work_flag)begin
            if(r_sm4_mode[3]&&!r_sm4_mode[2])
                state<=encrypt;
            else if(!r_sm4_mode[3]&&r_sm4_mode[2])
                state<=decrypt;
            else state<=idle;
        end
        else state<=idle;
    end
    gen_key :begin //include initalize
        ri_keygen_en<=1'b1;
        cnt3_en    <=1'b1;
        if(cnt3_valid) begin
            ri_wen<=1'b1;
            ri_wdata      <= wo_key;  //write in ram
            ri_init_Key   <= wo_key;  //go to init
            ri_init_valid <= 1'b1; 
            state<=idle ;
        end else 
            state<=gen_key;
    end 

    fetch_key :begin

        if(r_ri_ren) begin
            ri_init_Key     <= wo_key_out;
            ri_init_valid   <= 1'b1;
            state <= idle;
        end else state <= fetch_key;
    end

    init_key :begin 
        ri_init_valid <= 1'b1;       
        state  <= idle;
    end  

    decrypt :begin
        ri_mode <= 2'b10;
        ri_valid<=1'b1 ;      
        state <= idle;

    end
    encrypt :begin
        ri_mode <= 2'b01;
        ri_valid<=1'b1 ;
        state <= idle;   
           
    end      
    endcase
    end
end


sm4_keygen u_sm4_keygen(
.i_clk              (i_clk ),      
.i_rst_n            (!i_rst ),
.i_keygen_en        (ri_keygen_en),
.o_key              (wo_key)
);


 key_ram_128 u_key_ram (

.i_clk               (i_clk ),
.i_rst_n             (!i_rst),
.i_ren               (ri_ren),
.i_wen               (ri_wen),  
.i_addr              (ri_addr),
.i_wdata             (ri_wdata), 
.o_key_out           (wo_key_out ),
.o_valid             (wo_valid   ),
.o_write_ack         (wo_write_ack)

);



 SM4_de_entop #(
) ude_en_top (
.i_clk              (i_clk           ),
.i_rst              (i_rst           ),
.i_init_Key         (ri_init_Key     ),
.i_init_valid       (ri_init_valid   ),
.i_mode            (ri_mode         ),
.i_data            (ri_data         ),
.i_valid_top       (ri_valid        ),
.o_ready           (ro_ready        ),
.o_data            (ro_data         ),
.o_valid           (ro_valid        )

);




endmodule
