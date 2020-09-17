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

#define RTPC_DEBUG_COUNTERS 1

Export   "rsv_labels.h";

LdAggregateENC_PRI TRUE;
LdMsgHdr RSV_MSG_HDR;
LdMsgStr MSG_STR;




#ifdef __comment__
Jmul FRAME_RECEIVED_FROM_2ND_NP,          //OhadM:handling packets from peer NP device  
     FRAME_TP_BYPASS_2NETW_TMP_LAB,       //FRAME_TP_BYPASS_2NETW
     FRAME_BYPASS_CPU_2NETWORK_LOCAL_LAB, //FRAME_HOST_BYPASS_2NETW     
     SPEC_ROUTE,                  //FRAME_CONF_EXTRACT     
     CONT_LAB,                            //FRAME_CONT_ACTION
     FRAME_BYPASS_HOST_LAB_GLOB_TMP_MODE, //FRAME_BYPASS_HOST
     FRAME_BYPASS_NETWORK_LAB,            //FRAME_BYPASS_NETWORK


jmp ERROR_HANDLING_RSV, NOP_2;  // This should never happen

#endif


PUBLIC FRAME_BYPASS_NETWORK_LAB:
FRAME_BYPASS_NETWORK_TRANSPARENT_LAB:

//reset rtpc if jumbo set
//Mov2Bits byTempCondByte3.bits[2,2] , byCtrlMsgPrs0.bits[ ~MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT,~MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT]; 

//nop;
//RTPC is set
If (!RTPC_IS_ENABLED_BIT) jmp SEND_PACKET_LAB, SEND_PACKET_LAB_CPU , NO_NOP;
    MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT], 1, 1;   
    Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;
  
FRAME_BYPASS_NETWORK_TRANSPARENT_CONT: 





//control error treatment 
ERROR_HANDLING_RSV:
// In case frame was shorter than expected
//STAT_OPERATION GC_ERROR_0, 1, EZ_INCR_CMD_STS;
jmp FRAME_DROP_LAB, NOP_2;


PUBLIC FRAME_BYPASS_HOST_LAB_GLOB_TMP_MODE:
if (!byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT]) jmp FRAME_BYPASS_HOST_LAB_GLOB_MODE, NOP_2;


PUBLIC CONT_LAB:

//jmp CONTROL_DISCARD_LAB_CONT , NOP_2;

copy 64( HW_OBS ),  0(FFT_VID_STR), 32;
PutKey   64( HW_OBS ) , 0xF3 , 1;
Putkey   MSG_VIF_OFF(HW_OBS) , UREG[6].byte[2] ,  1;
PutKey  MSG_L3_USR_OFF(HW_OBS) , UREG[4] , 4; 
//PutKey MSG_CTRL_TOPRSV_0_OFF(

MovBits byGlobalStatusBitsReg.bit[SRC_100G_BIT] , byCtrlMsgPrs2Rsv2.BIT[MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT] , 1;

xor uqTmpReg6, ALU, !ALU, 4, RTPC_FILTER_EN, MASK_BOTH;   // Get MREG Value
//Mov ENC_PRI, 0 , 2;
GetCtrlBits UREG[1] ,         STRNUM[ L4SRCPRT_STR ].bit[ MATCH_BIT ] , 
                              STRNUM[ L4DSTPRT_STR ].bit[ MATCH_BIT ],
                              STRNUM[ RTPC_RES_STR ].bit[ MATCH_BIT ], 
                              STRNUM[ RTPC_RES_STR ].bit[ VALID_BIT ];

If ( Z ) jmp  SKIP_RTPC_INIT;
//RTPC structure result + F_PR indication , we need 1 clock to grub bit 12 of ENC_PRI
    Sub ALU , UREG[1] , 3 , 1 ,   MASK_00000003 , MASK_SRC1; 
    //set default disable 
    movBits RTPC_IS_ENABLED_BIT, 0, 2;  //set to 0 both RTPC_IS_ENABLED_BIT and  RTPC_IS_DOUBLE_COUNT_BIT        


If ( !Z )  jmp  SKIP_RTPC_INIT;
    //bits 2-0 l4 type 
    GetRes ALU, EXTERNAL_HEADER_TYPE_RTPC(MSG_STR), 1 ;  // get real offset to counter 
    Decode ALU , ALU , 1 , MASK_00000007 , MASK_SRC1; 
    
GetRes uqTmpReg4, 1(RTPC_RES_STR), 4;

#define L4PRT_UDP_RES 5
#define L4PRT_TCP_RES 1
#define IP_RTPCICMP_RES   7
#define NW_UDP_ANY        5

MovBits ENC_PRI.bit[13] , ALU.bit[1] , 3;

jmul RTPCICMP,RTPCUDP,RTPCTCP,NO_NOP;        
    MovMul IP_RTPCICMP_RES,L4PRT_UDP_RES ,L4PRT_TCP_RES;
    GetRes uqTmpReg5 ,7(RTPC_RES_STR), 3; //7-3bit ICMP , 3-0 bit other
    
RTPCOTHER:
   jmp FINAL_RTPC_RES;        
        Mov uqTmpReg3.byte[0] , uqTmpReg5.byte[1]  , 1;
        Nop;
    

RTPCUDP:
GetRes uqTmpReg4.byte[2] , NW_UDP_ANY(RTPC_RES_STR), 2;

RTPCTCP:
Mov RMEM_OFFSET , ENC_PRO , 2;
Mov ALU , 0 , 4;
Nop;
GetRes  uqTmpReg1 ,RMEM_OFFSET(L4SRCPRT_STR)+  ,2;
If (!UREG[1].bit[3])  Mov  uqTmpReg1 , ALU , 4;

GetRes  uqTmpReg2.byte[0] ,RMEM_OFFSET(L4DSTPRT_STR)  ,2;
If (!UREG[1].bit[2])  Mov  uqTmpReg2 , ALU , 4;

//inputs:
    //UREG[1] bit[3 L4SRC MATCH,2 L4DSTMATCH]
    //uqTmpReg4 [byte 3 TCP/UDP any dport mask , 2  TCP/UDP any sport mask, byte 1-0 fw-bw]  
    //uqTmpReg1 [byte 0-1 TCP/UDP fw-bw ] L4SRC res
    //uqTmpReg2 [byte 2-3 TCP/UDP fw-bw ] L4DST res
    //ALU uqTmpReg3 temporary
    //output uqTmpReg3.byte[0]
    And uqTmpReg3.byte[0] , uqTmpReg1.byte[0] ,uqTmpReg4.byte[0] ,2; //fwd_nw & fwd_sport  and  bwd_nw & bwd_sport    
    Or uqTmpReg5.byte[3] , uqTmpReg1.byte[0] , uqTmpReg2.byte[0] , 1; ////fwd_sport | fwd_dport    
    And uqTmpReg3.byte[2] , uqTmpReg2.byte[0] ,uqTmpReg4.byte[0] ,2; //fwd_nw & fwd_dport  and  bwd_nw & bwd_dport
    Nop;
    Or  ALU.byte[0] , ALU.byte[0] , uqTmpReg3.byte[3], 1;  // dport_fwd | dport_bkwd 

    Or  uqTmpReg3.byte[2] , ALU.byte[0] , uqTmpReg4.byte[3] , 1; //  dport_fwd | dport_bkwd  | dport_any

    Or ALU , uqTmpReg3.byte[0] ,uqTmpReg3.byte[1] ,1; //sport_fwd | sport_bkwd 
    Or ALU , ALU , uqTmpReg4.byte[2] , 1; //  sport_fwd | sport_bkwd  | sport_any
    And uqTmpReg3.byte[0] , ALU , uqTmpReg3.byte[2] , 1;

    jmp FINAL_RTPC_RES;
        Or ALU,uqTmpReg5.byte[3] , uqTmpReg5.byte[2] , 1;   //(l4_table_match_rule | udp_fwd_sport | udp_fwd_dport)   
        And uqTmpReg3.byte[0] , ALU , uqTmpReg3.byte[0]  , 1; 

