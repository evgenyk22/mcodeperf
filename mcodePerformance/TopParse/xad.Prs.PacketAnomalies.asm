/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.PacketAnomalies.asm
*
*  Usage:         Packet Anomalies macro file: decides what to do with packet according to marking 
*                 from parser and configuration from the user. This macro does packet discarding, 
*                 marks to send to host, or forward the packet to the next security feature
*
*******************************************************************************/

#include "xad.common.h"
#include "xad.Prs.PacketAnomalies.h"


/****************************************************************
*
* Packet Anomalies (Immediate Check) Macro 
*
*****************************************************************/


MACRO packetAnomalies   paInReg,              // uqInReg - Parsing errors indication register
                        paOffsetReg,          // uqOffsetReg0 - L3 & L4 starting offset indication register
                        pauqFramePrsReg,      // uqFramePrsReg - Stores data collected during parsing phase
                        ERROR_HANDLING_LAB,   // Jump to this label when unexpected error occures and drop packet
                        PA_END_LAB,           // Continue from this label after completing packetAnomalies macro
                        CPU_BYPASS_LAB,       // Send to CPU label
                        NET_BYPASS_LAB,       // Feature Bypass Label
                        DROP_LAB,             // Drop label
                        CONT_LAB;           // Continue label


xor actReg0, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 
Mov actRegMask0, IC_CNTRL_MASK_0, 4;

Mov ALU, PA_L2_L3_MASK, 4;
Mov icCtrlType, 0, 1;
And ALU, paInReg, ALU, 4;          
Mov uqCondReg, paInReg, 4;
Mov uqTmpReg3, 0, 4; //All uxTmpReg1 base

// Skip L2-3 checks if no problem in L2-3 header was found
if (FLAGS.BIT[ F_ZR ]) jmp L4_PAYLOAD_LEN_HANDLE_LAB, NO_NOP;    
   Mov ENC_PRI,   0, 4;
   Mov uqTmpReg2, 0, 4;   //All bytmp base


///////////////////////////////////
//  L2 - Unsupported Etype check
///////////////////////////////////

