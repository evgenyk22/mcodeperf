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
LdReg TRIG_ADDR[0], ALST_SRH_TCAM_LOOKASIDE_CALLBACK;

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


////////////////////////////////////////////////
//    Policy Handling
////////////////////////////////////////////////

public POLICY_START:

   // ##AMIT_GUY: for TCAM keys integration to combined concurrent lookups, change the code so that if routing mode then perform the TCAM RoutingTableIndexLookup from here using relevant profile, instead of calling TOPsearch CMP_ROUTING_TABLE_INDEX_TCAM_LAB. Guy will integrate the 3 lookups to one concurent lookup.
   // Common handling of policies, applies both to tagged and untagged frames
   Policy_Treat;



////////////////////////////////////////////////
//    OOS Handling
////////////////////////////////////////////////

public OOS_START:

#if 0
LookUp OREG , TCP_OOS_STR , TREG[0] , TCP_OOS_KEY_SIZE,  TREG[ 0 ], 0 , WR_LAST; 

//LookUp OREG , TCP_OOS_STR , TREG[0] , 4,  TREG[ 0 ], 0 , WR_LAST; 
//LookUp OREG , TCP_OOS_STR , TREG[1] , 1 ,  TREG[ 0 ], 0 , WR_LAST; 
//write OREG , TCP_OOS_STR , TREG[32] , 4 , WR_LAST; 
halt;
#endif


//////////////////////////////////////////////
//      SYN Protection Handling
//////////////////////////////////////////////

Public NON_SYN_PROT_DEST_START:

LookupTCAM 	   TREG[TREG_TCAM_RESULT_UNF_OFF] , EXT_TCAM_STR,
      			TREG[0], 21,      // DPORT(2), VLAN(2), DIP(16), Phys PORT(1)
               TREG[32], 19,     // SIP(16),  SPORT(2), L4_TYPE(1)
      			PROFILE EXT_TCAM_LINE_NUM_ALST, NO_WR_LAST; 

WriteCond COND_REG , TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4] , SET_MATCH_BIT;  

Jcond;
JMatch L_ALST_MATCH_IN_TCAM_CONT;

   movImm  TREG[TREG_TCAM_RESULT_UNF_OFF], 0x1 , 4; 
   write OREG, ALST_RES_STR, TREG[TREG_TCAM_RESULT_UNF_OFF], ALST_RES_SIZE ,  NO_WR_LAST;

WriteCond COND_REG, TREG[UNF_PROT_POLICY_PHASE_OFF].bit[4], SET_MATCH_BIT;   
JCond;                    
JMatch Policy_Phase1_NON_SYN;

Policy_Phase0_NON_SYN:
LookupTCAM TREG[TREG_TCAM_RESULT_UNF_OFF], EXT_TCAM_STR, 
              TREG[UNF_PROT_VLAN_OFF     ],  19, // unified [ key vlan { 2 byte } + DIP {16 byte} + phys port { 1 byte } 
              TREG[UNF_PROT_SIP_OFF   ], /*16*/21, // unified [ SIP { 16 byte} ]  
              PROFILE EXT_TCAM_LINE_NUM_POLICY_PHASE0, NO_WR_LAST;

WriteCond COND_REG, TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4], SET_MATCH_BIT;   
JCond;                    
JNoMatch L_POLICY_SIP_NO_MATCH_IN_TCAM;

Lookup OREG, POLICY_RES_STR,
		 TREG[TREG_TCAM_IDX_UNF_OFF], POLICY_RES_KEY_SIZE,
       TREG[TREG_TCAM_IDX_UNF_OFF], 0,
       WR_LAST;  

Halt;

Policy_Phase1_NON_SYN:

LookupTCAM TREG[TREG_TCAM_RESULT_UNF_OFF], EXT_TCAM_STR, 
              TREG[UNF_PROT_VLAN_OFF     ],  19, // unified [ key vlan { 2 byte } + DIP {16 byte} + phys port { 1 byte } 
              TREG[UNF_PROT_SIP_OFF   ], /*16*/21, // unified [ SIP { 16 byte} ]  
              PROFILE EXT_TCAM_LINE_NUM_POLICY_PHASE1, NO_WR_LAST;

