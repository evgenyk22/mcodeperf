/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Srh.asm
*
*  Usage:         TOPsearch main file
*
*******************************************************************************/

EZTop Search;

#define __SIM__
//#define SRC_DEBUG_NOPS

#include "xad.Srh.macros.asm"


/******************************************************************************
   Resource Init Instruction
*******************************************************************************/

// Mask registers
LDREG   MREG[0],           0x00000201;
#define MASK_POLICY_TABLE  MREG[0];

LDREG   MREG[1],           0x000FFFFF;
#define MASK_000FFFFF      MREG[1];

LDREG   MREG[2],           0x00000FFF;
#define MASK_00000FFF      MREG[2];

LDREG   MREG[3],           0x00000001;
#define MASK_00000001      MREG[3];

/*******************************************************************************/
               
#define SYN_PROT_SRST_OFF   7;
#define SYN_PROT_SRST      (1<<SYN_PROT_SRST_OFF);
#define SYN_PROT_SRST_TYPE (SYN_PROT_SRST|3);

#define TREG_TCAM_RESULT_UNF_OFF       80  // Size 4 bytes 

//ALIST_END_P1:
//Write OREG, ALIST_SRC_STR , TREG.BYTE[0], 2, NULL, 0, _WR_LAST;
//Halt;

//-------------------------- TOPsearch II lookups ---------------------------------
public SRC2_FFT_VID_START_LAB:


nop;
nop;
nop;

	lookup 	CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , NO_WR_LAST;
   
   halt;


#define FFT_VID_STR_IN_TREG         2;
#define FFT_VID_STR_SIZE            32;
#define MDF_VLAN_TX_OFF             2;  // 2 byte Self port TX VLAN; Used for SYN challenge packets
#define MDF_VLAN_TP_AND_BYPASS_OFF  4;  // 2 byte Packet trace vlan
#define MDF_VIF_TX_VLAN_OFF         6;  // 2 byte FFT/SFT TX VLAN
#define MDF_VLAN_TP_ONLY_OFF        MDF_VLAN_TP_AND_BYPASS_OFF;  // 2 byte VLAN for TP only
#define MDF_FFT_TX_COPY_INFO_OFF    11; // 4 bytes TX copy information

public SRH2_FFT_FRMHOSTTX_LAB:
/*
   Nop;
   Nop;
   Nop;
   Nop;
 */

   Lookup   TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[0], 
            2, 
            NO_WR_LAST;


   Write    TREG[FFT_VID_STR_IN_TREG+MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE+1],
            4; 

   MovBits  TREG[FFT_VID_STR_IN_TREG],
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE],
            8; 


   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;

   Halt;

// Syn protection label
public SRH2_FFT_ALST_LAB:

/*
   Nop;
   Nop;
   Nop;
*/
	Lookup   TREG[FFT_VID_STR_IN_TREG], FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , TREG[0], 0 ,NO_WR_LAST;

   JNoMatch SRH2_FFT_ROUTE_NO_MATCH;

   Lookup   TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[FFT_VID_STR_IN_TREG+MDF_VIF_TX_VLAN_OFF], 
            2, 
            NO_WR_LAST;

   Write    TREG[FFT_VID_STR_IN_TREG+MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE+1],
            4; 

   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;
   Halt;

// Syn protection label
public SRH2_FFT_SYN_LAB:
/*

   Nop;
   Nop;
   Nop;
*/
	Lookup   TREG[FFT_VID_STR_IN_TREG], FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , TREG[0], 0 ,NO_WR_LAST;

   JNoMatch SRH2_FFT_ROUTE_NO_MATCH;

   Lookup   TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[FFT_VID_STR_IN_TREG+MDF_VLAN_TX_OFF], 
            2, 
            NO_WR_LAST;

   Write    TREG[FFT_VID_STR_IN_TREG+MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE+1],
            4; 

   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;
   Halt;