RTPCICMP:
    Nop;
    MovBits uqTmpReg3.byte[0] , uqTmpReg5.byte[0]  , 1;


FINAL_RTPC_RES:
    mov uxEthTypeMetaData,RTPC_MATCH_DEFAULT, 2;  //instead of nop
    And byRTPCFlags,  uqTmpReg3.byte[0] , uqTmpReg6 ,1;
    Nop;
    If (!Z) movbits RTPC_IS_ENABLED_BIT , 1, 1;


SKIP_RTPC_INIT:

   
//look for Access list results

xadAccessListResolve FRAME_BYPASS_HOST_LAB, 
                     FRAME_BYPASS_NETWORK_TRANSPARENT_LAB,
                     BDOS_OOS_PERFORM_LAB,
                     FRAME_DROP_LAB,
                     FRAME_DROP_LAB, 
                     FRAME_DROP_LAB;

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
#define  uqBdosTempReg  UREG[1];      // 4 bytes
#define  uqTempReg      uqTmpReg5;    // 4 bytes


GetRes uqTmpReg2, { POLICY_HW_ID_OFF }(POLICY_RES_CONF_STR), 2 ;
GetRes uqGlobalStatusBitsReg, { RMEM_POLICY_WORD_1 }(POLICY_RES_CONF_STR) , 4 ;

SHL ALU , uqTmpReg2 , 2, 2;//ALU = POLICY_HW_ID * 4
Sub ALU , ALU , uqTmpReg2 , 2;//ALU = POLICY_HW_ID * 3
SHL uqTempReg , ALU , 5 , 4 ; //uqTempReg = POLICY_HW_ID * 3 *32
xor uqBdosTempReg, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH; // get GC_CNTRL_1_MREG, for BDoS phase (statistical counters phase)

Nop;
If(!uqBdosTempReg.bit[GC_CNTRL_1_BDOS_ACTIVE_BIT])  jmp BDOS_PHASE0 ;
    Mov ALU , BC_BASE , 4 ;  
    Nop;
       
Mov ALU ,  BC_S0G0S1_SEL  , 4;

#undef  uqBdosTempReg;
#define bySigNum                   bySigNumTmpStorage; // 1 byte, defines signature num
#define uqAllSignaToInspectBitmask CTX_REG[1];
#define uqAllNegativeSignaBitmask  uqTmpReg3;
#define uqSignaPolicyBase          uqRSV_TempCTX_REG6; // 4 bytes

BDOS_PHASE0:

//GetRes uqBdosL4ValidBitsReg, { 8 }(POLICY_RES_CONF_STR), 4;

//ALU has BC_BASE or BC_S0G0S1_SEL according to phase
Add uqSignaPolicyBase , uqTempReg , ALU , 4; //uqSignaPolicyBase = BC_BASE + POLICY_HW_ID * 3 *32  (or BC_S0G0S1_SEL if phase 1)(A.K.A POLICY_SIGNATURES_BASE)

if (!byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT]) jmp POLICY_DEFAULT_ACTION_LAB, NO_NOP;//if "don't alayze policy" - jmp to default action
   GetCtrlBits ALU, STRNUM[ POLICY_RES_CONF_STR ].bit[ MATCH_BIT ],STRNUM[ POLICY_RES_CONF_STR ].bit[ MATCH_BIT ], 
                    STRNUM[ POLICY_RES_CONF_STR ].bit[ VALID_BIT ],STRNUM[ POLICY_RES_CONF_STR ].bit[ VALID_BIT ] ;
   Sub ALU , ALU , 7 , 1 , MASK_00000007 , MASK_SRC1 ;//check policy MATCH_BIT and VALID_BIT    


GetRes bytmp0, { POLICY_RTPC_FILTERS_BITMAP_OFF }(POLICY_RES_CONF_STR), 1;
MovBits ALU, uqGlobalStatusBitsReg.bit[POLICY_CNG_ACTION_BIT], 2;//ALU <- policy 2 action bits
MovBits byRTPCPolicyFlags.bit[0] , bytmp0.bit[0], 5;

   
JNZ POLICY_DEFAULT_ACTION_LAB; //no match in policy
    decode ALU, ALU, 1, MASK_00000003, MASK_SRC1;//ALU <- decoded action 
    GetRes uqTmpReg6, { POLICY_UID_OFF }(POLICY_RES_CONF_STR), 2;  // Save policy id in message to be used for Host metadata addition in TOPmodify

MovBits ENC_PRI.bit[13], ALU.bit[0], 4;//ENC_PRI[16-13] = decoded action (only ALU bits 0-3 may be '1')      

//policy match 
//read the result from policy STR, field POLICY_RTPC_FILTERS_BITMAP
//AND with the RTPC result and MREG bits 0-4
//If match - set the uxRTPCFlags
#ifdef RTPC_HARDCODE_ENABLE
MovBits byRTPCPolicyFlags.bit[0] , 0x1F, 5;
Nop;
#endif RTPC_HARDCODE_ENABLE
       
And ALU, byRTPCFlags, byRTPCPolicyFlags, 1;
Nop;
//if not zero no need to mark since it is already marked as RTPC_MATCH_DEFAULT (legit and process)
// if zero it means that we should return it to un marked, RTPC_STANDART_ETH_TYPE (0x8100)
JNZ RTPC_POLICY_CONT, NOP_1;
   MovBits byRTPCFlags, ALU, 5;
  
   JMP RTPC_POLICY_DONE, NO_NOP;
   //if not zero, it means we have at least one enable and match, set the bit of IsRTPCMatchEnable;             
   mov uxEthTypeMetaData,RTPC_STANDART_ETH_TYPE, 2;   
   movbits RTPC_IS_ENABLED_BIT , 0, 1;

RTPC_POLICY_CONT:

   mov uxEthTypeMetaData,RTPC_MATCH_DEFAULT, 2;   
  
   //if not zero, it means we have at least one enable and match, set the bit of IsRTPCMatchEnable;             
   movbits RTPC_IS_ENABLED_BIT , 1, 1;

RTPC_POLICY_DONE:


MovBits uqTmpReg6.bit[9], 0xf , 4;

// Bypass policy action and send frame to CPU in case "Packet Anomalies" instructed sending to CPU after policy lookup
//if (byTempCondByte1.bit[FRAME_BYPASS_HOST_BIT]) jmp SEND_PACKET_LAB_CPU, NO_NOP;        
   //signature bitmask of controller for this policy(from lksd). 
   //The set bit are the local signatures id to be compared with results
   GetRes uqAllSignaToInspectBitmask, { 0x18 }(POLICY_RES_CONF_STR), 4 ;
   GetRes uqAllNegativeSignaBitmask, {POLICY_ALL_NEGETIVE_SIGNATURES}(POLICY_RES_CONF_STR) , 4;
//read bdos result
GetRes byTempCondByte2 , 0x16(POLICY_RES_CONF_STR) , 1;

//according to "US33814 Traffic Filters non-matched design v2_0.docx" Fig.1
Mov uqTempReg,uqAllSignaToInspectBitmask,4;
Or uqAllSignaToInspectBitmask,uqAllSignaToInspectBitmask,uqAllNegativeSignaBitmask,4;//uqAllSignaToInspectBitmask |= uqAllNegativeSignaBitmask
Not uqTempReg,4;//uqTempReg = not(uqAllSignaToInspectBitmask)
//skip counter read for policy only path ( see TS )
    Nop;
    And uqAllNegativeSignaBitmask,uqAllNegativeSignaBitmask,uqTempReg,4;//uqAllNegativeSignaBitmask &= not(uqAllSignaToInspectBitmask)

#undef uqTempReg;

Encode bySigNum , uqAllSignaToInspectBitmask , 4;//bySigNum = number of highest priority signature (from signature bitmask)

If (byTempCondByte2.bit[1])  jmp SKIP_CNTR; 
   SHL ALU , ALU , 2 , 4;//ALU = highest priority signature * 4
   Sub ALU , ALU , bySigNum , 4;//ALU = highest priority signature * 3

//wait for interface ready
EZwaitFlag F_ST;

