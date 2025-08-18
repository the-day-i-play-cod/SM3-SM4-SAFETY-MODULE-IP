#configurable long data gen
import os
import struct
import binascii

# 配置参数
#
TOTAL_SIZE_KB = 1
TOTAL_BYTES = TOTAL_SIZE_KB * 1024  # 自动计算为 131072 字节
UINT32_COUNT = TOTAL_BYTES // 4     # 32位数组元素个数：32768
def generate_random_data():
    # 1. 生成随机字节数据（使用os.urandom确保高效且安全）
    random_bytes = os.urandom(TOTAL_BYTES)

    # 2. 转换为32位大端序（高位在前）数组
    # 格式说明：'>'表示大端序，'I'表示无符号32位整数，重复UINT32_COUNT次
    uint32_array = struct.unpack('>' + 'I' * UINT32_COUNT, random_bytes)

    # 3. 转换为16进制字符串（大写）
    hex_str = binascii.hexlify(random_bytes).decode('ascii').upper()

    return uint32_array, hex_str


def write_uint32_array_to_file(uint32_array, filename):
    with open(filename, 'w') as f:
        f.write(f"uint32_t random_data[{UINT32_COUNT}] = {{\n")
        # 每4个元素一行，增强可读性
        for i in range(0, UINT32_COUNT, 4):
            line_elements = [f"0x{num:08X}" for num in uint32_array[i:i + 4]]
            f.write("    " + ", ".join(line_elements) + ",\n")
        f.write("};\n")


def write_hex_to_file(hex_str, filename):
    with open(filename, 'w') as f:
        f.write(hex_str)


if __name__ == "__main__":
    uint32_array, hex_str = generate_random_data()

    # 写入32位数组文件
    write_uint32_array_to_file(uint32_array, "uint32_array_py.txt")

    # 写入16进制文件
    write_hex_to_file(hex_str, "hex_data_py.txt")

    print("数据生成完成：")
    print(f"- 32位数组（大端序）：uint32_array_py.txt")
    print(f"- 16进制完整数据：hex_data_py.txt")



