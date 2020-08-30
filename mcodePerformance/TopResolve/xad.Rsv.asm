/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Rsv.asm
*
*  Usage:         TOPresolve main file
*
*******************************************************************************/

EZTop Resolve;

#include "EZcommon.h"
#include "EZresolve.h"
#include "EZrfd.h"
#include "EZstat.h"
#include "lrn_labels.h"
#include "src_labels.h"

#include "xad.common.h"
#include "xad.cntrBase.h"
#include "xad.portMap.h"
#include "xad.Rsv.h"
#include "xad.Rsv.macros.asm"
#include "xad.Rsv.Acl.asm"  



// Base registers initialization
Mov HW_OBS,  0, 1;                 
Mov ENC_PRI, 0, 2;
//Hardware message 0 , start from 1      
Mov COM_HBS , 1 , 1;
Mov KMEM_OFFSET , KMEM_RSV2SRH2_FFT_KEY_OFF , 1;
GetRes  byFrameActionReg, MSG_ACTION_ENC_OFF(MSG_STR), 1; // Extract frame action

//PutHdr  HREG[ 1 ], RSV_FFT_VID_LKP_INVALID_HDR;           // Init HREG1: the init is in order to have the placeholder of Key that may (or may not) be passed in HREG[1] and have a constant start offset for key passed in HREG[2]

/////////////////////////////////////////////////////////////////////////////////////////////
// The following "C style" pseudo code describes how the FFT search label in SRCH2 is chosen.
// Below this comment is the implementation itself

//if (1 == byFrameActionReg.BIT[FRAME_SYN_COOKIE_GEN_BIT])
//{
//   PutHdr HREG[ 1 ], RSV_FFT_SYN_LKP_HDR;     
//}
//else if (1 == byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_TP_EN_BIT])
//{
//  if (1 == byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_TP_COPY_PRT_BIT])
//   {
//      PutHdr HREG[ 1 ], RSV_FFT_VLAN_TP_ONLY_LKP_HDR;
//   }
//   else // (1 == byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_TP_COPY_BYPASS_PRT_BIT])
//   {
//      PutHdr HREG[ 1 ], RSV_FFT_TP_LKP_HDR;
//  }
//}
//else
//{
//     PutHdr HREG[ 1 ], RSV_FFT_TX_LKP_HDR;
//}
//////////////////////////////////////////////////////////////////////////////////////////////

// Start with assuming main path will be taken (bypass).
// This will later on be overwritten if it turns out to be that either TP or SYN paths are taken
//PutHdr HREG[ 1 ], RSV_FFT_TX_LKP_HDR;

// Populate the TOPsearch2 FFT key
//copy KMEM_RSV2SRH2_FFT_KEY_OFF( HW_OBS ),  MSG_VIF_OFF(MSG_STR), 1;
Mov byTemp3Byte0 , 0 , 1;
copy KMEM_OFFSET( HW_OBS ),  MSG_VIF_OFF(MSG_STR), 1;
  

movBits ENC_PRI.bit[7], byFrameActionReg.bit[0], 8;

// Init registers and copy the whole msg from TOPparse
Copy  0(HW_OBS), 0(MSG_STR),  32;


//set default HREG[ 1 ]¨content according to input action
MovMul 0, 0, SRH2_FFT_FRMHOSTTX_LAB, 0, 0, 0, 0, 0, SRH2_FFT_TX_LAB, 0, 0;
Mov  byGlobalStatusBitsReg, 0, 1;

//Avoid LKP_VALID bits set in case when no action expected 
Sub ALU , ENC_PRO , 0 ,2 ;

Mov  uqGlobalStatusBitsReg.byte[2], 0, 2;

//construct dynamic label 

JZ SKIP_HREG1_CHANGE; 
    Mov    byCtrlMsgRsv0,  0, 2;                                // both byCtrlMsgRsv0 and byCtrlMsgRsv1 are zeroed here
    Copy 32(HW_OBS), 32(MSG_STR), 32;

//Or ALU , ALU , uqTmpReg3 ,4;      
PutHdr HREG[ COM_HBS ], ((LKP_VALID   | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT))) ;
PutHdrBits HREG[ COM_HBS ].BIT[ HREG_FIRST_LINE_ADDR_BIT ]  , ENC_PRO , 10;
//movbits $uqRSV_INDIRECT_CTX_LOAD.bit[CTX_LINE_OUT_IF], HREG[COM_HBS].bit[22], 1;
MovBits byTemp3Byte0.bit[CTX_LINE_OUT_IF]  , 1 , 1;
Add COM_HBS  , COM_HBS ,  1 , 1;
Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

//xor ALU, ALU, !ALU, 4, TRAFFIC_ENGINE_NUMBER, MASK_BOTH; // using MREG[12] 
//Copy { KMEM_RSV2SRH2_FFT_KEY_OFF + 2 } ( HW_OBS ),  MSG_HASH_CORE_OFF(MSG_STR), 1;
//PutKey { KMEM_RSV2SRH2_FFT_KEY_OFF + 4 } ( HW_OBS ),  ALU, 1;


SKIP_HREG1_CHANGE:

// Message control registers init
GetRes byCtrlMsgPrs2,  MSG_CTRL_TOPPRS_2_OFF(MSG_STR), 1;   // initialize byCtrlMsgPrs2
GetRes byCtrlMsgPrs0,  MSG_CTRL_TOPPRS_0_OFF(MSG_STR), 2;   // both byCtrlMsgPrs0 and byCtrlMsgPrs1 are initilized here

// Prepare RX copy test
Mov byTempCondByte, byCtrlMsgPrs2, 1;

// Set ENC_PRI register MSbit to jump into special label handling inter-NP packets path.
// This is done in such way in order to minimize code processing, and join all relevant 
// paths into one jmul instruction
MovBits ENC_PRI.bit[15], byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_INTERLINK_PACKET_BIT], 1;

If (!byTempCondByte.BIT[MSG_CTRL_TOPPRS_2_HAS_RX_COPY_BIT])   
   Jmp NO_RX_COPY_LAB, NO_NOP; 

      // Copying control bits that needs to be passed from TOPparse through TOPresolve to TOPmodify without modification
      // initialize MSG_CTRL_TOPRSV_2_HAS_RX_COPY_BIT, MSG_CTRL_TOPRSV_2_DELAY_DROP_BIT, MSG_CTRL_TOPRSV_2_INTERLINK_PACKET_BIT, MSG_CTRL_TOPRSV_2_IS_CAUI_PORT_BIT
      MovBits byCtrlMsgRsv1.bit[MSG_CTRL_TOPRSV_2_HAS_RX_COPY_BIT], byCtrlMsgPrs2.bit[MSG_CTRL_TOPPRS_2_HAS_RX_COPY_BIT], 4;	

      // Copying control bits that needs to be passed from TOPparse through TOPresolve to TOPmodify without modification
      MovBits byCtrlMsgRsv1.bit[MSG_CTRL_TOPRSV_1_L3_TUNNEL_EXISTS_BIT], byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_L3_TUNNEL_EXISTS_BIT], 5;	// initialize also MSG_CTRL_TOPPRS_1_ROUTING_EN_BIT, MSG_CTRL_TOPPRS_1_IS_IPV4_BIT, and MSG_CTRL_TOPPRS_1_IS_IPV6_BIT, MSG_CTRL_TOPPRS_1_USER_VLAN_IN_FRAME_BIT 

Copy KMEM_OFFSET ( HW_OBS ),  MSG_VIF_OFF(MSG_STR), 1;

Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

//movbits $uqRSV_INDIRECT_CTX_LOAD.bit[CTX_LINE_RX_COPY_INFO], HREG[COM_HBS].bit[22], 1; // to mark to TOPmodify's HW to start execution only after the context line is ready with this result of the RX copy ports
MovBits byTemp3Byte0.bit[CTX_LINE_RX_COPY_INFO]  , 1 , 1;
// The following commands are executed only when packet arrives from a port which has "RX copy port".
If (byTempCondByte.BIT[MSG_CTRL_TOPPRS_2_DELAY_DROP_BIT])
   Jmp  FRAME_BYPASS_NETWORK_LAB, NO_NOP;    // can also be directed to TOP_RESOLVE_TERMINATION_LAB (shoter execution)

      PutHdr HREG[ COM_HBS ], RSV_RX_COPY_PORT_LKP_HDR;              // Init HREG2: the init is in order to have the placeholder of Key that may (or may not) be passed in HREG[2]
      Add COM_HBS  , COM_HBS ,  1 , 1;


NO_RX_COPY_LAB:

Jmul FRAME_RECEIVED_FROM_2ND_NP,          //OhadM:handling packets from peer NP device  
     FRAME_TP_BYPASS_2NETW_TMP_LAB,       //FRAME_TP_BYPASS_2NETW
     FRAME_BYPASS_CPU_2NETWORK_LAB /*FRAME_BYPASS_CPU_2NETWORK_LOCAL_LAB*/, //FRAME_HOST_BYPASS_2NETW
     ERROR_HANDLING_RSV,                  //FRAME_SYN_COOKIE_GEN    
     CONTROLFRAME_ACTION_LAB,             //FRAME_CONF_EXTRACT
     ERROR_HANDLING_RSV,                  //FRAME_DROP              //AmitA: this was not set in TOPparse and not in TOPresolve, so probably should never jump into here.
     CONT_LAB,                            //FRAME_CONT_ACTION
     FRAME_BYPASS_HOST_LAB_GLOB_TMP_MODE, //FRAME_BYPASS_HOST
     FRAME_BYPASS_NETWORK_LAB,            //FRAME_BYPASS_NETWORK
     ERROR_HANDLING_RSV,
     ERROR_HANDLING_RSV;


jmp ERROR_HANDLING_RSV, NOP_2;  // This should never happen

FRAME_BYPASS_NETWORK_LAB:

jmp SEND_PACKET_LAB, NO_NOP;
    MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT], 1, 1;   
    Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;

//FRAME_BYPASS_CPU_2NETWORK_LOCAL_LAB:
//jmp FRAME_BYPASS_CPU_2NETWORK_LAB, NOP_2;

FRAME_TP_BYPASS_2NETW_TMP_LAB:
xor ALU, ALU, !ALU, 4, GC_CNTRL_2_MREG, MASK_BOTH;                   // Get MREG Value
   Nop;
Movbits byTempCondByte.bit[0], ALU.bit[GC_CNTRL_2_IMM_CHK_TP_ACTION_OFFSET], 1;

FRAME_TP_BYPASS_2NETW_LAB:

//ENC_PRI - actual action can be drop/bypass to network 
//byTempCondByte.bit[3] - ; 0 - trace , 1 - copy type
//STAT_OPERATION TP_ACT_TB, TP_SIZE_CONST, STS_GET_COLOR_CMD;
Mov ALU, TP_SIZE_CONST, 4;
   Nop;
EZstatPutDataSendCmdIndexImm TP_ACT_TB, ALU, STS_GET_COLOR_CMD;
   nop;
   nop;
EZwaitFlag F_SR;

MovBits byTempCondByte.bit[2], STAT_RESULT_L.bit[RED_FLAG_OFF],      1; // Color is also returned to UDB.bits 16,17.

// Increment number TP marked packets
EZstatIncrByOneIndexImm  TP_CNTRL_PRT_MRK; 

//EZstatIncrByOneIndexReg
decode ALU, byTempCondByte, 1, MASK_00000007, MASK_SRC1;
   nop;
mov ENC_PRI.byte[1], ALU, 1 ;
Mov ENC_PRI.byte[0], 0, 1;
   nop;

//jmul error, check it
Jmul TP_FRAME_BYPASS_NETWORK_LAB, 
     ERROR_HANDLING_RSV,  
     FRAME_DROP_LAB, //TP_FRAME_DROP_LAB, 
     ERROR_HANDLING_RSV, 
     TP_BYPASS_COPY_LAB,
     ERROR_HANDLING_RSV,
     TP_COPY_LAB,
     ERROR_HANDLING_RSV,
     ERROR_HANDLING_RSV,
     ERROR_HANDLING_RSV,
     ERROR_HANDLING_RSV;
   nop;
   nop;

jmp FRAME_DROP_LAB /*TP_FRAME_DROP_LAB*/, NOP_2;


TP_FRAME_BYPASS_NETWORK_LAB:
//STAT_OPERATION GS_TRL_EX_PAS, 1, EZ_INCR_CMD_STS; 
jmp FRAME_BYPASS_NETWORK_LAB, NOP_1;
   MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT], 1, 1;  //set indication bit for Top Modify


//TP_FRAME_DROP_LAB:
//jmp FRAME_DROP_LAB, NOP_2;

      
TP_BYPASS_COPY_LAB:
#define TP_BYPASS_COPY ((1<<MSG_CTRL_TOPRSV_0_TP_COPY_BYPASS_PRT_BIT) | (1<<MSG_CTRL_TOPRSV_0_TP_EN_BIT));
jmp FRAME_BYPASS_NETWORK_LAB, NO_NOP;
   MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_TP_COPY_PRT_BIT], TP_BYPASS_COPY, 3;
   PutHdr HREG[ 1 ], RSV_FFT_TP_LKP_HDR;

  
TP_COPY_LAB:
//STAT_OPERATION GS_TRL_EX_DRP, 1, EZ_INCR_CMD_STS;
#if !GLOBAL_RTM_IN_TOP_MODIFY
jmp rtmCountersUpdate_LAB, NO_NOP;  //RT monitoring drop counters update
   Mov PC_STACK, TP_COPY_RT_DONE_LAB, 2;
   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;  
#endif

//returns after realtime counters treatment
indirect TP_COPY_RT_DONE_LAB:

#define TP_COPY ((1<<MSG_CTRL_TOPRSV_0_TP_EN_BIT)|(1<<MSG_CTRL_TOPRSV_0_TP_COPY_PRT_BIT));
PutHdr HREG[ COM_HBS ], RSV_FFT_VLAN_TP_ONLY_LKP_HDR;
jmp FRAME_BYPASS_NETWORK_LAB, NO_NOP;
   MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_TP_COPY_PRT_BIT], TP_COPY, 3;
   Add  COM_HBS , COM_HBS , 1, 1;
   



//control error treatment 
ERROR_HANDLING_RSV:
// In case frame was shorter than expected
//STAT_OPERATION GC_ERROR_0, 1, EZ_INCR_CMD_STS;
jmp FRAME_DROP_LAB, NOP_2;


FRAME_BYPASS_HOST_LAB_GLOB_TMP_MODE:
if (!byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT]) jmp FRAME_BYPASS_HOST_LAB_GLOB_MODE, NOP_2;


CONT_LAB:
 
//look for Access list results

xadAccessListResolve FRAME_BYPASS_HOST_LAB, 
                     FRAME_BYPASS_NETWORK_LAB,
                     BDOS_OOS_PERFORM_LAB,
                     FRAME_DROP_LAB,
                     FRAME_TP_BYPASS_2NETW_LAB, 
                     FRAME_DROP_LAB;

jmp SYN_PROT_LAB, NOP_2;  
//anyway jump to policy
//jmp BDOS_OOS_PERFORM_LAB, NOP_2;

                      



//FRAME_BYPASS_HOST_LAB:        
FRAME_BYPASS_HOST_LAB_GLOB_MODE:      
FRAME_BYPASS_HOST_LAB:
jmp SEND_PACKET_LAB_CPU, NO_NOP;
   mov byFrameActionReg, FRAME_BYPASS_HOST, 1;  //set action bypass to host
   nop;


//send packet to network, disable Vlan replace
FRAME_BYPASS_CPU_2NETWORK_LAB:
EZstatIncrByOneIndexImm  GS_TRL_IN_RCV; //increment number of internal packets received on TOP Resolve   

Mov byFrameActionReg, FRAME_HOST_BYPASS_2NETW, 1; //set action bypass to network

copy KMEM_RSV2SRH2_FFT_KEY_OFF( HW_OBS ),  MSG_SWITCH_VLAN_FROM_HOST(MSG_STR), 2;

// Check for Policy Update status
/*
Xor ALU, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH;    // getRes MREG Value
Nop;
Movbits ALU.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT], ALU.bit[GC_CNTRL_1_UPD_POL_STATUS_BIT], 1;    // Set Update Policies status
Or byTempCondByte, ALU.byte[0], byCtrlMsgPrs0, 1;
 ???? - Risky */
PutHdr HREG[ 0 ], RSV_MSG_HDR;
// -- Risky MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT], 1, 1;   

// RT monitoring receive counters update
// rtmCountersUpdate RT_MONITOR_BASE_CNTR; 
// RT monitoring drop counters update
#if !GLOBAL_RTM_IN_TOP_MODIFY
jmp rtmCountersUpdate_LAB, NO_NOP;
   Mov PC_STACK, RT_DONE_TO_NW_LAB, 2;
   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  
#endif

RT_DONE_TO_NW_LAB:

vardef regtype uqRSV_INDIRECT_CTX_LOAD    INDIRECT_CTX_LOAD.byte[0:1];  // INDIRECT_CTX_LOAD register (UREG[12]): bits 8:15 (ignore_rdy_bits) part of this register should always be zero in order to assure that TOPmodify will start ONLY when the relevant context lines marked in bits 7:0 (load_context_bitmap) part of the register are valid.

movbits $uqRSV_INDIRECT_CTX_LOAD , byTemp3Byte0 , 3;
nop;   
PutKey MSG_CTRL_TOPRSV_0_OFF(HW_OBS), byCtrlMsgRsv0, 2;  // Writing 2 ctrl bytes (byCtrlMsgRsv0 and byCtrlMsgRsv1) in 1 operation

varundef uqRSV_INDIRECT_CTX_LOAD;
//Finish handling with non search and jump to the next stage (TOPmodify) 
halt UNIC,
     HW_MSG_HDR,
     IND_LD_CTX;




// Valid for bypass to network              
SEND_PACKET_LAB:
SEND_TO_CPU: 
    