// First check according to L2 type, if no Ethernet type get default action
Mov PC_STACK, L2_BCAST_LAB, 2;
if (uqCondReg.BIT[L2_UNS_PROT_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_L2_FORMAT_OFF], 2;
   Mov uxTmpReg1, IS_UN_L2_DRP, 2;


///////////////////////////////////
//    L2 - Broadcast check
///////////////////////////////////

indirect L2_BCAST_LAB: //##TODO_OPTIMIZE: 3 clocks are spent for every check in the fall through path as a result of the indirect preprocessor. this is multiplied by the number of tests and then by 2 for running PA twice. see how to optimize this code in all places in this code to prevent and minimize the NOPics.

// Check if this is broadcast frame
Mov PC_STACK, L2_UNS_PROT_LAB, 2; // Default value for transparent mode: do not check if frame is MCAST or L2 control frame, as these frames are not treated as anomalies, even though they are marked as so by the parser.
if (bitPRS_isRoutingMode)  Mov PC_STACK, L2_MCAST_OR_L2_CTRL_FRAME_LAB, 2; // In routing mode overtite the default to handle MCAST or L2 control frame as BC frames. (Should be configured by the host to punt to the host if in routing mode).
If (uqCondReg.BIT[L2_BROADCAST_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_L2_BROADCAST_OFF], 2;
   Mov uxTmpReg1, IS_L2_BRD_DRP, 2;

///////////////////////////////////
//    L2 - Multicast or L2 control frame check
///////////////////////////////////

indirect L2_MCAST_OR_L2_CTRL_FRAME_LAB:

// Check if this is multicast or L2 control frame
Mov PC_STACK, L2_UNS_PROT_LAB, 2;
If (uqCondReg.BIT[L2_MULTICAST_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_L2_BROADCAST_OFF], 2; // using IC_CNTRL_0_L2_BROADCAST_OFF for MCAST and L2 control frames, meaning the same configuration for BC will be also applied on mcast and L2 control frames in routing mode.
   Mov uxTmpReg1, IS_L2_BRD_DRP, 2;



///////////////////////////////////
//  L3 - Unsupported protocol check
///////////////////////////////////

indirect L2_UNS_PROT_LAB: 

// Check L3 errors 
Mov PC_STACK, L2_UNS_PROT_CONT_LAB, 2;
If (uqCondReg.BIT[L3_UNS_PROT_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_L3_UNK_OFF], 2;
   Mov uxTmpReg1, IS_UN_L3_DRP, 2;

indirect L2_UNS_PROT_CONT_LAB: 
            
Mov uqCondReg, pauqFramePrsReg,4;
nop;

// Check if L3 type IPv6 or IPv4  
if (uqCondReg.BIT[L3_TYPE_OFF]) Jmp L3_IPv6_HLEN_LAB, NOP_1;
   Mov uqCondReg, paInReg, 4;


///////////////////////////////////
//  L3 - IPv4 Checksum error check
///////////////////////////////////

Mov PC_STACK, L3_IPv4_HLEN_LAB, 2;
If (uqCondReg.BIT[IPv4_CHECKSUM_ERR_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_IPv4_INC_CHEKSUM_OFF], 2;
   Mov uxTmpReg1, IS_IP4_CK_DRP, 2;
       

///////////////////////////////////
//  L3 - IPv4 Header length check
///////////////////////////////////

indirect L3_IPv4_HLEN_LAB:

// IPv4 Header length check        
Mov PC_STACK, L3_IPv4_TTL_LAB, 2;
If (uqCondReg.BIT[L3_HLEN_ERR_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_IPv4_INC_PKTHDRLEN_OFF], 2;
   Mov uxTmpReg1, IS_IP4_HE_DRP, 2;


///////////////////////////////////
//  L3 - IPv4 TTL check
///////////////////////////////////

indirect L3_IPv4_TTL_LAB:

Mov PC_STACK, L4_PAYLOAD_LEN_HANDLE_LAB, 2;
Mov uxTmpReg1, IS_IP4_TTL_DRP,2;
If (uqCondReg.BIT[IPv4_TTL_EXP_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_INC_TTL_OFF], 2;
   If (uqCondReg.BIT[IPv4_TTL_EXP_OFFSET]) Mov icCtrlType, IC_CNTRL_0_INC_TTL_OFF, 1; //Save IC_CNTRL type offset bit [0..31] for further processing after the jump
       
Jmp L4_PAYLOAD_LEN_HANDLE_LAB, NOP_2;


///////////////////////////////////
//  L3 - IPv6 Header length check
///////////////////////////////////
                    
indirect L3_IPv6_HLEN_LAB:

// IPv6 Header length check        
Mov PC_STACK, L3_IPv6_SUB_HLEN_LAB, 2;
If (uqCondReg.BIT[L3_HLEN_ERR_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_IPv4_INC_PKTHDRLEN_OFF], 2;
   Mov uxTmpReg1, IS_IP4_HE_DRP, 2;


///////////////////////////////////
//  L3 - IPv6 Sub-Header length check
///////////////////////////////////

indirect L3_IPv6_SUB_HLEN_LAB:

// IPv6 sub header's length check
Mov PC_STACK, L3_IPv6_HOP_EXP_LAB, 2;
if (uqCondReg.BIT[IPv6_FRAMELEN_ERR_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_IPv6_INC_HDR_OFF], 2;
   Mov uxTmpReg1, IS_IP6_HE_DRP, 2;


///////////////////////////////////
//  L3 - IPv6 Hop expired check
///////////////////////////////////

indirect L3_IPv6_HOP_EXP_LAB:

Mov PC_STACK, L4_PAYLOAD_LEN_HANDLE_LAB, 2;
Mov uxTmpReg1, IS_IP6_HOP_DRP, 2;
if (uqCondReg.BIT[IPv6_HOP_EXP_OFFSET]) Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_IPv6_HLIM_OFF], 2;
   if (uqCondReg.BIT[IPv6_HOP_EXP_OFFSET]) Mov icCtrlType, IC_CNTRL_0_IPv6_HLIM_OFF, 1; //Save IC_CNTRL type offset bit [0..31] for further processing after the jump


///////////////////////////////////
//  L4 Payload Length Handling
///////////////////////////////////

indirect L4_PAYLOAD_LEN_HANDLE_LAB:

if (!uqCondReg.BIT[L4_PAYLOAD_LEN_ERR_OFFSET]) Jmp TUN_CHK_LAB, NOP_2;

Mov PC_STACK, TUN_CHK_LAB, 2;
jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_IPv4_INC_PKTHDRLEN_OFF], 2;
   Mov uxTmpReg1, IS_IP4_HE_DRP, 2;


///////////////////////////////////
//    L4 - Tunnel check
///////////////////////////////////

indirect TUN_CHK_LAB:

Mov ENC_PRI.byte[1], 0, 1;
nop; 
Mov4Bits ENC_PRI.bits[13,12,11,10], uqInReg.bits[GRE_UNS_VER_OFFSET, GRE_SRE_NUM_ERR_OFFSET, GRE_HLEN_ERR_OFFSET, GTP_UNS_VER_OFFSET];
MovBits  ENC_PRI.bit[9], uqInReg.bit[GTP_HLEN_ERR_OFFSET], 1;
Mov PC_STACK, TUN_CHK_LAB_LOOP, 2;

indirect TUN_CHK_LAB_LOOP:

MovBits ENC_PRI.bit[5], 0, 2;
xor actReg0, ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH;
Mov actRegMask0, IC_CNTRL_MASK_1, 4;
MovBits uqCondReg.bit[0], actReg0.bit[IC_CNTRL_0_TUN_INNER_EN_OFF], 1;
 
Jmul L4_FRAG_CHECK_LAB, 
     L4_FRAG_CHECK_LAB, 
     GRE_UNS_VER_LAB,
     GRE_SRE_NUM_ERROR_LAB,
     GRE_HLEN_ERR_LAB,
     GTP_UNS_VER_LAB,
     GTP_HLEN_ERR_LAB;
     nop;
     nop;

// If no problem found in GRE\GTP -> continue with L4 checks
Jmp  L4_FRAG_CHECK_LAB, NOP_2;


///////////////////////////////////
//  L4 - GRE\GTP Tunnel failures
///////////////////////////////////

GRE_UNS_VER_LAB:
//MovBits ENC_PRI.bit[4] , 0 , 1;
if (!uqCondReg.bit[0]) Mov icCtrlType, IC_CNTRL_1_GRE_VERSION_OFF, 1;         //If tunnel bit is disabled save IC_CNTRL type offset bit for policy checking before sending to CPU (otherwise remains 0)
Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_GRE_VERSION_OFF], 2;
   Mov uxTmpReg1, IS_GRE_VER_DRP, 2;

GRE_SRE_NUM_ERROR_LAB:
//MovBits ENC_PRI.bit[3] , 0 , 1;
if (!uqCondReg.bit[0]) Mov icCtrlType, IC_CNTRL_1_GRE_ROUTING_HDR_NUM_OFF, 1; //If tunnel bit is disabled save IC_CNTRL type offset bit for policy checking before sending to CPU (otherwise remains 0)
Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_GRE_ROUTING_HDR_NUM_OFF], 2;
   Mov uxTmpReg1, IS_GRE_ROUT_DRP, 2;

GRE_HLEN_ERR_LAB:
//MovBits ENC_PRI.bit[2] , 0 , 1;
if (!uqCondReg.bit[0]) Mov icCtrlType, IC_CNTRL_1_GRE_INV_HDR_LEN_OFF, 1;     //If tunnel bit is disabled save IC_CNTRL type offset bit for policy checking before sending to CPU (otherwise remains 0)
Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_GRE_INV_HDR_LEN_OFF], 2;
   Mov uxTmpReg1, IS_GRE_HDR_DRP, 2;

GTP_UNS_VER_LAB:
if (!uqCondReg.bit[0]) Mov icCtrlType, IC_CNTRL_1_INC_VER_GTP_OFF, 1;         //If tunnel bit is disabled save IC_CNTRL type offset bit for policy checking before sending to CPU (otherwise remains 0)
Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_INC_VER_GTP_OFF], 2;
   Mov uxTmpReg1, IS_GTP_INC_VER_DRP, 2;

GTP_HLEN_ERR_LAB:
if (!uqCondReg.bit[0]) Mov icCtrlType, IC_CNTRL_1_INC_HLEN_GTP_OFF, 1;        //If tunnel bit is disabled save IC_CNTRL type offset bit for policy checking before sending to CPU (otherwise remains 0)
Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_INC_HLEN_GTP_OFF], 2;
   Mov uxTmpReg1, IS_GTP_HLEN_DRP, 2;


///////////////////////////////////
//  L4 - Fragmentation check
///////////////////////////////////

L4_FRAG_CHECK_LAB:

// decode first fragment + fragment 
// 01 - no fragment
// 02 - don't care
// 04 - fragment ipv4 packet
// 08 - fragment ipv6 packet
// else ipv4 or ipv6 first fragment

xor actReg0, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 
Mov ALU, {1<<GRE_L4_HDR_SKIP_OFFSET}, 4;
And ALU, paInReg, ALU, 4;
Mov actRegMask0, IC_CNTRL_MASK_0, 4;
jnz PA_END_LAB, NOP_2;

//decode  bytmp2 , uqInReg.byte[FFRAG_OFFSETB] , 1 , MASK_00000007 , MASK_SRC1;
MovBits ENC_PRI.bit[13], uqInReg.bit[FIRST_FRAG_OFFSET], 3;
And byTempCondByte1, pauqFramePrsReg.byte[L4_TYPE_OFFB], 0x2f, 1;
Mov PC_STACK, PA_END_LAB, 2;

Jmul FRAG_IPv6_LAB,
     FRAG_IPv4_LAB,
     FIRST_FRAG_IPV4_LAB;
     nop;
     nop;

jmp L4_PROT_HANDLE_LAB, NOP_2;

FRAG_IPv6_LAB:
//Save IC_CNTRL type offset bit [0..31] for further processing after the jump 
Mov icCtrlType, IC_CNTRL_0_IPv6_FRAG_OFF, 1;  
Jmp CHK_FAIL_LAB, NO_NOP; 
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_IPv6_FRAG_OFF], 2;
   Mov uxTmpReg1, IS_IP6_FRG_DRP, 2;

FRAG_IPv4_LAB:
FIRST_FRAG_IPV4_LAB:
//Save IC_CNTRL type offset bit [0..31] for further processing after the jump 
Mov icCtrlType, IC_CNTRL_0_FRAG_OFF, 1;  
Jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_0_FRAG_OFF], 2;
   Mov uxTmpReg1, IS_IP4_FRG_DRP, 2;


