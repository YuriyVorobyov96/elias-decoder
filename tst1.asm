#include <def21060.h>
#define N 10
#define M 20
#define TCB_SIZE 8

.SECTION/PM iner_start;	
	nop;
	jump start;
	nop;
	nop;
	
.SECTION/PM inter_sport_res;
	JUMP workFunk(DB);
	BIT TGL MODE1 SRD1L;;
	nop;
	nop;

.SECTION/PM buffers;
.VAR inp1[N];
.VAR inp2[N];
.VAR out1[M];
.VAR out2[M];



.SECTION/DM tcb;
//
.VAR Otcb1[TCB_SIZE]=0,0,0,0,0,M,1,out1;
.VAR Otcb2[TCB_SIZE]=0,0,0,0,0,M,1,out2;
.VAR Itcb1[TCB_SIZE]=0,0,0,0,Itcb2+TCB_SIZE-1,N,1,inp1;
.VAR Itcb2[TCB_SIZE]=0,0,0,0,Itcb1+TCB_SIZE-1,N,1,inp2;


.SECTION/PM prog;


start:		
			R9 = 32;
			
			B0=out1;
			L0=M;
			M0=1;
			
			B1=inp1;
			L1=N;
			M1=1;
			
			I2=Otcb1+TCB_SIZE-1;
			M2=-2;
			
			BIT TGL MODE1 SRD1L;
			nop;
			//input
			
			B0=out2;
			L0=M;
			M0=1;
			
			B1=inp2;
			L1=N;
			M1=1;
			
			I2=Otcb2+TCB_SIZE-1;
			M2=-2;
			
			R0 = 300;
			R1 = 16;
			R0 = LSHIFT R0 BY R1;
			R0 = R0+R1;
			DM(RDIV0)=R0;
			//spen=1 dtype=01 slen=32-1 frameen=1 iframe=1 inerclk=1 dma=1 chain=1 | 11000110010111110001
			R0=0xC65F1;
			//R0=0x865F1;
			DM(SRCTL0)=R0;
			
			//set LINK ch 0 buf 2 dma + chaining
			R0=0x3FE3F; //111 111 111 000 111 111
			DM(LAR)=r0; 	
			R0=0xF00; //1111 0000 0000
			DM(LCTL)=r0; 
			
			//setup dma
			R0=	Itcb1+TCB_SIZE-1;
			DM(CP0)=R0;
			
			BIT SET MODE1 IRPTEN;
			//enable sport
			BIT SET IMASK SPR0I;
				
Wait:		IDLE;
			jump Wait;
			


writeBit1:	R7 = BSET R7 BY R8;
			R8=R8-1;
			IF NE RTS;
				R10=R10+1;		
				R8=32;
				RTS(DB);
				DM(I0,M0)=R7;
				R7=0;
			
writeBit0:	
			R8=R8-1;
			IF NE RTS;
				R10=R10+1;
				R8=32;
				RTS(DB);
				DM(I0,M0)=R7;
				R7=0;
				
				
workFunk:	R8=32;
			LCNTR=N, DO cycle UNTIL LCE;
				R0=DM(I1,M1);
				R0 = PASS R0;
				IF NE jump work;
					CALL writeBit0;
					jump cycle;
work:			F3 = FLOAT R0;
				R1= LOGB F3;
				LCNTR=R1, DO cycle2 UNTIL LCE;
					R8=R8-1;
					IF NE JUMP cycle2;
						R10=R10+1;
						R8=32;
						DM(I0,M0)=R7;
						R7=0;
cycle2:				nop;
				CALL writeBit0;
				CALL writeBit1;
				R2 = 1;
				R2 = LSHIFT R2 BY R1;
				R4 = R0-R2;
				R5=R1;
				R5=R5-1;
				LCNTR=R1, DO cycle3 UNTIL LCE;
					BTST R4 BY R5;
						IF NOT SZ R7 = BSET R7 BY R8;
					R8=R8-1;
					IF NE JUMP cycle3;
						R10=R10+1;
						R8=32;
						DM(I0,M0)=R7;
						R7=0;
cycle3:				R5=R5-1;
cycle:				nop;

			COMP(R8, R9);
				IF NE R10=R10+1, DM(I0,M0)=R7;
			R7=0;
			I0=B0;		
			R8=32;
			DM(M2,I2)=R10;
			RTI(DB);
			R10=0;
			DM(CP4)=I2;
			