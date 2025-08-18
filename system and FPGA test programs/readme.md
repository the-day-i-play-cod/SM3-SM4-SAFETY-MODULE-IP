//放大可显示下划线

ten_batches_1kb_test

    |___ 1
    
    | |___ hex_data_py.txt            //16进制1kb长度数据
    
    | |___ right_result.png           //正确哈希值运算结果 
    
    | |___ uint32_array_py.txt        //数组形式1kb数据,用于程序调用
    
    |
    
    |___ 2                            //第二组1kb数据，与"1"目录结构相同 
    
    .
    
    .
    
    .
    
    |___ 10
    
    |
    
    |___ code_project                 //软件程序工程，核心文件为main.c,data.h,data.c
    
    |___ test_result1.png             //FPGA平台运行结果图1
    
    |___ test_result2.png             //FPGA平台运行结果图2 
    
    |___ hash_long_data.py            //长数据哈希值运算python代码
    
    |___ sm3_1kb_data.py              //可配置长度参数长数据生成代码 

    

SM4press

    |___ 1                          //testbench平台生成的一千条随机数据
    
    |___ 2                          //第二份目录"1"同性质内容
    
    |___ 3                          //第三份目录"1"同性质内容
    
    |___ a_SM3_SM4_press_on_FPGA    //软件程序工程
    
    |___ gen_alock.py               //生成调用一千次调用SM4加密函数的python代码
    
    |___ trans_code.py              //将16进制数据文件"text_file.txt"每行数据生成C语言数组定义的python转换代码
    
    |___ text_file.txt              //第一份testbench平台仿真数据中的明文文件（第一行为秘钥）
    
    |___ sm4_data.h                 //trans_code.py生成的数据文件
    
    |___ sm4_encrypt_calls.c        //gen_alock.py生成的调用C代码



SM3press

    |___ correct_result
    
    |       |___sm3_results512.txt  //text_data_512.txt 中的数据的正确哈希值运算结果
    
    |___ a_SM3_SM4_press_on_FPGA    //软件程序工程
    
    |___ gen_alock.py               //生成调用一千次调用SM3运算的python代码
    
    |___ trans_code.py              //将16进制数据文件"text_data_512.txt"每行数据生成C语言数组定义的python转换代码
    
    |___ text_data_512.txt          //一千条512bits数据文本
    
    |___ sm3_data.h                 //trans_code.py生成的数据文件
    
    |___ long_hash_calls.c          //gen_alock.py生成的调用C代码

    


code_prj_printresults_veri        //综合测试工程，覆盖所有设计功能，打印测试结果

    |___ code_prj //相关程序代码
    
    |___ photo    //测试结果截图

    

code_prj_not_printresults_fast  //不打印结果快速完成加密功能版本程序

    |___ code_prj //相关程序代码
    