///////////////////////////////////
//    L4 Protocol Handling
///////////////////////////////////

L4_PROT_HANDLE_LAB:

//reload new action mask
//xor actReg0, actReg0, actReg0, 4;                             
decode byTempCondByte1, byTempCondByte1, 1, MASK_00000007, MASK_SRC1;    

//xor ALU, ALU, ALU, 4;    
xor actReg0, ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH;  // TOPparse MREG[11]
Mov actRegMask0, IC_CNTRL_MASK_1, 4;   
MovBits ENC_PRI.bit[9], byTempCondByte1, 7;    

//Save IC_CNTRL type offset bit [0..31] for further processing after the jump 
if (byTempCondByte1.bit[L4_UNS_TYPE]) Mov icCtrlType, IC_CNTRL_1_UNK_L4_OFF, 1; 

//Mov LIM_REG , 0 , 4;
//mov tmp , 0 , 4;

// Perform L4 tests
Mov PC_STACK, PA_END_LAB, 2;
 
MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_UNK_L4_OFF], 2;
Mov uxTmpReg1, IS_UN_L4_DRP, 2;

Jmul PA_END_LAB,           // GRE  - L4_GRE_TYPE
     SCTP_HEADER_LAB,      // SCTP - L4_SCTP_TYPE
     PA_END_LAB,           // IGMP - L4_IGMP_TYPE
     PA_END_LAB,           // ICMP - L4_ICMP_TYPE
     UDP_HEADER_LAB,       // UDP  - L4_UDP_TYPE
     TCP_HEADER_LAB,       // TCP  - L4_TCP_TYPE
     CHK_FAIL_LAB;         // Fail - L4_UNS_TYPE
     nop;
     nop;

