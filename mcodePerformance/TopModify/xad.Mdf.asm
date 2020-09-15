/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Mdf.asm
*
*  Usage:         TOPmodify main file
*
*******************************************************************************/

EZTop Modify;

#include "EZcommon.h"
#include "EZmodify.h"
#include "EZnetwork.h"
#include "EZrfd.h"
#include "EZstat.h"
#include "xad.cntrBase.h"

#include "xad.common.h"
#include "xad.Mdf.h"
#include "xad.Mdf.macros.asm"
#include "xad.portMap.h"

//#define __SIMULATOR__

#define __SANITY_CHECK__

#define ROUTE_BIT 23



//uncomment to disable core distribution
//#define NONE_VLAN_CORE_DISTR

// This is used for loading the HW_MSG that was copied from TOPresolve to TOPmodify
LdMsgStr HW_GEN_MSG_STR;

   

   Mov ENC_PRI, 0, 2;
   GetRes  bytmp1,  MSG_HASH_CORE_OFF(MSG_STR), 1; // get hash
   GetRes  byCtrlMsgMdf0, MSG_CTRL_TOPRSV_0_OFF(MSG_STR), 3; // also get byCtrlMsgMdf1, byCtrlMsgMdf2
   MovBits bytmp2, bytmp1.BIT[4], 4;
   GetRes  byActionReg,   MSG_ACTION_ENC_OFF(MSG_STR), 1;
    

   // Check If packet arrived from peer device and send copy packets to CAUI ports
   If (byCtrlMsgMdf2.BIT[MSG_CTRL_TOPRSV_2_INTERLINK_PACKET_BIT])
      Jmp MDF_PACKET_FROM2ND_NP_LAB , NO_NOP;
         Xor     CAMI, bytmp1, bytmp2, 1, MASK_0000000F, MASK_BOTH;
         LookCam CAMO, CAMI, BCAM8[LINK_DISTRIBUTION_GRP];



   Mov ALU , {1 << 30 }, 4;
   Xor ALU, uqZeroReg, ALU, 4, NP_NUM, MASK_BOTH;

   Nop;



   If (!Z) MovBits byCtrlMsgMdf2.BIT[MSG_CTRL_TOPRSV_2_INTERLINK_PACKET_BIT] , 1 ,1;


Indirect MDF_COPY_PORT_DONE_LAB:

MDF_TRAFFIC_LIMIT_COUNTING:

   //route packet , don't sent it to CPU
   //if (uqTempCondReg.bit[ROUTE_BIT]) jmp DISCARD_LAB , NO_NOP;
       And ALU, byActionReg, { FRAME_TP_BYPASS_2NETW | FRAME_BYPASS_NETWORK | FRAME_CONF_EXTRACT | FRAME_SYN_COOKIE_GEN | FRAME_HOST_BYPASS_2NETW }, 1;
       Mov uqTmpReg2, TRAFFIC_LIMIT_CNTR_BASE, 4;

   If (FLAGS.BIT[F_ZR])
      Jmp MDF_TRAFFIC_LIMIT_COUNTING_DONE, NO_NOP;

         // for TP copy port only, we are not counting frame
         Sub ALU, byCtrlMsgMdf0, { (1 << MSG_CTRL_TOPRSV_0_TP_COPY_PRT_BIT) | (1 << MSG_CTRL_TOPRSV_0_TP_EN_BIT) }, 1, MASK_00000007, MASK_BOTH;
         Nop;

   If (FLAGS.BIT[F_ZR])
      Jmp MDF_TRAFFIC_LIMIT_COUNTING_DONE, NO_NOP;

         // calculate counter address for counting the number of bytes received so far.
         // Since this operation overloads the memory, we use 4 counters to divide the overload accross several memory banks.
         Add uqTmpReg1, UNIT_NUM, uqTmpReg2, 3, MASK_00000003, MASK_SRC1;
         Nop;


   // Note that this counter also counts the VLAN from switch/host
   // TODO: add calculations to avoid counting VLAN/Meetadata bytes
   EZstatIncrIndexReg uqTmpReg1, sSend_uxFrameLen;

MDF_TRAFFIC_LIMIT_COUNTING_DONE:

   Mov ALU , {1 << GC_CNTRL_3_NP_ID_OFF}, 4;
   Xor ALU, uqZeroReg, ALU, 4, NP_NUM, MASK_BOTH;

   Nop;
   If ( FLAGS.BIT[ F_ZR ] )  Xor CAMO , CAMO , 2 , 1;

   If (byCtrlMsgMdf2.BIT[MSG_CTRL_TOPRSV_2_DELAY_DROP_BIT])
      Jmp DISCARD_LAB, NO_NOP;
         // following 2 instructions are from the fallthrough path, assuming the above jmp will not occur often.
         And  ALU , byActionReg , {FRAME_BYPASS_HOST | FRAME_CONT_ACTION  } , 1;
         GetRes bytmp3, MSG_CORE_NUM_OFF(MSG_STR), 1;

#if 1

   GetRes byTempCondByte1, MSG_CORE_NUM_OFF(MSG_STR), 1;
   //Mov uqTmpReg7, IF_PORT_HOST_1, 1;
   GetRes uqTmpReg7.byte[2] , MSG_NP5_INTERFACE_PORT_NUM_OFF(MSG_STR), 2; //get vif out from structure
   GetRes L3_FR_PTR, MSG_L3_USR_OFF (MSG_STR), 2;
   // Only in case of packet to host, a VLAN representing 100G port will be added to packet
   // For packet destinated to network, there will be no VLAN addition.
   // If (byTempCondByte1.BIT[0])
   //   Mov uqTmpReg7, IF_PORT_HOST_0, 1;
    Mov ALU , IF_PORT_HOST_0_HTQE , 1;
   If ( byCtrlMsgMdf2.BIT[MSG_CTRL_TOPRSV_2_INTERLINK_PACKET_BIT] ) Mov ALU , IF_PORT_HOST_0_MRQ , 1;



   // jump in case packet is not directed to host
   Jz CHECK_100G_PORTS_SKIP, NO_NOP;
      Add    uqTmpReg7.byte[0] , CAMO , ALU, 1;
      GetRes L4_FR_PTR, MSG_L4_USR_OFF (MSG_STR), 2; // Initialize L4_FR_PTR for future use, in case it will ever be needed.

   // jump in case packet is not from CAUI port
   If (!byCtrlMsgMdf2.BIT[MSG_CTRL_TOPRSV_2_IS_CAUI_PORT_BIT])
      Jmp  CHECK_100G_PORTS_SKIP, NO_NOP;
         //GetRes byTempCondByte1, MSG_HASH_CORE_OFF(MSG_STR), 1;
         nop;
         //GetRes uqTmpReg7 , MSG_NP5_PPORT_NUM_OFF(MSG_STR) , 1;
         nop;

   // if we reached here, source port is CAUI

   // Assume default select operation for the first host port.
   // Update later if result changed
   //Mov uqTmpReg7, IF_PORT_HOST_0, 1;

   //If (byTempCondByte1.BIT[0])
   //   Mov uqTmpReg7, IF_PORT_HOST_1, 1;
   write -4(L2_FR_PTR), 0(L2_FR_PTR), 12, DISP_UPDATE;
   If (byCtrlMsgMdf1.bit[MSG_CTRL_TOPRSV_1_L3_TUNNEL_EXISTS_BIT])
       GetRes  L3_FR_PTR, MSG_L3_TUN_OFF (MSG_STR), 2;
   MovBits bitMDF_isCAUIport ,1 , 1;
   MovBits uqTmpReg7.byte[2].bit[6] , uqTmpReg7.byte[0].bit[0] , 8;

   Put 12(L2_FR_PTR), 0x8100,    2, SWAP;
   Put 14(L2_FR_PTR), 0x00FF,    2, SWAP;


CHECK_100G_PORTS_SKIP:

//If (byCtrlMsgMdf1.bit[MSG_CTRL_TOPRSV_1_L3_TUNNEL_EXISTS_BIT]) GetRes  L3_FR_PTR, MSG_L3_TUN_OFF (MSG_STR), 2;
//note that since routing code is not done in perforrmance, MSG_CTRL_TOPPRS_3_OFF is not loaded in TopParse with value


vardef regtype byMDF_TempCondByte4_SEARCH_MATCH_BITMAP byTempCondByte4;

And ALU, byActionReg, {FRAME_BYPASS_HOST | FRAME_CONT_ACTION | FRAME_DROP | FRAME_CONF_EXTRACT | FRAME_SYN_COOKIE_GEN | FRAME_HOST_BYPASS_2NETW}, 1; // This mask DOES NOT include FRAME_BYPASS_NETWORK and FRAME_TP_BYPASS_2NETW

//Mov $byMDF_TempCondByte4_SEARCH_MATCH_BITMAP, SEARCH_MATCH_BITMAP, 1; // 2 LSbits are used to tell the match result for 2 lookups that return result to Context lines.
//Get $byMDF_TempCondByte4_SEARCH_MATCH_BITMAP , VID_BASE_MSG(MSG_STR) , 1;
nop;
If (!FLAGS.BIT[F_ZR]) Jmp SKIP_TX_VLAN_LAB;
    GetRes byDstPortReg, MSG_CTRL_TOPPRS_3_OFF(MSG_STR), 1;
    Nop;

//if (bitMDF_isRoutingMode) jmp SKIP_VIF_OUT_STAT_LAB, NOP_2;

/* Now in transparent mode. */
//ignore result temporary. Change it next for ND version
//if (!$byMDF_TempCondByte4_SEARCH_MATCH_BITMAP.BIT[CTX_LINE_OUT_IF]) jmp  FFT_NO_MATCH_LAB;
Mov uqTmpReg5, uqZeroReg, 4;
Nop;

/*
GetRes uqTmpReg2.byte[0], MDF_VIF_INF_OFF(OUT_VID_STR), 1;
   Mov ALU, PERVIF_OUT_BASE, 4;
MovBits uqTmpReg5.bit[1], uqTmpReg2.bit[0], 8;
   nop;
Add uqTmpReg5, ALU, uqTmpReg5, 4;
   Nop;
EZstatIncrIndexReg uqTmpReg5, 1;


SKIP_VIF_OUT_STAT_LAB:
*/
#ifdef __comment__
if (!byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_TP_EN_BIT]) jmp SKIP_TP_PRT_SEL_LAB, NO_NOP;
   MovBits ENC_PRI.bit[14], byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_TP_COPY_PRT_BIT], 2;
      Nop;