// trace point label   
public SRH2_FFT_TP_LAB:
	Lookup   TREG[FFT_VID_STR_IN_TREG], FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , TREG[0], 0 ,NO_WR_LAST;

   JNoMatch SRH2_FFT_ROUTE_NO_MATCH;

   Lookup   TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[FFT_VID_STR_IN_TREG+MDF_VLAN_TP_AND_BYPASS_OFF], 
            2, 
            NO_WR_LAST;

   Write    TREG[FFT_VID_STR_IN_TREG+MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE+1],
            4; 

   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;
   Halt;

// TX VLAN label
#define FFT_OFF_TREG 5

public SRH2_FFT_2CPU_CONT_TX_LAB:

#ifdef SRC_DEBUG_NOPS
   Nop;
   Nop;
   Nop;
   Nop;
#endif

       
	Lookup   TREG[FFT_OFF_TREG], FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , TREG[0], 0 ,NO_WR_LAST;


   JNoMatch SRH2_FFT_ROUTE_NO_MATCH;

   
   Lookup   TREG[FFT_OFF_TREG + FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[FFT_OFF_TREG + MDF_VIF_TX_VLAN_OFF], 
            2, 
            NO_WR_LAST;


   Write    TREG[FFT_OFF_TREG  + MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[ FFT_OFF_TREG + FFT_VID_STR_SIZE + 1 ],
            4; 
   
   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_OFF_TREG], (32-FFT_OFF_TREG), TREG[32], FFT_OFF_TREG;

   Halt;

// TX VLAN label
public SRH2_FFT_TX_LAB:

/*
   Nop;
   Nop;
   Nop;
   Nop;
*/
	Lookup   TREG[FFT_VID_STR_IN_TREG], FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , TREG[0], 0 ,NO_WR_LAST;

   JNoMatch SRH2_FFT_ROUTE_NO_MATCH;

   Lookup   TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[FFT_VID_STR_IN_TREG+MDF_VIF_TX_VLAN_OFF], 
            2, 
            NO_WR_LAST;

   Write    TREG[FFT_VID_STR_IN_TREG+MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE+1],
            4; 

   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;
   Halt;


// TX VLAN label
public SRH2_FROM_HOST_TX_LAB:

/*
   Nop;
   Nop;
   Nop;
   Nop;
*/
	Lookup   TREG[FFT_VID_STR_IN_TREG], FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , TREG[0], 0 ,NO_WR_LAST;

   JNoMatch SRH2_FFT_ROUTE_NO_MATCH;

   Lookup   TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[FFT_VID_STR_IN_TREG+MDF_VIF_TX_VLAN_OFF], 
            2, 
            NO_WR_LAST;


   Write    TREG[FFT_VID_STR_IN_TREG+MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE+1],
            4; 

   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;
   Halt;

// TP only VLAN label
public SRH2_FFT_TP_ONLY_VLAN_LAB:
	Lookup   TREG[FFT_VID_STR_IN_TREG], FFT_VID_STR, TREG[0], FFT_VID_KEY_SIZE , TREG[0], 0 ,NO_WR_LAST;

   JNoMatch SRH2_FFT_ROUTE_NO_MATCH;

   Lookup   TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE], 
            TX_COPY_PORT_STR, 
            TREG[FFT_VID_STR_IN_TREG+MDF_VLAN_TP_ONLY_OFF], 
            2, 
            NO_WR_LAST;

   Write    TREG[FFT_VID_STR_IN_TREG+MDF_FFT_TX_COPY_INFO_OFF],
            TX_COPY_PORT_STR,
            TREG[FFT_VID_STR_IN_TREG+FFT_VID_STR_SIZE+1],
            4; 

   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;
   Halt;


SRH2_FFT_ROUTE_NO_MATCH:

   // If there is no match - set valid + no match bit
   MovImm TREG[FFT_VID_STR_IN_TREG], 0x1, 4; 

   Write CTX CTX_LINE_OUT_IF, FFT_VID_STR, TREG[FFT_VID_STR_IN_TREG], (32-FFT_VID_STR_IN_TREG), TREG[32], FFT_VID_STR_IN_TREG;
   Halt;


public SRH2_RX_COPY_INFO_LAB:

   lookup 	CTX CTX_LINE_RX_COPY_INFO, RX_COPY_PORT_STR, TREG[0], RX_COPY_PORT_KEY_SIZE, TREG[0], 0, NO_WR_LAST;
   halt;