//parallel THREAD_ID_MASK 1; // don't wait for INT_TCAM_STR result
WriteCond COND_REG, TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4], SET_MATCH_BIT;   
//parallel THREAD_ID_MASK 1; // don't wait for INT_TCAM_STR result
JCond;                    
JNoMatch L_POLICY_SIP_NO_MATCH_IN_TCAM;

Lookup OREG, POLICY_RES_STR,
		 TREG[TREG_TCAM_IDX_UNF_OFF], POLICY_RES_KEY_SIZE,
       TREG[TREG_TCAM_IDX_UNF_OFF], 0,
       WR_LAST;  

Halt;

//////////////////////////////////////////////
//      SYN Protection Handling
//////////////////////////////////////////////

Public SYN_PROT_DEST_START:

#define TREG_SYN_PROT_OFF        64;
#define TREG_CONTENDER_OFF      (TREG_SYN_PROT_OFF + SYN_PROT_DEST_RES_SIZE);  // 64 + 16
#define TREG_AUTH_OFF           (TREG_SYN_PROT_OFF + SYN_PROT_DEST_RES_SIZE);  // 64 + 16

#ifndef __SIM__

//LookupTCAM 	   TREG[TREG_TCAM_RESULT_OFF], EXT_TCAM_STR, TREG[0], 32, TREG[32], 8, PROFILE 0, NO_WR_LAST;
LookupTCAM 	   CTX CTX_LINE_DUMMY_FOR_TCAM , EXT_TCAM_STR,
      			TREG[0], 22,
               TREG[32], 18,
      			PROFILE 0, NO_WR_LAST, TRIG_ADDR[0]; 

#else

// AccessList
LookupTCAM 	   TREG[TREG_TCAM_RESULT_UNF_OFF] , EXT_TCAM_STR,
      			TREG[0], 21,      // DPORT(2), VLAN(2), DIP(16), Phys PORT(1)
               TREG[32], 19,     // SIP(16),  SPORT(2), L4_TYPE(1)
      			PROFILE EXT_TCAM_LINE_NUM_ALST, NO_WR_LAST; 
//   LookupTCAM 	TREG[TREG_TCAM_RESULT_OFF], EXT_TCAM_STR, TREG[0], 32, TREG[32], 8, PROFILE EXT_TCAM_LINE_NUM_ALST, NO_WR_LAST;


//Lookup  TREG[TREG_TCAM_RESULT_OFF], CTX_STR , TREG[UNF_CTX_STR_IDX] , 1 , TREG[32] , 0 , NO_WR_LAST;

   //JNoMatch L_ALST_NO_MATCH_IN_TCAM;
WriteCond COND_REG , TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4] , SET_MATCH_BIT;  

Jcond;
JNoMatch L_ALST_NO_MATCH_IN_TCAM_CONT;

L_ALST_MATCH_IN_TCAM_CONT:
Lookup 	OREG, ALST_RES_STR,
				TREG[TREG_TCAM_IDX_UNF_OFF], ALST_KEY_SIZE,
            WR_LAST;
       
Halt;
#endif 

L_ALST_NO_MATCH_IN_TCAM_CONT:

   //set valid + no match bit
   movImm  TREG[TREG_TCAM_RESULT_UNF_OFF], 0x1 , 4; 
   write OREG, ALST_RES_STR, TREG[TREG_TCAM_RESULT_UNF_OFF], ALST_RES_SIZE ,  NO_WR_LAST;

//   Halt;


      //Halt ?????????????

// Lookup with Policy full key in External TCAM
#if 0
#ifndef __SIM__
// Syn Protected Destination
LookupTCAM TREG[TREG_SYN_PROT_OFF], INT_TCAM_STR, 
           TREG[UNF_PROT_DPORT_OFF], 26/*21*/,		// SYN_PROT_DPORT_OFF (2bytes) + SYN_PROT_VLAN_OFF (2bytes) + SYN_PROT_DIP_OFF (16bytes) + SYN_PROT_PORT_OFF (1byte) + SYN_PROT_PHASE_OFF (1byte)
           PROFILE INT_TCAM_LINE_NUM_SYN_PROT, NO_WR_LAST,
           /*THREAD_ID 3,*/ KEEP_PREV_CTRL_BITS, NO_WR_LAST;

