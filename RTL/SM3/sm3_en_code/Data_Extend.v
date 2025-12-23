
`timescale 1ns / 1ps

module Data_Extend(
    input               i_clk           ,
    input               i_rst           ,
    input  [511 :0]     i_padding_data  ,
    input               i_padding_valid ,
    // Dual read-port interface for consumer (SM3_Encrypt)
    input      [6:0]    i_rd_addr0      ,
    input      [6:0]    i_rd_addr1      ,
    output reg [31:0]   o_rd_data0      ,
    output reg [31:0]   o_rd_data1      ,
    // Schedule ready flag
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
reg                     ro_extend_valid         ;

wire [511:0]            w_padding_data_f        ;

assign o_extend_valid = ro_extend_valid ;

// -----------------------------------------------------------------------------
// Internal dual-read single-write RAM (132 x 32) for W and W'
// -----------------------------------------------------------------------------
reg [31:0] mem [0:131];
reg        mem_we;
reg [6:0]  mem_waddr;
reg [31:0] mem_wdata;
reg [6:0]  mem_raddr0;
reg [6:0]  mem_raddr1;

always @(posedge i_clk) begin
    if (mem_we) begin
        mem[mem_waddr] <= mem_wdata;
    end
end

// synchronous read (registered outputs)
always @(posedge i_clk) begin
    o_rd_data0 <= mem[mem_raddr0];
    o_rd_data1 <= mem[mem_raddr1];
end


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


// Note: Removed wide o_extend_data bus. Consumer reads words via RAM ports.


// -----------------------------------------------------------------------------
// FSM to fill RAM with W (0..67) and W' (68..131)
// -----------------------------------------------------------------------------
localparam S_IDLE               = 3'd0;
localparam S_W0_15              = 3'd1;
localparam S_W16_67_READ1       = 3'd2;
localparam S_W16_67_READ2       = 3'd3;
localparam S_W16_67_READ3_REQ6  = 3'd4;
localparam S_WP_0_67_READ       = 3'd5;
localparam S_WP_0_67_WRITE      = 3'd6;
localparam S_DONE               = 3'd7;

reg [2:0]  state;
reg [6:0]  idx;       // generic index up to 131
reg [6:0]  j_round;   // 16..67

// Temporaries for W16..67
reg [31:0] t_jm16, t_jm9, t_jm3, t_jm13, t_jm6;
reg [31:0] t_p1x, t_p1, t_mid1, t_wj;

// Helper: extract padding word in reversed order (matches original mapping)
function [31:0] get_pad_word;
    input [511:0] din;
    input [4:0]   k; // 0..15
    reg [31:0]    tmp;
begin
    case (k)
        5'd0:  tmp = din[511:480];
        5'd1:  tmp = din[479:448];
        5'd2:  tmp = din[447:416];
        5'd3:  tmp = din[415:384];
        5'd4:  tmp = din[383:352];
        5'd5:  tmp = din[351:320];
        5'd6:  tmp = din[319:288];
        5'd7:  tmp = din[287:256];
        5'd8:  tmp = din[255:224];
        5'd9:  tmp = din[223:192];
        5'd10: tmp = din[191:160];
        5'd11: tmp = din[159:128];
        5'd12: tmp = din[127:96];
        5'd13: tmp = din[95:64];
        5'd14: tmp = din[63:32];
        5'd15: tmp = din[31:0];
        default: tmp = 32'd0;
    endcase
    get_pad_word = tmp;
end
endfunction

// Control FSM body
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state <= S_IDLE;
        idx   <= 7'd0;
        j_round <= 7'd16;
        mem_we <= 1'b0;
        mem_waddr <= 7'd0;
        mem_wdata <= 32'd0;
        mem_raddr0 <= 7'd0;
        mem_raddr1 <= 7'd0;
        ro_extend_valid <= 1'b0;
        t_jm16 <= 32'd0; t_jm9 <= 32'd0; t_jm3 <= 32'd0; t_jm13 <= 32'd0; t_jm6 <= 32'd0;
        t_p1x <= 32'd0; t_p1 <= 32'd0; t_mid1 <= 32'd0; t_wj <= 32'd0;
    end else begin
        mem_we <= 1'b0; // default
        case (state)
            S_IDLE: begin
                ro_extend_valid <= 1'b0;
                if (ri_padding_valid_1d) begin
                    idx <= 7'd0;
                    state <= S_W0_15;
                end
            end

            // Write W0..W15 to RAM addresses 0..15
            S_W0_15: begin
                mem_waddr <= idx;
                mem_wdata <= get_pad_word(ri_padding_data, idx[4:0]);
                mem_we    <= 1'b1;
                if (idx == 7'd15) begin
                    j_round <= 7'd16;
                    state   <= S_W16_67_READ1;
                end else begin
                    idx <= idx + 7'd1;
                end
            end

            // For each j=16..67: READ1 -> READ2 -> READ3 (request j-6)
            S_W16_67_READ1: begin
                mem_raddr0 <= j_round - 7'd16; // j-16
                mem_raddr1 <= j_round - 7'd9;  // j-9
                state <= S_W16_67_READ2;
            end
            S_W16_67_READ2: begin
                t_jm16 <= o_rd_data0;
                t_jm9  <= o_rd_data1;
                mem_raddr0 <= j_round - 7'd3;  // j-3
                mem_raddr1 <= j_round - 7'd13; // j-13
                state <= S_W16_67_READ3_REQ6;
            end
            S_W16_67_READ3_REQ6: begin
                t_jm3  <= o_rd_data0;
                t_jm13 <= o_rd_data1;
                // compute intermediates
                t_p1x  <= t_jm16 ^ t_jm9 ^ {t_jm3[16:0], t_jm3[31:17]};
                t_mid1 <= {t_jm13[24:0], t_jm13[31:25]};
                // request j-6 and on next S_W16_67_READ1 use write-back path
                mem_raddr0 <= j_round - 7'd6; // j-6
                // piggyback write in parallel (one cycle latency)
                t_p1 <= P1(t_p1x);
                t_wj <= t_p1 ^ t_mid1; // add j-6 next cycle
                // next cycle: S_W16_67_READ1
                state <= S_W16_67_READ1;
                // use idx[0] as small flag-based write enable in next cycle
                idx[0] <= 1'b1;
            end
        endcase

        // Perform the delayed write when j-6 data arrives (on S_W16_67_READ1)
        if (state == S_W16_67_READ1 && idx[0]) begin
            t_jm6 <= o_rd_data0;
            mem_waddr <= j_round;
            mem_wdata <= t_wj ^ t_jm6;
            mem_we    <= 1'b1;
            idx[0]    <= 1'b0;
            if (j_round == 7'd67) begin
                idx <= 7'd0;
                state <= S_WP_0_67_READ;
            end else begin
                j_round <= j_round + 7'd1;
                state   <= S_W16_67_READ1;
            end
        end

        // Compute W'0..67 = Wj ^ Wj+4 into addresses 68..131
        if (state == S_WP_0_67_READ) begin
            mem_raddr0 <= idx;         // j
            mem_raddr1 <= idx + 7'd4;  // j+4
            state <= S_WP_0_67_WRITE;
        end else if (state == S_WP_0_67_WRITE) begin
            mem_waddr <= 7'd68 + idx;
            mem_wdata <= o_rd_data0 ^ o_rd_data1;
            mem_we    <= 1'b1;
            if (idx == 7'd67) begin
                state <= S_DONE;
            end else begin
                idx <= idx + 7'd1;
                state <= S_WP_0_67_READ;
            end
        end else if (state == S_DONE) begin
            ro_extend_valid <= 1'b1;
            // allow new input to retrigger
            if (ri_padding_valid_1d) begin
                ro_extend_valid <= 1'b0;
                state <= S_W0_15;
                idx <= 7'd0;
                j_round <= 7'd16;
            end
        end
    end
end

// W' computed in FSM into RAM addresses 68..131

// Removed register stage array; outputs are read via RAM ports.




// Valid is managed by FSM; removed delay chain

endmodule