Jmul VLAN_FROM_GRP_LAB,
     VLAN_TP_LAB,
     DISCARD_LAB,
     NOP_2;

jmp PRT_SEL_DONE_LAB, NOP_2;


//Send to TP port and static forwarding port (bypass)
VLAN_FROM_GRP_LAB:
EZstatIncrByOneIndexImm TP_CNTRL_PRT_GRP;
if (bitMDF_isRoutingMode) jmp CONTINUE_TST_LAB, NOP_2;

// Now in transparent mode
GetRes uxTmpReg1, MDF_VLAN_TP_AND_BYPASS_OFF(OUT_VID_STR), 2;
jmp CONTINUE_TST_LAB, NOP_1;
   // In routing mode do NOT overwrite the switch VLAN: it should be determined by the routing table result, or should be keapt as was in the frame when handling the SYN protection.
   if (!bitMDF_isRoutingMode) Put ETH_VID_OFF(L2_FR_PTR), uxTmpReg1, 2, SWAP;

//Send to TP port only (drop)
VLAN_TP_LAB:

   // For TP only, use appropriate VLAN value from FFT table
   GetRes uxTmpReg1, MDF_VLAN_TP_ONLY_OFF(OUT_VID_STR), 2;

//   xor ALU, ALU, !ALU, 4, GC_CNTRL_MDF_2, MASK_BOTH; // ##TODO_OPTIMIZE: make the xor on 2 bytes size and destination uxTmpReg1. b4 doing this change, check if uxTmpReg1 is needed at all from this path onward.
//     nop;
//   Mov uxTmpReg1, ALU, 2;

// check if packet needs to be clipped
xor uqTmpReg1, ALU, !ALU, 4, GC_CNTRL_MDF_1, MASK_BOTH;
   nop;
Sub ALU, uqTmpReg1.byte[0], sSend_uxFrameLen, 2;
   nop;

if (!FLAGS.bit[F_SN]) Jmp SKIP_PCKT_CLIP, NO_NOP;
   Sub ALU , sSend_byBuffNum , uqTmpReg1.byte[2] , 2, RFD_RD0_3F_MASK, MASK_BOTH;
   Nop;

Mov sSend_uxFrameLen, uqTmpReg1.byte[0], 2;

jz VLAN_TP_LAB_CONT_NORECYCLE, NO_NOP;
   Sub CNT, uqTmpReg1.byte[2], 1, 1, RFD_RD0_3F_MASK, MASK_SRC1;
   Mov sRfd_uxFramePtr, sSend_uxFramePtr, 2;

// sanity check should be never heppened
js DISCARD_LAB, NOP_2;


GET_RECYCLE_PTR:
EZwaitFlag F_RD;

// Get next RFD pointer
EZrfdReadEntryOptimized;
Mov sRfd_uxFramePtr, sRfdReadEntry_uxNxtPtr, 2;
loop GET_RECYCLE_PTR, NOP_2;

// Recycle from next buffer
Sub sSend_byBuffNum, sSend_byBuffNum, uqTmpReg1.byte[2], 2, RFD_RD0_3F_MASK, MASK_SRC1;
EZrfdRecycle RFD_RD0, sSend_byBuffNum, sSend_bySrcPort;


VLAN_TP_LAB_CONT_NORECYCLE:
// Set number of buffers to required
Movbits sSend_byBuffNum, uqTmpReg1.byte[2], 5;

// Validate if configured is one buff only
Sub ALU, uqTmpReg1.byte[2], 1, 2;
   Nop;
JNZ SKIP_PCKT_CLIP, NO_NOP;
    Sub ALU, uqTmpReg1.byte[0], 1, 2;
    Nop;
// Update first buffer len field
Mov sSend_ux1stBufLen, ALU, 2;


SKIP_PCKT_CLIP:
EZstatIncrByOneIndexImm TP_CNTRL_CP_PRT;
jmp CONTINUE_TST_LAB, NOP_1;
   // In routing mode do NOT overwrite the switch VLAN: it should be determined by the routing table result, or should be keapt as was in the frame when handling the SYN protection.
   if (!bitMDF_isRoutingMode) Put ETH_VID_OFF(L2_FR_PTR), uxTmpReg1, 2, SWAP;



SKIP_TP_PRT_SEL_LAB:
jmp CONTINUE_TST_LAB, NO_NOP;
   if (bitMDF_isRoutingMode) jmp CONTINUE_TST_LAB, NOP_2;
   //Copy ETH_VID_OFF(L2_FR_PTR), MDF_VIF_TX_VLAN_OFF(OUT_VID_STR), 2, SWAP; // only performed in transparent mode
    Nop;

#endif /* __comment__ */






CONTINUE_TST_LAB:
PRT_SEL_DONE_LAB:
SKIP_TX_VLAN_LAB:

#define CNTRL_MDF_DSTR_TYPE_BIT_VAL_OFF        0; // important: must be bit 0, as this specific bit is used in few more lines in the code
#define FRAME_2HOST_TYPE                      (FRAME_BYPASS_HOST | (1 << CNTRL_MDF_DSTR_TYPE_BIT_VAL_OFF) );
#define FRAME_CONT_TYPE                       (FRAME_CONT_ACTION | (1 << CNTRL_MDF_DSTR_TYPE_BIT_VAL_OFF));
#define FRAME_BYPASS_HOST_OR_CONT_ACTION_TYPE (FRAME_BYPASS_HOST | FRAME_CONT_ACTION);

if (byActionReg.bit[FRAME_SYN_COOKIE_GEN_BIT]) jmp SYN_COOKIE_GEN_LAB, NO_NOP;
   And bytmp2, byActionReg, FRAME_BYPASS_HOST_OR_CONT_ACTION_TYPE, 1;
   xor ALU, ALU, !ALU, 4, GC_CNTRL_MDF, MASK_BOTH;
      //nop;
// Get new traffic distribution enable by changing the VLAN if sending to the host or continue, and if enabled by MREG
//##TODO_OPTIMIZE - the following block code can still be rewriten to work more efficiently.
Nop;
MovBits bytmp2.bit[CNTRL_MDF_DSTR_TYPE_BIT_VAL_OFF], ALU.bit[CNTRL_MDF_DSTR_TYPE_OFF], 1; // Sets the value of bit 0 according to host configuration. when this value is '1' this will enable the jumps to change the VLAN soon if other conditions are met as well.
   GetRes bytmp1, MSG_SRC_PORT_OFF(MSG_STR), 1; //##TODO_OPTIMIZE: this line is probably not needed as bytmp1 is not used. may be replaces with a nop for other optimization or with any other line.
Sub ALU, bytmp2, FRAME_CONT_TYPE, 1;     // FRAME_CONT_TYPE = bits 0 and 2 are set (FRAME_BYPASS_HOST)
   Get uxTmpReg1, ETH_VID_OFF(L2_FR_PTR), 2, SWAP;
Jz CHANGE_SWITCH_VLAN_FOR_CPU_SIDE_LAB, NO_NOP;
   Sub ALU, bytmp2, FRAME_2HOST_TYPE, 1; // FRAME_2HOST_TYPE = bits 0 and 1 are set (FRAME_CONT_ACTION)
      Nop;
Jz CHANGE_SWITCH_VLAN_FOR_CPU_SIDE_LAB, NOP_2;


//##TODO_OPTIMIZE - check if changing the code to check VALID and MATCH in a single action can improve performance. // and ALU, ALU, ((1 << MDF_ROUTING_TABLE_RSLT__CONTROLS__VALID_BIT) | (1 << MDF_ROUTING_TABLE_RSLT__CONTROLS__MATCH_BIT)), 1;
//##TODO_OPTIMIZE - check if the code can be rewritten so that it will not need to check the MY_IP twice, in 2 separate locations (here and in routing procedure under label MDF_BYPASS2NW_ROUTE_FRAME_MODIFICATION_LAB)

// The next code block handles only frames destined to network
/*  If routingTable Lookup result valid bit is set this means that a lookup in routing table was invoked.
    This can happen only when in routing mode and the frame is destined to network or in case of frame with IP TO_ME.
    In this case, at this stage only check if frame.DIP = IP_TO_ME. in case it is switch the VLAN accordig tot he configuraiton set in MREG.
    The routing procedure will be performed in a later phase. */
// Check routing mode
if (!bitMDF_isRoutingMode) jmp MDF_SKIP_VLAN_CHANGE_LAB, NO_NOP;
   GetRes ALU, MDF_ROUTING_TABLE_RSLT__CONTROLS_OFF(MDF_ROUTING_TABLE_RSLT_STR), 1;
   and ALU, ALU, (1 << MDF_ROUTING_TABLE_RSLT__CONTROLS__VALID_BIT), 1;
// Check if both routing mode and CNTRL_MDF_DSTR_TYPE_BIT_VAL_OFF is set to allow VLAN modification.
and ALU, ALU, bytmp2, 1; // bytmp2.bit 0 holds the MREG configuration that allows VLAN modification before sending it to the host.
   GetRes ALU, MDF_ROUTING_TABLE_RSLT__APP_CONTROLS_OFF(MDF_ROUTING_TABLE_RSLT_STR), 1;
      jz MDF_SKIP_VLAN_CHANGE_LAB, NOP_2;
and ALU, ALU, (1 << MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__IS_MY_IP_BIT), 1;
   // Now check if RoutingTable match and MY_IP bit is set - if all tests are true then change the VLAN.
   //if (!$byMDF_TempCondByte4_SEARCH_MATCH_BITMAP.BIT[CTX_LINE_ROUTING_TABLE_RSLT]) jmp MDF_ROUTING_TABLE_NO_MATCH_LAB, NOP_2;
// At this stage we know that this is routing mode, there is routing lookup match, it is a MY_IP frame
// (meaning it should be sent to the host), and MREG is configured to allow the VLAN modification.
// Jump to the code location that changes the VLAN.
nop;
jnz CHANGE_SWITCH_VLAN_FOR_CPU_SIDE_LAB, NOP_2;
#undef FRAME_BYPASS_HOST_OR_CONT_ACTION_TYPE;
#undef FRAME_CONT_TYPE;
#undef FRAME_2HOST_TYPE;


MDF_SKIP_VLAN_CHANGE_LAB:
CONTINUE_TO_CPU_LAB:
/* This part is common both to frames going to the CPU and frames destined to the Network */
// Test case of black list sample action type and change DMAC accordinally
if (byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_ALIST_SAMPL_BIT]) jmp CHANGE_DST_MAC_LAB, NOP_2;