// ##TODO_OPTIMIZE: Check if in routing mode the lookup in OUT_VID_STR can be canceled (as it will not be used). if so cancel it from the place the lookup is called.


/* TOPsearch 2 RoutingTable lookup using the index (rank) returned from the TCAM lookup in TOPsearch 1. */
public SRC2_ROUTING_TABLE_START_LAB:
	lookup 	CTX CTX_LINE_ROUTING_TABLE_RSLT, ROUTING_TABLE_STR, TREG[0], 2, NO_WR_LAST;
   halt;

//--------------------------------------------------------------------------------




//-------------------------- TOPsearch I lookups ---------------------------------

//TopParse LookAside for IPv4DIP match in internal hash table of TOpparse.
public SRH_PRS_LA_IPV4_DIP_LOOKASIDE_LAB:
   LookUp CTX CTX_LINE_EZCH_SYSTEMS_IPV4DIP_LA, GRE_MY_IPS_TABLE_STR, TREG[0], 4 , WR_LAST;
   Halt;


/* Issue the DIP lookup in the external TCAM in the routingTableIndex table. */

#define TREG_ROUTING_PHASE_OFF      (CMP_ROUTING_DIP_OFF + CMP_ROUTING_KMEM_SIZE);  // 0 + 16   // routing table phase - used to distingiush between the active and inactive entries.

public ROUTING_START_P0:
   MovImm TREG[TREG_ROUTING_PHASE_OFF], 0x00000000, 4;
   jmp L_ROUTING_COMMON;


public ROUTING_START_P1:
   MovImm TREG[TREG_ROUTING_PHASE_OFF], 0x00000001, 4;

L_ROUTING_COMMON:
   LookupTCAM OREG, ROUTING_TABLE_INDEX_STR,
              TREG[CMP_ROUTING_DIP_OFF   ], CMP_ROUTING_KMEM_SIZE,
              TREG[TREG_ROUTING_PHASE_OFF], 4,
              PROFILE 2,
              WR_LAST;
   
   jcond; // Performing jcond as a nop replacement, because the halt command not allowed after LookupTCAM when the destination is not context..
   halt;




//////////////////////////////////////////////
//      SYN Protection Handling
//////////////////////////////////////////////

#define TREG_TCAM_RESULT_OFF           96 /*{68+4}*/  // Size 4 bytes
#define    TREG_TCAM_IDX_OFF           (TREG_TCAM_RESULT_OFF + 1) // Size 3 bytes
#define    TREG_TCAM_IDX_UNF_OFF       (TREG_TCAM_RESULT_UNF_OFF + 1) // Size 3 bytes

Public MAIN_START:

MAIN:
// Put byte 2 of SYN_PROT_DEST_STR result in CondReg
//WriteCond COND_REG, TREG[UNF_TASK_CNTR]; 

Jmul  TREG[UNF_TASK_CNTR],
      EMPTY,
      EMPTY, 
      EMPTY,
      ACCESS_LIST,
      POLICY , 
      SYN,
      BDOS,  
      RESET,NO_DEFAULT_JUMP;
 
//no more jobs , terminate
//Write TREG[0] , TREG[0] , 0 , WR_LAST;


Write  TREG[0], SYN_PROT_DEST_STR, 
      TREG[0], SYN_PROT_DEST_RES_SIZE,  
      WR_LAST; 


Halt;

ACCESS_LIST:

LookupTCAM 	   TREG[TREG_TCAM_RESULT_UNF_OFF] , EXT_TCAM_STR,
      			TREG[0], 21,      // DPORT(2), VLAN(2), DIP(16), Phys PORT(1)
               TREG[32], 19,     // SIP(16),  SPORT(2), L4_TYPE(1)
      			PROFILE EXT_TCAM_LINE_NUM_ALST, NO_WR_LAST; 

WriteCond COND_REG , TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4] , SET_MATCH_BIT;  

