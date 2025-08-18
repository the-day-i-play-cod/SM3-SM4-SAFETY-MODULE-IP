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

wire         io_SM4_interrupt;
wire         io_SM3_interrupt;


reg [31:0]  data_r0;
reg [31:0]  data_r1;
reg [31:0]  data_r2;
reg [31:0]  data_r3;

reg [127:0] data_result;
reg [127:0] de_result;

integer chip_file;
integer text_file;
integer de_chip_file;


integer chip_file1,	chip_file2,	chip_file3,	chip_file4,	chip_file5,	chip_file6,	chip_file7,	chip_file8,	chip_file9,	chip_file10,	chip_file11,	chip_file12,	chip_file13,	chip_file14,	chip_file15,	chip_file16,	chip_file17,	chip_file18,	chip_file19,	chip_file20;
integer text_file1,	text_file2,	text_file3,	text_file4,	text_file5,	text_file6,	text_file7,	text_file8,	text_file9,	text_file10,	text_file11,	text_file12,	text_file13,	text_file14,	text_file15,	text_file16,	text_file17,	text_file18,	text_file19,	text_file20;
integer de_chip_file1,	de_chip_file2,	de_chip_file3,	de_chip_file4,	de_chip_file5,	de_chip_file6,	de_chip_file7,	de_chip_file8,	de_chip_file9,	de_chip_file10,	de_chip_file11,	de_chip_file12,	de_chip_file13,	de_chip_file14,	de_chip_file15,	de_chip_file16,	de_chip_file17,	de_chip_file18,	de_chip_file19,	de_chip_file20;
// ʵ��������ģ???
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
);

// ʱ������
initial begin
    io_mainClk = 0;
    forever #5 io_mainClk = ~io_mainClk;
end

// APB����???2???
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
    de_result<={data_r0,data_r1,data_r2,data_r3};
    #20;
    //$display("de_result cycle_%d: %h", i,de_result); 
    $fdisplay(de_chip_file, "%h", de_result);      
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
    //$display("en_result cycle_%d: %h", i,data_result); 
    $fdisplay(chip_file, "%h", data_result);  
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
    // д������
    
    begin
    $fdisplay(text_file, "%h", text);
    apb_write(12'h14C, 4'b1000); 
    apb_write(12'h104, text[31:0]);
    apb_write(12'h108, text[63:32]);
    apb_write(12'h10C, text[95:64]);
    apb_write(12'h110, text[127:96]);
    apb_write(12'h114, 32'b1);      

    // �ȴ��ж�
    wait(io_SM4_interrupt);
    // ��ȡ���ܽ��
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


//128λ���������
task random_128bit_gen();
    output [127:0] ran_128b;
    begin
        ran_128b = {
      $urandom(),  // 32λ�����
      $urandom(),  // 32λ����� 
      $urandom(),  // 32λ�����
      $urandom()   // 32λ�����
    };
    end
endtask



task en_de_correct_test_task();
    reg [127:0] ran_key ;//random key
    reg [127:0] ran_text;
    integer i;
    begin

random_128bit_gen(ran_key);
direct_init(ran_key);
#4000
//begin en&de
 for (i = 0; i < 100; i = i + 1) begin
    random_128bit_gen(ran_text);
    text_write_encrypt(ran_text);//en->data_result
    #20;
    de_data(data_result);//de the en result
    #20; // ����������ʱ����
    end
    end
endtask




//begin test

integer j;
string text_name; 
string chip_name; 
string dechip_name;
initial begin
    // ��ʼ???
    resetCtrl_systemReset = 1;
    io_apb_PSEL = 0;
    io_apb_PENABLE = 0;

    #100;
    resetCtrl_systemReset = 0;
    #100;    
    
    for (j = 1; j < 21; j = j + 1) begin
        // $system("mkdir -p ./%0d", j);
        chip_name = $sformatf("./%0d/chip_file.txt", j); 
        chip_file = $fopen(chip_name, "w");
          if (!chip_file) begin
              $display("Error opening file!");
              $finish;
          end


        text_name = $sformatf("./%0d/text_file.txt", j);
        text_file = $fopen(text_name, "w");
         if (!text_file) begin
             $display("Error opening file!");
             $finish;
         end

        dechip_name = $sformatf("./%0d/de_chip_file.txt", j);
        de_chip_file = $fopen(dechip_name, "w");
          if (!de_chip_file) begin
              $display("Error opening file!");
              $finish;
          end    


        en_de_correct_test_task();
    
        $fclose(chip_file);
	    $fclose(text_file);
        $fclose(de_chip_file);

    end

  //$fclose(chip_file);
    //$fclose(text_file);
  //$fclose(de_chip_file);
  //$display("test_end");
          


 // direct_init(128'b10101010);
 // //wait(wo_ready);
 // #4000;
/*
    use_key_in_rom(7'h1);
    wait(wo_ready);
    #100    
    gen_key(7'h2);
    wait(wo_ready);
    #100     


    text_write_encrypt(128'h1022);
    text_write_encrypt(128'h1055);    
    text_write_encrypt(128'h1033);    
    de_data(data_result);
    de_data(128'h91919199a);
    de_data(128'h91917773a);
    de_data(128'h916677d9a);
    gen_key(7'h3);
    wait(wo_ready);    
    #100
    */
   $finish;  
end
endmodule