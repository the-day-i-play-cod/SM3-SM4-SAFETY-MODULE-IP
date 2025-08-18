def compare_txt_files(file1_path: str, file2_path: str) -> None:
    """
    比对两个txt文档的每一行数据（不区分大小写），输出详细比对结果
    :param file1_path: 文档1的路径
    :param file2_path: 文档2的路径
    """
    try:
        # 读取文件内容（保留原始行顺序，去除换行符）
        with open(file1_path, 'r', encoding='utf-8') as f1:
            lines1 = [line.rstrip('\n') for line in f1.readlines()]  # 去除行尾换行符

        with open(file2_path, 'r', encoding='utf-8') as f2:
            lines2 = [line.rstrip('\n') for line in f2.readlines()]

    except FileNotFoundError as e:
        print(f"错误：文件未找到 → {e.filename}")
        return
    except UnicodeDecodeError:
        print("错误：文件编码非UTF-8，请检查文件编码")
        return

    # 初始化统计变量
    total_lines = max(len(lines1), len(lines2))  # 总行数（以较长文件为准）
    match_count = 0  # 一致的行数
    mismatch_details = []  # 存储不一致的行信息（行号, 文件1内容, 文件2内容）
    extra_lines = []  # 存储行数差异的信息（文件路径, 起始行号, 剩余行数）

    # 逐行比对（处理共同行数部分）
    for line_num, (line1, line2) in enumerate(zip(lines1, lines2), start=1):
        # 不区分大小写比较（转换为小写后比对）
        if line1.lower() == line2.lower():
            match_count += 1
        else:
            mismatch_details.append((line_num, line1, line2))

    # 处理行数不一致的情况（文件1比文件2长）
    if len(lines1) > len(lines2):
        extra_start = len(lines2) + 1
        extra_count = len(lines1) - len(lines2)
        extra_lines.append((file1_path, extra_start, extra_count))

    # 处理行数不一致的情况（文件2比文件1长）
    if len(lines2) > len(lines1):
        extra_start = len(lines1) + 1
        extra_count = len(lines2) - len(lines1)
        extra_lines.append((file2_path, extra_start, extra_count))

    # 输出比对总结
    print(f"\n===== 比对总结 =====")
    print(f"总行数（以较长文件为准）: {total_lines}")
    print(f"一致的行数: {match_count}")
    print(f"不一致的行数: {len(mismatch_details)}")
    print(f"行数差异: {len(extra_lines)}个文件存在多余行")

    # 输出不一致的行详情（区分大小写的原始内容）
    if mismatch_details:
        print(f"\n===== 不一致的行详情 =====")
        for line_num, line1, line2 in mismatch_details:
            print(f"行号 {line_num}:")
            print(f"  文件1内容: {line1}")
            print(f"  文件2内容: {line2}")
            print(f"  小写比对: {line1.lower()} vs {line2.lower()} → 不一致\n")

    # 输出行数差异详情
    if extra_lines:
        print(f"\n===== 行数差异详情 =====")
        for file_path, start_line, count in extra_lines:
            print(f"文件 {file_path} 从行号 {start_line} 开始，多出 {count} 行")

def compare_txt_files_no_firstline(file1_path: str, file2_path: str) -> None:  #the first input ignore 1st line
    """
    比对两个txt文档的每一行数据（不区分大小写），输出详细比对结果
    :param file1_path: 文档1的路径
    :param file2_path: 文档2的路径
    """
    try:
        # 读取文件内容（保留原始行顺序，去除换行符）
        with open(file1_path, 'r', encoding='utf-8') as f1:
            lines1 = [line.rstrip('\n') for line in f1.readlines()[1:]]  # 去除行尾换行符

        with open(file2_path, 'r', encoding='utf-8') as f2:
            lines2 = [line.rstrip('\n') for line in f2.readlines()]

    except FileNotFoundError as e:
        print(f"错误：文件未找到 → {e.filename}")
        return
    except UnicodeDecodeError:
        print("错误：文件编码非UTF-8，请检查文件编码")
        return

    # 初始化统计变量
    total_lines = max(len(lines1), len(lines2))  # 总行数（以较长文件为准）
    match_count = 0  # 一致的行数
    mismatch_details = []  # 存储不一致的行信息（行号, 文件1内容, 文件2内容）
    extra_lines = []  # 存储行数差异的信息（文件路径, 起始行号, 剩余行数）

    # 逐行比对（处理共同行数部分）
    for line_num, (line1, line2) in enumerate(zip(lines1, lines2), start=1):
        # 不区分大小写比较（转换为小写后比对）
        if line1.lower() == line2.lower():
            match_count += 1
        else:
            mismatch_details.append((line_num, line1, line2))

    # 处理行数不一致的情况（文件1比文件2长）
    if len(lines1) > len(lines2):
        extra_start = len(lines2) + 1
        extra_count = len(lines1) - len(lines2)
        extra_lines.append((file1_path, extra_start, extra_count))

    # 处理行数不一致的情况（文件2比文件1长）
    if len(lines2) > len(lines1):
        extra_start = len(lines1) + 1
        extra_count = len(lines2) - len(lines1)
        extra_lines.append((file2_path, extra_start, extra_count))

    # 输出比对总结
    print(f"\n===== 比对总结 =====")
    print(f"总行数（以较长文件为准）: {total_lines}")
    print(f"一致的行数: {match_count}")
    print(f"不一致的行数: {len(mismatch_details)}")
    print(f"行数差异: {len(extra_lines)}个文件存在多余行")

    # 输出不一致的行详情（区分大小写的原始内容）
    if mismatch_details:
        print(f"\n===== 不一致的行详情 =====")
        for line_num, line1, line2 in mismatch_details:
            print(f"行号 {line_num}:")
            print(f"  文件1内容: {line1}")
            print(f"  文件2内容: {line2}")
            print(f"  小写比对: {line1.lower()} vs {line2.lower()} → 不一致\n")

    # 输出行数差异详情
    if extra_lines:
        print(f"\n===== 行数差异详情 =====")
        for file_path, start_line, count in extra_lines:
            print(f"文件 {file_path} 从行号 {start_line} 开始，多出 {count} 行")

# 示例使用（修改路径后运行）
if __name__ == "__main__":
    FILE1 = "SM3_DATA_PY/sm3_results256.txt"  # 替换为你的第一个txt文件路径
    FILE2 = "SM3_DATA_TB/hash_result_256.txt"  # 替换为你的第二个txt文件路径
    compare_txt_files(FILE1, FILE2)

    FILE1 = "SM3_DATA_PY/sm3_results512.txt"  # 替换为你的第一个txt文件路径
    FILE2 = "SM3_DATA_TB/hash_result_512.txt"  # 替换为你的第二个txt文件路径
    compare_txt_files(FILE1, FILE2)

    for i in range(1, 21):  # 循环i从1到20（包含20）
        FILE1 = f'SM4_DATA_TB/{i}/chip_file.txt'
        FILE2 = f'SM4_DATA_PY/{i}/encrypted.txt'
        compare_txt_files(FILE1, FILE2)

        FILE3 = f'SM4_DATA_TB/{i}/de_chip_file.txt'
        FILE4 = f'SM4_DATA_TB/{i}/text_file.txt'
        compare_txt_files_no_firstline(FILE4, FILE3)