//prepare for AnalyzeBdosResult  - read policy bdos first signature 
Add SREG_LOW [9] ,  uqSignaPolicyBase , ALU , 4;//SREG_LOW [9] = POLICY_SIGNATURES_BASE(see above) + highest priority signature * 3
movbits    SREG_LOW [1].BYTE [2], ((0x2E << offset_bit(EZstat_StsCmd.bitsOpcode)) | ( 0 << offset_bit(EZstat_StsCmd.bitCtxEnable)) | ( 0 << offset_bit(EZstat_StsCmd.bitsCtxOffset))),     offset_bit(EZstat_StsCmd.bitsReserved_11);
Mov uqTmpReg9, SREG_LOW [9], 4;                          //Update register = First executed Signature base
SKIP_CNTR:


Jmul POLICY_ACTION_BYPASS_LAB,       // Bypass to network after policy handling
     SYN_PROT_LAB,                   // Continue with frame flow (SYN Protection) after policy handling
     POLICY_ACTION_DROP_LAB , NO_NOP;         // Drop frame after policy handling
    Mov uxGlobalPolIdx, uqTmpReg2.byte[0], 2;          // Policy index storage is only 16 bits length
    PutKey MSG_POLICY_ID_OFF(HW_OBS) , uqTmpReg6, 2;

    //Copy MSG_POLICY_ID_OFF(HW_OBS), { POLICY_UID_OFF }(POLICY_RES_CONF_STR), 2;  

                      



//FRAME_BYPASS_HOST_LAB:        
FRAME_BYPASS_HOST_LAB_GLOB_MODE:      
FRAME_BYPASS_HOST_LAB:
jmp SEND_PACKET_LAB_CPU, NO_NOP;
   mov byFrameActionReg, FRAME_BYPASS_HOST, 1;  //set action bypass to host
   nop;


//send packet to network, disable Vlan replace
PUBLIC FRAME_BYPASS_CPU_2NETWORK_LOCAL_LAB:

FRAME_BYPASS_CPU_2NETWORK_LAB:
EZstatIncrByOneIndexImm  GS_TRL_IN_RCV; //increment number of internal packets received on TOP Resolve   

If (bitRSV_isRoutingMode) jmp SKIP_FFT_FROM_HOST_HARDCODED_LAB , NOP_2;
copy KMEM_RSV2SRH2_FFT_KEY_OFF( HW_OBS ),  MSG_SWITCH_VLAN_FROM_HOST(MSG_STR), 2; 

SKIP_FFT_FROM_HOST_HARDCODED_LAB:

jmp SEND_PACKET_LAB_CPU, NO_NOP;    
   Mov byFrameActionReg, FRAME_HOST_BYPASS_2NETW, 1; //set action bypass to network
   Mov byCtrlMsgRsv0 , byCtrlMsgPrs0 , 1;


// Valid for bypass to network              
SEND_PACKET_LAB:
Indirect SEND_TO_CPU: 
    

//aaaaaaaaaaaaaaaaa
//PutHdr HREG[ 1 ], RSV_FFT_VID_LKP_HDR; // TODO_OPTIMIZE: May save a lookup (!) and some more code: maybe the whole lookup may be skipped in routing mode. if so need to cancel the vould key, the lookup in TOPsearch and the code in TOPmodify. before doing that check that the code is not needed in transparent mode, and check that the lookup result is not needed for any other purpose.


jmp DONE_LAB;
    //PutHdr HREG[ 0 ], RSV_MSG_HDR;
    nop;
    Nop;


// The following copies the message from TOPparse and places the external VLAN tag for TOPsearch-II lookup 
Indirect SEND_PACKET_LAB_CPU:

   // Check if packet is GRE keepalive
   GetRes uqTmpReg3.byte[0], MSG_GLOB_CONFIG_OFF(MSG_STR), 1;// Get Message

// Check for Policy Update status
Xor ALU, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH;    // getRes MREG Value
//Nop;
   MovBits byGlobalStatusBitsReg.bit[GRE_KEEPALIVE_BIT], uqTmpReg3.byte[0].bit[MSG_GLOB_CONFIG_GRE_KEEPALIVE], 1; // Get keepalive bit
Movbits ALU.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT], ALU.bit[GC_CNTRL_1_UPD_POL_STATUS_BIT], 1;    // Set Update Policies status

   // NO BYPASS NW for keepalive packets
   If (byGlobalStatusBitsReg.bit[GRE_KEEPALIVE_BIT]) jmp DONE_LAB, NO_NOP;
Or byTempCondByte, ALU.byte[0], byCtrlMsgPrs0, 1;
PutHdr HREG[ 0 ], RSV_MSG_HDR;

//check jumbo flags and Policy Update status

    If (!byTempCondByte.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT]) jmp SEND_PACKET_LAB;
        Mov UREG[1].byte[3] , byFrameActionReg , 1;  
        GetRes byTempCondByte,  MSG_CTRL_TOPPRS_2_OFF(MSG_STR), 2;   // both byCtrlMsgPrs0 and byCtrlMsgPrs1 are initilized here        

If (UREG[1].byte[3].bit[FRAME_HOST_BYPASS_2NETW_BIT]) jmp SEND_PACKET_LAB , NOP_2;
    If (byTempCondByte.bit[MSG_CTRL_TOPPRS_LACP_TYPE_BIT]) jmp SEND_PACKET_LAB , NOP_2;


MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT], 1, 1;   
Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;



FFT_TABLE_TXCOPY_END1_LAB:



jmp  SEND_PACKET_LAB, NO_NOP;
    nop;
    nop;

DONE_LAB: 
  
// RT monitoring receive counters update
// rtmCountersUpdate RT_MONITOR_BASE_CNTR; 
// RT monitoring drop counters update

jmp rtmCountersUpdate_LAB, NO_NOP;
   Mov PC_STACK, RT_DONE_LAB, 2;
   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  


indirect RT_DONE_LAB:


/* ----------------------------------------------------------------------------------------------------  */
/* Routing Table Lookup invoke: should be performed if in routing mode and frame is destined to network. */
/* ----------------------------------------------------------------------------------------------------  */
if (!bitRSV_isRoutingMode) jmp AFTER_ROUTING_TABLE_INDEX_RESULT_CHECK_LAB, NOP_2;

// Check according to byFrameActionReg that packet is destined to network (and not to the host).
// According to Guy when sending to network frameAction should be any of (FRAME_BYPASS_NETWORK | FRAME_HOST_BYPASS_2NETW | FRAME_CONT_ACTION),
// and it is assured that if frameAction is any of these - the frame is not destined to the host.
and ALU, byFrameActionReg, (FRAME_BYPASS_NETWORK | FRAME_HOST_BYPASS_2NETW), 1;
nop;
jz AFTER_ROUTING_TABLE_INDEX_RESULT_CHECK_LAB, NOP_2;


/* This is Routing mode and frame is destined to the network.
   Check the result for the routiung table TCAM:
     -> In case of no match, halt and discard.
     -> In case of match, invoke the lookup from TOPsearch 2 for the routing table entry using the routingTableIndex result. */

//vardef regtype by3RSV_routingTableIndexResultRank uqRSV_TempCTX_REG6.BYTE[0:2];
//vardef regtype byRSV_routingTableIndexResultCtrls uqRSV_TempCTX_REG6.BYTE[3];

//GetRes $byRSV_routingTableIndexResultCtrls, 0(INT_TCAM_STR), 1;
//GetRes $by3RSV_routingTableIndexResultRank, 1(ROUTING_TABLE_INDEX_STR), 3;
GetRes uqTmpReg6 , 0(INT_TCAM_STR), 3 ;
Nop;
/* Verify for the lookup that was done that this is a valid, match, and single match result.
   Note: This will have to be modified when multiple concurent TCAM lookups will be implemented. */
Sub ALU, uqTmpReg6.byte[0], 0x51, 1; // check match from the TCAM lookup, with support future enhancement for concurrent parallel lookups.
Nop;
//sub ALU, ALU, 0x51, 1;
   //and ALU, $by3RSV_routingTableIndexResultRank, $by3RSV_routingTableIndexResultRank, 3, MASK_000007FF, MASK_BOTH;//nop; // take only the 11 LSbits (which represent 2K results (1K + 1K for active and inactive values - double buffer)) for the rank, and mask the higher bits from the returned result.

