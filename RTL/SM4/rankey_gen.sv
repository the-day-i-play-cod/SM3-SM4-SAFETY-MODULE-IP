module sm4_keygen (
    input wire i_clk,          
    input wire i_rst_n,        
    input wire i_keygen_en,    
    output reg [127:0] o_key   
);


reg [127:0] lfsr_state;


wire feedback = lfsr_state[127] ^ lfsr_state[125] ^ 
                lfsr_state[100] ^ lfsr_state[98];

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        lfsr_state <= 128'h9E3779B97F4A7C15F39D060B_CE4E;
    end
    else if (i_keygen_en) begin
        lfsr_state <= {lfsr_state[126:0], feedback};
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_key <= 128'b0;
    end
    else if (i_keygen_en) begin
        o_key <= lfsr_state;
    end
end

endmodule