PutHdr HREG[ 0 ], RSV_MSG_HDR;
//PutHdr HREG[ 1 ], RSV_FFT_VID_LKP_HDR; // TODO_OPTIMIZE: May save a lookup (!) and some more code: maybe the whole lookup may be skipped in routing mode. if so need to cancel the vould key, the lookup in TOPsearch and the code in TOPmodify. before doing that check that the code is not needed in transparent mode, and check that the lookup result is not needed for any other purpose.


jmp DONE_LAB, NOP_2;


// The following copies the message from TOPparse and places the external VLAN tag for TOPsearch-II lookup 
Indirect SEND_PACKET_LAB_CPU:
COMMON_END:
// Check for Policy Update status
Xor ALU, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH;    // getRes MREG Value
Nop;
Movbits ALU.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT], ALU.bit[GC_CNTRL_1_UPD_POL_STATUS_BIT], 1;    // Set Update Policies status
Or byTempCondByte, ALU.byte[0], byCtrlMsgPrs0, 1;
PutHdr HREG[ 0 ], RSV_MSG_HDR;

//check jumbo flags and Policy Update status
If (!byTempCondByte.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT]) jmp DONE_LAB , NOP_2;

MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT], 1, 1;   
Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;


PutHdr HREG[ COM_HBS ], RSV_FFT_ALST_LKP_HDR;
Copy KMEM_OFFSET ( HW_OBS ),  MSG_VIF_OFF(MSG_STR), 1;
MovBits byTemp3Byte0.bit[CTX_LINE_OUT_IF]  , 1 , 1;
Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

DONE_LAB: 
  
// RT monitoring receive counters update
// rtmCountersUpdate RT_MONITOR_BASE_CNTR; 
// RT monitoring drop counters update
#if !GLOBAL_RTM_IN_TOP_MODIFY
jmp rtmCountersUpdate_LAB, NO_NOP;
   Mov PC_STACK, RT_DONE_LAB, 2;
   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  
#endif

indirect RT_DONE_LAB:


TOP_RESOLVE_TERMINATION_LAB:
PrepareRsvMsg;

//Finish handling with non search and jump to the next stage (TOPmodify) 
halt UNIC,
     HW_MSG_HDR,
     IND_LD_CTX;

/*
halt UNIC,
     HW_MSG_HDR,
     LD_CTX_BITMAP 1,
     LD_IGN_CTX_READY 0;
*/            



////////////////////////////////////////
//       Policy Handling
////////////////////////////////////////

// "Policy" means definitions of necesary actions for this specific flow.
// Policy actions: perform frame clasification - map policy according to frame attributes/flow (SIP,DIP,NP_SPORT,VLAN_ID).
// The value of policy is saved in counters (used as memory) by the host. The counter's will be interpeted by the mcode, and it is bitwise.


BDOS_OOS_PERFORM_LAB:   

#define  P_SIP_STR      RMEM_BASE0;
#define  P_DIP_STR      RMEM_BASE0;
#define  P_VLAN_STR     RMEM_BASE1;
#define  P_PORT_STR     RMEM_BASE1;

   Mov uqTmpReg1, 0, 4;
   //Mov HW_OBS,    0, 1;

Movbits byGlobalStatusBitsReg.bit[POLICY_PHASE_BIT], 0, 1; // Set policy phase 0

if (byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT]) jmp ANALYZE_POLICY, NO_NOP;
   GetRes uqBdosL4ValidBitsReg, SIGNA_CNTRL_RES_OFF(BDOS_ATTACK_RESULTS_L23_2_STR), 4;
   nop;


/////////////////////////////////////////////////////////////////////////////////////
//    Default Policy Handling (When there is no match in Policy classification)
/////////////////////////////////////////////////////////////////////////////////////

POLICY_DEFAULT_ACTION_LAB:

// GuyE, 20.1.2014: Remove NOPS somehow

//////////////////////////////////////////////////////////////////////////////////
xor ALU, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH; // Get MREG Value
Nop;

// Calculate default policy counter index
Mov     bytmp0, ALU.byte[2], 1;
Nop;
decode  ALU, bytmp0, 1, MASK_00000003, MASK_SRC1;
Nop;
MovBits ENC_PRI.bit[9], ALU.bit[0], 7;

Mov     ALU, POLICY_CNTR_DEF_POL_BASE, 4;
MovBits ENC_PRI.bit[12], byCtrlMsgPrs2.bit[MSG_CTRL_TOPPRS_2_PA_SAMPL_BIT], 1;
Add     ALU, bytmp0, ALU, 4, MASK_00000003, MASK_SRC1;
//////////////////////////////////////////////////////////////////////////////////


EZstatIncrIndexReg ALU, 1;  //increment this

Jmul DEFAULT_POLICY_ACTION_ERROR_LAB,       // Drop frame after default policy handling
     DEFAULT_POLICY_ACTION_ERROR_LAB,       // Drop frame after default policy handling
     DEFAULT_POLICY_ACTION_ERROR_LAB,       // Drop frame after default policy handling
     DEFAULT_POLICY_ACTION_SEND_TO_CPU_LAB, // Send frame to CPU after default policy handling
     DEFAULT_POLICY_ACTION_BYPASS_LAB,      // Bypass to network after default policy handling
     DEFAULT_POLICY_ACTION_CONTINUE_LAB,    // Continue with frame flow (SYN Protection) after default policy handling
     DEFAULT_POLICY_ACTION_DROP_LAB;        // Drop frame after default policy handling
     nop;
     nop;

// We should not reach this point!
jmp DEFAULT_POLICY_ACTION_CONTINUE_LAB, NOP_2;


// Drop frame after default policy handling
DEFAULT_POLICY_ACTION_DROP_LAB:
DEFAULT_POLICY_ACTION_ERROR_LAB:
jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters drop , none supported yet
    Mov PC_STACK, DEFAULT_POLICY_RTM_DONE_DROP_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;  //update recive counters only
indirect DEFAULT_POLICY_RTM_DONE_DROP_LAB:
jmp FRAME_DROP_LAB, NOP_2;


// Send frame to CPU after default policy handling
DEFAULT_POLICY_ACTION_SEND_TO_CPU_LAB:
jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters recive
    Mov PC_STACK, DEFAULT_POLICY_RTM_DONE_SEND_TO_CPU_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  //update recive counters only
indirect DEFAULT_POLICY_RTM_DONE_SEND_TO_CPU_LAB:
jmp SEND_PACKET_LAB_CPU, NOP_2;


// Bypass to network after default policy handling
DEFAULT_POLICY_ACTION_BYPASS_LAB:

PutHdr HREG[ COM_HBS ], RSV_FFT_ALST_LKP_HDR;
Copy KMEM_OFFSET ( HW_OBS ),  MSG_VIF_OFF(MSG_STR), 1;
MovBits byTemp3Byte0.bit[CTX_LINE_OUT_IF]  , 1 , 1;
Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters recive
    Mov PC_STACK, DEFAULT_POLICY_RTM_DONE_BYPASS_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  //update recive counters only
indirect DEFAULT_POLICY_RTM_DONE_BYPASS_LAB:
jmp FRAME_BYPASS_NETWORK_LAB, NOP_2;


// Continue with frame flow (SYN Protection) after default policy handling
DEFAULT_POLICY_ACTION_CONTINUE_LAB:
jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters recive
    Mov PC_STACK, DEFAULT_POLICY_RTM_DONE_CONTINUE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  //update recive counters only
indirect DEFAULT_POLICY_RTM_DONE_CONTINUE_LAB:
jmp SYN_PROT_LAB, NOP_1;
   MovBits byGlobalStatusBitsReg.bit[POLICY_CONT_ACT_BIT], 1, 1;



/////////////////////////////////////////////////////////////////////////////////////
//    Specific Policy Handling (When there is match in Policy classification)
/////////////////////////////////////////////////////////////////////////////////////

ANALYZE_POLICY:

Mov ALU, 0, 4;


// Get the match bit from RMEM for policy tree structures
GetCtrlBits ALU,
            STRNUM[ POLICY_RES_STR ].bit[ MATCH_BIT ], // ALU.bit 3 - Policy result match bit
            STRNUM[ POLICY_RES_STR ].bit[ MATCH_BIT ], // ALU.bit 2 - Policy result match bit 
            STRNUM[ POLICY_RES_STR ].bit[ VALID_BIT ], // ALU.bit 1 - Policy result valid bit
            STRNUM[ POLICY_RES_STR ].bit[ VALID_BIT ]; // ALU.bit 0 - Policy result valid bit


Sub ALU, ALU, 0xF, 1;
GetRes byPolicyValidBitsReg, MSG_POLICY_VALIDATION_BITS_OFF( MSG_STR ), 1;

jnz POLICY_DEFAULT_ACTION_LAB, NO_NOP; 
   GetRes uqGlobalStatusBitsReg, POLICY_ACTION_OFFSET( POLICY_RES_STR ),  (POLICY_ACTION_SIZE + POLICY_USER_ID_SIZE);
   GetRes uqTmpReg2, POLICY_ID_OFFSET( POLICY_RES_STR ), POLICY_ID_SIZE, RESET; // uqTmpReg2 <- policy index (0 - 404)

