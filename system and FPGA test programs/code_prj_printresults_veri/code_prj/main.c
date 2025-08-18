#include <stdio.h> 
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include <my_func.h>

#include "common_func.h"

//BSP板级支持包所需全局变量
unsigned long UART_BASE = 0xbf000000;					//UART16550的虚地址
unsigned long CONFREG_TIMER_BASE = 0xbf20f100;			//CONFREG计数器的虚地址
unsigned long CONFREG_CLOCKS_PER_SEC = 50000000L;		//CONFREG时钟频率
unsigned long CORE_CLOCKS_PER_SEC = 33000000L;			//处理器核时钟频率

int  simu_flag;

void Timer_IntrHandler(void);
void Button_IntrHandler(unsigned char button_state);
//void SM3_SM4_IntrHandler(void);

void SM3_IntrHandler(void);
void SM4_IntrHandler(void);




int main(int argc, char** argv)
{	

	//ip_apbwrite(268,3);
	//ip_apbread(280);
	
	simu_flag = RegRead(0xbf20f500);

	//RegWrite(0xbf20f004,0x0f);//edge
	//RegWrite(0xbf20f008,0x1f);//pol
	//RegWrite(0xbf20f00c,0x1f);//clr
	//RegWrite(0xbf20f000,0x1f);//en

	//new add ip    bit 7 is sm3 ,bit 6 is sm4
	RegWrite(0xbf20f004,0x6f);//edge  110_1111
	RegWrite(0xbf20f008,0x7f);//pol   111_1111
	RegWrite(0xbf20f00c,0x7f);//clr
	RegWrite(0xbf20f000,0x7f);//en	

	if(simu_flag){
		RegWrite(0xbf20f104,50000);//timercmp 1ms
	}
	else{
		RegWrite(0xbf20f104,50000000);//timercmp 1s
	}
	RegWrite(0xbf20f108,0x1);//timeren

	//ip_apbwrite(268,3);
	//ip_apbread(280);	

	
    uint32_t input_data[] = {

		0,1,2,3,4,5,6,7,8,9,0xa,0xb,0xc,0xd,0xe,0xf
        //0xffffffff, 0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff,
		//0, 0, 0, 0, 0, 0, 0, 0 
    };
	uint32_t hex_array3[48] = {
	    0x00000000,  // 第1组：前8位 "00000000"
	    0x00000001,  // 第2组：接下来8位 "00000001"
	    0x00000002,  // 第3组："00000002"
	    0x00000003,  // 第4组："00000003"
	    0x00000004,  // 第5组："00000004"
	    0x00000005,  // 第6组："00000005"
	    0x00000006,  // 第7组："00000006"
	    0x00000007,  // 第8组："00000007"
	    0x00000008,  // 第9组："00000008"
	    0x00000009,  // 第10组："00000009"
	    0x0000000a,  // 第11组："0000000a"
	    0x0000000b,  // 第12组："0000000b"
	    0x0000000c,  // 第13组："0000000c"
	    0x0000000d,  // 第14组："0000000d"
	    0x0000000e,  // 第15组："0000000e"
	    0x0000000f,   // 第16组：最后8位 "0000000f"
		0x00000000,
		0x00000001,
		0x00000002,
		0x00000003,
		0x00000004,
		0x00000005,
		0x00000006,
		0x00000007,
		0x00000008,
		0x00000009,
		0x0000000a,
		0x0000000b,
		0x0000000c,
		0x0000000d,
		0x0000000e,
		0x0000000f,
		0x00000000,
		0x00000001,
		0x00000002,
		0x00000003,
		0x00000004,
		0x00000005,
		0x00000006,
		0x00000007,
		0x00000008,
		0x00000009,
		0x0000000a,
		0x0000000b,
		0x0000000c,
		0x0000000d,
		0x0000000e,
		0x0000000f  		
	};
	uint32_t hex_array2[31] = {
	    0x00000000,  // 第1组：前8位 "00000000"
	    0x00000001,  // 第2组：接下来8位 "00000001"
	    0x00000002,  // 第3组："00000002"
	    0x00000003,  // 第4组："00000003"
	    0x00000004,  // 第5组："00000004"
	    0x00000005,  // 第6组："00000005"
	    0x00000006,  // 第7组："00000006"
	    0x00000007,  // 第8组："00000007"
	    0x00000008,  // 第9组："00000008"
	    0x00000009,  // 第10组："00000009"
	    0x0000000a,  // 第11组："0000000a"
	    0x0000000b,  // 第12组："0000000b"
	    0x0000000c,  // 第13组："0000000c"
	    0x0000000d,  // 第14组："0000000d"
	    0x0000000e,  // 第15组："0000000e"
	    0x0000000f,   // 第16组：最后8位 "0000000f"
		0x00000000,
		0x00000001,
		0x00000002,
		0x00000003,
		0x00000004,
		0x00000005,
		0x00000006,
		0x00000007,
		0x00000008,
		0x00000009,
		0x0000000a,
		0x0000000b,
		0x0000000c,
		0x0000000d,
		0x0000000e
		
	};	
	uint32_t hex_array[32] = {
	    0x00000000,  // 第1组：前8位 "00000000"
	    0x00000001,  // 第2组：接下来8位 "00000001"
	    0x00000002,  // 第3组："00000002"
	    0x00000003,  // 第4组："00000003"
	    0x00000004,  // 第5组："00000004"
	    0x00000005,  // 第6组："00000005"
	    0x00000006,  // 第7组："00000006"
	    0x00000007,  // 第8组："00000007"
	    0x00000008,  // 第9组："00000008"
	    0x00000009,  // 第10组："00000009"
	    0x0000000a,  // 第11组："0000000a"
	    0x0000000b,  // 第12组："0000000b"
	    0x0000000c,  // 第13组："0000000c"
	    0x0000000d,  // 第14组："0000000d"
	    0x0000000e,  // 第15组："0000000e"
	    0x0000000f,   // 第16组：最后8位 "0000000f"
		0x00000000,
		0x00000001,
		0x00000002,
		0x00000003,
		0x00000004,
		0x00000005,
		0x00000006,
		0x00000007,
		0x00000008,
		0x00000009,
		0x0000000a,
		0x0000000b,
		0x0000000c,
		0x0000000d,
		0x0000000e,
		0x0000000f 		
	};
	//apb work test: reg h10


//sm3_finished
	printf("\nsm3 test begin!\n");
	printf("\nbe hashed data:000000000000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f\n");
	hashcompu(hex_array,16,0);
	printf("\ntest_1 finished!\n");
	printf("\ntest_2 begin!\n");
	printf("\nbe hashed data:000000000000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000000000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e\n");
	long_hash(hex_array2,31);	

	printf("\ntest_2 finish!\n");
	printf("\ntest_3 begin!\n");
	printf("\nbe hashed data:000000000000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000000000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000000000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f\n");
	long_hash(hex_array3,48);	
	printf("\ntest_sm3 finish!\n");
	

	//hashcompu (input_data,16,0);

	uint32_t key0[4]={0x10101010,0x0,0x0,0x0}; //low bits first
	uint32_t readyflag;
	uint32_t text0[4]={0x10101010,0x0,0x10101010,0x0};
	uint32_t text1[4]={0x10101010,0x0,0x0,0x10101010};
	uint32_t text2[4]={0x0,0x0,0x10101010,0x10101010};
	uint32_t text3[4]={0xf,0xe,0xe,0xe};
	
	

  
	


	printf("\nbegin_gen_key\n");	
	genkey(7);
    for(int i=0; i<2;i++){
        printf("\nwait_ready_flag!\n");
        while (readyflag != 1) {

        readyflag = ready_read();      
        }        
        printf("\nready!!!\n");
    }      
	printf("\nfinish_gen_key\n");	

	direct_init(key0);

	readyflag = ready_read();
    for(int i=0; i<2;i++){
        printf("\nwait_ready_flag!\n");
        while (readyflag != 1) {
        readyflag = ready_read();      
        }        
        printf("\nready!!!\n");
    }   
	printf("\nfinish_direct_init\n");

	printf("\nbegin_use_key_in_rom\n");		
 	use_key_in_rom(7);
    for(int i=0; i<2;i++){
        printf("\nwait_ready_flag!\n");
        while (readyflag != 1) {

        readyflag = ready_read();      
        }        
        printf("\nready!!!\n");
    }      
	printf("\nfinish_use_key_in_rom\n");		

	printf("\nbegin_text_encrypt\n");
	printf("\nbe encrypted data: 10101010000000001010101000000000\n");		
	text_encrypt(text0);
	printf("\nbe encrypted data: 10101010000000000000000010101010\n");
	text_encrypt(text1);
	printf("\nbe encrypted data: 00000000000000001010101010101010\n");
	text_encrypt(text2);
	printf("\nbe encrypted data: 0000000f0000000e0000000e0000000e\n");
	text_encrypt(text3);
	printf("\nbegin decrypted data,result should be:  0000000f0000000e0000000e0000000e!");
	chiptext_de(sm4_result);
	printf("\nsm4 test finished!\n");



	while(1)
	{
		
	}

	return 0;
}