#pragma EZ_Warnings_Off; // disable data hazard pragma - the tested flag status is for older then previous ALU command, not the last ALU command.
if (FLAGS.bit[F_ZR]) jmp RSV_AFTER_CHECK_ROUTING_TABLE_INDEX_MATCH_LAB;
    and ALU, uqTmpReg6.byte[1], uqTmpReg6.byte[1] , 2, MASK_000007FF, MASK_BOTH;    
    Nop;

#pragma EZ_Warnings_On;
EZstatIncrByOneIndexImm  ROUTING__L_CNTR__ROUTING_TABLE_INDEX_NO_MATCH;
jmp FRAME_DROP_LAB;
    MovBits RTPC_IS_ENABLED_BIT , 0 , 1;
    nop;

RSV_AFTER_CHECK_ROUTING_TABLE_INDEX_MATCH_LAB:


// TCAM Match: The rank (index) is now located in by3RSV_routingTableIndexResultRank. use it to invoke lookup from TOPsearch 2 in the rouing table
//PutHdr HREG[ COM_HBS ], RSV_ROUTING_TABLE_LKP_HDR;

//set routing table search enable in case 
MovBits byTemp3Byte0.bit[CTX_LINE_ROUTING_TABLE_RSLT]  , 1 , 1; 

// Populate the TOPsearch2 RoutingTable key
//PutKey  KMEM_OFFSET (HW_OBS), ALU, 2;

//Add COM_HBS , COM_HBS , 1 , 1;
//Add KMEM_OFFSET , KMEM_OFFSET , RSV_ROUTING_LKP_KEY_SIZE_KMEM_ALIGN , 1;

//varundef by3RSV_routingTableIndexResultRank;
//varundef byRSV_routingTableIndexResultCtrls;


AFTER_ROUTING_TABLE_INDEX_RESULT_CHECK_LAB:

TOP_RESOLVE_TERMINATION_LAB:

/***
store the ethertype for metadata (RTPC) 
intersect with uqRSV_INDIRECT_CTX_LOAD, therefore should be store before the macro.
set the counter
*/
movbits  byRTPCPolicyFlags.bit[0] ,  byRTPCFlags.bit[0],  5;
movbits  byRTPCPolicyFlags.bit[7] ,  RTPC_IS_ENABLED_BIT, 1;
#ifndef RTPC_DEBUG_COUNTERS
Nop;
#else
Movbits ALU, uxEthTypeMetaData.bit[7],5,RESET;
#endif //RTPC_DEBUG_COUNTERS

PutKey MSG_METADATA_RTPC_VAL(HW_OBS), byRTPCPolicyFlags, 1;
If (RTPC_IS_ENABLED_BIT) //RTPC is set
   jmp  TOP_RESOLVE_RTPC_COUNTER, NO_NOP; 
      Mov uqTmpReg3, RTPC_FILTER_CNTR_BASE, 1;
      MovBits uxEthTypeMetaData.bit[0], byRTPCFlags.bit[0], 5; //filter set
       
//RTPC is not set
jmp  TOP_RESOLVE_TERMINATION_AFTER_RTPC, NOP_1;
   mov uxEthTypeMetaData,RTPC_STANDART_ETH_TYPE, 2;  


TOP_RESOLVE_RTPC_COUNTER:

#ifdef RTPC_DEBUG_COUNTERS
Mov uqTmpReg7,RTPC_POSTED_DEBUG_CNTR_BASE,4;
Nop;
Add ALU,ALU,uqTmpReg7,4;
Nop;
//update counter                                        
EZstatPostedLongIncrIndex  ALU , 1;
#endif

   //need only 5b , will return offset of the set the msb
   Encode byTemp3Byte3, byRTPCFlags, 1;

TOP_RESOLVE_RTPC_COUNTER_LOOP: 
Nop;
JZ  TOP_RESOLVE_TERMINATION_AFTER_RTPC, NO_NOP;
   Add uqTmpReg3, uqTmpReg3, byTemp3Byte3, 1;
   //clear the msb  
   Decode ALU, byTemp3Byte3, 1;   
   
Xor byRTPCFlags, byRTPCFlags, ALU, 1;

If (RTPC_IS_DOUBLE_COUNT_BIT) //RTPC double
   jmp  TOP_RESOLVE_RTPC_DOUBLE_COUNTER, NOP_2;       
//update counter                                        
EZstatIncrIndexReg  uqTmpReg3 , 1;           

jmp TOP_RESOLVE_RTPC_COUNTER_LOOP, NO_NOP;
   Mov uqTmpReg3, RTPC_FILTER_CNTR_BASE, 1;
   Encode byTemp3Byte3, byRTPCFlags, 1;
TOP_RESOLVE_RTPC_DOUBLE_COUNTER:
//update counter                                        
EZstatIncrIndexReg  uqTmpReg3 , 2;  
#ifdef RTPC_DEBUG_COUNTERS
Mov uqTmpReg7,RTPC_POSTED_DEBUG_CNTR_BASE,4;
Mov ALU, 0x04, 2; 
Nop;
Add ALU,ALU,uqTmpReg7,4;
Nop;
//update counter                                
EZstatPostedLongIncrIndex  ALU , 1;        
#endif         
jmp TOP_RESOLVE_RTPC_COUNTER_LOOP, NO_NOP;
   Mov uqTmpReg3, RTPC_FILTER_CNTR_BASE, 1;
   Encode byTemp3Byte3, byRTPCFlags, 1;


TOP_RESOLVE_TERMINATION_AFTER_RTPC:
PutKey MSG_METADATA_ETH_TYPE_VAL(HW_OBS), uxEthTypeMetaData, 2;

Mov INDIRECT_CTX_LOAD, 0, 2;
PrepareRsvMsg;         

//Finish handling with non search and jump to the next stage (TOPmodify) 

halt UNIC,
     HW_MSG_HDR;

/*
halt UNIC,
     HW_MSG_HDR,
     LD_CTX_BITMAP 1,
     LD_IGN_CTX_READY 0;
*/            



    

// Send frame to CPU after policy handling or default policy continue handling
DEFAULT_POLICY_ACTION_CONTINUE_LAB:
jmp POLICY_ACTION_SEND_TO_CPU_LAB , NOP_2;

// Continue with frame flow (SYN Protection) after default policy handling
//DEFAULT_POLICY_ACTION_CONTINUE_LAB:
//jmp rtmCountersExcludeUpdate_LAB /*SYN_PROT_LAB, NOP_1*/;
//   Mov PC_STACK, SYN_PROT_LAB, 2;
//   MovBits byGlobalStatusBitsReg.bit[POLICY_CONT_ACT_BIT], 1, 1;



// Drop frame after default policy handling
DEFAULT_POLICY_ACTION_DROP_LAB:
DEFAULT_POLICY_ACTION_ERROR_LAB:
//if RTPC is set, should mark
If (RTPC_IS_ENABLED_BIT) Mov uxEthTypeMetaData, RTPC_POLICY_EXC_DROP , 2;
jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters drop , none supported yet
    Mov PC_STACK, FRAME_DROP_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;  //update recive counters only




// Bypass to network after default policy handling
/*
DEFAULT_POLICY_ACTION_BYPASS_LAB:
jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters recive
    Mov PC_STACK, FRAME_BYPASS_NETWORK_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  //update recive counters only
*/

DEFAULT_POLICY_ACTION_BYPASS_LAB:
//if RTPC is set
If (RTPC_IS_ENABLED_BIT)  Mov uxEthTypeMetaData, RTPC_POLICY_EXC_BYPASS , 2;

if (!bitRSV_isRoutingMode) jmp FFT_TABLE_TXCOPY_END2_LAB;
    