Jcond;
JMatch L_ALST_MATCH_IN_TCAM_CONT;

   movImm  TREG[TREG_TCAM_RESULT_UNF_OFF], 0x1 , 4; 
   write OREG, ALST_RES_STR, TREG[TREG_TCAM_RESULT_UNF_OFF], ALST_RES_SIZE ,  NO_WR_LAST;
   Jcond;
   jmp MAIN;
    
L_ALST_MATCH_IN_TCAM_CONT:

//access list glob threfore no need 2 cont after hit
Lookup 	OREG, ALST_RES_STR,
				TREG[TREG_TCAM_IDX_UNF_OFF], ALST_KEY_SIZE,
            WR_LAST;
   
halt;

//WriteCond COND_REG, TREG[UNF_PROT_POLICY_PHASE_OFF].bit[4], SET_MATCH_BIT;   
//JCond;                    
//JMatch Policy_Phase1_NON_SYN;

POLICY:
WriteCond COND_REG, TREG[UNF_PROT_POLICY_PHASE_OFF].bit[4], SET_MATCH_BIT;   
JCond;                    
JNoMatch POLICYP0;
WriteIndreg POLICY_RES_CONF_STR_P1 ;

LookupTCAM TREG[TREG_TCAM_RESULT_UNF_OFF], EXT_TCAM_STR, 
              TREG[UNF_PROT_VLAN_OFF     ],  19, // unified [ key vlan { 2 byte } + DIP {16 byte} + phys port { 1 byte } 
              TREG[UNF_PROT_SIP_OFF   ], /*16*/21, // unified [ SIP { 16 byte} ]  
              PROFILE EXT_TCAM_LINE_NUM_POLICY_PHASE0 /*EXT_TCAM_LINE_NUM_POLICY_PHASE1*/, NO_WR_LAST;

jmp  POLICYTCAM_END;
POLICYP0:
 
WriteIndreg POLICY_RES_CONF_STR_P1 ;
LookupTCAM TREG[TREG_TCAM_RESULT_UNF_OFF], EXT_TCAM_STR, 
              TREG[UNF_PROT_VLAN_OFF     ],  19, // unified [ key vlan { 2 byte } + DIP {16 byte} + phys port { 1 byte } 
              TREG[UNF_PROT_SIP_OFF   ], /*16*/21, // unified [ SIP { 16 byte} ]  
              PROFILE EXT_TCAM_LINE_NUM_POLICY_PHASE1, NO_WR_LAST;

POLICYTCAM_END:

WriteCond COND_REG, TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4], SET_MATCH_BIT;   
JCond;                    
JNoMatch POLICY_NO_MATCH;

nop;
Lookup TREG[ TREG_TCAM_RESULT_OFF  ], POLICY_RES_STR,
		 TREG[ TREG_TCAM_IDX_UNF_OFF ], POLICY_RES_KEY_SIZE,
       TREG[ TREG_TCAM_IDX_UNF_OFF ], 0,
       NO_WR_LAST;  



     //policy configuration result start from 64
Lookup TREG[ TREG_TCAM_RESULT_OFF ], IND_REG,
		  TREG[ { TREG_TCAM_RESULT_OFF + 3 } ], 2 ,TREG[TREG_TCAM_IDX_OFF], 0,RES_SIZE 32 ,
        NO_WR_LAST; 

Write OREG , POLICY_RES_CONF_STR , TREG[TREG_TCAM_RESULT_OFF] , 32  ,  NO_WR_LAST;

jcond;
jmp  MAIN;

POLICY_NO_MATCH:

   // If there is no match Policy for full key - set valid + no match bit
   MovImm TREG[TREG_TCAM_RESULT_OFF], 0x1, 4; 

   // Write no match result
   Write OREG, POLICY_RES_STR, 
         TREG[TREG_TCAM_RESULT_OFF], POLICY_RES_RES_SIZE,
         WR_LAST; 

   // no need 2 continue
   Halt;


#define POLICY_ID_OFFSET  3
#define POLICY_ID_SIZE    2
#define TREG_SYN_PROT_OFF        64;
#define TREG_CONTENDER_OFF      (TREG_SYN_PROT_OFF + SYN_PROT_DEST_RES_SIZE);  // 64 + 16
#define TREG_AUTH_OFF           (TREG_SYN_PROT_OFF + SYN_PROT_DEST_RES_SIZE);  // 64 + 16 

