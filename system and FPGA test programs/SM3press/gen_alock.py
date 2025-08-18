# 生成1000条SM3单分组消息运算调用代码的脚本
with open("long_hash_calls.c", "w") as f:
    for i in range(1, 1001):
        f.write(f"hashcompu(hex_array{i}, 16,0);\n")