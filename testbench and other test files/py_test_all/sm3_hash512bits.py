from gmssl import sm3


def sm3_hash_512bit(hex_data: str) -> str:
    """
    使用 gmssl 库计算512位16进制数据的SM3哈希（自动处理填充）
    :param hex_data: 512位16进制字符串（128字符，如"00"*64）
    :return: 256位SM3哈希值（16进制字符串）
    """
    # 验证输入长度（512位=64字节=128个16进制字符）
    if len(hex_data) != 128:
        raise ValueError(f"输入应为512位16进制数据（128字符），当前长度：{len(hex_data)}")

    # 16进制转字节流
    try:
        data_bytes = bytes.fromhex(hex_data)
    except ValueError:
        raise ValueError("输入的16进制数据格式错误")

    # 调用gmssl的SM3计算（自动处理填充和哈希）
    hash_hex = sm3.sm3_hash(list(data_bytes))  # 注意：gmssl要求输入为字节列表
    return hash_hex


# 测试示例
#if __name__ == "__main__":
#    # 测试1：512位全0数据
#    test_hex = "00" * 64  # 64字节 → 512位
#    print(f"512位全0数据的SM3哈希: {sm3_hash_512bit(test_hex)}")
#
#    # 测试2：512位随机数据（"12345678"重复16次）
#    test_hex = "12345678" * 16  # 64字节 → 512位
#    print(f"512位随机数据的SM3哈希: {sm3_hash_512bit(test_hex)}")
def process_file(input_path: str, output_path: str):
    """
    读取输入文件，逐行加密512位数据，结果写入输出文件
    :param input_path: 输入文件路径（含1000行512位16进制数据）
    :param output_path: 输出文件路径（保存1000个加密结果）
    """
    encrypted_results = []  # 存储加密结果

    # 1. 读取输入文件并逐行处理
    with open(input_path, 'r', encoding='utf-8') as f_in:
        for line_num, line in enumerate(f_in, 1):  # line_num从1开始计数
            data = line.strip()  # 去除行首尾空白/换行符
            if not data:
                print(f"警告：第{line_num}行为空，跳过处理")
                continue

            try:
                # 2. 对每行数据加密
                result = sm3_hash_512bit(data)
                encrypted_results.append(result)
                print(f"已处理第{line_num}行，加密结果：{result}")  # 可选：打印进度

            except ValueError as e:
                print(f"错误：第{line_num}行处理失败，原因：{str(e)}")
                # 可选择继续处理后续行（注释下一行）或终止程序（取消注释）
                # raise  # 取消注释则遇到错误时终止程序

    # 3. 将加密结果写入输出文件（每行一个结果）
    with open(output_path, 'w', encoding='utf-8') as f_out:
        for result in encrypted_results:
            f_out.write(result + '\n')  # 每行末尾添加换行符

    print(f"处理完成！共处理{len(encrypted_results)}行数据，结果保存在：{output_path}")


# 主程序运行（修改路径后执行）
if __name__ == "__main__":
    # 用户需修改以下路径：
    INPUT_FILE = "SM3_DATA_TB/text_data_512.txt"  # 输入文件路径（含1000行512位数据）
    OUTPUT_FILE = "SM3_DATA_PY/sm3_results512.txt"  # 输出文件路径

    process_file(INPUT_FILE, OUTPUT_FILE)