GetRes uqTmpReg6 , 0(INT_TCAM_STR), 3 ;
PutHdr HREG[ COM_HBS ], RSV_ROUTE_ALST_LKP_HDR;
and ALU, uqTmpReg6.byte[1], uqTmpReg6.byte[1] , 2, MASK_000007FF, MASK_BOTH;    
Nop;
PutKey KMEM_OFFSET ( HW_OBS ),  ALU, 2;

FFT_TABLE_TXCOPY_END2_LAB:

MovBits byTemp3Byte0.bit[CTX_LINE_OUT_IF]  , 1 , 1;
Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters recive
    Mov PC_STACK, FRAME_BYPASS_NETWORK_TRANSPARENT_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1; 




/////////////////////////////////////////////////////////////////////////////////////
//    Specific Policy Handling (When there is match in Policy classification)
/////////////////////////////////////////////////////////////////////////////////////

/*
ANALYZE_POLICY:


GetCtrlBits ALU,
            STRNUM[ POLICY_RES_CONF_STR ].bit[ MATCH_BIT ], 
            STRNUM[ POLICY_RES_CONF_STR ].bit[ MATCH_BIT ], 
            STRNUM[ POLICY_RES_CONF_STR ].bit[ VALID_BIT ], 
            STRNUM[ POLICY_RES_CONF_STR ].bit[ VALID_BIT ] ;   

Sub ALU , ALU , 7 , 1 , MASK_00000007 , MASK_SRC1 ;

GetRes byPolicyValidBitsReg, MSG_POLICY_VALIDATION_BITS_OFF( MSG_STR ), 1;

JZ POLICY_ACTION_LAB;
    mov byTempCondByte1, byFrameActionReg, 1;
    Mov ALU, 0, 4;
*/

/////////////////////////////////////////////////////////////////////////////////////
//    Default Policy Handling (When there is no match in Policy classification)
/////////////////////////////////////////////////////////////////////////////////////

POLICY_DEFAULT_ACTION_LAB:

// GuyE, 20.1.2014: Remove NOPS somehow


//////////////////////////////////////////////////////////////////////////////////



xor uqTmpReg1, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH; // Get MREG Value
Mov byTempCondByte2 , byCtrlMsgPrs2Rsv2 , 1; 
Mov ALU , ALU.byte[2] ,  2 ; 
decode  ALU ,  ALU , 1 , MASK_00000003 , MASK_SRC1 ;
Mov uqAllSignaToInspectBitmask , 0 , 4;//Moti: to check - seems not needed
MovBits ENC_PRI.bit[13] , ALU , 3;
Mov     ALU.byte[0], POLICY_CNTR_DEF_POL_BASE, 4;
Add ALU ,  uqTmpReg1.byte[2]  , ALU , 4;



//MovBits ENC_PRI.bit[12], byCtrlMsgPrs2Rsv2.bit[MSG_CTRL_TOPPRS_2_PA_SAMPL_BIT], 1;
//special case PA sampling send 2 CPU in any rate 


//Add     ALU, bytmp0, ALU, 4, MASK_00000003, MASK_SRC1;
//////////////////////////////////////////////////////////////////////////////////


EZstatIncrIndexReg ALU , 1;  //increment this

//default policy for RTPC
xor uqTmpReg5, ALU, !ALU, 4, RTPC_FILTER_EN, MASK_BOTH;   // Get MREG Value
Nop;

And ALU, uqTmpReg5.byte[1], byRTPCFlags, 1;
Nop;
//if not zero no need to mark since it is already marked as RTPC_MATCH_DEFAULT (legit and process)
// if zero it means that we should return it to un marked, RTPC_STANDART_ETH_TYPE (0x8100)
JNZ RTPC_POLICY_EXCLUSIVE_CONT, NOP_2;

   mov uxEthTypeMetaData,RTPC_STANDART_ETH_TYPE, 2;   
   
   //if not zero, it means we have at least one enable and match, set the bit of IsRTPCMatchEnable;             
   movbits RTPC_IS_ENABLED_BIT , 0, 1;

RTPC_POLICY_EXCLUSIVE_CONT:
 
Jmul DEFAULT_POLICY_ACTION_BYPASS_LAB,      // Bypass to network after default policy handling
     DEFAULT_POLICY_ACTION_CONTINUE_LAB,    // Continue with frame flow (SYN Protection) after default policy handling
     DEFAULT_POLICY_ACTION_DROP_LAB , NO_NOP;        // Drop frame after default policy handling
     Nop;
     Nop;

// We should not reach this point!
//jmp DEFAULT_POLICY_ACTION_SEND_TO_CPU_LAB, NOP_2;
// Send frame to CPU after default policy handling
DEFAULT_POLICY_ACTION_SEND_TO_CPU_LAB:
//RTPC- should not change legit+process
jmp rtmCountersExcludeUpdate_LAB, NO_NOP;      //update exclude rtm counters recive
    Mov PC_STACK, SEND_PACKET_LAB_CPU, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;  //update recive counters only



//get policy bitmask
//policy bitmask structure
//Features bitmask               - 8 bits
//PT status per feature bitmask  - 8 bits TBD
//Sampling status per feature    - 8 bits TBD
//PA actions per feature (20 according to Ilia design for NG) - 40 bits TBD



// Drop frame after policy handling
POLICY_ACTION_DROP_LAB:
POLICY_ACTION_ERROR_LAB:
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;    //update exclude rtm counters drop , none supported yet
    Mov PC_STACK, FRAME_DROP_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;


// Send frame to CPU or bypass to network after policy handling
POLICY_ACTION_BYPASS_LAB:

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;    //update exclude rtm counters recive
    Mov PC_STACK, FRAME_BYPASS_NETWORK_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;



AFTER_POLICY:
POLICY_ACTION_SEND_TO_CPU_LAB:
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;    //update exclude rtm counters recive
    Mov PC_STACK, SEND_PACKET_LAB_CPU, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;





//perform global oos result
//OOS_Perform_Action;

//jmp SEND_PACKET_LAB_CPU, NOP_2;

  
indirect CONTROL_DISCARD_LAB:

//RTPC should not change JUMBO frame action
if (byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT]) jmp CONTROL_DISCARD_LAB_CONT, NOP_2;

//if RTPC is set and it is not jumbo frame, send to CPU
If (RTPC_IS_ENABLED_BIT) //RTPC is set
   jmp  SEND_PACKET_LAB_CPU, NOP_2; 


   /////////////////
CONTROL_DISCARD_LAB_CONT:
 /*
   Discardtreatment;
   Mov INC_HLN_ORD, 5, 4; 
   Halt     HALT_DISC;
  */
   /* 2. Recycle and discard the packet. */
   EZrfdRecycleOptimized;
   halt DISC;





//////////////////////////////////////////
//   SYN Protection Handling
//////////////////////////////////////////

SYN_PROT_LAB:

#define bySynProtCtrl      byTempCondByte;
#define uqSynProtCounter   uqTmpReg1;

/* if (!byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_PERFORM_SYN_PROT_BIT])*/
 jmp POLICY_PERFORM_ACTION_LAB, NOP_2;

GetRes byTempCondByte1, SYN_PROT_CTRL_0_OFF(SYN_PROT_DEST_STR), 1; // Get SYN Protection control bits byte[0]
GetRes bySynProtCtrl,   SYN_PROT_CTRL_2_OFF(SYN_PROT_DEST_STR), 1; // Get SYN Protection control bits byte[2]

// If no lookup was performed in SYN_PROT_DEST_STR continue with packet processing
if (!byTempCondByte1.bit[VALID_BIT]) jmp POLICY_PERFORM_ACTION_LAB, NOP_2;

// If lookup in SYN_PROT_DEST_STR was performed but no match continue with OOS
if (!byTempCondByte1.bit[MATCH_BIT]) jmp POLICY_PERFORM_ACTION_LAB, NOP_2;

If (byTempCondByte2.bit[1])  jmp SKIP_BDOS_CNTR, NOP_2;

EZwaitFlag F_SR;

//Store First signature counters
Mov  BDOS_SIG31_CFG_TSTORE,  STAT_RESULT_L , 4;
Mov  uqTmpReg8,              STAT_RESULT_H , 4;

SKIP_BDOS_CNTR: 

