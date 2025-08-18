files in "py_test_all" statement:
“photo”为测试部分截图。
“SM3_DATA_PY” 为SM3模块testbench测试所使用的随机数据的python标准库运算结果
“SM3_DATA_TB” 为SM3模块testbench测试结果以及systemverilog代码
“SM4_DATA_PY” 为SM4模块testbench测试所使用的随机数据的python标准库运算结果
“SM4_DATA_TB” 为SM3模块testbench测试结果以及systemverilog代码，其中每个编号文件夹中的chip_file.txt为数据加密后结果，de_chip_file.txt为对加密结果进行解密后的结果，应与未加密随机数据text_file.txt文件中的内容（除第一行为秘钥外）完全一致。
“compare_console_output.txt” 为正确结果与IP运算结果的一致性对比代码的结果输出。 
“compare_correct.py”为完成正确结果与IP运算结果的一致性对比代码。
“sm3_hash_256bits.py”为完成一千条256位数据SM3运算的python代码。
“sm3_hash512bits.py” 为完成一千条512位数据SM3运算的python代码。
“sm4_lib_encrypt.py” 为完成tb_SM4_APB_amount_test.sv文件生成的随机数据进行标准库加密的python代码。