jmp PA_END_LAB, NOP_2;


///////////////////////////////////
//      L4 - SCTP Handling
///////////////////////////////////

SCTP_HEADER_LAB:

Sub ALU, pauqFramePrsReg.byte[L4_TYPE_OFFB], L4_SCTP_TYPE, 1, MASK_00000007, MASK_SRC1;    
Mov uqCondReg, paInReg, 4;
jnz PA_END_LAB, NOP_2;

Mov PC_STACK, PA_END_LAB, 2;
Mov uxTmpReg1, IS_SCTP_HLEN_DRP, 2;
if (uqCondReg.BIT[SCTP_HLEN_ERR_OFFSET]) jmp CHK_FAIL_LAB, NO_NOP;
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_SCTP_HLEN_OFF], 2;
   if (uqCondReg.BIT[SCTP_HLEN_ERR_OFFSET]) Mov icCtrlType, IC_CNTRL_1_SCTP_HLEN_OFF, 1; //Save IC_CNTRL type offset bit [0..31] for further processing after the jump

jmp PA_END_LAB, NOP_2;


///////////////////////////////////
//      L4 - TCP Handling
///////////////////////////////////
       
TCP_HEADER_LAB:
    
Mov CAMI, 0, 4;
Mov FMEM_BASE, paOffsetReg.byte[L4_OFFB], 2;
// Check TCP flag violation
Mov PC_STACK, TCP_HEADERLEN_CONT_LAB, 2;
nop;  
Get ALU, TCP_FLAGS_OFF(FMEM_BASE), 1; 
Mov uqCondReg, paInReg, 4;
MovBits CAMI.BIT[0], ALU, 5; 