void HWI0_IntrHandler(void)
{	
	unsigned int int_state;
	int_state = RegRead(0xbf20f014);

	if((int_state & 0x10) == 0x10){
		Timer_IntrHandler();
	}    
	else if((int_state & 0x40)== 0x40){
        SM3_IntrHandler();
    }	
    else if((int_state & 0x20)== 0x20){
        SM4_IntrHandler();
    }	
	else if(int_state & 0xf){
		Button_IntrHandler(int_state & 0xf);
	}

}


void SM3_IntrHandler(void){
	
	hash_out_read( sm3_result);
	sm3_flag=1; 
	printf("\n\n sm3 result:");
	for (int i = 0; i < 8; i++) {
	    printf("%08X ", sm3_result[i]);
	}	
	printf("\n");
	RegWrite(0xbf20f00c,0x40);


}

void SM4_IntrHandler(void){

	
	sm4_result_read( sm4_result);
	sm4_flag=1; 
	printf("\n\n sm4 result:");
	for (int i = 0; i < 4; i++) {
	    printf("%08X ", sm4_result[i]);
	}	
	printf("\n");
	RegWrite(0xbf20f00c,0x20);

}

void Timer_IntrHandler(void)
{
	RegWrite(0xbf20f108,0);//timeren
	RegWrite(0xbf20f108,1);//timeren
	printf("timer int\n");
}

void Button_IntrHandler(unsigned char button_state)
{
	if((button_state & 0b1000) == 0b1000){
		printf("button4 int\n");
		RegWrite(0xbf20f00c,0x8);//clr
	}
	else if((button_state & 0b0100) == 0b0100){
		printf("button3 int\n");
		RegWrite(0xbf20f00c,0x4);//clr
	}
	else if((button_state & 0b0010) == 0b0010){
		printf("button2 int\n");
		RegWrite(0xbf20f00c,0x2);//clr
	}
	else if((button_state & 0b0001) == 0b0001){
		printf("button1 int\n");
		RegWrite(0xbf20f00c,0x1);//clr
	}
}