SEND_LAB:
// ------------------------------------------------------------------------------------------------------
/*  If routingTable Lookup result valid bit is set this means that a lookup in routing table was invoked.
    This can happen only when in routing mode and the frame is destined to network or in case of frame with IP TO_ME.
    In this case jump to the routing handle label. */
// Check routing mode
if (!bitMDF_isRoutingMode) jmp SEND_METADATA_MODE_CHECK_LAB, NO_NOP;
   GetRes ALU, MDF_ROUTING_TABLE_RSLT__CONTROLS_OFF(MDF_ROUTING_TABLE_RSLT_STR), 1;
   and ALU, ALU, (1 << MDF_ROUTING_TABLE_RSLT__CONTROLS__VALID_BIT), 1;
      nop;
jnz MDF_BYPASS2NW_ROUTE_FRAME_MODIFICATION_LAB, NOP_2;
// ------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------
/*  If routingTable Lookup result isn't valid bit, check if this is a GRE with IP TO_ME.
    This code will work when no match in the routing table or match with IP TO_ME condition */

SEND_METADATA_MODE_CHECK_GRE_LAB:

#define  GRE_COPY_SIZE 8    // one basic copy block size



GetRes byTempCondByte1, MSG_CTRL_TOPPRS_2_OFF(MSG_STR), 1;

Nop;

SEND_METADATA_MODE_CHECK_LAB:
Mov ENC_PRI, 0, 2;
xor byTempCondByte1, ALU, !ALU, 1, GC_CNTRL_MDF, MASK_BOTH;
Mov3Bits ENC_PRI.bits[12,13,14], byActionReg.bits[FRAME_CONT_ACTION_BIT, FRAME_BYPASS_HOST_BIT, FRAME_HOST_BYPASS_2NETW_BIT];
If (!byTempCondByte1.bit[CNTRL_MDF_METADATA_EN_OFF]) Movbits ENC_PRI.bit[15], 1, 1;
GetRes uxTmpReg1, MSG_POLICY_ID_OFF(MSG_STR), 2;

Jmul SEND_CHECK_BPASS_COUNTER_INC_LAB,
     SEND_REM_METADATA_LAB,
     SEND_ADD_METADATA_LAB,
     SEND_ADD_METADATA_LAB,
     DISCARD_LAB,
     DISCARD_LAB,
     DISCARD_LAB;

// If no jump was made continue as before (this case should not be reached)
Jmp SEND_CHECK_BPASS_COUNTER_INC_LAB, NOP_2;

// Add metadata to frame sent to Host
SEND_ADD_METADATA_LAB:
Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 16, DISP_UPDATE;
// Set default Traffic Filter id
MovBits uxTmpReg1.bit[9], 0xF , 4;
nop;
Jmp SEND_CONTINUE_LAB, NO_NOP;
   Put HOST_METADATA_PROT_OFF(L2_FR_PTR), 0x8100,    2, SWAP;
   Put HOST_METADATA_VAL_OFF(L2_FR_PTR) , uxTmpReg1, 2, SWAP;

// Remove metadata from frame received from Host
SEND_REM_METADATA_LAB:

Write 4( L2_FR_PTR ), 0( L2_FR_PTR ), 16, DISP_UPDATE;
nop;
nop;

// Check if bypass counter should be incremented
SEND_CHECK_BPASS_COUNTER_INC_LAB:
if (!byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT]) jmp SEND_CONTINUE_LAB, NOP_2;

EZstatIncrByOneIndexReg GS_TMD_EX_TRN;

SEND_CONTINUE_LAB:
   #define     uqTxInfo       uqTmpReg1;

   // Check whether frames goes to network or host
   And  ALU , byActionReg , { FRAME_BYPASS_NETWORK | FRAME_SYN_COOKIE_GEN | FRAME_HOST_BYPASS_2NETW | FRAME_TP_BYPASS_2NETW }, 1;
   Nop;

   // If frame goes to host, just add TM header and send it.
   // For network direction, the TX copy port information has to be processed first
   Jz  L_MDF_ADD_TM_HDR, NO_NOP;
      //
      Xor ALU, uqZeroReg, {1 << GC_CNTRL_3_TRAFFIC_LIMIT_OFF}, 4, GC_CNTRL_MDF_3, MASK_BOTH;
      Nop;

   // If traffic limit bit is turned on (in MREG), and frame goes to network - it should be dropped
   // Assume that no traffic limit happens and jump to normal path. If this is not the case, next
   // command will force jump to the drop label
   Jmp MDF_TX_COPY_PORT_LAB, NO_NOP;
      Jnz  MDF_TRAFFIC_LIMIT_REACHED_LAB, NO_NOP;
      Mov uqTmpReg2, TRAFFIC_LIMIT_DROP_CNTR_BASE, 4;

MDF_TRAFFIC_LIMIT_REACHED_LAB:

   // calculate counter address for counting the number of frames dropped so far.
   // Since this operation overloads the memory, we use 4 counters to divide the overload accross several memory banks.
   Add uqTmpReg1, UNIT_NUM, uqTmpReg2, 3, MASK_00000003, MASK_SRC1;
   Mov uqTmpReg2, TRAFFIC_LIMIT_BYTE_DROP_CNTR_BASE , 4;

   EZstatIncrIndexReg uqTmpReg1, 1;

   Add uqTmpReg2, UNIT_NUM, uqTmpReg2, 3, MASK_00000003, MASK_SRC1;
   nop;
   EZstatIncrIndexReg uqTmpReg2, sSend_uxFrameLen;

   If ( byActionReg.bit[FRAME_SYN_COOKIE_GEN_BIT] ) jmp SKIP_OPTIMIZED_RECYCLING_LAB , NOP_2;
   EZrfdRecycleOptimized;
   Halt DISC;
SKIP_OPTIMIZED_RECYCLING_LAB:
   EZrfdRecycle sSend_uxFramePtr, sSend_byBuffNum, sSend_bySrcPort;

   Halt DISC;


L_MDF_ADD_TM_HDR:

// update the Displacement register to include the TM at the beginning of the packet

//update select FID according output port

//Put 6(tmpFR_PTR), byTempCondByte3, 1;

Mov sSend_byDstPort, uqTmpReg7.byte[0], 1;
AddTMHeaderToHostOutPort;



L_MDF_SEND_FRAME:

jmp DISCARD_LAB , NO_NOP;
// Send the frame and finish the program


#if GLOBAL_RTM_IN_TOP_MODIFY
Mov uqTmpReg5, 0, 4;
GetRes uqTmpReg5.byte[2], MSG_SRC_PRT_OFF(MSG_STR), 1 ;  // GetRes real offset to counter
GetRes uqTmpReg4, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2, RESET;
MovBits uqTmpReg5.byte[0].bit[1] , uqTmpReg5.byte[2].bit[0] , 8;
Mov ALU, RT_MONITOR_BASE_CNTR+1, 4;
Add uqTmpReg2, uqTmpReg5, ALU, 4, MASK_0000FFFF, MASK_SRC1;
Sub uqTmpReg4, uqTmpReg4, 4,   4 ,MASK_0000FFFF, MASK_SRC1; //calculate size w/o vlan
MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received
EZstatPutDataSendCmdIndexReg uqTmpReg2, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1;
#endif

halt UNIC,
     WR_FR_MEM,
     HW_OPTIMIZE;


#ifdef __SANITY_CHECK__
MDF_TX_COPY_PORT_ERROR_LAB:

/* increment this special counter in case when Rx,Tx table logical error exist */

EZstatIncrByOneIndexImm GS_TMD_EX_TX_RX_DRP ;

#endif /* __SANITY_CHECK__ */

DISCARD_LAB:
EZstatIncrByOneIndexImm GS_TMD_EX_DRP ;
EZrfdRecycleOptimized;

#if GLOBAL_RTM_IN_TOP_MODIFY
Mov uqTmpReg5, 0, 4;
GetRes uqTmpReg5.byte[2], MSG_SRC_PRT_OFF(MSG_STR), 1 ;  // GetRes real offset to counter
GetRes uqTmpReg4, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2, RESET;
MovBits uqTmpReg5.byte[0].bit[1] , uqTmpReg5.byte[2].bit[0] , 8;
Mov ALU, RT_MONITOR_BASE_CNTR, 4;
Add uqTmpReg2, uqTmpReg5, ALU, 4, MASK_0000FFFF, MASK_SRC1;
Sub uqTmpReg4, uqTmpReg4, 4,   4 ,MASK_0000FFFF, MASK_SRC1; //calculate size w/o vlan
MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received
EZstatPutDataSendCmdIndexReg uqTmpReg2, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1;
#endif

halt DISC;


SYN_COOKIE_GEN_LAB:
CreateSynCookiePacket_GRE;
Mov FMEM_BASE0 , 0 , 2;
/* Requirement: When in routing mode, for the SYN protection to work, set the dest port (Switch VLAN) back to src port. */
//##TODO_OPTIMIZE: when SYN_PROTECTION is active, check if can cancel the OUT_VID_STR lookup in both routing and transparent mode.
jmp SEND_METADATA_MODE_CHECK_LAB, NO_NOP;
   if (bitMDF_isRoutingMode) jmp SEND_METADATA_MODE_CHECK_LAB, NOP_2;
   /* Only overwrite the Switch VLAN in transparent mode. In routing mode keep the source port (switch VLAN) as it is.
      This will cause the frame to be sent back to the port it came from.
      At this stage, we have SYN_Protection in Transparent mode */
   //Copy ETH_VID_OFF (L2_FR_PTR), MDF_VLAN_TX_OFF(OUT_VID_STR), 2, SWAP;
   Nop;


CHANGE_SWITCH_VLAN_FOR_CPU_SIDE_LAB:
GetRes bytmp3, MSG_CORE_NUM_OFF(MSG_STR), 1;
GetRes bytmp1, MSG_SRC_PORT_OFF(MSG_STR), 1;

// Implemented a new solution:
// VLAN in the following format: [0-4: ACC core][4-10: 0][11-15: port number].
// ACC core should be 1,2,3
Add bytmp3, bytmp3, 1, 1;
MovBits uxTmpReg1.bit[11], bytmp1,        5, RESET;
MovBits uxTmpReg1.bit[0],  bytmp3,        4;
jmp CONTINUE_TO_CPU_LAB, NOP_1;
   Put ETH_VID_OFF(L2_FR_PTR), uxTmpReg1, 2, TCP_CHK, SWAP;


