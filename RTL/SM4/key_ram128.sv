module key_ram_128 (
    input wire          i_clk,       
    input wire          i_rst_n,     
    input wire          i_ren,       
    input wire          i_wen,       
    input wire  [6:0]   i_addr,      
    input wire  [127:0] i_wdata,     
    output reg  [127:0] o_key_out,   
    output reg          o_valid,     
    output reg          o_write_ack  
);


parameter MASKING = 0;       
parameter ADDR_DECOY = 3;    
parameter WRITE_LOCK = 1;    


(* ram_style = "distributed", keep = "true" *) 
reg [127:0] ram [0:127];


reg [127:0] write_lock_mask;


wire [127:0] mask = MASKING ? {64{2'b10}} : 128'h0;

integer i;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin 
        for (i = 0; i < 128; i = i + 1) begin
            ram[i] <= 128'h0;
        end
        o_valid <= 1'b0;
        o_key_out <= 128'h0;
        o_write_ack <= 1'b0;
        write_lock_mask <= 128'h0; 


        if (ADDR_DECOY > 0) begin
            ram[32]  <= 128'hDEADBEEF_DEADBEEF_DEADBEEF_DEADBEEF;
            ram[95]  <= 128'hCAFEBABE_CAFEBABE_CAFEBABE_CAFEBABE;
            ram[127] <= 128'hBADF00D_BADF00D_BADF00D_BADF00D;
            

            write_lock_mask[32] <= 1'b1;
            write_lock_mask[95] <= 1'b1;
            write_lock_mask[127] <= 1'b1;
        end
    end
    else begin
        o_valid <= 1'b0;
        o_write_ack <= 1'b0;
        

        if (i_wen) begin
            if (i_addr < 128) begin
                if ((ADDR_DECOY > 0 && ((i_addr == 7'd32) || (i_addr == 7'd95) || (i_addr == 7'd127))) || (write_lock_mask[i_addr])) begin
                    o_write_ack <= 1'b0; 
                end
                else begin
                    ram[i_addr] <= i_wdata;
                    o_write_ack <= 1'b1;
                    if (WRITE_LOCK) begin
                        write_lock_mask[i_addr] <= 1'b1;
                    end
                end
            end
        end
        else if (i_ren) begin
            if (i_addr < 128) begin
                if ((ADDR_DECOY > 0) && ((i_addr == 7'd32) || (i_addr == 7'd95) || (i_addr == 7'd127))) begin
                    o_key_out <= 128'h0;
                    o_valid <= 1'b0;
                end
                else begin
                    o_key_out <= ram[i_addr] ^ mask;
                    o_valid <= 1'b1;
                end
            end
        end
    end
end


(* keep = "true" *) wire [127:0] ram_shield [0:3];
assign ram_shield[0] = 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;
assign ram_shield[1] = 128'h00000000_00000000_00000000_00000000;
assign ram_shield[2] = 128'hAAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA;
assign ram_shield[3] = 128'h55555555_55555555_55555555_55555555;


endmodule