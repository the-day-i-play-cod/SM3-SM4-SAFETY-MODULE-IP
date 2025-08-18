`timescale 1ns/1ps
`define simulation
module tb_SM4_APB_TOP_rangen_new();

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


reg [31:0]  data_r0;
reg [31:0]  data_r1;
reg [31:0]  data_r2;
reg [31:0]  data_r3;

reg [127:0] data_result;
reg         wo_ready;


integer chip_file;
integer text_file;
integer de_chip_file;
// 实例化待测模�??
APB_TOP_SM3_SM4 uut (
    .io_apb_PADDR          (io_apb_PADDR),
    .io_apb_PSEL           (io_apb_PSEL),
    .io_apb_PENABLE        (io_apb_PENABLE),
    .io_apb_PREADY         (io_apb_PREADY),
    .io_apb_PWRITE         (io_apb_PWRITE),
    .io_apb_PWDATA         (io_apb_PWDATA),
    .io_apb_PRDATA         (io_apb_PRDATA),
    .io_apb_PSLVERROR      (),
    .io_SM4_interrupt      (io_SM4_interrupt),
    .io_SM3_interrupt      (io_SM3_interrupt),
    .io_mainClk            (io_mainClk),
    .resetCtrl_systemReset (resetCtrl_systemReset)
    //.wo_ready              (wo_ready)
);

// 时钟生成
initial begin
    io_mainClk = 0;
    forever #5 io_mainClk = ~io_mainClk;
end

// APB事务�??2�??
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


task de_result_read();
begin
    apb_read(12'h118, data_r0);
    apb_read(12'h11C, data_r1);
    apb_read(12'h120, data_r2);
    apb_read(12'h124, data_r3);
    data_result<={data_r0,data_r1,data_r2,data_r3};
    #20;
end
endtask

task en_result_read();
begin
    apb_read(12'h118, data_r0);
    apb_read(12'h11C, data_r1);
    apb_read(12'h120, data_r2);
    apb_read(12'h124, data_r3);
    data_result<={data_r0,data_r1,data_r2,data_r3};
    #20;
end
endtask


task automatic de_data(input [127:0] text);begin
    apb_write(12'h14C, 4'b0100);        //i_sm4_mode   = 4'b0100;  

    apb_write(12'h104, text[31:0]);     //i_data  = data;
    apb_write(12'h108, text[63:32]);
    apb_write(12'h10C, text[95:64]);
    apb_write(12'h110, text[127:96]);         

    apb_write(12'h114, 32'b1);          //r_work_flag  = 1'b1;

    wait(io_SM4_interrupt);
    de_result_read();
    #100;
end
endtask


task text_write_encrypt(input [127:0] text);
    // 写入明文
    begin
    apb_write(12'h14C, 4'b1000); 
    apb_write(12'h104, text[31:0]);
    apb_write(12'h108, text[63:32]);
    apb_write(12'h10C, text[95:64]);
    apb_write(12'h110, text[127:96]);
    apb_write(12'h114, 32'b1);      

    // 等待中断
    wait(io_SM4_interrupt);
    // 读取加密结果
    en_result_read(); //write_in_chip_file.txt
    end
endtask


task automatic gen_key(input [6:0] addr);begin //in rom and initial

    apb_write(12'h14C, 4'b0001); 
    apb_write(12'h150, addr   );
    apb_write(12'h148, 32'b1  );     
    #200;
    end
endtask    


task automatic use_key_in_rom(input [6:0] addr); begin//initial
    apb_write(12'h14C, 4'b0010); 
    apb_write(12'h150, addr   );    
    apb_write(12'h148, 32'b1  );    
    #200;      
    end
endtask        

task direct_init(input [127:0] key);begin
    apb_write(12'h14C, 4'b0000);     

    apb_write(12'h138, key[31:0]);
    apb_write(12'h13C, key[63:32]);
    apb_write(12'h140, key[95:64]);
    apb_write(12'h144, key[127:96]);    

    apb_write(12'h148, 32'b1  );    
    #200;     

end
endtask 


//begin test
integer i;
initial begin
    // 初始�??
    resetCtrl_systemReset = 1;
    io_apb_PSEL = 0;
    io_apb_PENABLE = 0;

    #100;
    resetCtrl_systemReset = 0;
    #100;    

  //direct_init(128'h0123456789ABCDEFFEDCBA9876543210);
  ////wait(wo_ready);
  //#4000

  //use_key_in_rom(7'h1);
  ////wait(wo_ready);
  //#4000  
  //gen_key(7'h2);
  ////wait(wo_ready);
  //#4000     

    direct_init(128'h0123456789ABCDEFFEDCBA9876543210);
    #4000
    text_write_encrypt(128'h0123456789ABCDEFFEDCBA9876543210);

    if(data_result==128'h681EDF34D206965E86B3E94F536E4246)begin
        $display("example_1 veri success!");
    end else begin
        $display("example_1 veri failed!");
    end


//example 2 encrypt 1 000 000 times

    #100
    direct_init(128'h0123456789ABCDEFFEDCBA9876543210);
    #4000
    // en the first time
    text_write_encrypt(128'h0123456789ABCDEFFEDCBA9876543210);

    //remaining 999_999
    
    for(i=1;i<1000000;i=i+1)begin
        text_write_encrypt(data_result);
    end

    #100
    if(data_result==128'h595298C7C6FD271F0402F804C33D3F66)begin
        $display("example_2 veri success!");
    end else begin
        $display("example_2 veri failed!");
    end    


     
    #100
    $finish;    
end
endmodule