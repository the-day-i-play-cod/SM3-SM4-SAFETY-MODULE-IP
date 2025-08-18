
import os

from gmssl import sm4
import binascii


def sm4_ecb_encrypt_no_padding(hex_key: str, hex_plain: str) -> str:
    """
    SM4-ECB无填充加密（严格128位）

    参数：
    hex_key : 32位十六进制密钥（128位）
    hex_plain : 32位十六进制明文（128位）

    返回：
    32位十六进制密文（大写）
    """
    # 参数校验
    if len(hex_key) != 32 or not all(c in '0123456789abcdefABCDEF' for c in hex_key):
        raise ValueError("密钥格式错误")
    if len(hex_plain) != 32 or not all(c in '0123456789abcdefABCDEF' for c in hex_plain):
        raise ValueError("明文格式错误")

    # 转换数据

    key = bytes.fromhex(hex_key)
    plain = bytes.fromhex(hex_plain)
    # 执行加密
    cipher = sm4.CryptSM4()
    cipher.set_key(key, sm4.SM4_ENCRYPT)
    ciphertext = cipher.crypt_ecb(plain)

    return ciphertext.hex().upper()


def sm4_encrypt_hex_file(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = [line.strip() for line in f.readlines()]
    key = lines[0]
    print("key==")
    print(key)
    # 验证密钥
    #key = bytes.fromhex(lines[0])
    #if len(key) != 16:
    #    raise ValueError("密钥必须为32位十六进制字符(128位)")

    # 处理数据块
    ciphertext_list = []


    for line in lines[1:]:
        #if len(line) != 32 or not all(c in '0123456789abcdefABCDEF' for c in line):
        #    raise ValueError("明文必须为32位十六进制字符(128位)")
        print("\ntext==")
        print(line)
        ciphertext = sm4_ecb_encrypt_no_padding(key, line)
       #print("\n")
       #print(f"加密结果: {ciphertext[:32]}")
       #print("\n")
       #ciphertext = ciphertext[:16]
       #ciphertext_list.append()
       # plain_block = bytes.fromhex(line)
       # cipher_block = cipher.crypt_ecb(plain_block)  # ECB模式加密
        ciphertext_list.append(ciphertext[:32])

    # 写入加密文件
    with open(output_file, 'w') as f:
        #f.write(lines[0] + '\n')  # 密钥行
        for ct in ciphertext_list:
            f.write(ct + '\n')


def sm4_decrypt_hex_file(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = [line.strip() for line in f.readlines()]

    # 读取密钥
    key = bytes.fromhex(lines[0])

    # 处理密文块
    plaintext_list = []
    cipher = sm4.CryptSM4()
    cipher.set_key(key, sm4.SM4_DECRYPT)

    for line in lines[1:]:
        if len(line) != 32 or not all(c in '0123456789abcdefABCDEF' for c in line):
            raise ValueError("无效的密文格式")
        cipher_block = bytes.fromhex(line)
        plain_block = cipher.crypt_ecb(cipher_block)  # ECB模式解密
        plaintext_list.append(plain_block.hex().upper())

    # 写入解密文件
    with open(output_file, 'w') as f:
        f.write(lines[0] + '\n')  # 密钥行
        for pt in plaintext_list:
            f.write(pt + '\n')


# 示例调用
#sm4_encrypt_hex_file('TB_SM4/1/text_file.txt', 'SM4_DATA_PY/1/encrypted.txt')

for i in range(1, 21):  # 循环i从1到20（包含20）
    # 动态生成输入路径（将原路径中的1替换为当前循环的i）
    input_path = f'TB_SM4/{i}/text_file.txt'
    # 动态生成输出路径（将原路径中的1替换为当前循环的i）
    output_path = f'SM4_DATA_PY/{i}/encrypted.txt'
    # 执行加密函数（假设sm4_encrypt_hex_file已定义）
    sm4_encrypt_hex_file(input_path, output_path)