MovBits ENC_PRI.bit[13], uqGlobalStatusBitsReg.bit[0], 3;
Nop;
Jmul POLICY_ACTION_BYPASS_LAB,       // Bypass to network after policy handling
     SYN_PROT_LAB,                   // Continue with frame flow (SYN Protection) after policy handling
     POLICY_ACTION_DROP_LAB,         // Drop frame after policy handling
     NO_NOP;
     PutKey MSG_POLICY_ID_OFF(HW_OBS), uqGlobalStatusBitsReg.byte[1], 2;  // Save policy id in message to be used for Host metadata addition in TOPmodify
     Mov uxGlobalPolIdx, uqTmpReg2.byte[0], 2;          // Policy index storage is only 16 bits length

And ALU, uqGlobalStatusBitsReg, 0x8, 1;
Nop;
JNZ POLICY_ACTION_SEND_TO_CPU_LAB, NO_NOP;

// We should not reach this point!
jmp SYN_PROT_LAB, NOP_2;


// Drop frame after policy handling
POLICY_ACTION_DROP_LAB:
POLICY_ACTION_ERROR_LAB:
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;    //update exclude rtm counters drop, none supported yet
    Mov PC_STACK, FRAME_DROP_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;


// Send frame to CPU or bypass to network after policy handling
POLICY_ACTION_BYPASS_LAB:
POLICY_ACTION_SEND_TO_CPU_LAB:
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;    //update exclude rtm counters recive
    Mov PC_STACK, SEND_PACKET_LAB_CPU, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;



Indirect AFTER_POLICY:

//perform global oos result
//OOS_Perform_Action;

jmp COMMON_END, NOP_2;

RX_COPY_AND_DROP_LAB:
   Jmp TOP_RESOLVE_TERMINATION_LAB, NOP_1;
      MovBits byCtrlMsgRsv1.BIT[MSG_CTRL_TOPRSV_2_DELAY_DROP_BIT], 1, 1;

  
indirect CONTROL_DISCARD_LAB:
 /*
   Discardtreatment;
   Mov INC_HLN_ORD, 5, 4; 
   Halt     HALT_DISC;
  */

   MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPRSV_2_HAS_RX_COPY_BIT] , byCtrlMsgRsv1.bit[MSG_CTRL_TOPRSV_2_HAS_RX_COPY_BIT] ,1;
   nop; 
   if (byCtrlMsgPrs1.BIT[MSG_CTRL_TOPRSV_2_HAS_RX_COPY_BIT])
      Jmp RX_COPY_AND_DROP_LAB, NOP_2;

   /* 2. Recycle and discard the packet. */
   EZrfdRecycleOptimized;
   halt DISC;


OOS_SYN_ACK_FR_ACTION:
    OOS_Preparse_Action POLICY_CNG_OOS_OTHER_ACT_BIT, OS_OTHR_CNT;

OOS_ACK_ACTION:
    OOS_Preparse_Action POLICY_CNG_OOS_ACK_ACT_BIT,   OS_OTHR_CNT;



//////////////////////////////////////////
//   SYN Protection Handling
//////////////////////////////////////////

SYN_PROT_LAB:

#define bySynProtCtrl      byTempCondByte;
#define uqSynProtCounter   uqTmpReg1;

if (!byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_PERFORM_SYN_PROT_BIT]) jmp POLICY_PERFORM_ACTION_LAB, NOP_2;

GetRes byTempCondByte1, SYN_PROT_CTRL_0_OFF(SYN_PROT_DEST_STR), 1; // Get SYN Protection control bits byte[0]
GetRes bySynProtCtrl,   SYN_PROT_CTRL_2_OFF(SYN_PROT_DEST_STR), 1; // Get SYN Protection control bits byte[2]

// If no lookup was performed in SYN_PROT_DEST_STR continue with packet processing
if (!byTempCondByte1.bit[VALID_BIT]) jmp POLICY_PERFORM_ACTION_LAB, NOP_2;

// If lookup in SYN_PROT_DEST_STR was performed but no match continue with OOS
if (!byTempCondByte1.bit[MATCH_BIT]) jmp POLICY_PERFORM_ACTION_LAB, NOP_2;

// Wait for Statistics Bus ready flag is required
EZwaitFlag F_ST;

// Take RTC timestamp (needs to do it as early as possible since this operation takes a few clocks)
// It is used later for Safe Reset timestamp validation
#if 1
Mov STAT_REG0, STS_READ_SYS_INFO_CMD__SRC_RTC, 4;
Nop;//Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;  //set action bypass to network
Nop;
Nop;
Mov STAT_CMD, STS_READ_SYS_INFO_CMD, 2;
#endif

// 2 instances handling:

// Check instance configuration match between Policy & SYN Protection:

/*MovBits byTempCondByte2, uqGlobalStatusBitsReg.bit[POLICY_INSTANCE_0_BIT], 2;*/                      // Get policy configured instance

/*if ( byGlobalStatusBitsReg.bit[POLICY_CONT_ACT_BIT] )*/ 
MovBits byTempCondByte2, bySynProtCtrl, 2; 	// For default policy set instance id identical to match itself
//MovBits byTempCondByte1, byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_SYN_BITS], 2;                        	// byTempCondByte1 is needed for handling SYN protection later in the code 
//And byTempCondByte2, bySynProtCtrl, byTempCondByte2, 1, MASK_00000003, MASK_BOTH;
//Nop;

// If no match between instance configured on Policy and instance configured on SYN Protection continue to POLICY_PERFORM_ACTION_LAB (Skip SYN protection feature, continue to bdos, oos, etc.)
//JZ POLICY_PERFORM_ACTION_LAB, NOP_2;

Mov uqSynProtCounter, 0, 4;
Nop;
                         
// If instance in SYN_PROT_DEST_STR equals instance configured in policy continue to SYN Protection handling
//If (byTempCondByte2.bit[0]) GetRes uqSynProtCounter, SYN_PROT_RES_INST_0_CID_OFF(SYN_PROT_DEST_STR), 2;
//If (byTempCondByte2.bit[1]) GetRes uqSynProtCounter, SYN_PROT_RES_INST_1_CID_OFF(SYN_PROT_DEST_STR), 2;

GetRes uqSynProtCounter, SYN_PROT_RES_INST_0_CID_OFF(SYN_PROT_DEST_STR), 4;
Mov byTempCondByte1,  0, 1;
Mov byTempCondByte2,  0, 1;
Mov byTempCondByte3,  0, 1;
Mov uqTmpReg6,        0, 4;


// Get timestamp to use in Contender table result from RTC register:
// STAT_RESULT_H.byte[0] is for seconds, STAT_RESULT_L.byte[3] is for second\0xFF -> each unit = 4ms

EZwaitFlag F_SR;

mov uqTmpReg6.byte[0], STAT_RESULT_L.byte[3], 1;
mov uqTmpReg6.byte[1], STAT_RESULT_H.byte[0], 1;


// Decode packet type (SYN\RST\ACK)
MovBits ALU, byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_SYN_BITS], 2;
nop;
decode  ALU, ALU, 1, MASK_00000003, MASK_SRC1;  // This decode ignores the case that byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_SYN_BITS] == 0x3 (ACK with payload), first it will discover only ACK and only then check if it also contains payload
MovBits ENC_PRI.bit[9], 0, 7;
Mov byTempCondByte1, ALU, 1;

// Decode entry configuration bits: Bit[5] - Aut.Table Match, Bit[6] - Aut.Table Lkp, Bit[7] - Config: Syn\Safe Reset
MovBits ALU, bySynProtCtrl.bit[SYN_PROT_CTRL_AUTH_MATCH_BIT], 3;
if (byTempCondByte1.bit[1]) MovBits ALU.bit[0], bySynProtCtrl.bit[SYN_PROT_CTRL_CONTENDER_MATCH_BIT], 1; // If RST packet - use Bit[2] (Cont.Table Match) instead of Bit[5]
Nop;
decode ALU, ALU, 1, MASK_00000007, MASK_SRC1;

MovBits ENC_PRI.bit[9], byTempCondByte1.bit[0], 7;
Nop;
Jmul ERROR_HANDLING_RSV,
     ERROR_HANDLING_RSV,
     ERROR_HANDLING_RSV,
     ACK_PROT_TYPE_LAB,       //byCtrlMsgPrs1[7|6]: 11 (Payload ACK)
     ACK_PROT_TYPE_LAB,       //byCtrlMsgPrs1[7|6]: 10 (Short ACK)
     RST_PROT_TYPE_LAB,       //byCtrlMsgPrs1[7|6]: 01 (RESET)
     SYN_PROT_TYPE_LAB;       //byCtrlMsgPrs1[7|6]: 00 (SYN)

jmp ERROR_HANDLING_RSV, NOP_2;