//update destination MAC with metadata
CHANGE_DST_MAC_LAB:
jmp SEND_LAB, NO_NOP;
   //Copy METADATA_HIGH_OFFS (L2_FR_PTR), MSG_ALIST_STAMP_INFO_TOP_MODIFY(MSG_STR), 2, NO_JPE, _NO_CHK_MDF, _NO_CHK_MDF, _SWAP;
   Copy METADATA_HIGH_OFFS(L2_FR_PTR), MSG_ALIST_STAMP_INFO_TOP_MODIFY(MSG_STR), 4, SWAP;
   Copy METADATA_LOW_OFFS (L2_FR_PTR), MSG_ALIST_SAMPL_INFO_TOP_MODIFY(MSG_STR), 2, SWAP;


//*****************************************************************************************
// Route frame: perform frame modification as required: Update SMAC and DMAC,
// update the Switch VLAN and the User Vlan according to configuration,
// decrement TTL (IPv4) /Hop Limit (IPv6) (and discard frame if after decrement the value is zero),
// and update IPv4 header checksum if TTL update was performed.
// TODO_INTEGRTION: should we also updates the transmit statistics counters for outgoing VIF id?

MDF_BYPASS2NW_ROUTE_FRAME_MODIFICATION_LAB:
//if (!$byMDF_TempCondByte4_SEARCH_MATCH_BITMAP.BIT[CTX_LINE_ROUTING_TABLE_RSLT]) jmp MDF_ROUTING_TABLE_NO_MATCH_LAB, NOP_2;
varundef byMDF_TempCondByte4_SEARCH_MATCH_BITMAP;


EZstatIncrByOneIndexImm ROUTING__L_CNTR__ROUTING_TABLE_MATCH ;
// -----------------------------------------------------------------------
// The order of frame modifications/routing operations is as follows:
// 1. If my IP punt to host without any modifications.
// 2. TTL/HOP Count update + discard if needed + IPv4 header checksum update due to the TTL change.
// 3. User vlan updates (add/remove/modify)
// 4. Switch vlan updates (set output port).
// 5. MAC addresses settings from the results.
// -----------------------------------------------------------------------

/* -------------------- */
/*      Is MY_IP?       */
/* -------------------- */
GetRes ALU, MDF_ROUTING_TABLE_RSLT__APP_CONTROLS_OFF(MDF_ROUTING_TABLE_RSLT_STR), 1;
And ALU, ALU, (1 << MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__IS_MY_IP_BIT), 1;
   Mov ENC_PRI, 0, 2; //nop;
MovBits ENC_PRI.bit[14], byCtrlMsgMdf1.bit[MSG_CTRL_TOPRSV_1_IS_IPV4_BIT], 2;
Jnz MDF_ROUTING_TABLE_MY_IP_LAB, NOP_2;

/* ------------------------------ */
/* Handle TTL / HOP count update. */
/* ------------------------------ */
/* In order to handle the TTL / HOP count, first need to determine if the frame is IPv4 or IPv6. */

Jmul L_MDF_IPV6_HOP_COUNT_HANDLE_LAB,
     L_MDF_IPV4_TTL_HANDLE_LAB,
     L_MDF_NOT_IP_FRAME_LAB,
     NOP_2;


L_MDF_NOT_IP_FRAME_LAB:
/* Fall through or jump due to unexpected value in ENC_PRI - anyway guaratnedd that this is not IPv4 and not
   IPv6 frame. Frames that are not IP frames should never arrive to the routing modul's frame modification code.
   This is an error - count and discard the frame. */
EZstatIncrByOneIndexImm ROUTING__L_CNTR__NOT_IPVX_FRAME_DISC ;
Jmp DISCARD_LAB, NOP_2;



L_MDF_IPV6_HOP_COUNT_HANDLE_LAB:
/* IPv6 - Handle Hop Count */
Get ALU, IPv6_HOP_LIMIT_OFF(L3_FR_PTR), 1;
Sub ALU, ALU, 1, 1;
   Nop;
Jnz HOP_COUNT_TTL_HANDLING_DONE_LAB, NOP_1;
   // HOP_COUNT was 1 and now zero: discard the frame.
   Put IPv6_HOP_LIMIT_OFF(L3_FR_PTR), ALU, 1;

// Fall through
/* HOP_COUNT_EXPIRED */
EZstatIncrByOneIndexImm ROUTING__L_CNTR__TTL_OR_HOP_EXP_DISC;
jmp DISCARD_LAB, NOP_2;


L_MDF_IPV4_TTL_HANDLE_LAB:
/* IPv4 - Handle TTL. The IP TTL change will affect the checksum of the frame, for this reason start checksum update here. */
// Read the current value of check sum from the frame.
Get CHK_SUM_IP, IP_CHK_OFF(L3_FR_PTR), 2;
Get ALU, IP_TTL_OFF(L3_FR_PTR), 1, IP_CHK;
Sub ALU, ALU, 1, 1;
   Nop;
Put IP_TTL_OFF(L3_FR_PTR), ALU, 1, IP_CHK;
Jnz HOP_COUNT_TTL_HANDLING_DONE_LAB, NO_NOP;
   Nop; // to allow CHK_SUM_IP update
   // HOP_COUNT was 1 and now zero: discard the frame.
   Put IP_CHK_OFF(L3_FR_PTR), CHK_SUM_IP, 2; // update also the IP header checksum as it should be changed due to the TTL field change.

// Fall through
/* TTL_EXPIRED */
EZstatIncrByOneIndexImm ROUTING__L_CNTR__TTL_OR_HOP_EXP_DISC;
Jmp DISCARD_LAB, NOP_2;

HOP_COUNT_TTL_HANDLING_DONE_LAB:
/* ------------------------------------------------------------------------------------------------------------ */


/* ------------------------------------------- */
/* Handle GRE encapsulation and decapsulation  */
/* ------------------------------------------- */


#define MDF_TEMP_COND_BYTE1__IS_GRE_DECAP_REQUIRED_BIT MSG_CTRL_TOPPRS_2_IS_GRE_DECAP_REQUIRED_BIT;
#define MDF_TEMP_COND_BYTE1__IS_GRE_ENCAP_REQUIRED_BIT 2;
GetRes ALU, MDF_ROUTING_TABLE_RSLT__APP_CONTROLS_OFF(MDF_ROUTING_TABLE_RSLT_STR), 1;
   GetRes byTempCondByte1, MSG_CTRL_TOPPRS_2_OFF(MSG_STR), 1;
movbits byTempCondByte1.bit[MDF_TEMP_COND_BYTE1__IS_GRE_ENCAP_REQUIRED_BIT], ALU.bit[MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__IS_GRE_ENCAP_REQUIRED_BIT], 1;

if (byTempCondByte1.bit[MDF_TEMP_COND_BYTE1__IS_GRE_DECAP_REQUIRED_BIT]) jmp L_MDF_REMOVE_GRE_LAB, NOP_2;

L_MDF_AFTER_GRE_REMOVE_LAB:
if (byTempCondByte1.bit[MDF_TEMP_COND_BYTE1__IS_GRE_ENCAP_REQUIRED_BIT]) jmp L_MDF_ADD_GRE_LAB, NOP_2;

L_MDF_AFTER_GRE_HANDLE_LAB:


/* ------------------------------------------------------------------------------------------------------------ */
/* Handle the User Vlans (add / modify / remove), according to user VLAN existance in the frame and the result  */
/* ------------------------------------------------------------------------------------------------------------ */

/* Fixing typos in EZnetwork.h */
#define ETH_PROT1_OFF                     ETH_PTOT1_OFF;
#define ETH_PROT2_OFF                     ETH_PTOT2_OFF;
#define ETH_PROT3_OFF                     ETH_PTOT3_OFF;
#define ETH_PROT4_OFF                     ETH_PTOT4_OFF;
#define L2_ETYPE_PLUS_VLANID_FIELD_SIZE   4;
#define L2_ETYPE_PLUS_VLANID_FIELD_SIZE_2 8;

#define uqUSER_VLAN                       uqTmpReg6;


// Check if user vlans exists in the frame.
And ALU, byCtrlMsgMdf1, (1<<MSG_CTRL_TOPRSV_1_USER_VLAN_IN_FRAME_BIT), 1;
GetRes ALU, MDF_ROUTING_TABLE_RSLT__APP_CONTROLS_OFF(MDF_ROUTING_TABLE_RSLT_STR), 1, RESET;

Jnz MDF_ROUTING_USER_VLAN_EXIST_IN_FRAME_LAB, NO_NOP; // Jump if user VLAN exists
   And ALU, ALU, (1 << MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__USER_VLAN_ADD_OR_CHANGE_BIT), 1;   // Check add/change control bit
   GetRes uqUSER_VLAN, MDF_ROUTING_TABLE_RSLT__USER_VLAN_ETHERTYPE_OFF(MDF_ROUTING_TABLE_RSLT_STR), L2_ETYPE_PLUS_VLANID_FIELD_SIZE;

// User vlan does NOT exists case:

Jz MDF_AFTER_USER_VLAN_HANDLING_LAB, NOP_2; // Add/change control bit not set -> finish user vlan handling


// User vlan does NOT exists and add/change control bit is set: add user vlan from the frame

MDF_ADD_USER_VLAN_LAB:



If ( byActionReg.bit[FRAME_HOST_BYPASS_2NETW_BIT] ) jmp MDF_ADD_USER_VLAN_LAB_CONT, NO_NOP;

   Add L3_FR_PTR, L3_FR_PTR, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 2;        // L3 and L4 frame pointers (relevant FMEM_BASEs) are also updated to reflect this change.
   Add L4_FR_PTR, L4_FR_PTR, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 2;


// Case without metadata

Write {ETH_PROT1_OFF - L2_ETYPE_PLUS_VLANID_FIELD_SIZE}(L2_FR_PTR), ETH_PROT1_OFF(L2_FR_PTR), L2_ETYPE_PLUS_VLANID_FIELD_SIZE; // Keep the Switch VLAN EtherType. The Switch VLAN Tag will be overwritten from the result soon, so actually no need to keep the existing switch vlan value from the frame, but this does not harm.
nop;
nop;
Jmp MDF_AFTER_USER_VLAN_HANDLING_LAB, NO_NOP;
   Put ETH_PROT1_OFF(L2_FR_PTR), uqUSER_VLAN, L2_ETYPE_PLUS_VLANID_FIELD_SIZE;  // Set the user VLAN from the result
   Sub DISP_REG, DISP_REG, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 1;


