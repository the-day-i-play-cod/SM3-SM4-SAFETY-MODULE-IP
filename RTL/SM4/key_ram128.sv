module key_ram_128_4bank #(
    parameter integer ADDR_DECOY = 1,
    parameter integer WRITE_LOCK = 1
) (
    input  wire         i_clk,
    input  wire         i_rst_n,

    input  wire         i_ren,
    input  wire         i_wen,
    input  wire [6:0]   i_addr,
    input  wire [127:0] i_wdata,

    output reg  [127:0] o_key_out,
    output reg          o_valid,
    output reg          o_write_ack
);

    localparam integer DEPTH = 128;

    /*
     * 每个RAM Bank存储128个32 bit数据
     *
     * bank0：key[31:0]
     * bank1：key[63:32]
     * bank2：key[95:64]
     * bank3：key[127:96]
     */
    (* ram_style = "distributed" *)
    reg [31:0] ram_bank0 [0:DEPTH-1];

    (* ram_style = "distributed" *)
    reg [31:0] ram_bank1 [0:DEPTH-1];

    (* ram_style = "distributed" *)
    reg [31:0] ram_bank2 [0:DEPTH-1];

    (* ram_style = "distributed" *)
    reg [31:0] ram_bank3 [0:DEPTH-1];


    /*
     * 每个地址的一次写锁
     */
    reg [DEPTH-1:0] write_lock_mask;


    localparam [127:0] DECOY_KEY0 =
        128'hDEAD_BEEF_DEAD_BEEF_DEAD_BEEF_DEAD_BEEF;

    localparam [127:0] DECOY_KEY1 =
        128'hCAFE_BABE_CAFE_BABE_CAFE_BABE_CAFE_BABE;

    localparam [127:0] DECOY_KEY2 =
        128'h000B_ADF0_0D00_0BAD_F00D_BADF_00D0_0BAD;


    wire addr_valid;

    wire addr_is_decoy;


    /*
     * i_addr是7 bit时，天然只能表示0~127。
     * 这里保留范围检查，便于以后参数化扩展。
     */
    assign addr_valid = (i_addr < DEPTH);


    assign addr_is_decoy =
        (ADDR_DECOY > 0) &&
        (
            (i_addr == 7'd32)  ||
            (i_addr == 7'd95)  ||
            (i_addr == 7'd127)
        );


    integer i;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin

            /*
             * 清空四个RAM Bank
             */
            for (i = 0; i < DEPTH; i = i + 1) begin
                ram_bank0[i] <= 32'b0;
                ram_bank1[i] <= 32'b0;
                ram_bank2[i] <= 32'b0;
                ram_bank3[i] <= 32'b0;
            end

            /*
             * 清除写锁
             */
            write_lock_mask <= {DEPTH{1'b0}};

            o_key_out   <= 128'b0;
            o_valid     <= 1'b0;
            o_write_ack <= 1'b0;


            /*
             * 写入诱饵数据。
             *
             * 这些数据只用于保留特殊地址，
             * 不参与正常密钥读取。
             */
            if (ADDR_DECOY > 0) begin

                ram_bank0[32] <= DECOY_KEY0[31:0];
                ram_bank1[32] <= DECOY_KEY0[63:32];
                ram_bank2[32] <= DECOY_KEY0[95:64];
                ram_bank3[32] <= DECOY_KEY0[127:96];

                ram_bank0[95] <= DECOY_KEY1[31:0];
                ram_bank1[95] <= DECOY_KEY1[63:32];
                ram_bank2[95] <= DECOY_KEY1[95:64];
                ram_bank3[95] <= DECOY_KEY1[127:96];

                ram_bank0[127] <= DECOY_KEY2[31:0];
                ram_bank1[127] <= DECOY_KEY2[63:32];
                ram_bank2[127] <= DECOY_KEY2[95:64];
                ram_bank3[127] <= DECOY_KEY2[127:96];
            end
        end
        else begin

            /*
             * 默认输出无效
             */
            o_valid     <= 1'b0;
            o_write_ack <= 1'b0;


            /*
             * 写操作优先于读操作
             */
            if (i_wen) begin

                if (addr_valid &&
                    !addr_is_decoy &&
                    (!WRITE_LOCK || !write_lock_mask[i_addr])) begin

                    /*
                     * 将一个128 bit key拆成四个32 bit bank写入
                     */
                    ram_bank0[i_addr] <= i_wdata[31:0];
                    ram_bank1[i_addr] <= i_wdata[63:32];
                    ram_bank2[i_addr] <= i_wdata[95:64];
                    ram_bank3[i_addr] <= i_wdata[127:96];

                    o_write_ack <= 1'b1;

                    /*
                     * 一次写入后锁定该地址
                     */
                    if (WRITE_LOCK) begin
                        write_lock_mask[i_addr] <= 1'b1;
                    end
                end
            end

            /*
             * 同步读操作
             */
            else if (i_ren) begin

                if (addr_valid && !addr_is_decoy) begin

                    /*
                     * 四个Bank拼接成完整128 bit密钥
                     */
                    o_key_out <= {
                        ram_bank3[i_addr],
                        ram_bank2[i_addr],
                        ram_bank1[i_addr],
                        ram_bank0[i_addr]
                    };

                    o_valid <= 1'b1;
                end
            end
        end
    end

endmodule