#else

LookupTCAM TREG[TREG_SYN_PROT_OFF], INT_TCAM_STR, 
           TREG[UNF_PROT_DPORT_OFF], 26/*21*/,		// SYN_PROT_DPORT_OFF (2bytes) + SYN_PROT_VLAN_OFF (2bytes) + SYN_PROT_DIP_OFF (16bytes) + SYN_PROT_PORT_OFF (1byte) + SYN_PROT_PHASE_OFF (1byte)
           PROFILE INT_TCAM_LINE_NUM_SYN_PROT, NO_WR_LAST,
           THREAD_ID 3, KEEP_PREV_CTRL_BITS, NO_WR_LAST;
#endif 

	//parallel THREAD_ID_MASK 8; // don't wait for INT_TCAM_STR result
/*
shr TREG[UNF_PROT_POLICY_PHASE_OFF], TREG[UNF_PROT_POLICY_PHASE_OFF], 4, 1;
Or  TREG[UNF_PROT_POLICY_PHASE_OFF], TREG[UNF_PROT_POLICY_PHASE_OFF], 0x2, 1, MASK_00000001, MASK_SRC1;
WriteIndReg TREG[UNF_PROT_POLICY_PHASE_OFF];
Nop;
Nop;
Nop;
*/
#endif
WriteCond COND_REG, TREG[UNF_PROT_POLICY_PHASE_OFF].bit[4], SET_MATCH_BIT;   
JCond;                    
JMatch Policy_Phase1;

Policy_Phase0:
LookupTCAM TREG[TREG_TCAM_RESULT_UNF_OFF], EXT_TCAM_STR, 
              TREG[UNF_PROT_VLAN_OFF     ],  19, // unified [ key vlan { 2 byte } + DIP {16 byte} + phys port { 1 byte } 
              TREG[UNF_PROT_SIP_OFF   ], /*16*/21, // unified [ SIP { 16 byte} ]  
              PROFILE EXT_TCAM_LINE_NUM_POLICY_PHASE0, NO_WR_LAST;

WriteCond COND_REG, TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4], SET_MATCH_BIT;   
JCond;                    
JNoMatch L_POLICY_SIP_NO_MATCH_IN_TCAM;
Nop;
/*
Lookup OREG, POLICY_RES_STR,
		 TREG[TREG_TCAM_IDX_UNF_OFF], POLICY_RES_KEY_SIZE,
       TREG[TREG_TCAM_IDX_UNF_OFF], 0,
       WR_LAST_IF_NO_JUMP;
*/
Lookup TREG[TREG_TCAM_RESULT_UNF_OFF] /*OREG*/, POLICY_RES_STR,
		 TREG[TREG_TCAM_IDX_UNF_OFF], POLICY_RES_KEY_SIZE,
       TREG[TREG_TCAM_IDX_UNF_OFF], 0,
       NO_WR_LAST;


//JMatch SYN_PROT_START;
//Halt;
JNoMatch L_POLICY_SIP_NO_MATCH_IN_TCAM;

Write  OREG, POLICY_RES_STR,TREG[TREG_TCAM_RESULT_UNF_OFF], POLICY_RES_RES_SIZE, TREG[TREG_TCAM_IDX_UNF_OFF], 0,NO_WR_LAST;
Jmp SYN_PROT_START;

Policy_Phase1:
LookupTCAM TREG[TREG_TCAM_RESULT_UNF_OFF], EXT_TCAM_STR, 
              TREG[UNF_PROT_VLAN_OFF     ],  19, // unified [ key vlan { 2 byte } + DIP {16 byte} + phys port { 1 byte } 
              TREG[UNF_PROT_SIP_OFF   ], /*16*/21, // unified [ SIP { 16 byte} ]  
              PROFILE EXT_TCAM_LINE_NUM_POLICY_PHASE1, NO_WR_LAST;