SYN:

// Lookup in Int.TCAM to find a key for SYN Protection table
Nop;
Nop;
Write  TREG[{ UNF_PROT_PHASE_OFF + 1}] ,POLICY_RES_STR ,  TREG[{ TREG_TCAM_RESULT_OFF + 2 }] , POLICY_ID_SIZE;

LookupTCAM TREG[TREG_SYN_PROT_OFF], INT_TCAM_STR,
           TREG[UNF_PROT_DPORT_OFF], 26,		// SYN_PROT_DPORT_OFF (2bytes) + SYN_PROT_VLAN_OFF (2bytes) + SYN_PROT_DIP_OFF (16bytes) + SYN_PROT_PORT_OFF (1byte)
           PROFILE INT_TCAM_LINE_NUM_SYN_PROT, NO_WR_LAST , NO_KEEP_PREV_CTRL_BITS;


//WriteCond COND_REG, TREG[TREG_SYN_PROT_OFF].bit[4], SET_MATCH_BIT;
//JCond;

JNoMatch SYN_PROT_CONT;

// Lookup in SYN Protection table
Lookup TREG[TREG_SYN_PROT_OFF      ], SYN_PROT_DEST_STR, 
       TREG[{TREG_SYN_PROT_OFF + 1}], SYN_PROT_DEST_KEY_SIZE, 
       TREG[0],  0, 
       WR_LAST_IF_NO_JUMP;

JMatch SYN_PROT_CONT;

// Write result of lookup in SYN_PROT_DEST_STR (this will also include results from Authentication & Contender tables)
Write OREG, SYN_PROT_DEST_STR, 
      TREG[TREG_SYN_PROT_OFF], SYN_PROT_DEST_RES_SIZE, 
      NO_WR_LAST; 
Jcond;
jmp MAIN;


SYN_PROT_CONT:

// Put byte 2 of SYN_PROT_DEST_STR result in CondReg
WriteCond COND_REG, TREG[{TREG_SYN_PROT_OFF + SYN_PROT_CTRL_2_OFF}]; 

JMul  CONT_AND_AUTH_TBL_LKP_LAB, 
      AUTH_TBL_LKP_LAB, 
      SYN_PROT_END_LAB,
      SYN_PROT_END_LAB,  
      SYN_PROT_END_LAB,
      SYN_PROT_END_LAB, 
      SYN_PROT_END_LAB;

// Write result of lookup in SYN_PROT_DEST_STR (this will also include results from Authentication & Contender tables)
Write OREG, SYN_PROT_DEST_STR, 
      TREG[TREG_SYN_PROT_OFF], SYN_PROT_DEST_RES_SIZE,  
      NO_WR_LAST; 
jcond;
jmp MAIN;


CONT_AND_AUTH_TBL_LKP_LAB:
Modulo TREG[22], TREG[UNF_PROT_SPORT_OFF_KMEM+1], 3, 1;  // TREG[22] = (Tcp Src Port 8 lsb) % 3 = 0/1/2
SHL    TREG[22], TREG[22], 2, 1;                         // TREG[22] = 0/4/8
OR     TREG[22], TREG[22], 2, 1;                         // TREG[22] = 2/4/8
WriteCond COND_REG, TREG[22]; 
SHL    TREG[22], TREG[UNF_PROT_CONT_COOKIE_OFF_KMEM], 0, 2, MASK_00000FFF, MASK_SRC1; // TREG[22] <- Tcp SeqNum 12lsb

JMul  F1_COOKIE_NO_SHL, 
      F1_COOKIE_NO_SHL, 
      F1_COOKIE_NO_SHL,
      F1_COOKIE_NO_SHL,  
      F1_COOKIE_SHL8,
      F1_COOKIE_SHL4, 
      F1_COOKIE_NO_SHL;

F1_COOKIE_SHL8:
   SHL    TREG[22], TREG[22], 4, 2;

F1_COOKIE_SHL4:
   SHL    TREG[22], TREG[22], 4, 2;