// TCP header length check 
Mov uxTmpReg1, IS_TCP_HE_DRP, 2;
If (uqCondReg.BIT[TCP_HLEN_ERR_OFFSET]) jmp CHK_FAIL_LAB, NO_NOP; /*TCP_HEADERLEN_ERROR_LAB;*/
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_TCP_HLEN_OFF], 2;
   If (uqCondReg.BIT[TCP_HLEN_ERR_OFFSET]) Mov icCtrlType, IC_CNTRL_1_TCP_HLEN_OFF, 1;   //Save IC_CNTRL type offset bit [0..31] for further processing after the jump 

indirect TCP_HEADERLEN_CONT_LAB:                                                             

LookCam CAMO, CAMI,BCAM8[TCP_VALID_COMBINATION_GRP];    
Mov PC_STACK, PA_END_LAB, 2;
Mov uxTmpReg1, IS_TCP_FL_DRP, 2;
if (!FLAGS.BIT[ F_MH ]) jmp CHK_FAIL_LAB, NO_NOP; /* UNSUPPORTED_TCP_COMB_LAB*/
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_TCP_FLAG_OFF], 2;
   if (!FLAGS.BIT[ F_MH ]) Mov icCtrlType, IC_CNTRL_1_TCP_FLAG_OFF, 1;   //Save IC_CNTRL type offset bit [0..31] for further processing after the jump 

jmp PA_END_LAB, NOP_2;
                                        

///////////////////////////////////
//      L4 - UDP Handling
///////////////////////////////////

UDP_HEADER_LAB:

Mov FMEM_BASE, paOffsetReg.byte[L4_OFFB], 2;
Mov uqCondReg, pauqFramePrsReg,4;
nop;            
Get uxTmpReg2, UDP_CHKSUM_OFF(FMEM_BASE), 2, SWAP;
Mov PC_STACK, UDP_ZERO_CHKSUM_CONT_LAB, 2;
Sub ALU, uxTmpReg2, 0, 2;

// Zero checksum test
Mov uxTmpReg1, IS_UDP_CZ_DRP, 2;
If (FLAGS.BIT[F_ZR ]) Jmp CHK_FAIL_LAB, NO_NOP; /*UDP_CHKSUM_ERR_LAB*/
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_UDP_ZCHKSUM_OFF], 2;
   If (FLAGS.BIT[F_ZR ]) Mov icCtrlType, IC_CNTRL_1_UDP_ZCHKSUM_OFF, 1;  //Save IC_CNTRL type offset bit [0..31] for further processing after the jump 

indirect UDP_ZERO_CHKSUM_CONT_LAB:

Get uxTmpReg2, UDP_HLEN_OFF(FMEM_BASE), 2, SWAP;
Mov PC_STACK, UDP_HLEN_NEXT_CHECK_LAB, 2;
Sub ALU, uxTmpReg2, 8, 2;

// Save IC_CNTRL type offset bit [0..31] for further processing after the jump 
Mov icCtrlType, IC_CNTRL_1_UDP_INC_HLEN_OFF, 1; 
        
// Check if HLEN < 8 
If (!FLAGS.BIT[F_SN]) Jmp UDP_HLEN_NEXT_CHECK_LAB, NO_NOP;
   Add ALU, uxTmpReg2, paOffsetReg.byte[L4_OFFB], 2;
   Mov uqCondReg, paInReg, 4;
                     
