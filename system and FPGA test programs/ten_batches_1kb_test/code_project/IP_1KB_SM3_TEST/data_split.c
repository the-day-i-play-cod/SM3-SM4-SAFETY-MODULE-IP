#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include <stdlib.h>
#include <stdarg.h>

#include <my_func.h>

#include "common_func.h"

//BSP板级支持包所需全局变量
//unsigned long UART_BASE = 0xbf000000;					//UART16550的虚地址
//unsigned long CONFREG_TIMER_BASE = 0xbf20f100;			//CONFREG计数器的虚地址
//unsigned long CONFREG_CLOCKS_PER_SEC = 50000000L;		//CONFREG时钟频率
//unsigned long CORE_CLOCKS_PER_SEC = 33000000L;			//处理器核时钟频率



/**
 * @brief 将任意长度的字节数组转换为512位大端格式（高位补零）
 * @param input 输入字节数组（大端模式，低位在后）
 * @param input_len 输入数据长度（字节），最大64字节
 * @param output 输出的512位大端缓冲区（需提前分配64字节）
 */
void convert_to_512bit(const uint8_t *input, size_t input_len, uint8_t *output) {
    // 初始化输出缓冲区为全0（高位自动补零）
    memset(output, 0, UINT512_SIZE);
    
    // 输入长度超过512位时截断（可选，根据需求调整）
    if (input_len > UINT512_SIZE) {
        input_len = UINT512_SIZE;
    }
    
    // 将输入数据复制到输出缓冲区的末尾（低位保留，高位补零）
    // 例如：输入32字节（256位），则从output[32]开始复制，前32字节保持0
    memcpy(output + (UINT512_SIZE - input_len), input, input_len);
}

/**
 * @brief 将512位大端字节数组分割为16个32位无符号整数
 * @param input_512bit 512位大端字节数组（64字节）
 * @param output_32bit 输出的32位整数数组（需提前分配16个元素）
 */
void split_512bit_to_32bit(const uint8_t *input_512bit, uint32_t *output_32bit) {
    for (int i = 0; i < UINT32_COUNT; i++) {
        // 每个32位块占4字节，大端模式（高位在前）
        uint32_t block = (input_512bit[i*4] << 24) | 
                        (input_512bit[i*4 + 1] << 16) | 
                        (input_512bit[i*4 + 2] << 8) | 
                        input_512bit[i*4 + 3];
        output_32bit[i] = block;
    }
}

/*
// 示例测试
int main() {
    // 测试输入：假设原始数据为128位（16字节），内容为0x112233445566778899AABBCCDDEEFF0011
    uint8_t input_data[] = {
        0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
        0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00
    };
    size_t input_len = sizeof(input_data);  // 16字节（128位）

    uint8_t uint512_buffer[UINT512_SIZE] = {0};  // 512位缓冲区
    uint32_t result[UINT32_COUNT] = {0};         // 存储16个32位结果

    // 步骤1：将输入转换为512位大端格式（高位补零）
    convert_to_512bit(input_data, input_len, uint512_buffer);

    // 步骤2：分割为16个32位整数
    split_512bit_to_32bit(uint512_buffer, result);

    // 打印结果（验证高位补零和分割逻辑）
    printf("data_split\n");
    for (int i = 0; i < UINT32_COUNT; i++) {
        printf("part%d: 0x%08X\n", i, result[i]);
    }

    return 0;
}
    */
/*
void genkey(uint32_t order){
    ip_apbwrite(83, 1);          //14c（0x14C=332 → 332/4=83）
    ip_apbwrite(84, order);      //150（0x150=336 → 336/4=84）
    ip_apbwrite(82,1)   ;        //148（0x148=328 → 328/4=82）
}

void use_key_in_rom(uint32_t order){
    ip_apbwrite(83, 2);           //14c（0x14C=332 → 332/4=83）
    ip_apbwrite(84, order);       //150（0x150=336 → 336/4=84）
    ip_apbwrite(82,1)   ;         //148（0x148=328 → 328/4=82）
}

void direct_init(uint32_t my_key[]){
    ip_apbwrite(83, 0);           //14c（0x14C=332 → 332/4=83）
    ip_apbwrite(78, my_key[0]);   //138（0x138=312 → 312/4=78）
    ip_apbwrite(79, my_key[1]);   //13c（0x13C=316 → 316/4=79）
    ip_apbwrite(80, my_key[2]);   //140（0x140=320 → 320/4=80）
    ip_apbwrite(81, my_key[3]);   //144（0x144=324 → 324/4=81）
    ip_apbwrite(82,1)   ;         //148（0x148=328 → 328/4=82）
}

void text_encrypt(uint32_t text[]){  // 原函数参数应为数组（text[3]）
    ip_apbwrite(83, 8);            //14c（0x14C=332 → 332/4=83）
    ip_apbwrite(65, text[0]);      //104（0x104=260 → 260/4=65）
    ip_apbwrite(66, text[1]);      //108（0x108=264 → 264/4=66）
    ip_apbwrite(67, text[2]);      //10c（0x10C=268 → 268/4=67）
    ip_apbwrite(68, text[3]);      //110（0x110=272 → 272/4=68）
    ip_apbwrite(69,1);             //114（0x114=276 → 276/4=69）
}

void chiptext_de(uint32_t chip[]){  // 原函数参数应为数组（chip[3]）
    ip_apbwrite(83, 4);            //14c（0x14C=332 → 332/4=83）
    ip_apbwrite(65, chip[0]);      //104（0x104=260 → 260/4=65）
    ip_apbwrite(66, chip[1]);      //108（0x108=264 → 264/4=66）
    ip_apbwrite(67, chip[2]);      //10c（0x10C=268 → 268/4=67）
    ip_apbwrite(68, chip[3]);      //110（0x110=272 → 272/4=68）
    ip_apbwrite(69,1);             //114（0x114=276 → 276/4=69）
}
    */