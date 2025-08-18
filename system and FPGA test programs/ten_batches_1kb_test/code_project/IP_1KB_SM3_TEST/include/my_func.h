#ifndef my_func
#define my_func
#include <stdint.h> 
#include <stddef.h>

#define UINT512_SIZE 64    // 512位 = 64字节
#define UINT32_COUNT 16    // 512位 / 32位 = 16份

// global var here
extern uint32_t  sm3_result[8];  // 256位存储空间 
extern uint32_t  sm4_result[4];  // 128位存储空间 
extern uint32_t  sm3_flag; 
extern uint32_t  sm4_flag;
extern uint32_t  fin_hash_mul_flag;

void ip_apbwrite( uint32_t addr,uint32_t data);
uint32_t ip_apbread(uint32_t addr);
void convert_to_512bit(const uint8_t *input, size_t input_len, uint8_t *output);
void split_512bit_to_32bit(const uint8_t *input_512bit, uint32_t *output_32bit);

void hashcompu (uint32_t* result, uint32_t byte_nums, uint32_t stat);
    
void hash_out_read(uint32_t hash_result[8]);
void sm4_result_read(uint32_t sm4_result[4]);

void long_hash (uint32_t data[],uint32_t byte_lens);

void genkey(uint32_t order);
void use_key_in_rom(uint32_t order);
void direct_init(uint32_t my_key[]);
void text_encrypt(uint32_t text[]);
void chiptext_de(uint32_t chip[]);

uint32_t ready_read();
//void console_putch(char ch);
//void rt_hw_console_output(const char *str);
#endif