// Take RTC timestamp (needs to do it as early as possible since this operation takes a few clocks)
// It is used later for Safe Reset timestamp validation

/*
Mov STAT_REG0, STS_READ_SYS_INFO_CMD__SRC_RTC, 4;
MovBits  ALU , STS_READ_SYS_INFO_CMD , 5 , RESET;
Nop;
Nop;
Mov STAT_CMD, ALU, 2;
*/

/*
Mov STAT_REG0, STS_READ_SYS_INFO_CMD__SRC_RTC, 4;
Nop;
Nop;
Nop;
Mov STAT_CMD, STS_READ_SYS_INFO_CMD, 2;

*/
EZstatSendCmdIndexImm STS_READ_SYS_INFO_CMD__SRC_RTC, STS_READ_SYS_INFO_CMD;




// 2 instances handling:

// Check instance configuration match between Policy & SYN Protection:

//MovBits byTempCondByte2, uqGlobalStatusBitsReg.bit[POLICY_INSTANCE_0_BIT], 2;                      // Get policy configured instance
MovBits byTempCondByte1, byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_SYN_BITS], 2;                        	// byTempCondByte1 is needed for handling SYN protection later in the code 
//And byTempCondByte2, bySynProtCtrl, byTempCondByte2, 1, MASK_00000003, MASK_BOTH;
//Nop;

// If no match between instance configured on Policy and instance configured on SYN Protection continue to POLICY_PERFORM_ACTION_LAB (Skip SYN protection feature, continue to bdos, oos, etc.)
//JZ POLICY_PERFORM_ACTION_LAB, NOP_2;

Mov uqSynProtCounter, 0, 4;
//Nop;
                         
// If instance in SYN_PROT_DEST_STR equals instance configured in policy continue to SYN Protection handling
/*
If (byTempCondByte2.bit[0]) GetRes uqSynProtCounter, SYN_PROT_RES_INST_0_CID_OFF(SYN_PROT_DEST_STR), 2;
If (byTempCondByte2.bit[1]) GetRes uqSynProtCounter, SYN_PROT_RES_INST_1_CID_OFF(SYN_PROT_DEST_STR), 2;
*/
GetRes uqSynProtCounter, SYN_PROT_RES_INST_0_CID_OFF(SYN_PROT_DEST_STR), 4;
Mov byTempCondByte1,  0, 1;
Mov byTempCondByte2,  0, 1;
MovBits byTempCondByte3.bit[0],  0, 2;
Mov uqTmpReg6,        0, 4;


// Get timestamp to use in Contender table result from RTC register:
// STAT_RESULT_H.byte[0] is for seconds, STAT_RESULT_L.byte[3] is for second\0xFF -> each unit = 4ms

EZwaitFlag F_SR;

mov uqTmpReg6.byte[0], STAT_RESULT_L.byte[3], 1;
mov uqTmpReg6.byte[1], STAT_RESULT_H.byte[0], 1;


// Decode packet type (SYN\RST\ACK)
MovBits ALU, byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_SYN_BITS], 2 , RESET;
//nop;
decode  ALU, ALU, 1, MASK_00000003, MASK_SRC1;  // This decode ignores the case that byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_SYN_BITS] == 0x3 (ACK with payload), first it will discover only ACK and only then check if it also contains payload
MovBits ENC_PRI.bit[9], 0, 7;
Mov byTempCondByte1, ALU, 1;

// Decode entry configuration bits: Bit[5] - Aut.Table Match, Bit[6] - Aut.Table Lkp, Bit[7] - Config: Syn\Safe Reset
MovBits ALU, bySynProtCtrl.bit[SYN_PROT_CTRL_AUTH_MATCH_BIT], 3;
if (byTempCondByte1.bit[1]) MovBits ALU.bit[0], bySynProtCtrl.bit[SYN_PROT_CTRL_CONTENDER_MATCH_BIT], 1; // If RST packet - use Bit[2] (Cont.Table Match) instead of Bit[5]
//Nop;
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

MovBits ENC_PRI.bit[13], ALU.bit[1], 3;
Mov   STAT_RESULT_L , BDOS_SIG31_CFG_TSTORE , 4; 
Jmul SYN_PROT_INC_CHAL_COUNTER_AND_CONT,  //011
     ACK_RCV_LAB,                         //010
     POLICY_PERFORM_ACTION_LAB , NO_NOP;           //001
     Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_CHALLENGE_OFFSET, 1;  // For ACK packets increment Challenge Response counter 
     Mov   STAT_RESULT_H , uqTmpReg8 , 4; 

//case 000


//get the metadata values
GetRes uqTmpReg6, { POLICY_UID_OFF }(POLICY_RES_CONF_STR), 2;  

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

Mov   STAT_RESULT_L , BDOS_SIG31_CFG_TSTORE , 4; 
Mov   STAT_RESULT_H , uqTmpReg8 , 4; 

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
Mov   STAT_RESULT_L , BDOS_SIG31_CFG_TSTORE , 4; 
Mov   STAT_RESULT_H , uqTmpReg8 , 4; 

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

if(bySynProtCtrl.bit[SYN_PROT_CTRL_CONTENDER_VALIDITY_BIT]) jmp FRAME_DROP_LOCAL_RTPC_MARKING_LAB, NO_NOP;  // Test Contender entry validation bit
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
if (C) jmp SYN_PROT_LRN_CONT_RTPC_MARK_LAB, NO_NOP;
    if (C) GetRes uqTmpReg6, SYN_PROT_RES_TS_OFF(SYN_PROT_DEST_STR), 4;   // Return original entry timestamp value for updating Contender table entry to invalid
    if (C) Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_BAD_SYN_OFFSET, 1;    

// Check if timestamp delta is within MAX limit (if not - update Contender entry to invalid)
Sub ALU, uxTmpReg2, uqTmpReg6, 2;
GetRes byTempCondByte2, MSG_IP_TTL_OFF(MSG_STR), 1;                       // Needed for TTL validation
if (C) jmp SYN_PROT_LRN_CONT_RTPC_MARK_LAB, NO_NOP;
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
if (C) jmp FRAME_DROP_LOCAL_RTPC_MARKING_LAB, NOP_1;
    if (C) Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_BAD_SYN_OFFSET, 1;

// Result must be >= 0, so now subtract 3 to validate if it's 0,1,2 (so we must have a Carry, otherwise result > 2 which is not valid)
Sub byTempCondByte1, byTempCondByte1, 3, 1;
nop;
if (!C) jmp FRAME_DROP_LOCAL_RTPC_MARKING_LAB, NOP_1;
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
//nop;
EZstatIncrByOneIndexReg uqSynProtCounter;

jmp POLICY_PERFORM_ACTION_LAB;
    Mov   STAT_RESULT_L , BDOS_SIG31_CFG_TSTORE , 4; 
    Mov   STAT_RESULT_H , uqTmpReg8 , 4; 


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
if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT]) jmp SYN_PROT_PREPARE_CHALLENGE_LAB, NO_NOP;
   if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT]) MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], SYN_PROT_RST_CHALLENGE_TYPE, 2;   // Instruct TOPmodify to send RST packet 
   If (RTPC_IS_ENABLED_BIT) mov uxEthTypeMetaData, RTPC_SYN_PRO_DROP , 2;

// Mode == 1 (Payload ACK): check if ACK contains data, if ACK contains data continue with verified ACK for TCP Reset handling (learn in Auth. table + Inc. challenge counter)
if (byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT]) jmp SYN_PROT_PREPARE_CHALLENGE_LAB, NO_NOP;
   if (byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT]) MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], SYN_PROT_RST_CHALLENGE_TYPE, 2;   // Instruct TOPmodify to send RST packet  
   If (RTPC_IS_ENABLED_BIT) mov uxEthTypeMetaData, RTPC_SYN_PRO_DROP , 2;

jmp FRAME_DROP_LOCAL_RTPC_MARKING_LAB, NOP_1;
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
 
jmp POLICY_PERFORM_ACTION_LAB;
    Mov   STAT_RESULT_L , BDOS_SIG31_CFG_TSTORE , 4; 
    Mov   STAT_RESULT_H , uqTmpReg8 , 4; 