// Case with metadata

MDF_ADD_USER_VLAN_LAB_CONT:

Write {ETH_PROT1_OFF - L2_ETYPE_PLUS_VLANID_FIELD_SIZE}(L2_FR_PTR), ETH_PROT1_OFF(L2_FR_PTR), L2_ETYPE_PLUS_VLANID_FIELD_SIZE_2; // Keep the Switch VLAN and Metadata EtherType. The Switch VLAN Tag will be overwritten from the result soon, so actually no need to keep the existing switch vlan value from the frame, but this does not harm.
nop;
nop;
Jmp MDF_AFTER_USER_VLAN_HANDLING_LAB, NO_NOP;
   Put ETH_PROT2_OFF(L2_FR_PTR), uqUSER_VLAN, L2_ETYPE_PLUS_VLANID_FIELD_SIZE;  // Set the user VLAN from the result
   Sub DISP_REG, DISP_REG, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 1;


MDF_REMOVE_USER_VLAN_LAB:

// User VLAN exists and add/change bit is NOT set: remove user vlan from the frame.
// This is done using copy of the switch VLAN into the User VLAN and adding to DISP_REG 4 bytes (==L2_ETYPE_PLUS_VLANID_FIELD_SIZE), to cut a single VLAN from the frame.
// L3 and L4 frame pointers (relevant FMEM_BASEs) are also updated to reflect this change.
// The MAC addresses and Switch VLANs are left untouched, as these will be written from the result later on anyway.


If ( byActionReg.bit[FRAME_HOST_BYPASS_2NETW_BIT] ) jmp MDF_REMOVE_USER_VLAN_LAB_CONT, NO_NOP;
   Sub L3_FR_PTR, L3_FR_PTR, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 2; // Note: MSG_L3_TUN_OFF in the message is not going to be updated and thus going to be outdated after this change. This does not bother us, as its value from the message will be used ONLY BEFORE performfing the frame modifications.
   Sub L4_FR_PTR, L4_FR_PTR, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 2;


// Case without metadata
Write ETH_PROT2_OFF(L2_FR_PTR), ETH_PROT1_OFF(L2_FR_PTR), L2_ETYPE_PLUS_VLANID_FIELD_SIZE; // Actually no need to copy all the 4 bytes, only the first 2 bytes of the VLAN ethertype, as the switch vtag will be written anyway later on from the routig result, but writing the hwole 4 bytes does not cause any affect on performance not on the final result.
jmp MDF_AFTER_USER_VLAN_HANDLING_LAB, NO_NOP;
   nop;
   Add DISP_REG, DISP_REG, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 1;


// Case with metadata

MDF_REMOVE_USER_VLAN_LAB_CONT:
Write ETH_PROT3_OFF(L2_FR_PTR), ETH_PROT2_OFF(L2_FR_PTR), L2_ETYPE_PLUS_VLANID_FIELD_SIZE; // Actually no need to copy all the 4 bytes, only the first 2 bytes of the VLAN ethertype, as the switch vtag will be written anyway later on from the routig result, but writing the hwole 4 bytes does not cause any affect on performance not on the final result.
jmp MDF_AFTER_USER_VLAN_HANDLING_LAB, NO_NOP;
   nop;
   Add DISP_REG, DISP_REG, L2_ETYPE_PLUS_VLANID_FIELD_SIZE, 1;


// User vlan exists case:

MDF_ROUTING_USER_VLAN_EXIST_IN_FRAME_LAB:
Jz MDF_REMOVE_USER_VLAN_LAB, NOP_2; // Jump if add/change control bit is NOT set

// User vlan exists and add/change bit is set: change the user vlan (the user vlan in this case is the second vlan from the beginning of the frame)
If ( byActionReg.bit[FRAME_HOST_BYPASS_2NETW_BIT] ) Put ETH_PROT3_OFF(L2_FR_PTR), uqUSER_VLAN, L2_ETYPE_PLUS_VLANID_FIELD_SIZE; // Set the user VLAN from the result with metadata
If (!byActionReg.bit[FRAME_HOST_BYPASS_2NETW_BIT] ) Put ETH_PROT2_OFF(L2_FR_PTR), uqUSER_VLAN, L2_ETYPE_PLUS_VLANID_FIELD_SIZE; // Set the user VLAN from the result

MDF_AFTER_USER_VLAN_HANDLING_LAB:

/* ------------------------------------------------------------------------------------------------------------ */
/* Set the the outer Switch VLAN with the Switch VLAN (port) value from the routing Table Result.               */
/* ------------------------------------------------------------------------------------------------------------ */

GetRes ALU, MDF_ROUTING_TABLE_RSLT__PORT_OFF(MDF_ROUTING_TABLE_RSLT_STR), 2, RESET;
   nop;
Put ETH_VID1_OFF(L2_FR_PTR), ALU, 2;

/* ------------------------------------------------------------------------------------------------------------ */
/* Update MAC addresses from the routing Table Result.                                                          */
/* ------------------------------------------------------------------------------------------------------------ */
copy ETH_DA_OFF(L2_FR_PTR), MDF_ROUTING_TABLE_RSLT__DMAC_OFF(MDF_ROUTING_TABLE_RSLT_STR), 12;

/* ------------------------------------------------------------------------------------------------------------ */
/* If IPv4, update the IP checksum.                                                                             */
/* ------------------------------------------------------------------------------------------------------------ */
// Already performed when the TTL was updated.

jmp SEND_METADATA_MODE_CHECK_LAB, NOP_2;



MDF_ROUTING_TABLE_MY_IP_LAB:
/* MY_IP frame: punt it to the host via Token Bucket. */
// ------------------------------------------------------------------------------------------------------------------
#ifndef AA_DEBUG_DISABLE_MY_IP_TO_HOST_TB_MECHANISM;
// ##GUY maybe a test to check if the frame came from host should be added in order to prevent circulation deadlock of frame that comes from host with MY_IP will be sent to the host due to wrong configuration - from from host with MY_IP bit set?
/* Check if we are below the maximum punt rate */
EZstatPutDataSendCmdIndexImm  ROUTING_MY_IP_TB, ROUTING_IS_MY_IP_SIZE_CONST, STS_GET_COLOR_CMD;
   Nop;
EZwaitFlag F_SR;
and ALU, STAT_RESULT_L, RED_COLOR_MASK_VAL, 1;
   nop;
// If we have exceeded sampling rate for current packet - drop it
jnz L_MDF_MY_IP_TB_DISC, NOP_2;
#endif; // of #ifndef AA_DEBUG_DISABLE_MY_IP_TO_HOST_TB_MECHANISM;
// ------------------------------------------------------------------------------------------------------------------

// Increment MY_IP frames counter
EZstatIncrByOneIndexImm ROUTING__L_CNTR__IS_MY_IP_SEND_TO_CPU;

Mov byActionReg, FRAME_BYPASS_HOST, 1;

// Check if need to Add metadata
Jmp SEND_METADATA_MODE_CHECK_GRE_LAB, NO_NOP;
   // Spread the frames between port 0 and 1 of host instance #0 using the calculated flow from TOPresolve
   Mov byDstPortReg, HOST_INST0_P0, 1;
   If ( byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_CPU_PORT_BIT]) mov byDstPortReg, HOST_INST0_P1, 1;

// Discard packet to CPU due to CPU Token Bucket threshold
L_MDF_MY_IP_TB_DISC:
EZstatIncrByOneIndexImm ROUTING__L_CNTR__IS_MY_IP_TB_DISC;
jmp DISCARD_LAB, NOP_2;


L_MDF_REMOVE_GRE_LAB:
// Remove the outer IPv4.RadwareTunnelGRE

// Since we remove the IPv4.GRE, we take 24 bytes out from the beginning of L3.
// Copy the last 12 bytes of L2, which will include all the data that should be preserved.
// This includes up to 3 VLANs: the switch VLAN, and optionaly up to 2 user VLANs, if exist in the frame.
// It will exclude the innestVlan.NxtProtocolType, but include the MAC.NxtProtocolType.
// The DMAC and SMAC are not kept, as these will be overwritten anyway with value from the result.
// The copy will start from the MAC.NxtProtocolType field, and will not include the EtherType of the innest VLAN.
// This way the NxtProtoclType of the GRE that is about to be removed will be preserved. It will become the Vlan.NxtProtocolType,
// and as a result the outcome will be that the innest Vlan.NxtProtocolType will hold the correct value of the following L3 EtherType. //##GUY_GRE_DECAP_AND_KEEPALIVE_IPv4_OPTIONS_SUPPORT

// Note: when arriving to L_MDF_REMOVE_GRE_LAB, the L3 offset was manually updated by IPV4_AND_RADWARE_TUNNEL_GRE_SIZE bytes,
// in order to point to the L3 level after the IPv4.GRE. Therefore this is also taken into calculation for the removal offsets in the frame.

Write {-IPV4_AND_RADWARE_TUNNEL_GRE_SIZE+IPV4_AND_RADWARE_TUNNEL_GRE_SIZE-2-12}(L3_FR_PTR), {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE+12+2)}(L3_FR_PTR), 12; // multiple command, takes 2 clocks (8 bytes per clock).  //##GUY_GRE_DECAP_AND_KEEPALIVE_IPv4_OPTIONS_SUPPORT
nop;
Sub L3_FR_PTR, L3_FR_PTR, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2; // Update L3_FR_PTR for future use.  //##GUY_GRE_DECAP_AND_KEEPALIVE_IPv4_OPTIONS_SUPPORT
jmp L_MDF_AFTER_GRE_REMOVE_LAB, NO_NOP;
   add DISP_REG, DISP_REG, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2;  //##GUY_GRE_DECAP_AND_KEEPALIVE_IPv4_OPTIONS_SUPPORT
   Sub L4_FR_PTR, L4_FR_PTR, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2; // Update L4_FR_PTR for future use, if any...  //##GUY_GRE_DECAP_AND_KEEPALIVE_IPv4_OPTIONS_SUPPORT


L_MDF_ADD_GRE_LAB:

// Add IPv4.RadwareTunnelGRE