F1_COOKIE_NO_SHL:
SHR   TREG[26], TREG[UNF_PROT_CONT_COOKIE_OFF_KMEM], 4, 4; // actuall for TREG[27] = (Tcp SeqNum)>>12
Add   TREG[UNF_PROT_CONT_COOKIE_OFF_KMEM],   TREG[27], TREG[22], 4, MASK_000FFFFF, MASK_BOTH;  // F1 for lookup: SYN after RST
Add   TREG[{TREG_SYN_PROT_OFF + SYN_PROT_RES_F1_OFF}], TREG[27], TREG[22], 4, MASK_000FFFFF, MASK_BOTH;  // F1 for ACK gen: first SYN


// Perform lookup in Contender table
Lookup TREG[TREG_CONTENDER_OFF], SYN_PROT_CONT_STR, 
       TREG[UNF_PROT_SIP_OFF], 18,              // SIP(16), SPORT(2)
       TREG[UNF_PROT_CONT_COOKIE_OFF_KMEM], 3,  // Safe Reset cookie(3)
       NO_WR_LAST;

JNoMatch AUTH_TBL_LKP_LAB;

// Combine SYN_PROT_DEST_STR control bits and SYN_PROT_CONT_STR control bits 
OR TREG[{TREG_SYN_PROT_OFF + SYN_PROT_CTRL_2_OFF}], TREG[{TREG_SYN_PROT_OFF + SYN_PROT_CTRL_2_OFF}], TREG[{TREG_CONTENDER_OFF + SYN_PROT_CONT_CTRL_2_OFF}], 1;

// Copy Timestamp + TTL fields from Contender result over to SYN_PROT_DEST_STR result (TREG bytes[4..7], byte 7 is not used)
Write TREG[{TREG_SYN_PROT_OFF  + SYN_PROT_RES_TS_OFF} ], 4,
      TREG[{TREG_CONTENDER_OFF + SYN_PROT_CONT_TS_OFF}], 3, 
      NO_WR_LAST;


AUTH_TBL_LKP_LAB:

// If RST bit is not enabled perform lookup in Authentication table 
Lookup TREG[TREG_AUTH_OFF    ], SYN_PROT_AUT_STR, 
       TREG[UNF_PROT_SIP_OFF ], SYN_PROT_AUT_LKP_SIZE,	// Key is SIP (16bytes) 
       TREG[0], 0,
	    NO_WR_LAST;

JNoMatch SYN_PROT_END_LAB;

MovBits TREG[{TREG_SYN_PROT_OFF + SYN_PROT_CTRL_2_OFF}].bit[SYN_PROT_CTRL_AUTH_MATCH_BIT], TREG[{ TREG_AUTH_OFF + SYN_PROT_AUT_CTRL_2_OFF}].bit[SYN_PROT_CTRL_AUTH_MATCH_BIT] ,  1  ;

SYN_PROT_END_LAB:

// Write result of lookup in SYN_PROT_DEST_STR (this will also include results from Authentication & Contender tables)
Write OREG, SYN_PROT_DEST_STR, 
      TREG[TREG_SYN_PROT_OFF], SYN_PROT_DEST_RES_SIZE,  
      NO_WR_LAST; 
jcond;
jmp MAIN;


BDOS:





   
EMPTY:
jcond;
jmp MAIN;

#define CORE2IP_OFF_TREG  8

public CORE_DISTR_LAB:

#ifdef SRC_DEBUG_NOPS
   Nop;
#endif
   // Clear second byte of the hash
   MovImm TREG[1] , 0 , 1;
       
   PseudoModulo TREG[64], TREG[0], TREG[2], 2;   

   Lookup   TREG[CORE2IP_OFF_TREG], CORE2IP_STR, TREG[64], 1, NO_WR_LAST;
   //MovImm   TREG[CORE2IP_OFF_TREG] , 0x51 , 1;

   Write CTX CTX_LINE_CORE2IP_DISTRIBUTION, CORE2IP_STR, TREG[CORE2IP_OFF_TREG], (CORE2IP_RESULT_SIZE);

   Halt;       
 