//////////////////////////////////////////////////////
//  SYN Protection: ACK\RST\SYN Packet Handling
//////////////////////////////////////////////////////

ACK_PROT_TYPE_LAB:

/*
Type: ACK

Config:  Aut. Aut.    Action:
SYN\RST  LKP  Match     
   1      1     1     - Continue
   1      1     0     - Continue
   1      0     1     - n\a
   1      0     0     - n\a 
   0      1     1     - Continue (+ Inc. challenge counter)
   0      1     0     - Handle verified ACK packet according to mode (Transparent Proxy\TCP Reset)
   0      0     1     - n\a
   0      0     0     - Continue 
*/

MovBits ENC_PRI.bit[9], ALU.bit[1], 7;
Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_CHALLENGE_OFFSET, 1;  // For ACK packets increment Challenge Response counter

Jmul POLICY_PERFORM_ACTION_LAB,           //111
     POLICY_PERFORM_ACTION_LAB,           //110
     POLICY_PERFORM_ACTION_LAB,           //101
     POLICY_PERFORM_ACTION_LAB,           //100
     SYN_PROT_INC_CHAL_COUNTER_AND_CONT,  //011
     ACK_RCV_LAB,                         //010
     POLICY_PERFORM_ACTION_LAB;           //001

//case 000
//get the metadata values
mov uqTmpReg6, uqGlobalStatusBitsReg.byte[1] , 2;

//do not mark if there is safe reset configuration
If (bySynProtCtrl.bit[SYN_PROT_CTRL_CHALLENGE_BIT]) Jmp POLICY_PERFORM_ACTION_LAB, NO_NOP;
   //set on the SYN mask bit
   MovBits uqTmpReg6.bit[9], 0x1f , 5;
   Nop;
jmp  POLICY_PERFORM_ACTION_LAB, NOP_1;
PutKey  MSG_POLICY_ID_OFF(HW_OBS)  , uqTmpReg6 ,  2;    


RST_PROT_TYPE_LAB:
/*
Type: RST
 
Config:  Aut. Cont.   Action:
SYN\RST  LKP  Match     
   1      1     1     - Drop packet (+ Inc. challenge counter)
   1      1     0     - Learn Contender entry (+ Inc. challenge counter)
   1      0     1     - n\a
   1      0     0     - n\a
   0      1     1     - n\a 
   0      1     0     - Continue
   0      0     1     - n\a
   0      0     0     - Continue 
*/

MovBits ENC_PRI.bit[9], ALU.bit[1], 7;
Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_CHALLENGE_OFFSET, 1;  // For RST packets increment Challenge Response counter

Jmul FRAME_DROP_LOCAL_LAB,             //111
     SYN_PROT_RST_AUTH_CHECK_LAB,      //110
     POLICY_PERFORM_ACTION_LAB,        //101
     POLICY_PERFORM_ACTION_LAB,        //100
     POLICY_PERFORM_ACTION_LAB,        //011
     POLICY_PERFORM_ACTION_LAB,        //010
     POLICY_PERFORM_ACTION_LAB;        //001
       
jmp  POLICY_PERFORM_ACTION_LAB, NOP_2; //000


SYN_PROT_TYPE_LAB:

/*
Type: SYN

Config:  Aut. Aut.    Action:
SYN\RST  LKP  Match     
   1      1     1     - Continue (+ Inc. SYN authenticated match counter)
   1      1     0     - Send ACK\Drop\Del Contender entry+Learn Auth. entry (Depends on Contender lookup result)
   1      0     1     - n\a
   1      0     0     - n\a 
   0      1     1     - Continue (+ Inc. SYN authenticated match counter) 
   0      1     0     - Send SYN-ACK
   0      0     1     - n\a
   0      0     0     - Send SYN-ACK
*/

MovBits ENC_PRI.bit[9], ALU.bit[1], 7;
Nop;
Jmul SYN_PROT_INC_AUTH_COUNTER_AND_CONT,                    //111
     SYN_PROT_TYPE_CONT_LAB,                                //110
     POLICY_PERFORM_ACTION_LAB,                             //101
     POLICY_PERFORM_ACTION_LAB,                             //100
     SYN_PROT_INC_AUTH_COUNTER_AND_CONT,                    //011
     SYN_PROT_PREPARE_CHALLENGE_AND_INC_COUNTER_LAB,        //010
     POLICY_PERFORM_ACTION_LAB;                             //001
       
jmp SYN_PROT_PREPARE_CHALLENGE_AND_INC_COUNTER_LAB, NOP_2;  //000


// Specific handling for received SYN with challenge = SYN (b7=1), Aut.LKP enabled (b6=1)
SYN_PROT_TYPE_CONT_LAB:

// Test Contender match bit: if match -> instruct TOPmodify to generate ACK challenge (Safe Reset protection is active)
if(!bySynProtCtrl.bit[SYN_PROT_CTRL_CONTENDER_MATCH_BIT]) jmp SYN_PROT_PREPARE_CHALLENGE_AND_INC_COUNTER_LAB, NOP_1;           
    if(!bySynProtCtrl.bit[SYN_PROT_CTRL_CONTENDER_MATCH_BIT]) MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], SYN_PROT_ACK_CHALLENGE_TYPE, 2;

if(bySynProtCtrl.bit[SYN_PROT_CTRL_CONTENDER_VALIDITY_BIT]) jmp FRAME_DROP_LOCAL_LAB, NO_NOP;  // Test Contender entry validation bit
    GetRes uxTmpReg1, SYN_PROT_RES_TS_OFF(SYN_PROT_DEST_STR), 2;  // Get timestamp saved in Contender result
    // For SYN packets that match to invalid Contender entries - increment Bad SYN counter
    if(bySynProtCtrl.bit[SYN_PROT_CTRL_CONTENDER_VALIDITY_BIT]) Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_BAD_SYN_OFFSET, 1;

// 1. Check timestamp validity

#define CONTENDER_INVALID   byTempCondByte3.bit[1];

// Check for wrap around (uxTmpReg1 > uqTmpReg6)
Sub uqTmpReg6, uqTmpReg6, uxTmpReg1, 4, MASK_0000FFFF, MASK_SRC2;
nop;

// Wrap around is not possible logicaly, so if it happened we add a full cycle (0xFF) to the result
if (C) Add uqTmpReg6.byte[1], uqTmpReg6.byte[1], 0xFF, 3;   // Instead of if (C) Add uqTmpReg6, uqTmpReg6, 0xFF00, 4;

// Kind of trick: Use 1 action to put MIN configuration in uxTmpReg1 and MAX configuration in uxTmpReg2
xor uxTmpReg1, ALU, !ALU, 4, SYN_PROT_TS_LIMITS_MREG, MASK_BOTH;       // Get timestamp limits from configuration MREG
MovBits CONTENDER_INVALID, 1, 1;            // Used for setting ctrl_bit[3] in Contender table learn as '1' to indicate invalid entry

// If not valid - increment Bad SYN counter, update entry (validity) and drop packet

// Check if timestamp delta is within MIN limit (if not valid update Contender entry to invalid)
Sub ALU, uqTmpReg6, uxTmpReg1, 2;
GetRes byTempCondByte1, SYN_PROT_RES_TTL_OFF(SYN_PROT_DEST_STR), 1;       // Needed for TTL validation
if (C) jmp SYN_PROT_LRN_CONT_LAB, NO_NOP;
    if (C) GetRes uqTmpReg6, SYN_PROT_RES_TS_OFF(SYN_PROT_DEST_STR), 4;   // Return original entry timestamp value for updating Contender table entry to invalid
    if (C) Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_BAD_SYN_OFFSET, 1;    

// Check if timestamp delta is within MAX limit (if not - update Contender entry to invalid)
Sub ALU, uxTmpReg2, uqTmpReg6, 2;
GetRes byTempCondByte2, MSG_IP_TTL_OFF(MSG_STR), 1;                       // Needed for TTL validation
if (C) jmp SYN_PROT_LRN_CONT_LAB, NO_NOP;
    if (C) GetRes uqTmpReg6, SYN_PROT_RES_TS_OFF(SYN_PROT_DEST_STR), 4;   // Return original entry timestamp value for updating Contender table entry to invalid
    if (C) Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_BAD_SYN_OFFSET, 1;    

// Timestamp validated (within MIN\MAX limits)


// 2. Check TTL validity
                                                                       
// Add 1 to SYN_PROT_RES_TTL_OFF (so subtraction of SYN_PROT_CONT_TTL_OFF - MSG_IP_TTL_OFF valid values should be 0,1,2)
Add byTempCondByte1, byTempCondByte1, 1, 1;
nop;

// Perform SYN_PROT_RES_TTL_OFF - MSG_IP_TTL_OFF
Sub byTempCondByte1, byTempCondByte1, byTempCondByte2, 1;
nop;

// If SYN_PROT_RES_TTL_OFF - MSG_IP_TTL_OFF < 0
if (C) jmp FRAME_DROP_LOCAL_LAB, NOP_1;
    if (C) Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_BAD_SYN_OFFSET, 1;

