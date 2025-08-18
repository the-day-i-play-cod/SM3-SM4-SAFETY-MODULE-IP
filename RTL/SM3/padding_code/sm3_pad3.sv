module sm3_padding (
    input                       i_clk,
    input                       i_rst,
    input       [511:0]         i_data_in,          // 输入数据（高位对齐）
    input       [9:0]           i_data_valid_len,  // 有效数据长度�?1-512位）
    input                       i_data_valid,       // 输入有效信号
    input                       i_m_l_bflag,
    input       [31:0]          i_bytes_multi ,
    output      [511:0]         o_padded_data0, // 输出填充结果（最�?1024位）
    output      [511:0]         o_padded_data1,
    output                      o_pad_done,     // 填充完成信号
    output                      o_pad_done1
);


//妙啊，不用赋值，初始化，本来就是0，不用管�?
// 状�?�机定义
localparam IDLE     = 4'd0;
localparam PAD_1    = 4'd1;
localparam PAD_LEN  = 4'd2;
localparam IDLE0    = 4'd3;
localparam IDLE_MUL = 4'd4;

reg [1023:0]padded_data;
reg [3:0] state;
reg [9:0] orig_len;  // 存储原始长度
reg [40:0] orig_len_mul;
reg [63:0] len_bits; // 64位长度

//reg [63:0] multi_len_bits;

reg pad_done;
reg pad_done1;

assign o_pad_done=pad_done;
assign o_pad_done1=pad_done1;

assign o_padded_data0=padded_data[1023:512];
assign o_padded_data1=padded_data[511:0];

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state <= IDLE0;
        pad_done <= 0;
        padded_data <= 1024'b0;
        orig_len<=0;
    end else begin
        case (state)

            IDLE0:begin
                  pad_done <= 0;
                  pad_done1<= 0;
                  padded_data<=1024'b0;
                  orig_len<=0;
                  if(i_data_valid&i_m_l_bflag) state <=IDLE_MUL;                
                  else if (i_data_valid&!i_m_l_bflag)   state <=IDLE;
                  else state <=IDLE0;
            end

            IDLE: begin

                    orig_len <= i_data_valid_len<<5;
                    // 保存原始数据（高位对齐）

                    padded_data[1023:0] <= i_data_in<<(1024-(i_data_valid_len<<5)); //include just 512bit
                    // 计算�?要补零的数量
                    len_bits <= i_data_valid_len<<5; // 转字节长�?

                    state <= PAD_1;
                end
                
            IDLE_MUL:begin
                    orig_len <= i_data_valid_len<<5;
                    padded_data[1023:0] <= i_data_in<<(1024-(i_data_valid_len<<5)); //include just 512bit
                    len_bits <= (i_bytes_multi<<5);

                    state <= PAD_1;
            end

            PAD_1: begin

                padded_data[1023 - orig_len] <= 1'b1;
                // 自动补零（Verilog默认补零�?
            
                state <= PAD_LEN;
            end


            PAD_LEN: begin
                if(orig_len<448)begin
                // 附加64位长度（大端模式�?
                padded_data[575:512] <= len_bits;
                pad_done <= 1;
                state <= IDLE0;
            end else begin
                padded_data[63:0] <= len_bits;
                pad_done1 <= 1;
                pad_done <= 1;
                state <= IDLE0;                    
                end
            end
        endcase
    end
end


endmodule