Jmp CHK_FAIL_LAB, NO_NOP; /*UDP_HLEN_ERR_LAB*/
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_UDP_INC_HLEN_OFF], 2;
   Mov uxTmpReg1, IS_UDP_HE_DRP, 2;
    
indirect UDP_HLEN_NEXT_CHECK_LAB:
Sub ALU, HWD_REG0.byte[2], ALU, 2;
If (uqCondReg.bit[FIRST_FRAG_OFFSET]) jmp PA_END_LAB, NOP_2;

If (FLAGS.BIT[F_SN] ) jmp CHK_FAIL_LAB, NO_NOP; //##TODO_GUY_BUG_FOUND: PC_STACK is not initialized - in case of an error and configuration of NEXT_CHK_LAB will get back to the same handling of UDP_HLEN_NEXT_CHECK_LAB
   MovBits bytmp1.BIT[0], actReg0.BIT[IC_CNTRL_1_UDP_INC_HLEN_OFF], 2;
   Mov uxTmpReg1, IS_UDP_HE_DRP, 2;

jmp PA_END_LAB, NOP_2;


///////////////////////////////////
//   Packet Anomalies Failed
///////////////////////////////////
       
CHK_FAIL_LAB:

decode  ALU, bytmp1, 1, MASK_00000003, MASK_SRC1;
Mov     uqTmpReg4, 0, 4;
MovBits bytmp3, ENC_PRI.bit[9], 7;  // Save ENC_PRIority register
MovBits ENC_PRI.bit[9], ALU, 7;
Add     uqTmpReg4, uxTmpReg1, bytmp1, 2, MASK_00000003, MASK_SRC2;

Jmul ERROR_HANDLING_LAB,
     ERROR_HANDLING_LAB,
     ERROR_HANDLING_LAB,
     SEND_TO_CPU_LAB,     //Send to CPU
     PA_NET_BYPASS,       //Bypass
     NEXT_CHK_LAB,        //Continue
     PA_DRP_LAB;          //Drop
   nop;
   nop;


////////////////////////////////////////////////
//   Packet Anomalies Failure - Continue Processing
////////////////////////////////////////////////
   
NEXT_CHK_LAB:
MovBits ENC_PRI.bit[9], bytmp3, 7;
EZstatIncrByOneIndexReg uqTmpReg4;
Jstack;
   Mov uxTmpReg2 , 0, 2;
   Mov bytmp1, 0, 1;


////////////////////////////////////////////////
//   Packet Anomalies Failure - Send to CPU Handling
////////////////////////////////////////////////

SEND_TO_CPU_LAB:

EZstatIncrByOneIndexReg uqTmpReg4;

// Decode IC_CNTRL type (offset bit [0..31], saved previously) to bitmap in ALU (4 bytes)
decode ALU, icCtrlType,  4,   MASK_0000001F, MASK_SRC1;
And    ALU, actRegMask0, ALU, 4; // AND mask of allowed types with ALU bitmap

Mov byFrameActionReg, FRAME_BYPASS_HOST, 1;

// GuyE: Need to be set from the driver!!!!!
if (!FLAGS.bit[F_ZR]) movbits uqGcCtrlReg0.bit[GC_CNTRL_0_SYN_ENABLE_BIT], 0, 1;

// Case 1: Frames that passed the mask (in tunnels case - also MUST have tunnel indication bit OFF) - need to lookup policy before sending to CPU
// Applies to tunneled frames: IC_CNTRL_1_GRE_VERSION_OFF, IC_CNTRL_1_GRE_ROUTING_HDR_NUM_OFF, IC_CNTRL_1_GRE_INV_HDR_LEN_OFF, IC_CNTRL_1_INC_VER_GTP_OFF, IC_CNTRL_1_INC_HLEN_GTP_OFF
// Applies to specific frames: IC_CNTRL_0_INC_TTL_OFF, IC_CNTRL_0_FRAG_OFF, IC_CNTRL_0_IPv6_HLIM_OFF, IC_CNTRL_0_IPv6_FRAG_OFF, IC_CNTRL_1_UNK_L4_OFF, IC_CNTRL_1_TCP_HLEN_OFF, IC_CNTRL_1_TCP_FLAG_OFF, IC_CNTRL_1_UDP_ZCHKSUM_OFF, IC_CNTRL_1_UDP_INC_HLEN_OFF, IC_CNTRL_1_SCTP_HLEN_OFF
if (!FLAGS.bit[F_ZR]) jmp CONT_LAB, NOP_2;    // POLICY_HANDLING_LAB