// Result must be >= 0, so now subtract 3 to validate if it's 0,1,2 (so we must have a Carry, otherwise result > 2 which is not valid)
Sub byTempCondByte1, byTempCondByte1, 3, 1;
nop;
if (!C) jmp FRAME_DROP_LOCAL_LAB, NOP_1;
    if (!C) Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_BAD_SYN_OFFSET, 1;

// TTL validated

// If timestamp & TTL are validated - delete Contender entry and add Authentication entry
Jmp SYN_PRT_DEL_CONT_LAB, NO_NOP;                             
    // For SYN packets that match to a valid Contender entry and its timestamp is validated - increment Good SYN counter
    Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_GOOD_SYN_OFFSET, 1;
    MovBits CONTENDER_INVALID, 0, 1;    // Used for setting ctrl_bit[3] in Contender table learn as '0' to indicate valid entry


//////////////////////////////////////////////////////
//  SYN Protection: SYN packet - increment counter & continue with packet processing
//////////////////////////////////////////////////////

SYN_PROT_INC_AUTH_COUNTER_AND_CONT:

// For SYN packets that match to Authentication entries - increment Authenticated SYN counter
Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_SYN_AUTH_OFFSET, 1;
nop;
EZstatIncrByOneIndexReg uqSynProtCounter;

jmp POLICY_PERFORM_ACTION_LAB, NOP_2;


//////////////////////////////////////////////////////
//  SYN Protection: ACK packet - increment counter & continue with packet processing
//////////////////////////////////////////////////////

SYN_PROT_INC_CHAL_COUNTER_AND_CONT:

if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT]) jmp SYN_PROT_ACK_AUTH_CONT, NOP_2;

#define PD_MATCH_SHORT_ACK_DELTA    (PD_MATCH_SHORT_ACK_OFFSET - PD_MATCH_CHALLENGE_OFFSET); 

// TCP Reset enabled: check TCP Reset mode

// Check cookie verification status != 0
GetRes byTempCondByte1, MSG_SYN_COOKIE_VERIF_OFF(MSG_STR), 1;
nop;
if (!byTempCondByte1.bit[0]) jmp SYN_PROT_ACK_AUTH_CONT, NOP_2;

// If mode == 0 (Short ACK): continue with verified ACK for TCP Reset handling (learn in Auth. table + Inc. challenge counter)
if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT]) jmp SYN_PROT_PREPARE_CHALLENGE_LAB, NOP_1;
   if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT]) MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], SYN_PROT_RST_CHALLENGE_TYPE, 2;   // Instruct TOPmodify to send RST packet 

// Mode == 1 (Payload ACK): check if ACK contains data, if ACK contains data continue with verified ACK for TCP Reset handling (learn in Auth. table + Inc. challenge counter)
if (byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT]) jmp SYN_PROT_PREPARE_CHALLENGE_LAB, NOP_1;
   if (byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT]) MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], SYN_PROT_RST_CHALLENGE_TYPE, 2;   // Instruct TOPmodify to send RST packet  

jmp FRAME_DROP_LOCAL_LAB, NOP_1;
    // If no data -> set bad ACK counter offset (do not increment, it is incremented in the drop label) and drop frame
    Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_SHORT_ACK_DELTA, 1;  // For "Bad ACKs" packets increment Short ACK counter

/*
// If in TCP Reset mode - go to RST challenge generation and do not increment any counter
if (bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT]) jmp SYN_PROT_PREPARE_CHALLENGE_LAB | _NOP1;
    // If TCP Reset mode - generate RST challenge
    if (bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT]) MovBits msgTopModify.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], SYN_PROT_RST_CHALLENGE_TYPE, 2;   // Instruct TOPmodify to send RST packet
*/
#undef PD_MATCH_SHORT_ACK_DELTA;

SYN_PROT_ACK_AUTH_CONT:
// If in Safe Reset mode - For ACK packets that match to Contender entries - increment challenge response counter
// No need to set offset counter here since it was already set before
EZstatIncrByOneIndexReg uqSynProtCounter;
 
jmp POLICY_PERFORM_ACTION_LAB, NOP_2;


//////////////////////////////////////////////////////
//  SYN Protection: Prepare Challenge Generation (ACK\SYN-ACK\RST)
//////////////////////////////////////////////////////

SYN_PROT_PREPARE_CHALLENGE_AND_INC_COUNTER_LAB:

// Increment counter for Non-Authenticated SYN packets (for both ACK & SYN-ACK generation)

Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_SYN_OFFSET, 1;
Nop;
EZstatIncrByOneIndexReg uqSynProtCounter;                        


SYN_PROT_PREPARE_CHALLENGE_LAB:

GetRes uqTmpReg6, SYN_PROT_RES_F1_OFF(SYN_PROT_DEST_STR), 4;

// Prepare challenge - ACK (Safe Reset) \ SYN-ACK (T.Proxy) \ RST (TCP Reset)

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, SYN_POL_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

indirect SYN_POL_DONE_LAB:
PutKey MSG_RST_COOKIE_OFF(HW_OBS), uqTmpReg6, 4;
PutHdr HREG[ 1 ], RSV_FFT_SYN_LKP_HDR;
MovBits byTemp3Byte0.bit[CTX_LINE_OUT_IF]  , 1 , 1;

Copy KMEM_OFFSET ( HW_OBS ),  MSG_VIF_OFF(MSG_STR), 1;
//Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;


#define SYN_COOKIE_ACTION (FRAME_BYPASS_NETWORK | FRAME_SYN_COOKIE_GEN);
jmp SEND_PACKET_LAB, NO_NOP;
   mov byFrameActionReg, SYN_COOKIE_ACTION, 1;
   //Mov OQ_REG, 0, 4; // do we need to update OQ_REG ?
   Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

#undef SYN_COOKIE_ACTION;


//////////////////////////////////////////////////////
//  SYN Protection: Verified ACK Receive Handling 
//////////////////////////////////////////////////////

ACK_RCV_LAB:

#define PD_MATCH_SHORT_ACK_DELTA    (PD_MATCH_SHORT_ACK_OFFSET - PD_MATCH_CHALLENGE_OFFSET);    

// TCP Reset disabled: Learn Authentication entry (+ Inc. challenge counter) and send packet to CPU
if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT]) jmp ACK_RCV_LAB_CONT, NO_NOP;
   //get the metadata values
   mov uqTmpReg6, uqGlobalStatusBitsReg.byte[1] , 2;
   //set on the SYN mask bit
   MovBits uqTmpReg6.bit[9], 0x1f , 5;

// TCP Reset enabled: check TCP Reset mode

// If mode == 0 (Short ACK): continue with verified ACK for TCP Reset handling (learn in Auth. table + Inc. challenge counter)
if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT]) jmp SYN_PROT_LRN_AUT_LAB, NOP_2;

// Mode == 1 (Payload ACK): check if ACK contains data, if ACK contains data continue with verified ACK for TCP Reset handling (learn in Auth. table + Inc. challenge counter)
if (byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT]) jmp SYN_PROT_LRN_AUT_LAB, NOP_2; 

jmp FRAME_DROP_LOCAL_LAB, NOP_1;
    // If no data -> set bad ACK counter offset (do not increment, it is incremented in the drop label) and drop frame
    Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_SHORT_ACK_DELTA, 1;  // For "Bad ACKs" packets increment Short ACK counter
ACK_RCV_LAB_CONT:
// Contunue with marking only for non TCP_RESET mode
jmp SYN_PROT_LRN_AUT_LAB, NOP_1;
   PutKey  MSG_POLICY_ID_OFF(HW_OBS), uqTmpReg6,  2;

#undef PD_MATCH_SHORT_ACK_DELTA;


//////////////////////////////////////////////////////
//  SYN Protection: RST packet additional checks
//////////////////////////////////////////////////////

SYN_PROT_RST_AUTH_CHECK_LAB:
if ( bySynProtCtrl.bit[SYN_PROT_CTRL_AUTH_MATCH_BIT] ) jmp POLICY_PERFORM_ACTION_LAB, NOP_2;
jmp SYN_PROT_LRN_CONT_LAB, NOP_2;


//////////////////////////////////////////////////////
//  SYN Protection: Learning Module
//////////////////////////////////////////////////////

// Delete Contender entry (and then continue to add Authentication entry)
SYN_PRT_DEL_CONT_LAB:

#define MSG_RST_LEARN_KEY_23 (MSG_RST_LEARN_KEY +  4);
#define MSG_RST_LEARN_KEY_45 (MSG_RST_LEARN_KEY +  8);
#define MSG_RST_LEARN_KEY_67 (MSG_RST_LEARN_KEY + 12);

