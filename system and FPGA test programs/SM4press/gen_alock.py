# 生成1000条long_hash调用代码的脚本
with open("sm4_encrypt_calls.c", "w") as f:
    for i in range(1, 1002):
        f.write(f"text_encrypt(data_array{i});\n")