// Case 2: All other frames (that did not pass the mask) - need to be sent straight to CPU (without policy check)
jmp CPU_BYPASS_LAB, NOP_2;                      // HOST_P0_BYPASS_LAB


////////////////////////////////////////////////
//  Packet Anomalies Failure - Bypass & Drop Handling
////////////////////////////////////////////////

indirect PA_DRP_LAB:
indirect PA_NET_BYPASS:

// If sampling is not enabled continue to drop processing
if (!uqGcCtrlReg0.BIT[GC_CNTRL_0_IMMCHK_SAMPLENABLED_BIT]) jmp HANDLE_DROPPED_PACKETS_LAB, NO_NOP;
   xor ALU, ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH; // using MREG[15] //##TODO_OPTIMIZE this line may be deleted - is not used.
   nop;

Mov uqTmpCtxReg1, IMM_CHK_SAM_TB, 4;
   nop;

EZstatPutDataSendCmdIndexReg uqTmpCtxReg1, IMM_SAMP_SIZE_CONST, STS_GET_COLOR_CMD;
   nop;
   nop;

EZwaitFlag F_SR;

// Check CPU sampling Token Bucket state (color is also returned to UDB.bits[16,17])
And ALU, STAT_RESULT_L, RED_COLOR_MASK_VAL, 1;
   nop;
jnz HANDLE_DROPPED_PACKETS_LAB, NOP_2; // No sampling in case of RED color (i.e. drop\bypass)

// Sample packet to CPU (50 packets per second)

// Check whether packet is jumbo
And ALU, uqFramePrsReg, {1 << JUMBO_PCKT_STATUS_OFF}, 1;
   nop;
jz L_PRS_SAMPLE_TO_CPU, NOP_2; // Not a jumbo packet, send to CPU

// This is a jumbo packet 

// Check whether configuration allows to send it to CPU: 0 - No support for jumbo frames (i.e. jumbo frames are discarded\bypassed), 1 - Jumbo frames are allowed and processed
Xor ALU, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH;
And ALU, ALU, { 1 << IC_CNTRL_0_JUMBOMODE_OFF }, 4;
   nop;
jz HANDLE_DROPPED_PACKETS_LAB, NOP_2;  // This case means we have a jumbo frame that needs to be sampled to CPU but configuration doesn't allow it (i.e. drop\bypass)
// ## TODO_BUG_FOUND: The credit was taken from the TB before, as if the frame would be sent to the CPU, but in actual, in this case the frame will not be sent to the CPU.
// In this case, when receiving many jumbo frames which are configured not to be sampled to the CPU, these frames will consume the budget of all other frames
// that are supposed to be sent to the CPU, while in actual these are not sent to the CPU at all.


L_PRS_SAMPLE_TO_CPU:
EZstatIncrByOneIndexImm IS_SAMP_CPU;
   nop; //##TODO_OPTIMIZE - check if this nop is needed.
jmp CPU_BYPASS_LAB, NOP_2;

// Count dropped packets and continue with drop handling

HANDLE_DROPPED_PACKETS_LAB:

MovBits ENC_PRI.bit[13], 0, 3;
EZstatIncrByOneIndexReg uqTmpReg4;

Jmul ERROR_HANDLING_LAB, 
     ERROR_HANDLING_LAB,
     ERROR_HANDLING_LAB,
     ERROR_HANDLING_LAB,
     NET_BYPASS_LAB,
     ERROR_HANDLING_LAB,
     PA_DISCARD_LAB;


// Discard packet

PA_DISCARD_LAB:

#define TP_EN (1<<IC_CNTRL_1_TP_EN_OFF);
Mov uqTmpCtxReg1, TP_EN, 4;
   xor ALU, ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH;
And ALU, ALU, uqTmpCtxReg1, 4;
   nop;
jmp DROP_LAB, NOP_1;
   if (!FLAGS.bit[F_ZR]) Mov byFrameActionReg, FRAME_TP_BYPASS_2NETW, 1;
#undef icCtrlType;

ENDMACRO; //packetAnomalies