//parallel THREAD_ID_MASK 1; // don't wait for INT_TCAM_STR result
WriteCond COND_REG, TREG[TREG_TCAM_RESULT_UNF_OFF].bit[4], SET_MATCH_BIT;   
//parallel THREAD_ID_MASK 1; // don't wait for INT_TCAM_STR result
JCond;                    
JNoMatch L_POLICY_SIP_NO_MATCH_IN_TCAM;
Nop;
Lookup TREG[TREG_TCAM_RESULT_UNF_OFF] /*OREG*/, POLICY_RES_STR,
		 TREG[TREG_TCAM_IDX_UNF_OFF], POLICY_RES_KEY_SIZE,
       TREG[TREG_TCAM_IDX_UNF_OFF], 0,
       NO_WR_LAST;  



//JMatch SYN_PROT_START; 
JNoMatch L_POLICY_SIP_NO_MATCH_IN_TCAM;    

Write  OREG, POLICY_RES_STR,TREG[TREG_TCAM_RESULT_UNF_OFF], POLICY_RES_RES_SIZE, TREG[TREG_TCAM_IDX_UNF_OFF], 0,NO_WR_LAST;  
  
//Halt;

#define POLICY_ID_OFFSET  3
#define POLICY_ID_SIZE    2


SYN_PROT_START:

// Lookup in Int.TCAM to find a key for SYN Protection table
Nop;
Nop;
Write  TREG[{UNF_PROT_PHASE_OFF+1}] ,POLICY_RES_STR ,  TREG[{TREG_TCAM_RESULT_UNF_OFF+3}] , POLICY_ID_SIZE;

LookupTCAM TREG[TREG_SYN_PROT_OFF], INT_TCAM_STR,
           TREG[UNF_PROT_DPORT_OFF], 24,		// SYN_PROT_DPORT_OFF (2bytes) + SYN_PROT_VLAN_OFF (2bytes) + SYN_PROT_DIP_OFF (16bytes) + SYN_PROT_PORT_OFF (1byte)
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
      WR_LAST; 

Halt;


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
      WR_LAST; 

Halt;


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
      WR_LAST; 

Halt;


////////////////////////////////////////////////
//    AccessList Handling
////////////////////////////////////////////////

Public ALST_SRH_TCAM_LOOKASIDE_CALLBACK/*ALST_EXT_TCAM_LOOKUP*/:
   

   Lookup  TREG[TREG_TCAM_RESULT_OFF], CTX_STR , TREG[0] , 1 , TREG[32] , 0 , NO_WR_LAST;

   //JNoMatch L_ALST_NO_MATCH_IN_TCAM;
   WriteCond COND_REG , TREG[TREG_TCAM_RESULT_OFF].bit[4] , SET_MATCH_BIT;  

   Jcond;
   JNoMatch L_ALST_NO_MATCH_IN_TCAM;

   Lookup 	OREG, ALST_RES_STR,
				TREG[TREG_TCAM_IDX_OFF], ALST_KEY_SIZE,
            WR_LAST;

   Halt;
   
      
L_ALST_NO_MATCH_IN_TCAM:

   //set valid + no match bit
   movImm  TREG[TREG_TCAM_RESULT_OFF], 0x1 , 4; 
   write OREG, ALST_RES_STR, TREG[TREG_TCAM_RESULT_OFF], ALST_RES_SIZE ,  WR_LAST;   

   Halt;


L_POLICY_SIP_NO_MATCH_IN_TCAM:

   // If there is no match Policy for full key - set valid + no match bit
   MovImm TREG[TREG_TCAM_RESULT_OFF], 0x1, 4; 

   // Write no match result
   Write OREG, POLICY_RES_STR, 
         TREG[TREG_TCAM_RESULT_OFF], POLICY_RES_RES_SIZE,
         WR_LAST; 

   Halt;

