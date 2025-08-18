
#include "uart_print.h"
#include <my_func.h>
#include "common_func.h"
#include "confreg_time.h"
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdint.h>   
#include <assert.h>   


volatile uint32_t* sm34ip = (volatile uint32_t*)0xbf010000;

uint32_t sm3_result[8];
uint32_t sm4_result[4];
uint32_t		 sm3_flag; 
uint32_t	 	 sm4_flag;
uint32_t         fin_hash_mul_flag;


void ip_apbwrite(uint32_t addr, uint32_t data) {

    sm34ip[addr] = data;  
}


uint32_t ip_apbread(uint32_t addr){
    int data;
    data = sm34ip[addr];
    return data;
}

uint32_t result[UINT32_COUNT] = {0};
//hash compute  SM3
//constant hash set stat :10,when last batch ,set stat 11 ,single batch set 00 ,two bits

void long_hash (uint32_t data[],uint32_t byte_lens) //max2^32-1 bytes
{

    fin_hash_mul_flag=0;
    uint32_t a = byte_lens / 16;
    uint32_t b = byte_lens % 16;


    if((a>0)&&(b>0)){
        printf("_"); 
        for(int i=0; i<a;i++){
               
            hashcompu(&data[i*16],16,2);
          printf("_");

            while (sm3_flag != 1) {
            }
          printf("_");
        }
        
        for(int h=0; h<(16-b);h++){
            ip_apbwrite(129+h,0);
        }
        uint32_t nums_0 = 129+(16-b);
        for(int x=0; x<b; x++){
            ip_apbwrite(nums_0+x,data[a*16+x]);
        }

        ip_apbwrite(0x91,b );
        ip_apbwrite(0x80,7   );  
        printf("_");
        for(int i=0; i<2;i++){
            printf("_");
            while (sm3_flag != 1) {
            }        
            printf("_");
        }        

    } 
    
    else if((a>1)&&(b==0)){
        printf("_");
        for(int i=0; i<a-1;i++){

            hashcompu(&data[i*16],16,2);
          printf("_");
            while (sm3_flag != 1) {
            }
          printf("_");
        }
        hashcompu(&data[(a-1)*16],16,3);
        printf("_");
        for(int i=0; i<2;i++){
            printf("_");
            while (sm3_flag != 1) {
            }        
            printf("_");
        }
    }
    fin_hash_mul_flag=1;
    ip_apbwrite(0x80,0);

}


void hashcompu (uint32_t result[UINT32_COUNT], uint32_t byte_nums, uint32_t stat){

    sm3_flag = 0;  
    uint32_t stat_in = (stat<<1)+1;
    ip_apbwrite(0x81,result[0]);            //  204
    ip_apbwrite(0x82,result[1]);            //  208
    ip_apbwrite(0x83,result[2]);            //  20C
    ip_apbwrite(0x84,result[3]);            //  210
    ip_apbwrite(0x85,result[4]);            //  214
    ip_apbwrite(0x86,result[5]);            //  218
    ip_apbwrite(0x87,result[6]);            //  21C
    ip_apbwrite(0x88,result[7]);            //  220
    ip_apbwrite(0x89,result[8]);            //  224
    ip_apbwrite(0x8A,result[9]);            //  228
    ip_apbwrite(0x8B,result[10]);           //  22C
    ip_apbwrite(0x8C,result[11]);           //  230
    ip_apbwrite(0x8D,result[12]);           //  234
    ip_apbwrite(0x8E,result[13]);           //  238
    ip_apbwrite(0x8F,result[14]);           //  23C
    ip_apbwrite(0x90,result[15]);           //  240
    ip_apbwrite(0x91,byte_nums );           //  244
    ip_apbwrite(0x80,stat_in   );           //  200
}




void hash_out_read(uint32_t hash_result[8]) {  
    hash_result[0] = ip_apbread(0X99);                 //248
    hash_result[1] = ip_apbread(0X98);                 //24C
    hash_result[2] = ip_apbread(0X97);                 //250
    hash_result[3] = ip_apbread(0X96);                 //254
    hash_result[4] = ip_apbread(0X95);                 //258
    hash_result[5] = ip_apbread(0X94);                 //25C
    hash_result[6] = ip_apbread(0X93);                 //260
    hash_result[7] = ip_apbread(0X92);                 //264
}



//---------------------------------SM4 PART

void sm4_result_read(uint32_t sm4f_result[4]){
sm4f_result[3] = ip_apbread( 0x49 );                   //118 
sm4f_result[2] = ip_apbread( 0x48 );                   //11C 
sm4f_result[1] = ip_apbread( 0x47 );                   //120 
sm4f_result[0] = ip_apbread( 0x46 );                   //124 

}

//key_initial_serial
void genkey(uint32_t order){
    ip_apbwrite( 83, 1);          //14c
    ip_apbwrite( 84, order);      //150
    ip_apbwrite( 82,1)   ;        //148
}

void use_key_in_rom(uint32_t order){
    ip_apbwrite( 83, 2);           //14c
    ip_apbwrite( 84, order);       //150
    ip_apbwrite( 82,1)   ;         //148
}

void direct_init(uint32_t my_key[]){
    ip_apbwrite( 83, 0);           //14c
    ip_apbwrite( 78, my_key[3]);   //138        
    ip_apbwrite( 79, my_key[2]);   //13c        
    ip_apbwrite( 80, my_key[1]);   //140   
    ip_apbwrite( 81, my_key[0]);   //144   
    ip_apbwrite( 82,1)   ;         //148
}


void text_encrypt(uint32_t text[]){
    sm4_flag=0;
    ip_apbwrite( 83, 8);            //14c
    ip_apbwrite( 65, text[3] ) ;     //104
    ip_apbwrite( 66, text[2] ) ;     //108
    ip_apbwrite( 67, text[1] ) ;     //10c
    ip_apbwrite( 68, text[0] ) ;     //110
    ip_apbwrite( 69     ,1 )   ;     //114
    for(int i=0; i<2;i++){
            printf("_");
            while (sm4_flag != 1) {
            }        
            printf("_");
    }    

}

void chiptext_de(uint32_t chip[]){
    sm4_flag=0;
    ip_apbwrite( 83 ,   4);           //14c
    ip_apbwrite( 65 , chip[3] ) ;     //104
    ip_apbwrite( 66 , chip[2] ) ;     //108
    ip_apbwrite( 67 , chip[1] ) ;     //10c
    ip_apbwrite( 68 , chip[0] ) ;     //110
    ip_apbwrite( 69   ,1 )      ;     //114    
    for(int i=0; i<2;i++){
            printf("_");
            while (sm4_flag != 1) {
            }        
            printf("_");
    }       
}

uint32_t ready_read(){
    uint32_t a;
    a=ip_apbread(4);
    return a;

    }