// Copy the last 12 bytes of L2, which will include all the data that should be preserved.
// This includes up to 3 VLANs: the switch VLAN, and optionaly up to 2 user VLANs, if exist in the frame.
// It will exclude the innestVlan.NxtProtocolType, but include the MAC.NxtProtocolType.
// The DMAC and SMAC are not kept, as these will be overwritten anyway with value from the result.
Write {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE+12+2)}(L3_FR_PTR), -(12+2)(L3_FR_PTR), 12; // multiple command, takes 2 clocks (8 bytes per clock).  //##GUY_GRE_DECAP_AND_KEEPALIVE_IPv4_OPTIONS_SUPPORT -- should ip options handling be implemented here as well?
nop;
// Set the last (innest) vlan.nxt_protocol_type field to IPv4
Put {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE+2)}(L3_FR_PTR), 0x0800, 2, SWAP; // EtherType for next protocol type = IPv4

// Populate the IPv4 header field.
// Clear the IP checksum register to prepare it to start calculating the added IP header's checksum.
Mov CHK_SUM_IP, 0, 2;


// Build and update the added IPv4 header and the radware GRE to the frame.
// Start by calculating the IP length field. this shuld be the legth of the frame, including the IP header, excluding the bytes that come before it.
Sub ALU, sSend_uxFrameLen, L3_FR_PTR, 2;
Add ALU, ALU, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2;
Put {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE    )}(L3_FR_PTR), 0x4500, 2, SWAP, IP_CHK; // IP version + IHL
Put {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE - 2)}(L3_FR_PTR), ALU,    2, SWAP, IP_CHK; // 2 bytes for IPv4.TotalLen

// As OAM_RELEASED_BUFFER_PTR is not used for its purpose, it is a 16 bits RW register, and it is not cleared between frames, it will be used as a register that remembers that sequence number - uxMDF_IPv4HeaderIdentification.
#pragma EZ_Warnings_Off; // in order to prevent warning of using uninitialized register
Mov ALU, $uxMDF_IPv4HeaderIdentification, 2;
#pragma EZ_Warnings_On;
// the 5 MSbits are taken from the unit (engine) number, in order to prevent repeat of values from diferent engines at TOPmodify.
MovBits ALU.bit[11], UNIT_NUM, 5;
   Put {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE-6 )}(L3_FR_PTR), 0x0000, 2, SWAP, IP_CHK; // Flags + Frag. Offset //   Nop;
Put    {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE-4 )}(L3_FR_PTR), ALU, 2, SWAP, IP_CHK; // 2 bytes for IPv4.Identification
Put    {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE-8 )}(L3_FR_PTR), 0x412F, 2, SWAP, IP_CHK; // TTL=65 + NextProtocolType=GRE. //##AMIT_TOTEST check if no need to swap.
Copy   {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE-12)}(L3_FR_PTR), MDF_ROUTING_TABLE_RSLT__TUNNEL_SIP_OFF(MDF_ROUTING_TABLE_RSLT_STR), 8, IP_CHK; // SIP + DIP from the RoutingTable result.
   // Increment $uxMDF_IPv4HeaderIdentification by 1 for the next frame. // (Using nop time to allow CHK_SUM_IP upodate before writing it to the frame)
   #pragma EZ_Warnings_Off; // in order to prevent warning of using uninitialized register
   add $uxMDF_IPv4HeaderIdentification, $uxMDF_IPv4HeaderIdentification, 1, 2;
   #pragma EZ_Warnings_On;
   Add L4_FR_PTR, L4_FR_PTR, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2; // Update L4_FR_PTR for future use, if any... // Nop;
Put {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE-10)}(L3_FR_PTR), CHK_SUM_IP, 2; // Put 2 bytes CHECKSUM

// Populate the GRE header field
Put {-(IPV4_AND_RADWARE_TUNNEL_GRE_SIZE-20)}(L3_FR_PTR), 0x0000, 2; // first 2 bytes of the GRE header according to RFC2784, without checksum.

// Update L3_FR_PTR and L4_FR_PTR
Add L3_FR_PTR, L3_FR_PTR, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2;    // Update L3_FR_PTR for future use, if any...
jmp L_MDF_AFTER_GRE_HANDLE_LAB, NO_NOP;
   Add L4_FR_PTR, L4_FR_PTR, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2; // Update L4_FR_PTR for future use, if any...
   // The place in the frame that originally held the innest VLAN's Next protocol type field now became the added GRE's.NextProtocolType. The old value of the next protocol type stays unchanged and is correct this way.
   sub DISP_REG, DISP_REG, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2;






////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Peer device (NP) packet handling
//
// Packet can be sent to either 1 or 2 CAUI ports
//
// 1. If destiation is only one CAUI port - send the packet to it (Halt UNIC)
// 2. If there are 2 CAUIs - send a copy to the first one, and then send the original to the 2nd port.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

MDF_PACKET_FROM2ND_NP_LAB:

#define uxCauiPorts        uqTempCondReg.BYTE[0];  //2 bytes
#define byIsCopyNeeded     uqTempCondReg.BYTE[2];

   // Read both CAUI0 and CAUI1 from message
   GetRes  uxCauiPorts,  MSG_CAUI_PORT_0_INFO_OFF(MSG_STR), 2;

   // reset condition register
   Add byIsCopyNeeded, uqZeroReg.BYTE[0], uqZeroReg.BYTE[0], 1;

   // check if copy is needed. Use AND logic operation between Valid bits of each CAUI (bit 7)
   And byIsCopyNeeded, uxCauiPorts.BYTE[0], uxCauiPorts.BYTE[1], 1;

   // For peer NP packet, remove metadata from packet
   Write 4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   nop;
   nop;

   // in case copy is needed, reset valid bit of the first CAUI in advance.
   // After copy is sent it will be easier to identify to which CAUI port we still need to send the packet
   If (byIsCopyNeeded.BIT[7])
      Xor uxCauiPorts.BYTE[0], uxCauiPorts.BYTE[0], NP_CAUI_PORT_VALID, 1;

   If (byIsCopyNeeded.BIT[7])
      Jmp L_MDF_SEND_REPLICA, NO_NOP;
         // Copy 7 LSbits (without valid bit) to sSend_byDstPort register
         MovBits sSend_byDstPort, uxCauiPorts.BYTE[0], 7;
         Mov PC_STACK, MDF_PACKET_FROM2ND_NP_SEND_LOCAL_PACKET, 4;

Indirect MDF_PACKET_FROM2ND_NP_SEND_LOCAL_PACKET:

   // At this point there should be only single indication of valid CAUI port
   // to send the packet to. A none valid indication is an unexpected error case
   If (uxCauiPorts.BIT[7])
      MovBits sSend_byDstPort, uxCauiPorts.BYTE[0], 7;

   If (uxCauiPorts.BIT[15])
      MovBits sSend_byDstPort, uxCauiPorts.BYTE[1], 7;

   // prepare TM header, send and recycle packet
   AddTMHeaderToOutPort;
   Jmp L_MDF_SEND_FRAME, NOP_2;

#undef uxCauiPorts;
#undef byIsCopyNeeded;



#define uqCopyInfo     uqTempCondReg;
#define uqPcStack      uqTmpReg1;
#define byHashVal      uqTmpReg2.BYTE[0];
#define byCauiBitmap   uqTmpReg2.BYTE[1];
#define byTrunkBitmap  uqTmpReg2.BYTE[2];
#define byNumOnesTrunk uqTmpReg2.BYTE[3];

#define byOutPort      uqTmpReg3.BYTE[0];
#define byOutPortMask  uqTmpReg3.BYTE[1];
#define byNumOnes      uqTmpReg3.BYTE[2];
#define byAddToRxCopy  uqTmpReg3.BYTE[3];

#define uqSelectedPort CNT;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// TX copy handling
//
// Packet can arrive or sent to 4 logical directions:
//
// 1. From host - should never have a "TX copy port"
// 2. From 2nd NP - should never have a "TX copy port"
// 3. From Switch -
//    3.1. To switch - should never have a "TX copy port" as this is handled by switch itself
//    3.2. To host - should never have a "TX copy port" as this is handled by switch itself
//    3.3. To local CAUI - remove switch VLAN
//    3.4. To remote CAUI - remove switch VLAN, add METADATA VLAN to be used by 2nd NP (same as overwrite of existing VLAN)
// 4. From local CAUI -
//    4.1. To switch - add switch VLAN from "TX copy port" entry
//    4.2. To host - add METADATA VLAN + constant VLAN representing the local CAUI port.
//    4.3. To local CAUI - nothing to do
//    4.4. To remote CAUI - add METADATA VLAN with information about remote CAUI ports to fwd the packet to.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


MDF_TX_COPY_PORT_LAB:

If ( !byCtrlMsgMdf2.BIT[MSG_CTRL_TOPRSV_2_INTERLINK_PACKET_BIT] ) jmp  MDF_TX_COPY_PORT_HTQE_LAB , NOP_2;

   And ALU, byActionReg, {  FRAME_BYPASS_NETWORK  | FRAME_SYN_COOKIE_GEN  }, 1;

   //get bypass sw vlan
   Mov2Bits CAMO.bits[ 1 , 0 ] , byActionReg.bits[FRAME_BYPASS_NETWORK_BIT , FRAME_SYN_COOKIE_GEN_BIT ] ;


   If (Z)  jmp SEND_MRQ_AS_IS;
       Nop;
       //clear routing mode logic for syn challenge , packet out to same port
       nop;


   GetRes  uqTmpReg8 , MDF_VIF_TX_VLAN_OFF(MSG_STR/*MDF_TX_COPY_INFO_STR*/), 2;
   If (CAMO.bit[ 0 ]) GetRes  uqTmpReg8 , MDF_VLAN_TX_OFF(MSG_STR), 2;

       //get self tx vlan offset (syn challenge)
       //GetRes  uqTmpReg8 , MDF_VLAN_TX_OFF(MDF_TX_COPY_INFO_STR), 2;

   //if syn challenge =
   Nop;

   // Metadata format: 0x8100 followed by the value of remote port bitmap
   Put ETH_PROT_OFF( L2_FR_PTR ), 0x8100, 2, SWAP;
   Put ETH_VID_OFF( L2_FR_PTR ), uqTmpReg8, 2, SWAP;


SEND_MRQ_AS_IS:
   // prepare TM header, send and recycle packet
   AddTMHeaderToOutPortMrq;
//for tracepoint
   nop;

// Send the frame and finish the program
halt UNIC,
     WR_FR_MEM,
     HW_OPTIMIZE;

MDF_TX_COPY_PORT_HTQE_LAB:

   //safty precotion action , remove this when debuging will be compleated

