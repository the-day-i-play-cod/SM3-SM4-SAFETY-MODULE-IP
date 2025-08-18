from gmssl import sm3
import os


def sm3_encrypt_hex_file(file_path):
    """
    读取文件中的16进制数据并进行SM3加密
    :param file_path: 16进制数据文件路径
    :return: SM3加密结果（64位16进制字符串）
    """
    # 读取文件内容（假设文件中仅包含16进制字符，无空格/换行）
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            hex_str = f.read().strip()  # 去除首尾空白字符
    except FileNotFoundError:
        raise FileNotFoundError(f"文件不存在：{file_path}")
    except Exception as e:
        raise RuntimeError(f"文件读取失败：{str(e)}")

    # 验证16进制字符串合法性
    if not all(c in '0123456789abcdefABCDEF' for c in hex_str):
        raise ValueError("文件内容包含非16进制字符")
    if len(hex_str) % 2 != 0:
        raise ValueError("16进制字符串长度必须为偶数")

    # 将16进制字符串转换为字节流
    try:
        data_bytes = bytes.fromhex(hex_str)
    except ValueError as e:
        raise ValueError(f"16进制转换失败：{str(e)}")

    # 计算SM3哈希值
    sm3_hash = sm3.sm3_hash(list(data_bytes))  # list()将字节流转为整数列表
    return sm3_hash


if __name__ == "__main__":
    # 文件路径（请确保文件在当前目录或填写绝对路径）
    file_path = "hex_data_py.txt"

    # 检查文件是否存在
    if not os.path.exists(file_path):
        print(f"错误：文件 '{file_path}' 不存在，请检查路径是否正确。")
    else:
        try:
            result = sm3_encrypt_hex_file(file_path)
            print(f"SM3加密结果（64位16进制）：\n{result}")
        except Exception as e:
            print(f"加密失败：{str(e)}")