//#define SYN_AUT_ADD_LEN ((SYN_PROT_AUT_LKP_SIZE + SYN_PROT_AUT_RES_SIZE) >> 2);
//#define SYN_AUT_STR_CREATE_OR_UPDATE_HEADER   (((SYN_AUT_ADD_LEN) << LRNIF_LRN_INFO_LEN_BIT) | (1 << LRNIF_ORDER_BIT) | (SYN_PROT_AUT_STR << LRNIF_STR_NUM_BIT ) | (LRNIF_ADD_ENTRY << LRNIF_CMD_BIT) | (LRNIF_CREATE << LRNIF_OVERWRITE_MODE_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (1 << LRNIF_ENTRY_PROFILE_BIT) | (0 << LRNIF_UPDATE_ONLY_BIT) );

   // Put Contender table delete header
   Mov LRN_REG, {LRN_DEL_HDR_CONT & 0xFFFF}, 2;
   Mov ALIAS_LRN_REG.BYTE[ 2 ], {LRN_DEL_HDR_CONT >> 16}, 2;
    	
   GetRes uqTmpReg6, SYN_PROT_RES_F1_OFF(SYN_PROT_DEST_STR), 4;
	EZwaitFlag  F_LN_RSV;

   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY   (MSG_STR), 4;     // Key bytes [0..3]
   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY_23(MSG_STR), 4;     // Key bytes [4..7]
   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY_45(MSG_STR), 4;     // Key bytes [ 8..11]
   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY_67(MSG_STR), 4;     // Key bytes [12..15]
   GetRes LRN_REG.byte[0], MSG_TCP_SPORT_OFF(MSG_STR),    2;     // Key bytes [16..17]
//   GetRes ALIAS_LRN_REG.byte[2], MSG_RST_COOKIE_OFF(MSG_STR), 2; // Key bytes [18..19]
   Mov ALIAS_LRN_REG.byte[2], uqTmpReg6, 2; // Key bytes [18..19]
   Mov LRN_REG, 0,  4; // Key bytes [20]
//   GetRes ALIAS_LRN_REG, MSG_RST_COOKIE_PLUS_2_OFF(MSG_STR),  1; // Key bytes [20]
   Mov ALIAS_LRN_REG, uqTmpReg6.byte[2],  1; // Key bytes [20]

   // Need 3 operations wait between 2 HLearn blocks (delete Contender and add Authentication)
   Mov uqTmpReg6, 0, 4;
   Nop;
   EZwaitNoFlag F_LN_RSV;
   jmp SYN_PROT_LRN_AUT_LAB, NOP_2;    


// Add Contender entry
SYN_PROT_LRN_CONT_LAB:

   // Put Contender table learn header
   Mov LRN_REG, {LRN_ADD_HDR_CONT & 0xFFFF}, 2;
   Mov ALIAS_LRN_REG.BYTE[ 2 ], {LRN_ADD_HDR_CONT >> 16}, 2;
    	
	Nop;
	EZwaitFlag  F_LN_RSV;
	
	// Result bytes [0..3]
   #define CONT_MATCH_BIT    ( (SYN_PROT_CONT_CTRL_2_OFF * 8) + CONTENDER_MATCH_BIT );
   #define REFRESH_BIT    3;
   Mov LRN_REG, { 1<<VALID_BIT | 1<<MATCH_BIT | 1<<REFRESH_BIT | 1<<CONT_MATCH_BIT}, 4;  // Result bytes [0..3]
   Movbits       LRN_REG.byte[SYN_PROT_CTRL_2_OFF].bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT], bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT], 2;  // Add Contender validity bit (for Auth. learn it is set to '0')
   Movbits ALIAS_LRN_REG.byte[SYN_PROT_CTRL_2_OFF].bit[CONTENDER_VALIDITY_BIT], CONTENDER_INVALID, 1;  // Add Contender validity bit (for Auth. learn it is set to '0')

	// Result bytes [4..7]
   Mov LRN_REG, uqTmpReg6,                           	         4;  // Result bytes [4..5], used for timestamp in Contender table
   GetRes ALIAS_LRN_REG.byte[2], MSG_IP_TTL_OFF(MSG_STR),      1;  // Result bytes [6]

	// Result bytes [ 8..15]
   Mov ALIAS_LRN_REG, 0,                                       4;  // Result bytes [ 8..11]
   Mov ALIAS_LRN_REG, 0,                                       4;  // Result bytes [12..15]
	
   // Key bytes [0..20]
   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY   (MSG_STR),      4;  // Key bytes [ 0.. 3]
   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY_23(MSG_STR),      4;  // Key bytes [ 4.. 7]
   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY_45(MSG_STR),      4;  // Key bytes [ 8..11]
   GetRes ALIAS_LRN_REG,   MSG_RST_LEARN_KEY_67(MSG_STR),      4;  // Key bytes [12..15]
   GetRes LRN_REG.byte[0], MSG_TCP_SPORT_OFF(MSG_STR),  		   2;  // Key bytes [16..17]
   GetRes ALIAS_LRN_REG.byte[2], MSG_RST_COOKIE_OFF(MSG_STR),  2;  // Key bytes [18..19]
   Mov    LRN_REG,         0,                                  4;  // Key bytes [20]
   GetRes ALIAS_LRN_REG,   MSG_RST_COOKIE_PLUS_2_OFF(MSG_STR), 1;  // Key bytes [20]

   // If Contender learn (for RST packets) - drop packet after learning
   jmp FRAME_DROP_LOCAL_LAB, NOP_2;


// Learn Authentication or Contender entry (depending on CONTENDER_LRN bit)
SYN_PROT_LRN_AUT_LAB:

   // Put Authentication table learn header
   Mov LRN_REG, {LRN_ADD_HDR_AUTH & 0xFFFF}, 2;
   Mov ALIAS_LRN_REG.BYTE[ 2 ], {LRN_ADD_HDR_AUTH >> 16}, 2;
    		
	Nop;
	EZwaitFlag  F_LN_RSV;
	
	// Result bytes [0..3]
   #define SYN_PROT_AUTH_LKP_BIT    ( (SYN_PROT_AUT_CTRL_2_OFF * 8) + SYN_PROT_AUT_CTRL_RSRVD_BIT );
   Mov LRN_REG, { 1<<VALID_BIT | 1<<MATCH_BIT | 1<<SYN_PROT_AUTH_LKP_BIT }, 4;  // Result bytes [0..3]
   Movbits LRN_REG.byte[SYN_PROT_CTRL_2_OFF].bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT], bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT], 1;   // Add TCP Reset bit
   Movbits ALIAS_LRN_REG.byte[SYN_PROT_CTRL_2_OFF].bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT], bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT], 2; // Add Contender validity bit (for Auth. learn it is set to '0')

	// Result bytes [4..15]
   GetRes ALIAS_LRN_REG, MSG_SYN_COOKIE_OFF(MSG_STR),   4;  // Result bytes [ 4.. 5], put SYN Cookie in the result, mostly used for debugging purposes
   Mov ALIAS_LRN_REG, 0,                                4;  // Result bytes [ 8..11]
   Mov ALIAS_LRN_REG, 0,                                4;  // Result bytes [12..15]
	
   // Key bytes [0..15]
   GetRes ALIAS_LRN_REG, MSG_RST_LEARN_KEY   (MSG_STR), 4;  // Key bytes [ 0.. 3]
   GetRes ALIAS_LRN_REG, MSG_RST_LEARN_KEY_23(MSG_STR), 4;  // Key bytes [ 4.. 7]
   GetRes ALIAS_LRN_REG, MSG_RST_LEARN_KEY_45(MSG_STR), 4;  // Key bytes [ 8..11]
   GetRes ALIAS_LRN_REG, MSG_RST_LEARN_KEY_67(MSG_STR), 4;  // Key bytes [12..15]

   EZstatIncrByOneIndexReg uqSynProtCounter;

// If Auth. learn and TCP Reset Active (this must be verified ACK) - Send RST challenge response
if (bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT]) jmp SYN_PROT_PREPARE_CHALLENGE_LAB, NOP_1;
    // If TCP Reset mode - generate RST challenge
    if (bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT]) MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], SYN_PROT_RST_CHALLENGE_TYPE, 2;   // Instruct TOPmodify to send RST packet

// Else - continue with packet processing
jmp POLICY_PERFORM_ACTION_LAB, NOP_2;

#undef CONTENDER_INVALID;
#undef MSG_RST_LEARN_KEY_23;
#undef MSG_RST_LEARN_KEY_45;
#undef MSG_RST_LEARN_KEY_67;


//////////////////////////////////////////////////////
//  SYN Protection: Drop packet & increment counter
//////////////////////////////////////////////////////

FRAME_DROP_LOCAL_LAB:

EZstatIncrByOneIndexReg uqSynProtCounter;

if( byGlobalStatusBitsReg.bit[POLICY_CONT_ACT_BIT]) jmp FRAME_DROP_LAB, NOP_2;

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, FRAME_DROP_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;


#undef uqSynProtCounter;
#undef bySynProtCtrl;


//////////////////////////////////////////
//   Control Frame Handling
//////////////////////////////////////////

CONTROLFRAME_ACTION_LAB:

   // for debug EZwaitFlag F_ORD;
   // for debug semtake;
   // for debug Mov ORDERING_REG ,1 , 1;

   HighLearnTCPSessions;

   // for debug semgive;
   halt DISC;



//////////////////////////////////////////
//   Perform Policy Action
//////////////////////////////////////////