/*****************************************************************************************************

* Perform safty precosion test of Tx , Rx table result. Match bit ever expected at least in one of
* structures . When this rule is fault I prefer to throw away packet , instead runs to endless TopModify
* loop . Ever monitor GS_TMD_EX_TX_RX_DRP counter to catch away and fix the situation

*******************************************************************************************************/

   GetRes  uqTmpReg8 , MDF_FFT_TX_COPY_INFO_OFF(MSG_STR), COPY_PORT_STR_BYTE_SIZE;
   Mov uqTmpReg3, 0, 4;
   And  ALU, uqTmpReg8, (1<<COPY_PORT_MATCH_BIT_OFF), 1, MASK_00000003, MASK_SRC1;
   nop;
   Jz  MDF_TX_COPY_PORT_ERROR_LAB;
       Xor uqTmpReg8 , uqTmpReg8 , uqTmpReg8 , 4;
       nop;


   // Use TX copy port information from FFT entry. If we are in routing mode the information
   //  will be overwritten in a couple of instructions
   GetRes  uqCopyInfo, MDF_FFT_TX_COPY_INFO_OFF(MSG_STR), COPY_PORT_STR_BYTE_SIZE;

   //Jmp MDF_COPY_PORT_START_LAB, NO_NOP;
      //  overwrite TX copy port information in routing mode (get it from routing structure)
   If (bitMDF_isRoutingMode)  GetRes  uqCopyInfo, MDF_ROUTING_TABLE_RSLT__TX_COPY_INFO_OFF(MDF_ROUTING_TABLE_RSLT_STR), COPY_PORT_STR_BYTE_SIZE;



   Mov4Bits uqTmpReg2.BITS[ COPY_PORT_CAUI0_BITMAP_BIT,
                            COPY_PORT_CAUI1_BITMAP_BIT,
                            COPY_PORT_CAUI2_BITMAP_BIT,
                            COPY_PORT_CAUI3_BITMAP_BIT] ,
            uqCopyInfo.BITS[COPY_PORT_CAUI2_BITMAP_BIT,
                            COPY_PORT_CAUI3_BITMAP_BIT,
                            COPY_PORT_CAUI0_BITMAP_BIT,
                            COPY_PORT_CAUI1_BITMAP_BIT] ;

   // Check if NP ID 0 or 1. Do that by examining the zero flag after the following instruction
   // zero flag == 0 means that this code is running on "second" NP, and the CAUI bits in the result
   // needs to be swapped.
   Mov ALU , {1 << GC_CNTRL_3_NP_ID_OFF}, 4 ;
  Xor ALU, uqZeroReg, ALU, 4, NP_NUM, MASK_BOTH;


   If (!uqCopyInfo.BIT[COPY_PORT_MATCH_BIT_OFF])
      Jmp MDF_COPY_PORT_IMPL_DONE_AFTER_VLAN_RESTORE_LAB, NO_NOP;

         // Swap CAUI bits for "second" NP
         If (!FLAGS.BIT[F_ZR])
            MovBits uqCopyInfo.BIT[COPY_PORT_CAUI0_BITMAP_BIT], uqTmpReg2.BIT[COPY_PORT_CAUI0_BITMAP_BIT], 4;

         Mov uqTmpReg2, 0, 4;


////////////////////////////////////////////////////////////////////////////
///////////////// Start Trunk handling for CAUI ports //////////////////////
////////////////////////////////////////////////////////////////////////////
MDF_COPY_PORT_TRUNK_HANDLING_LAB:

   // check if 1st trunk is valid. In case it does, perform "select" operation and update CAUI's bitmap.
   // If 1st trunk is not valid, so does 2nd trunk, so continue with parsing CAUI's bitmap
   If (!uqCopyInfo.BIT[COPY_PORT_TRUNK0_VALID_BIT]) Jmp MDF_COPY_PORT_TRUNK_PROCESSING_DONE_LAB, NO_NOP;

      // Read hash value from message
      GetRes byHashVal, MSG_CORE_NUM_OFF(MSG_STR), 1;

      // Copy CAUI bitmap for further update from trunks
      MovBits byCauiBitmap, uqCopyInfo.BIT[COPY_PORT_CAUI0_BITMAP_BIT], 4;

	// Copy trunk bitmap and count the number of CAUI port bits in bitmap
   MovBits byTrunkBitmap, uqCopyInfo.BIT[COPY_PORT_TRUNK0_BITMAP_BIT_OFF], COPY_PORT_TRUNK_BITMAP_SIZE;
   Nop;

   // Count the number of valid bits in bitmap (should be either 2, 3 or 4)
   NumOnes byNumOnesTrunk, byTrunkBitmap, 1;
   Nop;

   // Perform Modulo operation to choose appropriate port out of those in the current trunk.
   // The result is used for loop operation
   Modulo ALU, byHashVal, byNumOnesTrunk, 1;
   Nop;
   Nop;
   Mov uqSelectedPort, ALU, 1;

L_FIND_OUT_PORT_LOOP0_MSB:

   Nop;
   encode byOutPort, byTrunkBitmap, 1;   // byOutPort = MS bit set
   loop L_FIND_OUT_PORT_LOOP0_MSB, NO_NOP;
      decode byOutPortMask, byOutPort, 1; // ALU (and byOutPortMask) contains MS bit only
      xor byTrunkBitmap, byTrunkBitmap, ALU, 1;

   // Now byOutPort contains the index in the bitmap for the chosen port (in the trunk).
   // Update the CAUI bitmap with that bit
   Or byCauiBitmap, byOutPortMask, byCauiBitmap, 1;

/////////////////////////////////////////////
/////////////////////////////////////////////

   // check if 2nd trunk is valid. In case it does, perform "select" operation and update CAUI's bitmap.
   If (!uqCopyInfo.BIT[COPY_PORT_TRUNK1_VALID_BIT]) Jmp MDF_COPY_PORT_TRUNK_PROCESSING_DONE_LAB, NOP_2;

   // Copy trunk bitmap and count the number of CAUI port bits in bitmap
   MovBits byTrunkBitmap, uqCopyInfo.BIT[COPY_PORT_TRUNK1_BITMAP_BIT_OFF], COPY_PORT_TRUNK_BITMAP_SIZE;

   // - No need to count the number of valid bits in bitmap. It must be 2
   // - CAUI bitmap is already copied
   // - Perform Modulo operation to choose appropriate port out of those in the current trunk.
   //   The result is used for loop operation
   Modulo ALU, byHashVal, 2, 1;
   Nop;
   Nop;
   Mov uqSelectedPort, ALU, 1;

L_FIND_OUT_PORT_LOOP1_MSB:

   Nop;
   encode byOutPort, byTrunkBitmap, 1;   // byOutPort = MS bit set
   loop L_FIND_OUT_PORT_LOOP1_MSB, NO_NOP;
      decode byOutPortMask, byOutPort, 1; // ALU (and byOutPortMask) contains MS bit only
      xor byTrunkBitmap, byTrunkBitmap, ALU, 1;

   // Now byOutPort contains the index in the bitmap for the chosen port (in the trunk).
   // Update the CAUI bitmap with that bit
   Or byCauiBitmap, byOutPortMask, byCauiBitmap, 1;

#undef uqSelectedPort;
#undef byOutPort;
#undef byOutPortMask;
#undef byNumOnesTrunk;
#undef byTrunkBitmap;

////////////////////////////////////////////////////////////////////////////
////////////////// End Trunk handling for CAUI ports ///////////////////////
////////////////////////////////////////////////////////////////////////////

MDF_COPY_PORT_TRUNK_PROCESSING_DONE_LAB:


#define upBackupUDB     uqTmpReg4;
#define byIsSrcPortCaui UDB.BYTE[0];
#define bySelectRes     UDB.BYTE[1];

#define uxRemoteBmp        uqTmpReg2.BYTE[2];

#define uqSavedVlan        uqTmpReg7;

   Mov ENC_PRI, 0, 2;

   // Update CAUI bitmap in the original structure.
   MovBits uqCopyInfo.BIT[COPY_PORT_CAUI0_BITMAP_BIT], byCauiBitmap, 4;

   // Temporarily save UDB register in UREG[3]
   Mov upBackupUDB, UDB, 4;

     // Count the number of bits in the control byte. There should be at least 1 bit turned on
   MovBits ENC_PRI.BIT[11], uqCopyInfo.BIT[COPY_PORT_CAUI0_BITMAP_BIT], 5;
   Nop;

#undef byCauiBitmap;

   // At this point trunk selection completed on all relevant trunks (if at all) and the CAUI bitmap is updated with the
   // original + selected CAUI ports.
   // check if source port is CAUI or Switch/Host. For Switch/Host source the VLAN should be removed from packet.

   NumOnes byNumOnes, ENC_PRI.BYTE[1], 1;

   If (byCtrlMsgMdf2.BIT[MSG_CTRL_TOPRSV_2_IS_CAUI_PORT_BIT])
      Jmp MDF_COPY_PORT_SEND_PACKETS, NO_NOP;
         // For RX copy mode, add some const value, to avoid case where the last replica will
         // force exiting the TOP modify (only perform replicates)
         Add byNumOnes, byNumOnes, byAddToRxCopy, 1;
         Nop;

   // Save VLAN ID and header. They will be used later on to recover frame to its original content.
   Get uqSavedVlan, 12( L2_FR_PTR ), 4, SWAP;
   // For source port equall Switch/Host, remove switch VLAN
   Write 4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   nop;
   // Write command takes 1 clock per 8 bytes. wait till it completes
   Nop;

////////////////////////////////////////////////////////////////////////////
//////////////// Start examining CAUI + switch bitmap //////////////////////
////////////////////////////////////////////////////////////////////////////

MDF_COPY_PORT_SEND_PACKETS:

   // Jump according to ports bitmap.
   // When there is no more ports to deliver a packet, return to caller (relevant only in RX copy)
   JMUL  MDF_COPY_PORT_SEND_TO_SWITCH,
         MDF_COPY_PORT_SEND_TO_REMOTE_CAUI,
         MDF_COPY_PORT_SEND_TO_REMOTE_CAUI,
         MDF_COPY_PORT_SEND_TO_CAUI_1,
         MDF_COPY_PORT_SEND_TO_CAUI_0,
         MDF_INVALID_LAB,
         MDF_INVALID_LAB,
         RESET;

   Jmp MDF_COPY_PORT_IMPL_DONE_LAB, NOP_2;