//////////////////////////////////////////////////////
//  SYN Protection: Prepare Challenge Generation (ACK\SYN-ACK\RST)
//////////////////////////////////////////////////////

SYN_PROT_PREPARE_CHALLENGE_AND_INC_COUNTER_LAB:

// Increment counter for Non-Authenticated SYN packets (for both ACK & SYN-ACK generation)

//Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_SYN_OFFSET, 1;
//Nop;
EZstatIncrByOneIndexReg uqSynProtCounter;                        

   If (RTPC_IS_ENABLED_BIT) mov uxEthTypeMetaData, RTPC_SYN_PRO_DROP , 2;

SYN_PROT_PREPARE_CHALLENGE_LAB:
//check if RTPC is enabled and mark as double count
If (RTPC_IS_ENABLED_BIT)  movBits RTPC_IS_DOUBLE_COUNT_BIT, 1, 1;
SYN_PROT_PREPARE_CHALLENGE_AFTER_RTPC:

copy { 64 + TX_COPY_IN_VID } ( HW_OBS ),  { TX_COPY_SYN_IN_VID } (FFT_VID_STR), 8;

// Prepare challenge - ACK (Safe Reset) \ SYN-ACK (T.Proxy) \ RST (TCP Reset)
mov byFrameActionReg, FRAME_SYN_COOKIE_GEN , 1;

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, SEND_PACKET_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

//indirect SYN_POL_DONE_LAB:

//jmp SEND_PACKET_LAB, NO_NOP;
   //mov byFrameActionReg, SYN_COOKIE_ACTION, 1;
   //Mov OQ_REG, 0, 4; // do we need to update OQ_REG ?
  // nop;
   //nop;

#undef SYN_COOKIE_ACTION;


//////////////////////////////////////////////////////
//  SYN Protection: Verified ACK Receive Handling 
//////////////////////////////////////////////////////

ACK_RCV_LAB:

#define PD_MATCH_SHORT_ACK_DELTA    (PD_MATCH_SHORT_ACK_OFFSET - PD_MATCH_CHALLENGE_OFFSET);    



// TCP Reset disabled: Learn Authentication entry (+ Inc. challenge counter) and send packet to CPU
if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT]) jmp ACK_RCV_LAB_CONT, NO_NOP;
   //get the metadata values
   GetRes uqTmpReg6, { POLICY_UID_OFF }(POLICY_RES_CONF_STR), 2;  
   //set on the SYN mask bit
   MovBits uqTmpReg6.bit[9], 0x1f , 5;

// TCP Reset enabled: check TCP Reset mode

// If mode == 0 (Short ACK): continue with verified ACK for TCP Reset handling (learn in Auth. table + Inc. challenge counter)
if (!bySynProtCtrl.bit[SYN_PROT_CTRL_TCP_RESET_MODE_BIT]) jmp SYN_PROT_LRN_AUT_LAB, NOP_1;
   If (RTPC_IS_ENABLED_BIT)  Mov uxEthTypeMetaData, RTPC_SYN_PRO_DROP, 2;

// Mode == 1 (Payload ACK): check if ACK contains data, if ACK contains data continue with verified ACK for TCP Reset handling (learn in Auth. table + Inc. challenge counter)
if (byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT]) jmp SYN_PROT_LRN_AUT_LAB, NOP_1; 
    If (RTPC_IS_ENABLED_BIT)  Mov uxEthTypeMetaData, RTPC_SYN_PRO_DROP, 2;

jmp FRAME_DROP_LOCAL_LAB, NO_NOP;
    // If no data -> set bad ACK counter offset (do not increment, it is incremented in the drop label) and drop frame
    Add uqSynProtCounter, uqSynProtCounter, PD_MATCH_SHORT_ACK_DELTA, 1;  // For "Bad ACKs" packets increment Short ACK counter
    //before drop the frame - mark it as RTPC if enable
   If (RTPC_IS_ENABLED_BIT)  Mov uxEthTypeMetaData, RTPC_SYN_PRO_FAIL_DROP , 2;
ACK_RCV_LAB_CONT:
// Contunue with marking only for non TCP_RESET mode
jmp SYN_PROT_LRN_AUT_LAB, NOP_1;
   PutKey  MSG_POLICY_ID_OFF(HW_OBS), uqTmpReg6,  2;

#undef PD_MATCH_SHORT_ACK_DELTA;


//////////////////////////////////////////////////////
//  SYN Protection: RST packet additional checks
//////////////////////////////////////////////////////

SYN_PROT_RST_AUTH_CHECK_LAB:
if ( bySynProtCtrl.bit[SYN_PROT_CTRL_AUTH_MATCH_BIT] ) jmp POLICY_PERFORM_ACTION_LAB;
                                                          Mov   STAT_RESULT_L , BDOS_SIG31_CFG_TSTORE , 4; 
                                                          Mov   STAT_RESULT_H , uqTmpReg8 , 4; 
If (RTPC_IS_ENABLED_BIT)  
   Mov uxEthTypeMetaData, RTPC_SYN_PRO_DROP, 2;

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

SYN_PROT_LRN_CONT_RTPC_MARK_LAB:
   If (RTPC_IS_ENABLED_BIT)   Mov uxEthTypeMetaData, RTPC_SYN_PRO_FAIL_DROP , 2;

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
jmp POLICY_PERFORM_ACTION_LAB;
    Mov   STAT_RESULT_L , BDOS_SIG31_CFG_TSTORE , 4; 
    Mov   STAT_RESULT_H , uqTmpReg8 , 4; 


#undef CONTENDER_INVALID;
#undef MSG_RST_LEARN_KEY_23;
#undef MSG_RST_LEARN_KEY_45;
#undef MSG_RST_LEARN_KEY_67;


//////////////////////////////////////////////////////
//  SYN Protection: Drop packet & increment counter
//////////////////////////////////////////////////////
FRAME_DROP_LOCAL_RTPC_MARKING_LAB:

If (RTPC_IS_ENABLED_BIT)   Mov uxEthTypeMetaData, RTPC_SYN_PRO_FAIL_DROP , 2;
FRAME_DROP_LOCAL_LAB:

EZstatIncrByOneIndexReg uqSynProtCounter;

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, FRAME_DROP_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;


#undef uqSynProtCounter;
#undef bySynProtCtrl;





//////////////////////////////////////////
//   Perform Policy Action
//////////////////////////////////////////

POLICY_PERFORM_ACTION_LAB:


//read bdos structure control bits from Policy structure 
//uqSignaPolicyBase - has Signatures policy counter offset
//uqTmpReg9         - has first executed signature counter offset
     
POLICY_BDOS_LAB:

   GetRes byTempCondByte2 , 0x16(POLICY_RES_CONF_STR) , 1;
   Sub ALU , uqAllSignaToInspectBitmask , 0 , 4;

   //if no match,but only if no negative foriegn controllers, set flag zero 
   If (!byTempCondByte2.bit[4]) Or ALU , uqAllNegativeSignaBitmask , uqAllNegativeSignaBitmask , 4;
   
        
    Nop;

   //match in bdos offset of policy structure 
   JZ AFTER_POLICY;
       Decode ALU,bySigNum,4;
       Nop;
   
POLICY_BDOS_LOOP:

   //uqTmpReg9 - signature base
   //STAT_RESULT_L - signature info ( glob policy id and more )
   //STAT_RESULT_H - group 0 result
   AnalyzeBdosResult bySigNum, uqAllNegativeSignaBitmask;   

   // clear evaluated signature num in the bitmask
   Decode ALU, bySigNum, 4;
   Xor uqAllSignaToInspectBitmask, uqAllSignaToInspectBitmask, ALU, 4;
   Nop;
   JZ AFTER_POLICY;          
      Encode bySigNum, ALU, 4;//bySigNum = next signature to inspect
      SHL ALU, ALU, 2, 4;     //ALU = bySigNum*4
   
   Sub ALU , ALU , bySigNum , 2;              // ALU = Signature offset (Local sigId *3)
   Add uqTmpReg9, ALU, uqSignaPolicyBase, 4;  // BDOS_SIGNA_SEL, ALU <- Signature Absolute Address in phase 0


   //wait for interface ready
   EZwaitFlag F_ST;

   // getRes the first group of the signature
   //EZstatSendCmdIndexReg ALU , STS_READ_CMD;
   Jmp POLICY_BDOS_LOOP;
       mov        SREG_LOW [9], ALU , 4;
       movbits    SREG_LOW [1].BYTE [2], ((0x2E << offset_bit(EZstat_StsCmd.bitsOpcode)) | ( 0 << offset_bit(EZstat_StsCmd.bitCtxEnable)) | ( 0 << offset_bit(EZstat_StsCmd.bitsCtxOffset))),     offset_bit(EZstat_StsCmd.bitsReserved_11)  ;