POLICY_PERFORM_ACTION_LAB:

/*
Mov     uqTmpReg1, 0, 4;
Mov     HW_OBS, 0, 1;
MovBits ENC_PRI.bit[13], uqTmpReg1.bit[0], 3;

MovBits ENC_PRI.bit[13], uqGlobalStatusBitsReg.bit[POLICY_CNG_OOS_BIT], 2;
GetRes  uqBdosL4ValidBitsReg, SIGNA_CNTRL_RES_OFF(BDOS_ATTACK_RESULTS_L23_2_STR), 4;
   
policyPerformActionLab BC_S0G0S0_SEL;
*/
// Don't increment rtm per policy for default policy case
if ( byGlobalStatusBitsReg.bit[POLICY_CONT_ACT_BIT] ) jmp SEND_PACKET_LAB_CPU, NOP_2;

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
   Mov PC_STACK, AFTER_POLICY, 2;
   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

// Finish policy evaluation 
Jmp AFTER_POLICY /*, NOP_2*/;
   Mov     uqTmpReg1, 0, 4;
   //Mov     HW_OBS, 0, 1;
   nop;



//////////////////////////////////////////
//   Frame discard handling
//////////////////////////////////////////

DISCARD_LAB:
indirect FRAME_DROP_LAB:

// RT monitoring drop counters update 
Mov PC_STACK, CONTROL_DISCARD_LAB, 2;
MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1 ;  


//////////////////////////////////////////
//   RT monitoring counters update
//////////////////////////////////////////
#if 1
rtmCountersUpdate_LAB:
//counter structure
// UINT_64 recive;
// UINT_64 drop;
// UINT_64 reciveByte;
// UINT_64 dropByte;

Mov uqTmpReg5, 0, 4;
Mov uqTmpReg3, 0, 4;
// This bit is set for:
// - Global processing bypass mode
// - Packets from HOST
// - For drop case should doesn't matter
if (byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_GLOB_DESC_BIT]) jmp SKIP_RT_CALC, NO_NOP;
    GetRes uqTmpReg5.byte[2], MSG_SRC_PRT_OFF(MSG_STR), 1 ;  // GetRes real offset to counter 
    GetRes uqTmpReg4, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2, RESET;

//Mov ALU , 4 , 4; // ##TODO_OPTIMIZE - what is this line needed for???
if (!byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_RT_EN_BIT]) jmp SKIP_RT_CALC, NO_NOP;
    //GetRes extra shift <<2 MSG_SRC_PRT_OFF message packet (port(7-3) , prot (2-0) )
    MovBits uqTmpReg5.byte[0].bit[1] , uqTmpReg5.byte[2].bit[0] , 8; 
    Mov ALU, RT_MONITOR_BASE_CNTR, 4;
 
//Mov uqTmpReg2 , RT_MONITOR_BASE_CNTR , 4;
Mov2Bits uqTmpReg3.BITS[2,2], byCtrlMsgPrs2.BITS[~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT,~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT]; // uqTmpReg3 = CAUI ? 0 : 4
Add uqTmpReg2, uqTmpReg5, ALU, 4, MASK_0000FFFF, MASK_SRC1;
Sub uqTmpReg4 , uqTmpReg4 , uqTmpReg3 , 4 ,MASK_0000FFFF , MASK_SRC1; //calculate size w/o vlan
MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received
if ( byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT] ) Add uqTmpReg2, uqTmpReg2, 1, 4; 

EZstatPutDataSendCmdIndexReg uqTmpReg2, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1;

SKIP_RT_CALC:

Jstack NOP_2;


//
// Macro for RT monitoring excluded counters update

//exlcude  rtm counters update 
//counter structure
// UINT_64 recive;
// UINT_64 drop;
// UINT_64 reciveByte;
// UINT_64 dropByte;

rtmCountersExcludeUpdate_LAB: 
//counterBase in ALU; 


Mov   uqTmpReg5 , 0 , 4;
Mov   uqTmpReg3 , 0 , 4;

GetRes uqTmpReg5.byte[2], MSG_SRC_PRT_OFF(MSG_STR), 1 ;  // get real offset to counter 
GetRes uqTmpReg4, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2, RESET;



//get extra shift <<2 MSG_SRC_PRT_OFF message packet (port(7-3) , prot (2-0) )
MovBits uqTmpReg5.byte[0].bit[1] , uqTmpReg5.byte[2].bit[0] , 8; 
Mov ALU, RT_MONITOR_EXLUD_BASE_CNTR, 4;
 
//Mov uqTmpReg2 , RT_MONITOR_BASE_CNTR , 4;

Mov2Bits uqTmpReg3.BITS[2,2], byCtrlMsgPrs2.BITS[~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT,~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT];
Add uqTmpReg2, uqTmpReg5, ALU, 4, MASK_0000FFFF, MASK_SRC1;
Sub uqTmpReg4, uqTmpReg4, uqTmpReg3, 4, MASK_0000FFFF, MASK_SRC1; //calculate size w/o vlan
MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received
if ( byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT] ) Add uqTmpReg2, uqTmpReg2, 1, 4; 

EZstatPutDataSendCmdIndexReg uqTmpReg2, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1;

Jstack NOP_2;


//per policy  rtm counters update 
//counter structure
// UINT_64 recive;
// UINT_64 drop;
// UINT_64 reciveByte;
// UINT_64 dropByte;

//XAD_COUNTER64           rtFrameCntr;        receive frame counter 
//XAD_COUNTER64           rtByteCntr;         receive bytes counter 
//XAD_COUNTER64           rtDropFrameCntr;    drop frame counter 
//XAD_COUNTER64           rtDropByteCntr;     drop bytes counter 


rtmCountersPerPolicyUpdate_LAB: 
//counterBase in ALU; 

#define POLICY_RTM_EN_MASK ( 1 << (POLICY_RTM_EN_BIT);
 
//And ALU ,  uqGlobalStatusBitsReg.byte[2] , 0x10 , 2;



// This bit is set for:
// - Global processing bypass mode
// - Packets from HOST
// - For drop case should doesn't matter
Mov   uqTmpReg5 , 0 , 4;
if ( !byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT] ) jmp DROP_COUNTER_LAB, NO_NOP;
    Mov uqTmpReg3, 0, 4;
    GetRes uqTmpReg5.byte[2], MSG_SRC_PRT_OFF(MSG_STR), 1 ;  // get real offset to counter 

//check if recive per policy counter already updated
//$$$$$$$$ should it be first command ?????????????
if ( byGlobalStatusBitsReg.bit[RTM_RECIVED_IND_BIT] ) jmp SKIP_POLICY_RT_CALC, NOP_2; 

DROP_COUNTER_LAB:

GetRes uqTmpReg4, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2, RESET;

//get extra shift <<2 MSG_SRC_PRT_OFF message packet (port(7-3) , prot (2-0) )
MovBits uqTmpReg5.byte[0].bit[1] , uqTmpReg5.byte[2].bit[0] , 8; 

//disable recive counter increment for this policy
if ( byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT] ) MovBits byGlobalStatusBitsReg.bit[RTM_RECIVED_IND_BIT], 1, 1; 

Mov2Bits uqTmpReg3.BITS[2,2], byCtrlMsgPrs2.BITS[~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT,~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT];

//per policy index dosen't need port , therefore in can be overrited by policy
MovBits uqTmpReg5.byte[0].bit[4], uxGlobalPolIdx.bit[0], 16; 
//Mov uqTmpReg2 , RT_MONITOR_BASE_CNTR , 4;

Sub uqTmpReg4, uqTmpReg4, uqTmpReg3, 4, MASK_0000FFFF, MASK_SRC1; //calculate size w/o vlan
Mov ALU, RT_MONITOR_POLICY_BASE_CNTR, 4;
Add uqTmpReg2, uqTmpReg5, ALU, 4, MASK_0000FFFF, MASK_SRC1;
   MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received
if ( byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT] ) //only recive till now 
    Add uqTmpReg2, uqTmpReg2, 1, 4; 

EZstatPutDataSendCmdIndexReg uqTmpReg2, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1;

SKIP_POLICY_RT_CALC:
Jstack NOP_2;
#else
rtmCountersUpdate_LAB:
rtmCountersExcludeUpdate_LAB: 
rtmCountersPerPolicyUpdate_LAB: 
Jstack NOP_2;
#endif


FRAME_RECEIVED_FROM_2ND_NP:

// set MSG_CTRL_TOPRSV_1_INTERLINK_PACKET_BIT bit in message to Top Modify

Jmp TOP_RESOLVE_TERMINATION_LAB, NO_NOP;
   // For frame from peer NP device, no context lines are loaded to Modify, so clear all bits
   // in the INDIRECT_CTX_LOAD register (used in the halt command)
   Mov INDIRECT_CTX_LOAD, 0, 2;

   // for frame from peer NP device, there is no need in any extra information to be calculated.
   // All the information was calculated in TOP Parse. Pass message to TOP Modify
   PutHdr HREG[ 0 ], RSV_MSG_HDR;

  
