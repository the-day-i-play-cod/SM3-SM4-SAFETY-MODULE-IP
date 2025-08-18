`timescale 1ns/1ps
module tb_sm3_task();

reg         io_mainClk;
reg         resetCtrl_systemReset;
reg  [11:0] io_apb_PADDR;
reg  [0:0]  io_apb_PSEL;
reg         io_apb_PENABLE;
reg         io_apb_PWRITE;
reg  [31:0] io_apb_PWDATA;
wire [31:0] io_apb_PRDATA;
wire        io_apb_PREADY;
wire        io_interrupt;


wire         io_SM4_interrupt;
wire         io_SM3_interrupt;


reg [255:0]  hash_result;

reg [511:0] data;


// 实例化待测模�?
APB_TOP_SM3_SM4 uut (
    .io_apb_PADDR          (io_apb_PADDR),
    .io_apb_PSEL           (io_apb_PSEL),
    .io_apb_PENABLE        (io_apb_PENABLE),
    .io_apb_PREADY         (io_apb_PREADY),
    .io_apb_PWRITE         (io_apb_PWRITE),
    .io_apb_PWDATA         (io_apb_PWDATA),
    .io_apb_PRDATA         (io_apb_PRDATA),
    .io_apb_PSLVERROR      (),
    //.io_interrupt          (io_interrupt),
    .io_SM4_interrupt      (io_SM4_interrupt),
    .io_SM3_interrupt      (io_SM3_interrupt),    
    .io_mainClk            (io_mainClk),
    .resetCtrl_systemReset (resetCtrl_systemReset)
);

// 时钟生成
initial begin
    io_mainClk = 0;
    forever #5 io_mainClk = ~io_mainClk;
end

// APB事务�?2�?
task apb_write;
    input [11:0] addr;
    input [31:0] data;
    begin
        @(posedge io_mainClk);
        io_apb_PSEL    = 1'b1;
        io_apb_PENABLE = 1'b0;
        io_apb_PWRITE  = 1'b1;
        io_apb_PADDR   = addr;
        io_apb_PWDATA  = data;
        @(posedge io_mainClk);
        io_apb_PENABLE = 1'b1;
        @(posedge io_mainClk);
        while (!io_apb_PREADY) @(posedge io_mainClk);
        io_apb_PSEL    = 1'b0;
        io_apb_PENABLE = 1'b0;
    end
endtask

task apb_read;
    input [11:0] addr;
    output [31:0] data;
    begin
        @(posedge io_mainClk);
        io_apb_PSEL    = 1'b1;
        io_apb_PENABLE = 1'b0;
        io_apb_PWRITE  = 1'b0;
        io_apb_PADDR   = addr;
        @(posedge io_mainClk);
        io_apb_PENABLE = 1'b1;
        @(posedge io_mainClk);
        while (!io_apb_PREADY) @(posedge io_mainClk);
        data = io_apb_PRDATA;
        io_apb_PSEL    = 1'b0;
        io_apb_PENABLE = 1'b0;
    end
endtask


task hash (input [511:0] data,input [31:0] byte_nums,input [1:0]stat_2_1,output [255:0] hash_result);
reg [31:0] hash_r0, hash_r1, hash_r2, hash_r3,  // SM3哈希结果寄存器（完整声明�?
           hash_r4, hash_r5, hash_r6, hash_r7;
begin
apb_write(12'h204, data[511:480]);  // �?�?32�?
apb_write(12'h208, data[479:448]);  
apb_write(12'h20C, data[447:416]);  
apb_write(12'h210, data[415:384]);  
apb_write(12'h214, data[383:352]);  
apb_write(12'h218, data[351:320]);  
apb_write(12'h21C, data[319:288]);  
apb_write(12'h220, data[287:256]);  
apb_write(12'h224, data[255:224]);  
apb_write(12'h228, data[223:192]);  
apb_write(12'h22C, data[191:160]);  
apb_write(12'h230, data[159:128]);  
apb_write(12'h234, data[127:96]);   
apb_write(12'h238, data[95:64]);    
apb_write(12'h23C, data[63:32]);    // 中间32�?
apb_write(12'h240, data[31:0]);     // �?�?32�?
apb_write(12'h244, byte_nums      );  
apb_write(12'h200, {29'b0,stat_2_1,1'b1});  // SM3_status_reg = 1  
wait(io_SM3_interrupt);
apb_read(12'h248, hash_r0);
apb_read(12'h24C, hash_r1);
apb_read(12'h250, hash_r2);
apb_read(12'h254, hash_r3);
apb_read(12'h258, hash_r4);
apb_read(12'h25C, hash_r5);
apb_read(12'h260, hash_r6);
apb_read(12'h264, hash_r7);
#10
hash_result={	
         hash_r7, hash_r6, hash_r5, hash_r4,
         hash_r3, hash_r2, hash_r1, hash_r0};
end
endtask

task stat_write_clr();
begin
    apb_write(12'h200, {29'b0, 3'b0});
end
endtask

integer text_data_256,hash_result_256;
integer text_data_512,hash_result_512;

task rank_256bits_datagen();
    begin
        data = {
            32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(), 
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom()                       
        };
    end
endtask

task rank_512bits_datagen();
    begin
        data = {
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(), 
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(),               
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(), 
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom()                       
        };
    end
endtask
integer i;
task one_thousand_256bits_hash();

for(i=0;i<1000;i=i+1)begin
    #10
    rank_256bits_datagen();
    $fdisplay(text_data_256,"%h",data);
    hash(data,32'd8,2'b0,hash_result);
    $fdisplay(hash_result_256,"%h",hash_result);
end
endtask



task one_thousand_512bits_hash();
for(i=0;i<1000;i=i+1)begin
    #10
    rank_512bits_datagen();
    $fdisplay(text_data_512,"%h",data);
    hash(data,32'd16,2'b0,hash_result);
    $fdisplay(hash_result_512,"%h",hash_result);
end
endtask

initial begin
    // 初始�?
    resetCtrl_systemReset = 1;
    io_apb_PSEL = 0;
    io_apb_PENABLE = 0;
    #100;
    resetCtrl_systemReset = 0;
    #100;
    text_data_256 = $fopen("text_data_256.txt", "w");
        if (!text_data_256) begin
            $display("Error opening file!");
            $finish;
        end
 
    hash_result_256 = $fopen("hash_result_256.txt", "w");
        if (!hash_result_256) begin
            $display("Error opening file!");
            $finish;
        end

    text_data_512 = $fopen("text_data_512.txt", "w");
        if (!text_data_512) begin
            $display("Error opening file!");
            $finish;
        end        

    hash_result_512 = $fopen("hash_result_512.txt", "w");
        if (!hash_result_512) begin
            $display("Error opening file!");
            $finish;
        end
    #100
    one_thousand_256bits_hash();
    #100
    one_thousand_512bits_hash();   

    $fclose(text_data_256);
	$fclose(hash_result_256);    
    $fclose(text_data_512);
    $fclose(hash_result_512);
    $finish;
end
endmodule