#undef uqAllNegativeSignaBitmask;   
#undef uqAllSignaToInspectBitmask;
#undef bySigNum;
//////////////////////////////////////////
//   Frame discard handling
//////////////////////////////////////////

indirect FRAME_DROP_LAB:

// RT monitoring drop counters update 
Mov PC_STACK, CONTROL_DISCARD_LAB, 2;

//if marked, skip RTM 
If (RTPC_IS_ENABLED_BIT)  jmp CONTROL_DISCARD_LAB, NOP_2;

MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1 ;



//////////////////////////////////////////
//   RT monitoring counters update
//////////////////////////////////////////

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
Mov2Bits uqTmpReg3.BITS[2,2], byCtrlMsgPrs2Rsv2.BITS[~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT,~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT]; // uqTmpReg3 = CAUI ? 0 : 4
Add uqTmpReg2, uqTmpReg5, ALU, 4, MASK_0000FFFF, MASK_SRC1;
Sub uqTmpReg4 , uqTmpReg4 , uqTmpReg3, 4 ,MASK_0000FFFF , MASK_SRC1; //calculate size w/o vlan
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

Mov2Bits uqTmpReg3.BITS[2,2], byCtrlMsgPrs2Rsv2.BITS[~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT,~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT];
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
    Mov   uqTmpReg3 , 0 , 4;
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

Mov2Bits uqTmpReg3.BITS[2,2], byCtrlMsgPrs2Rsv2.BITS[~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT,~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT]; // uqTmpReg3 = CAUI ? 0 : 4

//per policy index dosen't need port , therefore in can be overrited by policy
MovBits uqTmpReg5.byte[0].bit[4], uxGlobalPolIdx.bit[0], 16; 
//Mov uqTmpReg2 , RT_MONITOR_BASE_CNTR , 4;

Sub uqTmpReg4, uqTmpReg4, uqTmpReg3, 4, MASK_0000FFFF, MASK_SRC1; //calculate size w/o vlan
Mov ALU, RT_MONITOR_POLICY_BASE_CNTR, 4;
Add uqTmpReg2, uqTmpReg5, ALU, 4, MASK_0000FFFF, MASK_SRC1;
   MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received
if ( byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT] ) //only recive till now 
    Add uqTmpReg2, uqTmpReg2, 1, 4; 

//EZstatPutDataSendCmdIndexReg uqTmpReg2, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1;

SKIP_POLICY_RT_CALC:

Jstack NOP_2;


PUBLIC FRAME_RECEIVED_FROM_2ND_NP:

// set MSG_CTRL_TOPRSV_1_INTERLINK_PACKET_BIT bit in message to Top Modify

Jmp TOP_RESOLVE_TERMINATION_LAB, NO_NOP;
   // For frame from peer NP device, no context lines are loaded to Modify, so clear all bits
   // in the INDIRECT_CTX_LOAD register (used in the halt command)
   Mov INDIRECT_CTX_LOAD, 0, 2;

   // for frame from peer NP device, there is no need in any extra information to be calculated.
   // All the information was calculated in TOP Parse. Pass message to TOP Modify
   PutHdr HREG[ 0 ], RSV_MSG_HDR;

//#undef uxGlobalPolIdx;

PUBLIC SPEC_ROUTE:

   GetRes  UREG[1], MSG_SPEC_SUB_ACTION(MSG_STR), 1; // Extract frame action
   
   Nop;
   If (UREG[1].bit[0]) jmp  L_RSV_INBLIM_START;   
// set MSG_CTRL_TOPRSV_1_INTERLINK_PACKET_BIT bit in message to Top Modify
   // For frame from peer NP device, no context lines are loaded to Modify, so clear all bits
   // in the INDIRECT_CTX_LOAD register (used in the halt command)
   PutKey  MSG_ACTION_ENC_OFF(HW_OBS), byFrameActionReg, 1;
   Mov INDIRECT_CTX_LOAD, 0, 2;
   
   If (UREG[1].bit[1]) jmp  L_RSV_PPS_INBLIM_START, NOP_2;      

   // for frame from peer NP device, there is no need in any extra information to be calculated.
   // All the information was calculated in TOP Parse. Pass message to TOP Modify
   PutHdr HREG[ 0 ], RSV_MSG_HDR;


halt UNIC,
     HW_MSG_HDR,
     IND_LD_CTX;
  
L_RSV_PPS_INBLIM_START:

EZstatIncrIndexImm TRAFFIC_LIMIT_INB_PPS_DROP_CNTR_BASE , 1;

GetRes  ALU, 0xA(MSG_STR), 2; // Extract frame len
EZstatIncrIndexReg TRAFFIC_LIMIT_INB_PPS_BYTE_CNTR_BASE, ALU;
                                    
MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;  
//GetRes  ALU, 0xA(MSG_STR), 2; // Extract frame len
//EZstatIncrIndexReg TRAFFIC_LIMIT_INB_BYTE_DROP_CNTR_BASE, ALU;

jmp rtmCountersUpdate_LAB, NO_NOP;  //RT monitoring drop counters update
   Mov PC_STACK, CONTROL_DISCARD_LAB, 2;   
   Nop;



halt UNIC,
     HW_MSG_HDR,
     IND_LD_CTX;

L_RSV_INBLIM_START:


if (!bitRSV_isRoutingMode) Jmp RSV_INBLIM_DROP, NO_NOP;
   GetRes byCtrlMsgPrs2Rsv2,  MSG_CTRL_TOPPRS_2_OFF(MSG_STR), 1;   // initialize byCtrlMsgPrs2Rsv2 (input output register)
   GetRes byCtrlMsgPrs0,  MSG_CTRL_TOPPRS_0_OFF(MSG_STR), 2;       // both byCtrlMsgPrs0 and byCtrlMsgPrs1 are initilized here

    
Mov ALU , 0 , 1;

GetCtrlBits ALU,
            STRNUM[ ROUTING_TABLE_STR ].bit[ MATCH_BIT ], 
            STRNUM[ ROUTING_TABLE_STR ].bit[ MATCH_BIT ], 
            STRNUM[ ROUTING_TABLE_STR ].bit[ 7 ], 
            STRNUM[ ROUTING_TABLE_STR ].bit[ VALID_BIT ] ; 

Sub ALU , ALU , 0xF , 1 , ;
Nop;
JZ MY_IP_DET_INB, NOP_2;  //Jump if my ip is detected


RSV_INBLIM_DROP:

EZstatIncrIndexImm TRAFFIC_LIMIT_INB_DROP_CNTR_BASE , 1;

MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;  
GetRes  ALU, 0xA(MSG_STR), 2; // Extract frame len
EZstatIncrIndexReg TRAFFIC_LIMIT_INB_BYTE_DROP_CNTR_BASE, ALU;

jmp rtmCountersUpdate_LAB, NO_NOP;  //RT monitoring drop counters update
   Mov PC_STACK, CONTROL_DISCARD_LAB, 2;   
   Nop;


MY_IP_DET_INB:
// for frame from peer NP device, there is no need in any extra information to be calculated.
// All the information was calculated in TOP Parse. Pass message to TOP Modify
PutHdr HREG[ 0 ], RSV_MSG_HDR;


halt UNIC,
     HW_MSG_HDR,
     IND_LD_CTX;