// For Ext.TCAM lookaside:
/*

Public ALST_EXT_TCAM_LOOKUP:


   LookupTCAM 	CTX CTX_LINE_TCAM, EXT_TCAM_STR , TREG[0], 32 , TREG[32], 8, PROFILE 0 , WR_LAST;
   Halt;


public ALST_SRH_READ_CTX_TCAM_RES:

   
   movImm  TREG[0], CTX_LINE_TCAM, 1;

	Lookup 	TREG[TREG_TCAM_RESULT_OFF], CTX_STR,
				TREG[0], 1, //treg 0 containes ctx line number         
				TREG[32], 0,
            NO_WR_LAST;
   JNoMatch L_SRH_WAIT_TCAM_RES_LOOP;  

L_SRH_CTX_TCAM_RES_VALID:

   WriteCond COND_REG, TREG[TREG_TCAM_RESULT_OFF].bit[4], SET_MATCH_BIT;
   JCond;
   JNoMatch L_ALST_NO_MATCH_IN_TCAM;



   Lookup 	OREG, ALST_RES_STR,
				TREG[TREG_TCAM_IDX_OFF], ALST_KEY_SIZE,
            WR_LAST;

   Halt;


L_ALST_NO_MATCH_IN_TCAM:

   //set valid no match bit
   movImm  TREG[TREG_TCAM_RESULT_OFF], 0x1 , 4;
   write OREG, ALST_RES_STR, TREG[TREG_TCAM_RESULT_OFF], ALST_RES_SIZE ,  WR_LAST;   

   Halt;

L_SRH_WAIT_TCAM_RES_LOOP:

   movImm  TREG[0], CTX_LINE_TCAM, 1;

   //initiate value for timer counter - used as workaround in case of single engine (see explanations below). 
   movImm  TREG[TREG_TIMER_COUNTER_OFF], TREG_TIMER_COUNTER_VALUE, 1;

   L_SRH_READ_CTX_TCAM_RES_LOOP:
	   Lookup 	TREG[TREG_TCAM_RESULT_OFF], CTX_STR,
	   			TREG[0], 1,         
   				TREG[48], 0,
               NO_WR_LAST;
      JMatch L_SRH_CTX_TCAM_RES_VALID; // JMatch checks the validity of the result - if the result is valid, jump back to the main flow, otherwise - continue with the timer mechanism waiting

   //decrease the counter by 1   
   sub TREG[TREG_TIMER_COUNTER_OFF], TREG[TREG_TIMER_COUNTER_OFF], 1, 1;
   //check the counter value - is it equal 0?
   cmp TREG[TREG_TIMER_COUNTER_CALC_OFF], TREG[TREG_TIMER_COUNTER_OFF], 0x0, 1;              //compare the counter value vs. 0. the result will be written in TREG

   //jump condition                   
   jcond TREG[TREG_TIMER_COUNTER_CALC_OFF], WR_LAST_IF_NO_JUMP;
   JMaskMatch 0x02, L_SRH_READ_CTX_TCAM_RES_LOOP;

   //set valid no match bit
   movImm  TREG[TREG_TCAM_RESULT_OFF], 0x1 , 4; 
   write OREG, ALST_RES_STR, TREG[TREG_TCAM_RESULT_OFF], ALST_RES_SIZE ,  WR_LAST;   

   //Now it means that we waited enough, timer expired 
   Halt;

*/
 

////////////////////////////////////////////////
//    BDOS Attack Handling
////////////////////////////////////////////////

// L3 Attacks - IPv4, IPv6

public ATTACK_IPV4_START_P0:
Attack_IPV4_Treat 0;
Write OREG, BDOS_ATTACK_RESULTS_L23_2_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_IPV4_START_P1:
Attack_IPV4_Treat 32;
Write OREG, BDOS_ATTACK_RESULTS_L23_2_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_IPV6_START_P0:
Attack_IPV6_Treat 0;
Write OREG, BDOS_ATTACK_RESULTS_L23_2_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_IPV6_START_P1:
Attack_IPV6_Treat 32;
Write OREG, BDOS_ATTACK_RESULTS_L23_2_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;


// L4 Attacks - TCP, UDP, ICMP, IGMP

public ATTACK_TCP_START_P0:
Attack_TCP_Treat 0;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_TCP_START_P1:
Attack_TCP_Treat 32;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_UDP_START_P0:
Attack_UDP_Treat 0;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_UDP_START_P1:
Attack_UDP_Treat 32;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_ICMP_START_P0:
Attack_ICMP_Treat 0;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_ICMP_START_P1:
Attack_ICMP_Treat 32;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_IGMP_START_P0:
Attack_IGMP_Treat 0;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

public ATTACK_IGMP_START_P1:
Attack_IGMP_Treat 32;
Write OREG, BDOS_ATTACK_RESULTS_L4_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE, WR_LAST;
Halt;

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
