#将数据切割为16个数组并按递增编号命名的代码
#例如：“8c5b5b3a1d9704a2503eca9c54320ecfff5a56fa189d9862be2ffb799f243e7a” ->uint32_t hex_array1[16] = {0x9bcdedd3, 0x20b52e34, 0x3d7ad896, 0x06536634, 0x7f5df7cc, 0x72306338, 0x17b5d29f, 0x157a879e, 0x21573668, 0x4b4a755e, 0x6e9d9395, 0x69e3702d, 0x50d92ccf, 0x4c6b5d41, 0x26dcf409, 0xb773c63b};

def generate_sm3_header(txt_path, output_header="sm3_data.h"):
    with open(txt_path, 'r') as f:
        lines = [line.strip() for line in f.readlines() if line.strip()]  # 读取并清理空行

    # 生成数组内容
    c_arrays = []
    for idx, line in enumerate(lines, 1):
        # 验证每行长度是否为128字符（16*8位）
        if len(line) != 128:
            raise ValueError(f"第{idx}行长度错误，需要128个十六进制字符，当前长度{len(line)}")

        # 按每8字符分割为32位块（每个十六进制字符4位，8字符=32位）
        chunks = [line[i * 8:(i + 1) * 8] for i in range(16)]

        # 转换为0xHHHHHHHH格式（大端模式）
        hex_values = [f"0x{chunk}" for chunk in chunks]

        # 生成C数组定义
        array_def = f"uint32_t hex_array{idx}[16] = {{{', '.join(hex_values)}}};"
        c_arrays.append(array_def)

    # 生成头文件内容（含保护宏）
    header_content = (
        "#ifndef SM3_DATA_H\n"
        "#define SM3_DATA_H\n\n"
        "// 自动生成的SM3数据数组，来自文件: {}\n\n"
        "{}\n\n"
        "#endif // SM3_DATA_H"
    ).format(txt_path, '\n'.join(c_arrays))

    # 写入头文件
    with open(output_header, 'w') as f:
        f.write(header_content)

    print(f"头文件已生成：{output_header}")


# 使用示例（假设txt文件路径为"hex_data.txt"）
if __name__ == "__main__":
    generate_sm3_header("text_data_512.txt")