MDF_INVALID_LAB:

// Error

MDF_COPY_PORT_SEND_TO_CAUI_0:

   Jmp L_MDF_SEND_REPLICA, NO_NOP;
      MovBits sSend_byDstPort, IF_PORT_CAUI_0, 8;
      MovBits ENC_PRI.BIT[11], 0, 1;


MDF_COPY_PORT_SEND_TO_CAUI_1:

   Jmp L_MDF_SEND_REPLICA, NO_NOP;
      MovBits sSend_byDstPort, IF_PORT_CAUI_1, 8;
      MovBits ENC_PRI.BIT[12], 0, 1;


MDF_COPY_PORT_SEND_TO_REMOTE_CAUI:

   MovBits ENC_PRI.BIT[13], 0, 2;

   // Perform "select operation on 2 interlink NP ports (use hash LS+1 bit)
   MovBits bySelectRes.BIT[0], CAMO.BIT[1], 1;

   MovBits uxRemoteBmp, uqCopyInfo.BIT[COPY_PORT_CAUI2_BITMAP_BIT], 2;

   // Assume default select operation for the first peer NP port. Update later if result changed
   MovBits sSend_byDstPort, IF_PORT_PEER_NP_0, 8;

   // examine whether packet is sent to both CAUI ports on the peer device.
   // In such case the number of actual copies need to be decreased by 1.
   Sub   ALU, uxRemoteBmp, 3, 1, MASK_00000003, MASK_BOTH;

   If (bySelectRes.BIT[0])
      MovBits sSend_byDstPort, IF_PORT_PEER_NP_1, 8;

   //  decreased number of copies by 1
   If (FLAGS.BIT[F_ZR])
      Sub byNumOnes, byNumOnes, 1, 1;

   // Now add metadata. This should always appear in the first VLAN, since we already removed switch VLAN.
   Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   nop;
   nop;

   Jmp L_MDF_SEND_REPLICA, NO_NOP;
      // Metadata format: 0x8100 followed by the value of remote port bitmap
      Put ETH_PROT1_OFF( L2_FR_PTR ), 0x8100, 2, SWAP;
      Put ETH_VID1_OFF( L2_FR_PTR ), uxRemoteBmp, 2, SWAP;


MDF_COPY_PORT_SEND_TO_SWITCH:

   // The source must be either CAUI-0 or CAUI-1. For switch to switch it will be handled in the switch itself
   // Use hash value (LS+1 bit) to determine which will be the chosen switch port.

   //MovBits bySelectRes.BIT[0], byHashVal.BIT[1], 1;

   // Assume default select operation for the first switch port.
   // Update later if result changed
   //MovBits sSend_byDstPort, IF_PORT_NET_SWITCH_0, 8;

   //If (bySelectRes.BIT[0])
   //   MovBits sSend_byDstPort, IF_PORT_NET_SWITCH_1, 8;

   Add sSend_byDstPort, CAMO, IF_PORT_NET_SWITCH_0_HTQE, 1;



   // Now add switch VLAN, taken from the entry found in TOP Search-II.
   Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
       Mov ALU.BYTE[0], uqCopyInfo.BYTE[1] , 2 , RESET;
       nop;
   /*
   Mov ALU.BYTE[0], uqCopyInfo.BYTE[2], 1, RESET;
   Mov ALU.BYTE[1], uqCopyInfo.BYTE[1], 1;
   */
   MovBits ALU.bit[15] , 0 , 1;


   Jmp L_MDF_SEND_REPLICA;
      // VLAN format: 0x8100 followed by the value of switch VLAN
       Put ETH_PROT1_OFF( L2_FR_PTR ), 0x8100, 2, SWAP;
       Put ETH_VID1_OFF( L2_FR_PTR ), ALU, 2, SWAP;


////////////////////////////////////////////////////////////////////////////
//////////////// End examining CAUI + switch bitmap //////////////////////
////////////////////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////////////////////
/////////////////////// Start replica handling ////////////////////////////
////////////////////////////////////////////////////////////////////////////

#define uxOriginPtr     uqTmpReg8.BYTE[0];

L_MDF_SEND_LAST_REPLICA:

   // For last packet to leave the TOP modify, there is no need to replicate it, nor to allocate RFD buffers.
   // prepare TM header, send and recycle packet
   AddTMHeaderToOutPort;
   Movbits sreg_high[3].bit[0], 1 ,1;
   Jmp L_MDF_SEND_FRAME, NOP_2;


L_MDF_SEND_REPLICA:

   Sub byNumOnes, byNumOnes, 1, 1;
   Nop;
   If (FLAGS.BIT[F_ZR])
      Jmp L_MDF_SEND_LAST_REPLICA, NOP_2;

   // Replicate the frame
   movbits sSend_bitMulticast, 1, 1;

   Mov uxOriginPtr, sSend_uxFramePtr, 2;

   EZrfdIncrCntOptimized 1;

   // The entire buffer data needs to be written for each replica, since it
   // is not written back to original FMEM buffer
   Movbits FMEM_WR_BITMAP, 0xFF0, 12;

   EZrfdPreFetch sSend_uxFramePtr, L_MDF_RFD_PREFETCH_FAILED;
   EZlinkNewBufferToRestOfFrame sSend_uxFramePtr, uxOriginPtr;
   EZrfdMultRecycle uxOriginPtr, 1 /* BUF_NUM */, sSend_bySrcPort;
   mov sRfd_uxFramePtr, sSend_uxFramePtr, 2;

   // build TM header
   AddTMHeaderToOutPort;

   // initiate the reading the original frame data from the FMEM to the internal buffer
   EZstartReadBufferToLocalMemory   uxOriginPtr, 0/*size*/;

   nop;

   // Waiting till frame buffer is ready. This should not take long, because fetching of the buffer
   // was performed with size "0".
   EZwaitFlag F_NBV_MDF;
   nop;

   // Copying the active stage FMEM to the next stage FMEM, before "halt CONTINUE"
   movbits  CP_MCODE_TO_NEXT_START, DISP_REG.bit[ 5 ], 4;
   nop;

   // Waiting till copying the active stage FMEM to the next stage FMEM is complete
   EZwaitFlag F_NBV_MDF;
   nop;

   // Write the internal buffer to the FMEM.
   // Send the copy and continue with the next copy


VarDef RegType uxTmpFrameLen           uqTmpReg5.BYTE[ 0:1 ];
VarDef RegType uxTmp1stBufLen          uqTmpReg5.BYTE[ 2:3 ];
   // Save Frame Length and 1st buffer length before "Halt with HW_MSG optimizations" will distroy them
   mov   $uxTmpFrameLen , sSend_uxFrameLen , 2;
   mov   $uxTmp1stBufLen, sSend_ux1stBufLen, 2;

   nop;

   halt CONTINUE,
        WR_FR_MEM,
        HW_OPTIMIZE;

   // Restore Frame Length and 1st buffer length
   mov   sSend_uxFrameLen , $uxTmpFrameLen , 2;
   mov   sSend_ux1stBufLen, $uxTmp1stBufLen, 2;
   // restore original DISP_REG register (before TM header).
   // TODO: This can be optimized later by adding TM header only once and just update
   //       its PSID field.
   Add   DISP_REG, DISP_REG, TM_HEADER_SIZE, 2;
   Sub ALU,  sSend_byDstPort, 116, 1;
   nop;

   halt  NO_SEND,
         NO_HW_OPTIMIZE;

VarUnDef uxTmpFrameLen;
VarUnDef uxTmp1stBufLen;


   // remove metadata/VLAN only for packets sent to switch/peer device
   If (!FLAGS.BIT[F_SN])
      Jmp MDF_COPY_PORT_SEND_PACKETS, NO_NOP;
         Mov   sSend_uxFramePtr, uxOriginPtr, 2;
         Mov   sRfd_uxFramePtr, uxOriginPtr, 2;

   Jmp MDF_COPY_PORT_SEND_PACKETS, NO_NOP;
      Nop;

      // Now remove metadata added before sending current copy.
      Write 4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
      nop;
      nop;



L_MDF_RFD_PREFETCH_FAILED:

   // In case the operation to pre-fetch a buffer fails,
   // increment the appropriate counter and continue

   // TODO: add counting for prefetch failure

   // Finish as if it was the last copy
   Jmp MDF_COPY_PORT_SEND_PACKETS, NOP_2;



////////////////////////////////////////////////////////////////////////////
/////////////////////// End of replica handling ////////////////////////////
////////////////////////////////////////////////////////////////////////////

Indirect MDF_COPY_PORT_IMPL_DONE_LAB:

   If (byIsSrcPortCaui.BIT[0])
      Jmp MDF_COPY_PORT_IMPL_DONE_AFTER_VLAN_RESTORE_LAB, NOP_1;
         // Restore UDB register from UREG[3]
         Mov UDB, upBackupUDB, 4;

   // For source port equall Switch/Host, restore switch VLAN
   Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   // Write command takes 1 clock per 8 bytes. wait till it completes
   Nop;
   nop;

   Put HOST_METADATA_VAL_OFF(L2_FR_PTR) , uqSavedVlan, 4, SWAP;

MDF_COPY_PORT_IMPL_DONE_AFTER_VLAN_RESTORE_LAB:

   Jstack NOP_2;

#undef uxOriginPtr;
#undef upBackupUDB;
#undef byIsSrcPortCaui;
#undef bySelectRes;

#undef uxRemoteBmp;

#undef uqCopyInfo;
#undef uqPcStack;

#undef byHashVal;
#undef uqSavedVlan;

//calculate action
MDF_ROUTING_TABLE_NO_MATCH_LAB:
FFT_NO_MATCH_LAB:
//fft search returned no match
EZstatIncrIndexReg FFT_FFT_NOT_FOUND_CNT, 1;

xor ALU, ALU, !ALU, 4, GC_CNTRL_MDF, MASK_BOTH;
  nop;
MovBits uqTmpReg1, ALU.bit[CNTRL_MDF_FFT_NOMATCH_OFF], 2;
  nop;
Sub ALU, uqTmpReg1, uqZeroReg, 1, MASK_00000003, MASK_SRC1;
   //change action to 2CPU qsw
   MovBits ALU, FRAME_BYPASS_HOST, 8;
// continue, to cpu, bypass
jnz SKIP_TX_VLAN_LAB, NO_NOP;
   Mov byActionReg, ALU, 1;
   nop;

//drop action detected
jmp DISCARD_LAB, NOP_2;
