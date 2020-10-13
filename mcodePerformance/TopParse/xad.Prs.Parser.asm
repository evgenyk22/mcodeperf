/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.Parser.asm
*
*  Usage:         Packet parser macro file: Detects packet anomalies and saves in vector (uqInReg), 
*                 also saves some offsets regarding L3/L4
*
*******************************************************************************/
#include "xad.Prs.Parser.h"



//6 byte from start of Ipv4 header
#define IPv4_FRAGMENT_OFFSET     6;
//tcp dest port bgp type
#define ROUTING_BGP_TCP_TYPE     179

#define UDP_HLEN_OFF          4;
#define UDP_CHKSUM_OFF        6; 


/****************************************************************
*
* Parse Frame Macro 
*
*****************************************************************/

//parseFrame;


/* *****************************************************************************
 Start parsing L2 of the frame:
   this includes the ethertype and VLANs checks.
   The DMAC checks was performed in earlier phase, by the IC (at parse main).
* ******************************************************************************/
//Mov uqCondReg, uqInReg, 4; 
//Mov uqFramePrsReg, 0, 4;
//Mov uqOffsetReg0,  0, 4;


Mov PC_STACK_STORE, /*PA_HANDLING_LAB*/FRAME_CONT_ACTION_LAB , 2;
//check if L3 offset is supported
//If ( uqCondReg.bit[L3_SUPPORT_OFFSET] ) Jmp IP_PROT_DECODE_LAB, NO_NOP;      
Mov uqCondReg, HWD_REG7, 4;
MovBits uqOffsetReg0.byte[L3_OFFB], sHWD_bitsLayer3Offset, 5, RESET;

// Test whether the frame is legal - has less than 4 Vlans (expected 1 vlan for the switch, and up to 2 user vlans for the tunnel, if exist)

// Num Of Vlans > 3 ?
//If (!uqCondReg.BIT[sHWD_bitMoreThan3Tags_off]) jmp NOT_MORE_THEN_3_VLANS_LAB, NOP_1;
xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 
//PA case never return (no need Continue lab )
If (uqCondReg.BIT[sHWD_bitMoreThan3Tags_off]) jmp CHECK_FAIL_L2;
      //If (uqCondReg.BIT[sHWD_bitMoreThan3Tags_off]) MovBits uqInReg.BIT[L2_UNS_PROT_OFFSET], 1, 1;
    If ( uqCondReg.BIT[sHWD_bitMoreThan3Tags_off] ) MovBits ENC_PRI.bit[13] , 1 , 3;
    MovBits bytmp, byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT], 1, RESET;
  

//EZstatIncrByOneIndexImm ROUTING__L_CNTR__MORE_THEN_3_VLANS_IN_FRAME;

//Jmp PARSING_DONE_LAB, NOP_1; // 4- More than 3 Vlan's in stack
//    MovBits uqInReg.BIT[L2_UNS_PROT_OFFSET], 1, 1;



//MovBits uqInReg.BIT[L2_UNS_PROT_OFFSET], 1, 1;
//jmp  PARSING_DONE_LAB /*JUST_INCREMENT*/;
   //Mov ALU , PARSING_DONE_LAB , 4;
//--bug  enable this counter in routing mode
   //mov sStat_uqAddress, ROUTING__L_CNTR__MORE_THEN_3_VLANS_IN_FRAME, 4,STAT_OPT;
   //movbits    SREG_LOW [1].BYTE [2], ((0x06 << offset_bit(EZstat_StsCmd.bitsOpcode)) | ( 0 << offset_bit(EZstat_StsCmd.bitCtxEnable)) | ( 0 << offset_bit(EZstat_StsCmd.bitsCtxOffset))),     offset_bit(EZstat_StsCmd.bitsReserved_11)   ;
 


NOT_MORE_THEN_3_VLANS_LAB:

// A check of (numOfVLANs !=0) was performed in Prs main, before reaching this code
MovBits ALU, sHWD_bitsNumberVlanInStack, 4, RESET; // Get 4 bits for number of VLANs detection (0/1/2/3 vlans, decoded as one hot respectively), and encode them into the values 0,1,2,3 respectively
encode  ALU, ALU, 1;
Add     ALU, ALU, bytmp, 1;                        // Simulate more VLAN's number for CAUI port
MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_IS_IPV4_BIT], sHWDall_bitL3IsIpV4, 2; // Determine IPv4\IPv6, in order to pass IP version of the outest level of the frame in the message for use by other TOPs.
                    //MSG_CTRL_TOPPRS_1_USER_VLAN_IN_FRAME_BIT

MovBits uqFramePrsReg.BIT[VLAN_TAG_NUM], ALU, 2,RESET;   // Keep the number of VLANs - 0/1/2/3

And ALU , byCtrlMsgPrs2 , {1<<MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT} , 1;

MovBits   ENC_PRI.bit[9] , 0 , 7;

//MovBits sHWD_bitMoreThan3Tags_off

MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_USER_VLAN_IN_FRAME_BIT], sHWDall_bitTwoTags, 1;
//MovBits ENC_PRI.bit[13] , sHWD_bitDaBroadcast , 3;
  

//JZ SET_SWITCH_USER_VLAN_INDICATION_FOR_ROUTING_MODE_LAB;
    //MovBits ALU, sHWD_bitEth2L2Type, 1, RESET;         // Get L2 protocol type 
Mov4Bits  ENC_PRI.bits[15,15,14,13] , sHWD4.bits[18,17,16,~26];
If (!bitPRS_isRoutingMode) MovBits ENC_PRI.bit[15] , 0 , 1;  
If (!Z ) MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_USER_VLAN_IN_FRAME_BIT], sHWDall_bitTagExist, 1;

//SET_SWITCH_USER_VLAN_INDICATION_FOR_ROUTING_MODE_LAB:
// Test Ethertype:
//try to use ENC_PRI agregation mode
//If ( UREG[1].bit[30] ) Jmp CHECK_FAIL_L2 ;
//    Nop;
//    Nop;
jmul  CHECK_FAIL_L2 , CHECK_FAIL_L2 , CHECK_FAIL_L2 , NO_NOP;
//set user vlan indication for packet arriving from CAUI
    
//jmul BPDU_MCAST , MCAST , BCAST , L2_NONE_ETH , TEST_TUNNEL_AWARE_LAB , TEST_TUNNEL_AWARE_LAB , TEST_TUNNEL_AWARE_LAB;
 
//And ALU, ALU, 0x01, 1;                             // Verify L2 protocol type is 0x1 (Ethernet)
//MovBits uqInReg.BIT[L2_BROADCAST_OFFSET], sHWD_bitDaBroadcast, 2;       // Mark L2_BROADCAST_OFFSET and L2_MULTICAST_OFFSET.


//Jz PARSING_DONE_LAB, NO_NOP; // Jump in case of invalid EtherType (i.e. not EtherType Version 2).
   //If (FLAGS.BIT[F_ZR]) MovBits uqInReg.BIT[L2_UNS_PROT_OFFSET], 1, 1; 
   //Movbits ALU, sHWD_bitL2CtrlFrame, 1; // Check for MAC_BC / MAC_MC or L2 control frames (BPDUs) and mark it in bits L2_BROADCAST_OFFSET and L2_MULTICAST_OFFSET, in L2_MULTICAST_OFFSET bit combine the reflection of L2_CONTRO_FRAMES too, i.e. if MAC_MC or L2_control_frame, then L2_MULTICAST_OFFSET will be set.

// Test MAC type:

// If routing mode AND (MAC_BC or MAC_MC or L2 control frame), then don't continue the parser's actions - it is not necesary as
// in case of routing mode need to punt to host all the MAC_BC, MAC_MC and L2 control frames.
// This case also does not require building a routing table key as the host will configure all such frames in routing mode either to be punted to the host or to be discarded.


//And     ALU, ALU, 0x01, 1;
//MovBits ALU, sHWDall_bitDaBrdcast, 3;  // MAC_BC, MAC_MC, and L2 control bits
//If (!FLAGS.bit[F_ZR]) MovBits uqInReg.BIT[L2_MULTICAST_OFFSET], 1, 1;   // Mark L2_MULTICAST_OFFSET as true also in case that this is a L2 control frames (BPDUs)
//And     ALU, ALU, 0x07, 1;             // Test MAC_BC or MAC_MC or L2 control frame bits from general decoder's result
//If (!bitPRS_isRoutingMode) jmp TEST_TUNNEL_AWARE_LAB, NOP_2;
//Jnz PARSING_DONE_LAB, NOP_2;           // Routing mode related code: If in routing mode and MAC type is BC\MC\BPDU - skip parsing

// Test Tunnel Aware state:

TEST_TUNNEL_AWARE_LAB:

// Packet from CAUI
If (uqCondReg.BIT[sHWD_bitNoTags_off] ) Jmp L3_PROT_DECODE_LAB; // jump if No User Vlan tunel, only 1 Vlan (the internally added Switch Vlan)
    nop;
    nop;

// Untagged frame: In case only 1 Vlan (switch Vlan) in frame, no need to check Tunnel Aware state
If (uqCondReg.BIT[sHWD_bitOneTag_off] ) Jmp L3_PROT_DECODE_LAB, NOP_2; // jump if No User Vlan tunel, only 1 Vlan (the internally added Switch Vlan)

// Tagged frame: There is more then 1 Vlan (Switch Vlan) in the frame (either 2/3 Vlans in the frame, i.e. 1/2 User Vlans). 
if (bitPRS_isRoutingMode) jmp ROUTING_MODE_CHECK_VLAN_AWARE_LAB, NOP_1;
   MovBits byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_USER_VLAN_IN_FRAME_BIT], 1, 1; // Prepare the routing enabled configuration to be passed via the message.

// Transparent mode
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_VLAN_TUN_CFG_BIT]) Jmp CONF_NETWORK_BYPASS_LAB , NOP_2; // Jump to CONF_NETWORK_BYPASS_LAB in case that more then 1 Vlan in the frame (2 or 3 Vlans i.e. user Vlan(s) exists) and GC_CNTRL_0_VLAN_TUN_CFG_BIT is clear
jmp L3_PROT_DECODE_LAB, NOP_2;

// Routing mode: Tagged frame (more then 1 Vlans in the frame) - Now check Vlan Aware mode
ROUTING_MODE_CHECK_VLAN_AWARE_LAB:

// If VLAN_UNAWARE (GC_CNTRL_0_VLAN_TUN_CFG_BIT is clear), set the frame to be sent to the network, and mark the case
// so that the parser will build the routing TCAM lookup key, and then stop the praser's execution.
// In case that more then 1 Vlans in the frame (2 or 3 VLANs i.e. user Vlan(s) exist, and configuration is set to vlan unaware , and in routing mode, set the flag
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_VLAN_TUN_CFG_BIT]) MovBits bitTmpCtxReg2DeferParsingDoneUntilBuildRoutingKey, 1, 1;

/* *************************************************
 Start parsing L2.5 (MPLS), L3 and L4 of the frame
***************************************************/

L3_PROT_DECODE_LAB:

// When the frame is a RadwareTunnelGRE start analisys the L3 offsets of it after the first IPv4.GRE section (skip the IPv4.GRE from being analized)
MovBits ALU, bitTmpCtxReg2RemoveRdwrGRETunnel, 1;
And     ALU, ALU, 0x01, 1;
Mov4Bits ENC_PRI.bits[15,14,13,13] ,  sHWD9.bits[14,15,16,17] ; 
   
Jnz L_PRS_RADWARE_GRE_TUNNEL_L3_HANDLE_LAB;
   Mov FMEM_BASE, uqOffsetReg0.byte[L3_OFFB], 2;
   //policy set default vlan
   PutKey UNF_PROT_VLAN_OFF (COM_KBS), 0x1000, CMP_POLICY_VLAN_SIZE; // set default VLAN id
   
   //Nop;



/*   
Jmul UNS_L3_PROT_LAB,      // Protocol type 0x8864 (PPPoE, unsupported)
     UNS_L3_PROT_LAB,      // Protocol type 0x0806 (ARP, unsupported)
     UNS_L3_PROT_LAB,      // Protocol type 0x88A8 (MAC in MAC, unsupported)
     MPLS_DECODE_LAB,      // Protocol type 0x8848 (MPLS Multicast)
     MPLS_DECODE_LAB,      // Protocol type 0x8847 (MPLS Unicast)
     IPv6_PROT_DECODE_LAB, // Protocol type 0x86DD (IPv6)
     IP_PROT_DECODE_LAB;   // Protocol type 0x0800 (IPv4)

 */
 Jmul IP_PROT_DECODE_LAB , IPv6_PROT_DECODE_LAB , MPLS_DECODE_LAB , NO_NOP;
     MovBits byCtrlMsgPrs3.bit[ROUTE_NETSTACK_BRMCAST_OFF] , HWD_REG7.bit[11] , 1;
     Nop;

UNS_L3_PROT_LAB:

MovBits  CAMO.bit[30] , byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT] , 1;
Mov FMEM_OFFSET1 , -0x14 , 2;
get      CAMIH.BYTE[ 2 ], -2(FMEM_BASE), 2;
If (CAMO.bit[30])  Mov FMEM_OFFSET1 , -0xe , 2;
Nop;
Nop;
get      CAMI.BYTE[ 0 ] , FMEM_OFFSET1(FMEM_BASE), 6;
lookcam  CAMO, CAMI, TCAM64[ LACP_GROUP ], KEY_SIZE 8;
nop;
nop;
// Note: protocol types from the protocol decoder results, which are other than the ones loaded to ENC_PRI will also fall through and arrive here.
Mov3Bits    ALU.BITS[0,1,2], uqGcCtrlReg0.BITS[0,1,GC_CNTRL_0_ROUTING_ENABLED_BIT]; //order action type bits (uqGcCtrlReg0.BITS[0,1]) and routing bit (uqGcCtrlReg0.BIT[31] in ALU.BITS[0,1,2] respectively)
And         ALU,  ALU,  0x7,  1; // mask inorder to have these bits only
Xor         ALU,  ALU,  0x6,  1; // Xor is for compare bits to b110, which is (RoutingMode && Action==BYPASS)
//cancel L3 policy search for this packet
MovBits uqGcCtrlReg0.bit[GC_CNTRL_0_POLICY_NON_EMPTY_BIT] , 0 , 1;

if       ( !FLAGS.BIT [ F_MCC ] )
      jmp   $ , NOP_2;

//LACP in static trunk/port transparent mode
If (!FLAGS.bit[F_MH]) jmp NONE_LACP , NOP_2;

//tracepoint magic
Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;

jmp NETW_P0_BYPASS_LAB , NOP_2;

NONE_LACP:
// Bug fix by Guy for Build2 (Release 9): In Bypass mode the packet does not go through packet anomalies, so configure L2 packets to be sent to the host is done manually here.
if (FLAGS.bit[F_ZR]) jmp  HOST_P0_BYPASS_LAB , NOP_2;

jmp PARSING_DONE_LAB, NO_NOP; // This case does not require building a routing table key as the host will configure all such frames in routing mode either to be punted to the host or to be discarded (such frames that arrive from the network will never be routed to the network).   
   MovBits uqInReg.BIT[L3_UNS_PROT_OFFSET], 1, 1;
   Nop;


// If L3 == MPLS (actually acts as L2.5), make manual decoding since HW decoder does not decodes MPLS label // ##TODO_OPTIMIZE: In NP4 there is MPLS HW decoder (see Decode_mpls command). check if we want to use it instead of the manual MPLS code handler.
MPLS_DECODE_LAB:

/* In routing mode frames with MPLS labels are not supported. in this case stop the frame parsing and mark L2_unsupported.
   the PA will either punt to the host or discard the frame */
if (bitPRS_isRoutingMode) jmp CHECK_FAIL_L2;
    MovBits ENC_PRI.bit[13] , 1 , 3;
   // Important: the mcode trusts that the host prevents configuration to Continue Or to Send_to_network when L2_unsupported, and only allows configuration of discard or punt to host !
   // As a result, this case does not require building a routing table key as the host will configure all such frames in routing mode either to be punted to the host or to be discarded (such frames that arrive from the network will never be routed to the network).
   Nop;

/* In transparent mode just skip the MPLS headers and continue cheking the frame assuming that after
   the MPLS headers the payload will be of type IPv4 or IPv6. */ //##TODO_GUY_BUG_FOUND: this asumption is not necesarily true. the type after the MPLS is depended on the tunnel setting and not available in the frame. checking if the values of the first byte start with 4 or 6 to match IPv4 or IPv6 will give only statistical probability of 1/16 for a real match. this does not assure that the next protocol type is what it is.
//Mov ENC_PRI, 0, 2;
MovBits ENC_PRI.bit[13], sHWD_bitMpls1LabelOnly, 3; // Get the number of MPls labels from the label stack. HWD_REG8.bit[0] = sHWD_bitMpls1LabelOnly when frame has MPLS in it.

if (!uqGcCtrlReg0.bit[GC_CNTRL_0_MPLS_TUN_CFG_BIT]) jmp CONF_NETWORK_BYPASS_LAB; // ##TODO_OPTIMIZE move this check to more early place.
// Load 3 different offsets to ENC_PRO, used below for offsets in frame
MovMul 12, 8, 4;
   Add FMEM_BASE, FMEM_BASE, ENC_PRO, 1;

// In case of 1/2/3 MPLS labels jump to IP_PROT_DECODE_LAB
Jmul IP_PROT_DECODE_LAB, // The code assume that after MPLS there will be IPv4 or IPv6 payload. In actual this data should be in
     IP_PROT_DECODE_LAB, // a MPLS table (psuedo wire element that hods the MPLS handlig instruction according to the MPLS label)
     IP_PROT_DECODE_LAB; // inside the router and the data in the table should be built by the host according to LDP/RSVPTE protocol messages.
                    // A test that checks if the protocol type is IPv4 / IPv6 after the MPLS part is performedm, but it may give false match
                         // result in case of MARTINI that has MAC that starts with 4 or 6, i.e. it is not fully reliable.

// AmitA: More then 3 MPLS labels, thus fall through. (No MPLS is not an option as the code lended in the MPLS_DECODE_LAB label.
// This case does not require building a routing table key as the host will configure all such frames in routing mode either to be punted to the host or to be discarded (such frames that arrive from the network will never be routed to the network).
jmp CHECK_FAIL_L2, NOP_1;
   //MovBits uqInReg.BIT[L2_UNS_PROT_OFFSET], 1, 1;
   MovBits ENC_PRI.bit[13] , 1 , 3;
   Nop;


///////////////////////////////////////
//  IP Protocol Decoding (IPv4\IPv6)
///////////////////////////////////////

IP_PROT_DECODE_LAB:

// In case we have IPv4\6 (without mpls label before) or mpls label frame (with ipv4/6 after it). 
// We assume that IPv4 or IPv6 is followed by the mpls label, and the check for this is not robust.
#define TUN_L4_TYPE_OFF_BIT1  (TUN_L4_TYPE_OFF+1);
#define TUN_L4_TYPE_OFF_BIT2  (TUN_L4_TYPE_OFF+2);
#define L4_TYPE_OFF_BIT1      (L4_TYPE_OFF+1);
#define L4_TYPE_OFF_BIT2      (L4_TYPE_OFF+2);
#define byPRS_tmp1_IP_ver      			 bytmp1;    // ##TODO_OPTIMIZE: change the define with vardef and make it work.
#define uxPRS_tmp1_IP_fragmentationData  uxTmpReg1; // ##TODO_OPTIMIZE: change the define with vardef and make it work.

//Mov CAMO, 0, 4;
//instead nop
Mov ENC_PRI.byte[0] , 0 , 2 ;
//reload PA mask ( tunnel case )
xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 
Mov uqTunnelOffsetReg.byte[L4_OFFB], uqOffsetReg0.byte[L4_OFFB], 2;
Get byPRS_tmp1_IP_ver, 0(FMEM_BASE), 1;
//Get byPRS_tmp1_IP_ver, 0(FMEM_BASE), 1;

///////////////////////////////////
//       L3 IPv4 Parsing
///////////////////////////////////

decode_ipv4  0(FMEM_BASE), 24;


Mov uqOffsetReg0.Byte[L3_OFFB], FMEM_BASE, 2;

//mov   uqCauiLagHash, 0, 1; //MB:2018: CAUI Lag Hash func result init

// Identify whether ip type is IPv4, IPv6 or other verify IPv6 for case of IP in a tunnel (probability of incorrect IPv6 identification: 1/16)
And ALU, byPRS_tmp1_IP_ver, 0xF0, 1;  // ##TODO_OPTIMIZE: consider changing the code to inspect the next protocol type in all places that jumps to here and cancel the IPv4/IPv6 checks here. (Instead of the existing code jump directly to the correct handling location - IPv4 / IPv6 / DISCARD  due to L3_Unsupported handling labels).
Sub ALU, ALU, 0x60, 1;
   Mov4Bits uqFramePrsReg.bits[TUN_L3_TYPE_OFF, TUN_L4_TYPE_OFF, TUN_L4_TYPE_OFF_BIT1, TUN_L4_TYPE_OFF_BIT2],
            uqFramePrsReg.bits[    L3_TYPE_OFF,     L4_TYPE_OFF,     L4_TYPE_OFF_BIT1,     L4_TYPE_OFF_BIT2];

Jz IPv6_PROT_DECODE_LAB, NO_NOP; // if IPv6 go to IPv6 handling. this can happen due to direct jumping to here using jmp command, not due to the JMUL that uses the decoder's bits.
   // keep the outer tunnel information
   Mov uqTunInReg, uqInReg, 4;  
   And ALU, byPRS_tmp1_IP_ver, 0xF0, 1;
#undef byPRS_tmp1_IP_ver;

// verify IPv4 for case of IP in a tunnel (probability of incorrect IPv4 identification: 1/16)
//Mov PA_CASE , IC_CNTRL_0_L3_UNK , 2 , THROW( sIpv4ProtDec_CAMO_bitBadVer );   
 If (sIpv4ProtDec_CAMO_bitBadVer) jmp PARSING_DONE_LAB;
    //set policy ipv4 mapping
    Mov  uqTmpReg6 , IPV4_IPV6_MAPPING_2ND, 4;
    If (sIpv4ProtDec_CAMO_bitBadVer)  MovBits uqInReg.BIT[L3_UNS_PROT_OFFSET], 1, 1;


   
//well , from unknown reason bit    CAMO.28,27,26 dosen't work in case of tunnel inner header
//let's calculate it manually
If ( !uqGcCtrlReg0.bit[ GC_CNTRL_GLOB_TUNNEL_STATUS_BIT ] ) jmp  GET_FLEN_ERR_FRROM_DECODER;  
    //or 3 bit ip header length error indication ( bit 18-19set 0 after decoder )
    Mov3Bits CAMO.bits[18,18,18] , CAMO.bits[28,27,26];
    get ALU , IP_LEN_OFF(FMEM_BASE), 2, SWAP;

Add ALU , FMEM_BASE , ALU , 2;
Sub ALU , ALU , sHWD_uxFrameLen , 2;
// Get hash 2 bytes
//Mov uxHash2BVal, HWD_REG5.byte[0], 2;

PutKey MSG_HASH_2B_CORE_OFF(HW_KBS), HWD_REG5.byte[0], 2 ;
//indicate frame len error 
//if (!FLAGS.bit[F_ZR]) MovBits CAMO.bit[18] , 1 ,1;
if (A) MovBits CAMO.bit[18] , 1 ,1;
//I failed to explan WTF mean , it connected to internal frag inside tunnel
if (uqGcCtrlReg0.bit[GC_CNTRL_0_FRAME_ACTION_DROP]) MovBits CAMO.bit[18] , 0 ,1;

GET_FLEN_ERR_FRROM_DECODER:
    
If (!bitPRS_isRoutingMode) jmp IPV4_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB /* , NOP_2 */;
    Fxor byHashVal, HWD_REG5.byte[0], HWD_REG5.byte[1], 1; // HWD_REG5.byte[0..1] = sIpv4ProtDec_HWD5_uxSipDipHashRes
    // We use register uqInReg for additional bit indications needed for packet anomalies macro (global register uqFramePrsReg does not have enough free bits so we use this register)
    //If (FLAGS.BIT[F_SN]) MovBits uqInReg.BIT[L3_HLEN_ERR_OFFSET], 1, 1; //##TODO_GUY_BUG_FOUND (?) why not check F_ZR ? this only checks if frame size > IPv4.len and does not include chekc for size < IPv4.len  to mark HLEN error

    // Make sure that the DIP KEY for the TCAM Lookup will be written only for the outer IP of the frame and only for routing mode
    MovBits ALU, bitTmpCtxReg2WasRoutingTcamKeyWritten, 1;


// Check if the RoutingTableIndex key was already written to the TCAM (if so then this is not the outer IP so no need to write it again)
And ALU, ALU, 0x01, 1;
MovBits bitTmpCtxReg2WasRoutingTcamKeyWritten, 1, 1;        // mark that the RoutingTableIndex key was written to the TCAM Lookup (will be done now, unless already done before).
Jnz IPV4_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB;  // If the RoutingTableIndex key was already written to the TCAM Key, meaning this is routing mode but not parser itteration on the outer level. in this case jump to skip the Key update.
    //ipv4 policy key mapping
    nop;
    //ipv4 policy key mapping 3
    Nop;
    //
// Routing mode: Route according to outer IPv4 DIP

// Write the DIP into the Key and perform all the relevant settings to invoke the TCAM lookup.
BuildTcamRoutingTableIndexKeyFromIPv4DIP  IPV4_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB, 
                                          CONF_NETWORK_BYPASS_LAB, 
                                          PARSING_DONE_LAB;

IPV4_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB:


//check HLEN result , use UREG[30] aggregation 
Mov PA_CASE , IC_CNTRL_0_IPv4_INC_PKTHDRLEN , 2 , THROW( CAMO.bit[18] );   
// Arriving here after writing the TCAM RoutingTableIndex key or in case of skipping writing the key (Due to transparent mode, or key was already written for a more outer DIP).
// Put in the message the folded xor result of the IPv4 SIP + DIP hash result.
    //set the flag to avoid calculation based on inner IP (for example in GRE) 
    //MovBits uqCondReg.bit[L3_CALC_SIP_DIP_HASH], 1, 1;
    //Nop;
    //PutKey MSG_HASH_2B_CORE_OFF( COM_KBS ), uxHash2BVal , 2;  // Store one byte hash and 2 bytes hash
    nop;
    nop;
    //PutKey MSG_HASH_CORE_OFF( HW_KBS ), byHashVal, 1;  // Store one byte hash and 2 bytes hash




    //Mov uqTmpReg5, IPV4_IPV6_MAPPING_4TH, 4;


///////////////////////////////////
//      IPv4 Checksum Check
///////////////////////////////////
//

//IPv4_HDR_CHKSUM_LAB:
// If packet has no IP options we take checksum result from the IPv4 protocol decoder,
// if packet has IP options then the checksum result in the protocol decoder is not valid, so checksum calculation will be performed manualy.
// IPv4 checksum offset is in CAMO (result of IPv4 protocol decoding)
if (!sIpv4ProtDec_CAMO_bitIpOptionExist) jmp IPv4_AFTER_HDR_CHKSUM_TEST_LAB, NO_NOP; // If options does not exist in frame, jump to relevant offset to continue the checks in the frame. sIpv4ProtDec_CAMO_bitIpOptionExist = CAMO.bit[16]
   // Prepare header size for case that manual checksum calculation will be needed
   MovBits SIZE_REG, sIpv4ProtDec_HWD4_byHdrLenght, 6; // sIpv4ProtDec_HWD4_byHdrLenght = HWD_REG4.bit[24]
      // In case if frame with no IP options, the checksum bit in decoder's result is valid. copy the checksum status from the IPv4 protocol decoder's result as preperation for handling this state.
      //MovBits uqInReg.BIT[IPv4_CHECKSUM_ERR_OFFSET], sIpv4ProtDec_CAMO_bitIpChskSumErr, 1; // sIpv4ProtDec_CAMO_bitIpChskSumErr = CAMO.BIT[30]
   //reset this flag if option exist in IP
   if (sIpv4ProtDec_CAMO_bitIpOptionExist) MovBits sIpv4ProtDec_CAMO_bitIpChskSumErr , 0 , 1;

      // IP options exist, thus the checksum decoding result is invalid, so the checksum should be calculate explicitly to verify if it is OK or not.
      MovBits uqInReg.BIT[IPv4_CHECKSUM_ERR_OFFSET], 0, 1; // nop; // mark no checksum error before the test is done. this overwrites the invalid value that was written to this bit dew lines above.
//check IP header checksum
CheckSum 0(FMEM_BASE), SIZE_REG;

   // Wait checksum computation to complete, as this is a multiple command
   //EZwaitflag F_MCC;

   if       ( !FLAGS.BIT [ F_MCC ] )
      jmp   $, NOP_2;

Sub ALU, CHECKSUM_REG, 0, 2;
   Nop;
// Utiliate the header checksum correctness result
If (!FLAGS.BIT[F_ZR]) MovBits sIpv4ProtDec_CAMO_bitIpChskSumErr, 1 , 1;

IPv4_AFTER_HDR_CHKSUM_TEST_LAB:


//Get $uqPRS_IPv4DIP, IP_DIP_OFF(FMEM_BASE), 4, SWAP;
Copy  UNF_PROT_DIP_OFF(COM_KBS), IP_DIP_OFF(FMEM_BASE),4, SWAP;
Mov PA_CASE , IC_CNTRL_0_IPv4_INC_CHEKSUM , 2 , THROW( sIpv4ProtDec_CAMO_bitIpChskSumErr  );   

//continue lab for hlen  checksum
IPv4_INCHLEN:
    //policy lksd key 
    PutKey UNF_PROT_DIP_OFF_2ND(COM_KBS), uqTmpReg6, 4;
    PutKey UNF_PROT_SIP_OFF_2ND(COM_KBS), uqTmpReg6, 4;
    
   //policy lksd key
    //mov    uqTmpReg6 , IPV4_IPV6_MAPPING_3RD, 4;

IPv4_INC_CHEKSUM:

///////////////////////////////////
//        IPv4 TTL Check
///////////////////////////////////
//IPv4_HDR_TTL_LAB:

Copy CMP_BDOS_L23_TTL_OFF(COM_KBS),     IP_TTL_OFF(FMEM_BASE),  CMP_BDOS_L23_TTL_SIZE;           // size is '1'. no need for swap 
Copy CMP_BDOS_L23_TOS_OFF(COM_KBS),     IP_TOS_OFF(FMEM_BASE),  CMP_BDOS_L23_TOS_SIZE;
Copy CMP_BDOS_L23_ID_NUM_OFF(COM_KBS),  IP_ID_OFF(FMEM_BASE),   CMP_BDOS_L23_ID_NUM_SIZE,  SWAP; // Id is 2 
Copy CMP_BDOS_L23_L3_SIZE_OFF(COM_KBS), IP_LEN_OFF(FMEM_BASE),  CMP_BDOS_L23_L3_SIZE_SIZE, SWAP; // Size is 2 

// Check if TTL == 0
Sub ALU, sIpv4ProtDec_HWD4_byNewTtl, 0xff, 1;    // sIpv4ProtDec_HWD4_byNewTtl - contains the hop limit - 1
   //nop; //MovBits uqFramePrsReg.BIT[L3_TYPE_OFF], L3_TYPE_IPV4, 1;
//If (FLAGS.BIT[ F_ZR ]) MovBits uqInReg.BIT[IPv4_TTL_EXP_OFFSET], 1, 1;
// Important: the mcode trusts that the host prevents configuration to route (send to NW) IP expired frames (both TTL and hop count), and only allows configuration of discard or punt to host !
//Nop;
//If (FLAGS.BIT[ F_ZR ]) MovBits uqInReg.BIT[IPv4_TTL_EXP_OFFSET], 1, 1;
//policy lksd key
Get  uqTmpReg9 ,  IP_DIP_OFF(FMEM_BASE) , 1; 
Mov PA_CASE , IC_CNTRL_0_INC_TTL , 2 , THROW( FLAGS.BIT[ F_ZR ]  );   
    //policy lksd key    
    Get  uqTmpReg9.byte[1] ,  IP_SIP_OFF(FMEM_BASE) , 1;
    //Mov FMEM_OFFSET1 , IP_PRT_OFF , 2 , RESET;
    Get CAMI ,  IP_PRT_OFF ( FMEM_BASE ) , 1;

TTL_CONT:
Mov ALU , uqTmpReg9.byte[0] , 1 , RESET;
CmpSet ALU.byte[3] , ALU , 0x007f , RESULT 1 ;
Mov ALU , uqTmpReg9.byte[1] , 1; 
CmpSet ALU.byte[3] , ALU , 0x007f , RESULT 1;
//Nop;
Copy  UNF_PROT_SIP_OFF(COM_KBS), IP_SIP_OFF(FMEM_BASE),4, SWAP;
MovBits  CAMO.bit[0] , ALU.byte[3] , 1; 
xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH; // TOPparse MREG[10] 

If (CAMO.bit[0]) jmp LAND_IPLOCAL_L4ZERO;
    If (CAMO.bit[0]) Mov PA_CASE , IC_CNTRL_1_SIPDIP_LOCAL  , 2 ;
    If (CAMO.bit[0]) Mov PC_STACK , LOCAL_CONT , 2;  

LOCAL_CONT:




//policy lksd key
//if don't frag is set reset hw decoder first frag indication . According to bug_80975.pkt I suspect Hardware decoder in 
//some kind of false positive . 
//If (  sIpv4ProtDec_CAMO_bitIpFlagDF ) jmp FRAG_CONT;
MovBits ALU, sIpv4ProtDec_HWD4_byHdrLenght, 6, RESET;   //get l4 sIpv4ProtDec_HWD4_byHdrLenght = HWD_REG4.bit[24]
Add uqOffsetReg0.byte[L4_OFFB], FMEM_BASE, ALU, 2;    
    

xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 
//////////////////////////////////////
//  IPv4 Fragmented Frame Handling
//////////////////////////////////////
//sIpv4ProtDec_CAMO_bitFirstFrag - dosen't work correctly if mpsl or 2 vlans in packet


// Check if frame is fragmented: first check if current frame is part of a fragmented frame - middle or last
Get ALU, IPv4_FRAGMENT_OFFSET(FMEM_BASE), 2, SWAP ;
//Mov ALU, 0x1FFF, 2; // 0x1FFF is the fragment offset mask
//And ALU, ALU, 0x1FFF , 2;
Sub ALU, ALU, 0 , 2 , MASK_00001FFF , MASK_SRC1;

//--bdos ????
PutKey UNF_FRAG_L4_MASK(COM_KBS), 0xff , 1;


If ( !FLAGS.BIT[ F_ZR ] )  PutKey UNF_FRAG_L4_MASK(COM_KBS), { 1<< L2_VLAN_VALIDATION_BIT | 1<<PACKET_SIZE_VALIDATION_BIT }, 1;

If ( !FLAGS.BIT[ F_ZR ] ) jmp GLOB_ANOMALY_LAB;
    If ( !FLAGS.BIT[ F_ZR ] ) Mov PA_CASE , IC_CNTRL_0_FRAG , 2 ;   
    If ( !FLAGS.BIT[ F_ZR ] ) MovBits uqFramePrsReg.BIT[L3_FRAG_OFF], 1, 1; 
      
//If ( ZR (frag offset == 0 ) && ! sIpv4ProtDec_CAMO_bitIpFlagMF ) 
///////////////////////////////////
//     L4 Protocol Parsing
///////////////////////////////////
Mov PA_CASE , IC_CNTRL_0_FIRST_FRAG , 2 , THROW(sIpv4ProtDec_CAMO_bitIpFlagMF  );   
    //MovBits uqFramePrsReg.BIT[L3_FRAG_OFF], 1, 1;
    If (sIpv4ProtDec_CAMO_bitIpFlagMF) MovBits uqFramePrsReg.BIT[L3_FRAG_OFF], 1, 1; 
    //reuse global drop flag , to skip hlen in case of first frag
    If (sIpv4ProtDec_CAMO_bitIpFlagMF) MovBits uqGcCtrlReg0.bit[GC_CNTRL_0_FRAME_ACTION_DROP] ,  1 , 1;



#undef uxPRS_tmp1_IP_fragmentationData;

//jnz IPv4_FRAG, NO_NOP;	// If frame is fragmented, and this is the middle or last fragment (not the first fragment of the frame)

//IPv4_FRAG -continue label  


//    Nop;
//    Nop;

//Fragment IPv4 packet, pass here only for first fragment
FRAG_CONT:

// If frame is not middle or last check if this is the first fragment, if not - this is not a fragmented frame
//valid both for first fragment and no fragment
//MovBits uqInReg.bit[FIRST_FRAG_OFFSET], sIpv4ProtDec_CAMO_bitIpFlagMF, 1; // sIpv4ProtDec_CAMO_bitIpFlagMF = CAMO.bit[20]
//MovBits uqFramePrsReg.BIT[L3_FRAG_OFF], sIpv4ProtDec_CAMO_bitIpFlagMF, 1;

// this case when first fragment or not only, depends only on the more fragment flag

MANUAL_L4_IPv6_PROTOCOL_DECODE_LAB:
MANUAL_L4_PROTOCOL_DECODE_LAB:
//Nop;
mov byL4Proto, CAMI,1;
// Detect next protocol (build bitmap according to detection of HW_DEC)
//LookCam CAMO ,  FMEM_OFFSET1(FMEM_BASE) , BCAM8[L4_HDR_TYPES_COMBINATION_GRP] ,GET_SIZE 1 , MASK_000000FF ,0 ,WR_ENC_PRI;
LookCam CAMO ,  CAMI , BCAM8[L4_HDR_TYPES_COMBINATION_GRP] ,WR_ENC_PRI;

//reload PA checkbase 
xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH; // TOPparse MREG[10] 

#define uqDip   uqTmpReg9;
//check landbase attack SIP==DIP
If (sIpv4ProtDec_CAMO_bitDipEqSip) jmp LAND_IPLOCAL_L4ZERO;
    If (sIpv4ProtDec_CAMO_bitDipEqSip) Mov PA_CASE , IC_CNTRL_1_LAND_ATTACK  , 2 ;
    If (sIpv4ProtDec_CAMO_bitDipEqSip) Mov PC_STACK , LAND_CONT , 2;  

//continue action after land attach treat
LAND_CONT:

get   uqDip, IP_DIP_OFF(FMEM_BASE), 4; //MB:2018: prepare DIP in uqTmpReg9 register for CAUI Lag Hash func calculation

Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2; 

MovMul L4_TCP_TYPE , L4_UDP_TYPE , L4_ICMP_TYPE , L4_SCTP_TYPE , L4_IGMP_TYPE , L4_GRE_TYPE , L4_IPinIP_TYPE;   
MovBits uqFramePrsReg.BIT[L4_TYPE_OFF] , ENC_PRO , 3;


//set minimal header len  
MovMul TCP_BASE_SIZE , UDP_BASE_SIZE , ICMP_BASE_SIZE , SCTP_BASE_SIZE , IGMP_BASE_SIZE , 0 ,0;
MovBits uqFramePrsReg.bit[L4_MIN_LEN_OFF], ENC_PRO, 6; 

//fxor  uqCauiLagHash, uqDip.BYTE[0], uqDip.BYTE[2], 2,; //MB:2018: CAUI LAG Hash func calculation
#undef uqDip;
// L4 for bdos key 
Copy UNF_L4_PROT(COM_KBS), IP_PRT_OFF(FMEM_BASE),  CMP_BDOS_L23_L4_PROT_SIZE;

jmul TCP_DECODE_LAB , UDP_DECODE_LAB , ICMP_DECODE_LAB  , SCTP_DECODE_LAB , L4_PAYLOAD_LEN_CHECK_LAB , GRE_DECODE_LAB ,IPinIP_DECODE_LAB; 

/////////////////////////////////////////
//   Unsupported and IPsec L4 Protocols Handling
/////////////////////////////////////////
if (!FLAGS.BIT[F_MH]) Mov PA_CASE , IC_CNTRL_1_UNK_L4 , 2 ; 
//continue label will be  L4_PAYLOAD_LEN_CHECK_LAB
if (FLAGS.BIT[F_MH]) Jmp IPSEC_DECODE_LAB , GLOB_ANOMALY_LAB /*L4_PAYLOAD_LEN_CHECK_LAB*/;
    Mov uqOffsetReg0.byte[L4_OFFB], 0, 2;
    MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3;




L_PRS_RADWARE_GRE_TUNNEL_L3_HANDLE_LAB:
#pragma EZ_Warnings_Off; // to prevent warning: command source operand intersect with variable bitTmpCtxReg2RadwareGRETunnelAroundIPv4
MovBits ENC_PRI.bit[14],                                  bitTmpCtxReg2RadwareGRETunnelAroundIPv4, 2; // get the value of bitTmpCtxReg2RadwareGRETunnelAroundIPv4 and bitTmpCtxReg2RadwareGRETunnelAroundIPv6 to ENC_PRI
MovBits byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_IS_IPV4_BIT], bitTmpCtxReg2RadwareGRETunnelAroundIPv4, 2;
#pragma EZ_Warnings_On;

Jmul IPv6_PROT_DECODE_LAB,         // IPv4.GRE.IPv6.*
     IP_PROT_DECODE_LAB,           // IPv4.GRE.IPv4.*
     L_PRS_UNEXPECTED_ENC_PRI_VAL, // This bit should always be zero, thus jumping to this label is never expected.
     NO_NOP;
     
     Add uqOffsetReg0.byte[L3_OFFB], FMEM_BASE, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2; //##GUY_GRE_DECAP_AND_KEEPALIVE_IPv4_OPTIONS_SUPPORT
     Add FMEM_BASE,                  FMEM_BASE, IPV4_AND_RADWARE_TUNNEL_GRE_SIZE, 2;

// Fall through should never happen in case of RADWARE_GRE_TUNNEL (always expect weither IPv4 or IPv6 bit to be set)
L_PRS_UNEXPECTED_ENC_PRI_VAL:
   Jmp PARSING_DONE_LAB, NOP_1; // 4- More than 3 Vlan's in stack
      MovBits uqInReg.BIT[L2_UNS_PROT_OFFSET], 1, 1;

//Fragment IPv4 packet, but not the first fragment
IPv4_FRAG:
LookCam CAMO ,  IP_PRT_OFF(FMEM_BASE) , BCAM8[L4_HDR_TYPES_COMBINATION_GRP] ,GET_SIZE 1 , MASK_000000FF ,0 ,WR_ENC_PRI;
    Get bytmp1, IP_PRT_OFF(FMEM_BASE), 1;
    MovBits uqInReg.BIT[FRAG_IPv4_OFFSET], 1, 1;

//if unknown protocol, set unspecified type
if (!FLAGS.bit[F_MH]) MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3;

MovMul L4_TCP_TYPE , L4_UDP_TYPE , L4_ICMP_TYPE , L4_SCTP_TYPE , L4_IGMP_TYPE , L4_GRE_TYPE , L4_IPinIP_TYPE;   
//update protocol only if protocol is known
if (FLAGS.bit[F_MH]) MovBits uqFramePrsReg.BIT[L4_TYPE_OFF] , ENC_PRO , 3;

//clear bytmp1 LSbit, so that IPSEC1(0x33) will become IPSEC2(0x32)
MovBits bytmp1.bit[0],0,1;
   MovBits uqFramePrsReg.BIT[L3_NON_FIRST_FRAG_OFF], 1, 1;// This is not a first fragment packet
Sub ALU, bytmp1, L4_IPSEC2_PROT_TYPE, 1;
   //set fragment indication for bdos - policy
   MovBits uqFramePrsReg.BIT[L3_FRAG_OFF], 1, 1;

jnz IPSEC_NONE_DET_LAB , NOP_2;

IPSEC_IN_FRAG_L4:
xor ALU, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // using MREG[10]
And ALU, ALU, { 1 << IC_CNTRL_0_IPSEC_MODE_OFF }, 4;
   MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3;

jnz CONF_NETWORK_BYPASS_LAB, NOP_2;


IPSEC_NONE_DET_LAB:
Jmp PARSING_DONE_LAB, NO_NOP;
   //L4 offset is fail, no first fragment packet
   Mov uqOffsetReg0.byte[L4_OFFB], 0, 2; // Disregard L4 header fields since this is fragmented frame which is not first (middle or last)
   MovBits uqFramePrsReg.BIT[L3_FRAG_OFF], 1, 1;

ICMP_DECODE_LAB:
//check bgp for routing mode
 jmp L4_PAYLOAD_LEN_CHECK_LAB;
     MovBits byCtrlMsgPrs3.bit[ROUTE_NETSTACK_ICMPBGP_OFF] ,  1 , 1;
     Nop;

///////////////////////////////////
//     IPv6 Protocol Parsing
///////////////////////////////////

IPv6_PROT_DECODE_LAB:

//Mov ALU, TUN_DET_MASK, 4;
//And ALU, uqFramePrsReg, ALU, 4;
//   nop;
//jnz IPv6_INNHDR_LAB; 

//avoid tunnel internal header IP mode check
If ( uqGcCtrlReg0.bit[ GC_CNTRL_GLOB_TUNNEL_STATUS_BIT ] ) jmp IPv6_INNHDR_LAB;
// Avoid decoding packet if IPv4 only mode detected  
    xor ALU, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // using MREG[10] 
// We check here if IPV6 bypass mode is configured, and if so we redirect the frame back to the network
    And ALU, ALU, { 1 << IC_CNTRL_0_IPMODE_OFF }, 4;
   
if (bitPRS_isRoutingMode) jmp CHECK_CFG_IPV6_SUPPORT_WHEN_ROUTING_MODE_LAB;
    PutKey UNF_FRAG_L4_MASK(COM_KBS), 0xff , 1;
    Nop;

// Transparent mode

jnz CONF_NETWORK_BYPASS_LAB, IPv6_INNHDR_LAB ,NOP_2;   // IPv4 mode
//jmp IPv6_INNHDR_LAB, NOP_2;      // IPv4/IPv6 mode 

// Routing mode

CHECK_CFG_IPV6_SUPPORT_WHEN_ROUTING_MODE_LAB:
if (!FLAGS.bit[F_ZR]) MovBits bitTmpCtxReg2DeferBypassNetworkUntilBuildRoutingKey, 1, 1;
if (!FLAGS.bit[F_ZR]) PutKey  MSG_L3_USR_OFF(HW_KBS), uqOffsetReg0.byte[L3_OFFB], 4; // initialize in the message both MSG_L3_USR_OFF and MSG_L4_USR_OFF from uqOffsetReg0.byte[L3_OFFB] and uqOffsetReg0.byte[L4_OFFB]

// Code that handles both Transparent and routing mode
IPv6_INNHDR_LAB:

Decode_IPv6 0(FMEM_BASE), IPv6_BASE_SIZE;

// Make sure that the DIP KEY for the TCAM Lookup will be written only for the outer IP of the frame and only for routing mode
MovBits ALU, bitTmpCtxReg2WasRoutingTcamKeyWritten, 1;

If (!bitPRS_isRoutingMode) jmp IPV6_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB;
//--bug policy_ipv6 lksd avoid tunnel replace
    //Copy CMP_POLICY_DIP_OFF(COM_KBS), IPv6_DIP_OFF_2ND (FMEM_BASE), SIZE_REG, SWAP;
     If (uqGcCtrlReg0.bit[GC_CNTRL_GLOB_TUNNEL_STATUS_BIT]) MovBits uqFramePrsReg.bit[TUN_L3_TYPE_OFF] , uqFramePrsReg.bit[L3_TYPE_OFF] , 1;
     If (uqGcCtrlReg0.bit[GC_CNTRL_GLOB_TUNNEL_STATUS_BIT]) MovBits uqFramePrsReg.bit[TUN_L4_TYPE_OFF] , uqFramePrsReg.bit[L4_TYPE_OFF] ,3;     //Copy CMP_POLICY_SIP_OFF_3RD(COM_KBS), IPv6_SIP_OFF (FMEM_BASE), SIZE_REG, SWAP;
    

// Check if the DIP was already written to the TCAM (if so then this is not the outer IP so no need to write it again)
And ALU, ALU, 0x01, 1;
   MovBits bitTmpCtxReg2WasRoutingTcamKeyWritten, 1, 1;     // mark that the RoutingTableIndex key was written to the TCAM Lookup (will be done now, unless already done before).
Jnz IPV6_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB, NOP_2;  // If DIP was already written to the TCAM Key, meaning this is routing mode but not parser itteration on the outer level. in this case jump to skip the Key update.

// Routing mode: Route according to outer IPv6 DIP

// Write the DIP into the Key and perform all the relevant settings to invoke the TCAM lookup.
BuildTcamRoutingTableIndexKeyFromIPv6DIP  IPV6_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB, 
                                          CONF_NETWORK_BYPASS_LAB, 
                                          PARSING_DONE_LAB;


IPV6_AFTER_WRITING_ROUTING_TABLE_INDEX_KEY_LAB:

//set multicast mac and local dip/sip indication
Mov ALU , { 1<<3 | 1<<20 } , 4;
And ALU , CAMO , ALU , 4;
//check  CAMO bit 3 for multicast detection
// Arriving here after writing the TCAM RoutingTableIndex key or in case of skipping writing the key (Due to transparent mode, or key was already written for a more outer DIP).
//Get ALU, IPv6_PAYLOAD_LEN_OFF(FMEM_BASE), 2, SWAP;  // Get L4 size
Nop;
If (!FLAGS.bit[F_ZR])    MovBits byCtrlMsgPrs3.bit[ROUTE_NETSTACK_BRMCAST_OFF] , 1 , 1;
//Mov ENC_PRI, 0, 2;
//Mov CAMI, 0, 4;
//Add ALU, ALU, FMEM_BASE, 2;         // Add L2 size (L3 offset)
//   nop;      
//Add ALU, ALU, IPv6_BASE_SIZE, 2;    // Add L3 size (IPv6 header length)


//##TODO_OPTIMIZE - put in comment the next line after checking that it is really not necesarry and after updating the comment in it.

//Sub ALU, FRAME_LENGTH, ALU, 2; //  FRAME_LENGTH = HWD_REG0.byte[2]
//   nop;    
//EZwaitFlag F_MCC;// The decode_ipv6 takes total of XX clocks: YY clocks to complete decoding + additional 2 clocks for the result to be ready in HWD_REGs, so now the decoder's result should be ready and no need to check the decoder complete flag F_MCC.
   if       ( !FLAGS.BIT [ F_MCC ] )
      jmp   $;
      //set ffame len error         
         Nop;
         Nop;
         //If ( FLAGS.BIT[ F_SN ] )  MovBits sIpv6ProtDec_CAMO_bitPayloadLnghtGReatFrLenght , 1 , 1;

          
// Error: Incorrect version number
If (sIpv6ProtDec_CAMO_bitBadVer) Jmp PARSING_DONE_LAB, NOP_1;  
   If (sIpv6ProtDec_CAMO_bitBadVer) MovBits uqInReg.BIT[L3_UNS_PROT_OFFSET], 1, 1;


// Check Scope is Link-Local
If ( !CAMO.bit[20] ) jmp DUMB_2, NO_NOP;
   //Check if it is a tunnel
   And ALU, uqFramePrsReg, (1 << TUN_EN_OFF), 4;
   Nop;

If (!FLAGS.bit[F_ZR]) jmp DUMB_2, NOP_2;

Mov ALU , LOCAL6 , 1; 
If (bitPRS_isRoutingMode) jmp XPY_XPY_LAB , NOP_2 ; 

DUMB_2:
// Error: FRAME_LENGTH < (IPv6 payload length value (in the IPv6 header) + L2 size + IPv6 header length)
//If ( FLAGS.BIT[ F_SN ] ) MovBits uqInReg.BIT[L3_HLEN_ERR_OFFSET], 1, 1;

// Folded XOR of 1st and 2nd bytes of SIP/DIP hash
//DE14254 4-April-2016 Motic: use decode_ipv4 for {SIP,DIP} hash, instead of decode_general to calculate the HASH
// Avoid this kind of error when packet is fragmented
if (uqGcCtrlReg0.bit[GC_CNTRL_0_FRAME_ACTION_DROP]) Jmp IPv6_INC_PKTHDRLEN, NO_NOP;
    Fxor byHashVal, HWD_REG5.byte[0], HWD_REG5.byte[1], 1; // HWD_REG5.byte[0..1] = sIpv4ProtDec_HWD5_uxSipDipHashRes
    PutKey MSG_HASH_2B_CORE_OFF(HW_KBS), HWD_REG5.byte[0], 2 ;
    //Mov uxHash2BVal, HWD_REG5.byte[0], 2;                  // Get hash 2 bytes    

Mov PA_CASE , IC_CNTRL_0_IPv6_INC_PKTHDRLEN , 2 , THROW( sIpv6ProtDec_CAMO_bitPayloadLnghtGReatFrLenght /*CAMO.bit[24]*/ );     
    Nop;
    Nop;

IPv6_INC_PKTHDRLEN:

// Check if hop limit == 0
Sub ALU, sIpv6ProtDec_HWD4_byNewHopLimit, 0xff, 1;    // HWD_REG4.byte[1] = sIpv6ProtDec_HWD4_byNewHopLimit - contains the hop limit - 1

//If (!uqCondReg.bit[L3_CALC_SIP_DIP_HASH]) mov byHashVal,uqTmpReg5,1;


///////////////////////////////////
//      IPv6 Hop Limit Check
///////////////////////////////////

Nop;

//If (FLAGS.BIT[ F_ZR ]) MovBits uqInReg.BIT[IPv6_HOP_EXP_OFFSET], 1, 1;
Mov PA_CASE , IC_CNTRL_0_IPv6_INC_HOPLIMIT , 2 , THROW( FLAGS.BIT[ F_ZR ] );     
    MovBits uqFramePrsReg.BIT[L3_TYPE_OFF], L3_TYPE_IPV6, 1;
    //set the flag to avoid calculation based on inner IP (for example in GRE) 
    //MovBits uqCondReg.bit[L3_CALC_SIP_DIP_HASH], 1, 1;
    Nop;

HOP_LIMIT:
// Important: the mcode trusts that the host prevents configuration to route (send to NW) IP expired frames (both TTL and hop count), and only allows configuration of discard or punt to host !


///////////////////////////////////
//      IPv6 Headers Check
///////////////////////////////////

If  (sIpv6ProtDec_CAMO_bitDipEqSip) jmp LAND_IPLOCAL_L4ZERO ;
    If (sIpv6ProtDec_CAMO_bitDipEqSip) Mov PA_CASE , IC_CNTRL_1_LAND_ATTACK  , 2 ;
    If  (sIpv6ProtDec_CAMO_bitDipEqSip) Mov PC_STACK , IPv6_LAND_CONT , 2;
   
IPv6_LAND_CONT:

// Return FMEM_BASE on next header start
Add FMEM_BASE, FMEM_BASE, IPv6_BASE_SIZE, 2;
// Prepare for parsing extention headers and for jump             
Mov /*uqTmpReg5*/ALU, PC_STACK, 2, RESET;
Mov bytmp2, sIpv6ProtDec_HWD4_byNextProtHdr, 1; // Get next header protocol type, GuyE: 6.3.2014 needed???
Mov uqTmpReg5 , ALU , 4;
//Mov FMEM_OFFSET1 , IPv6_NEXT_HEADER_OFF , 2 ; 

// Copy decoded protocol type to ENC_PRI (to prepare the protocol decoder Jmul)
MovBits ENC_PRI.bit[9], sIpv6ProtDec_CAMO_bitNextIsTcp, 7;                                        

// Check if IPv6 subheader exists
//if (!sIpv6ProtDec_CAMO_bitNextIsOther) jmp MANUAL_L4_PROTOCOL_DECODE_LAB;  // Subheader does not exists (sIpv6ProtDec_CAMO_bitNextIsOther == 0)      
   mov CAMI, 0, 4;   
   Mov CAMI , sIpv6ProtDec_HWD4_byNextProtHdr , 1;
   
   
   //mov CAMI, 0, 4;   
   //get next protocol
   //mov CAMI, HWD_REG4.byte[0], 1;

Add uxTmpReg2, uqOffsetReg0.byte[L3_OFFB], IPv6_BASE_SIZE, 2; // uxTmpReg2 - represents L3 header size and will be calculated
Mov bytmp, 10, 1; // bytmp1 will count the number of extension headers, allowing 10 max.
            
GET_NEXT_HDR_LAB:

// Parsing of ipv6 subheaders

LookCam CAMO, CAMI, BCAM32[IPv6_SUBHEAD_ID_GRP]  ;

   MovBits FLAGS.bit[F_ED], 0, 1;   //clear ed flag NP4
   Mov ALU, bytmp, 1;
   Sub bytmp, bytmp, 1, 1;
   //MovBits CAMO.bit[sIpv4ProtDec_CAMO_bitDipEqSip] ,  CAMO.bit[sIpv6ProtDec_CAMO_bitDipEqSip]  , 1;
   Nop;

//in case of  next header is L4 reset FMEM_BASE to L3 start


if (!FLAGS.BIT[ F_MH ]) jmp MANUAL_L4_IPv6_PROTOCOL_DECODE_LAB, NO_NOP;
   MovBits ENC_PRI.bit[13], CAMO.bit[0], 3;
   if (!FLAGS.BIT[ F_MH ]) Mov uqOffsetReg0.byte[L4_OFFB], uxTmpReg2, 2; // Store calculated L3 header size 

JBE MANUAL_L4_IPv6_PROTOCOL_DECODE_LAB, NO_NOP;
   Mov bytmp2, L4_UNS_TYPE, 1;                          // set L4 Type to be unsupported (in case the jump is taken)
   MovBits uqInReg.BIT[IPv6_FRAMELEN_ERR_OFFSET], 1, 1; // set PA107 (IPV6_INCONSIST_HDR) in case the jump is taken

Get bytmp2, IPv6_EXTENSION_NEXT_HEADER_OFF(FMEM_BASE), 1;
Get bytmp3, IPv6_EXTENSION_HEADER_LENGTH_OFF(FMEM_BASE), 1;

MovBits uqInReg.BIT[IPv6_FRAMELEN_ERR_OFFSET], 0, 1; // unset PA107 (IPV6_INCONSIST_HDR) in case the jump was not taken

if (FLAGS.bit[F_ED]) jmp GET_NEXT_HDR_ERROR_LAB, NO_NOP;
   Mov uxTmpReg1, 0, 2;
   Mov CAMI, bytmp2, 1;
    
Jmul EXT_HEADER_AUT_LAB, 
     EXT_HEADER_FRAGMENT_LAB, 
     EXT_HEADER_HOP_ROUTE_DEST_LAB;
     
If (!CAMO.bit[3]) jmp MANUAL_L4_IPv6_PROTOCOL_DECODE_LAB,IPSEC_DECODE_LAB_IPV6_DET;
   Mov uqOffsetReg0.byte[L4_OFFB], uxTmpReg2, 2; // Store calculated L3 header size
   Nop; 

EXT_HEADER_HOP_ROUTE_DEST_LAB:

MovBits uxTmpReg1.BIT[3], bytmp3.BIT[0], 8;
   nop;
Add uxTmpReg1, uxTmpReg1, 8, 2;
   nop;
Add FMEM_BASE, FMEM_BASE, uxTmpReg1, 2;
   nop;
Sub ALU, FMEM_BASE, HWD_REG0.byte[2], 2;
   nop;

//check Ipv6 extension header lenght 
jbe IPv6_EXT_HDR_OK, NOP_2;

//header len greather than packet size
jmp PARSING_DONE_LAB, NO_NOP;
   MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3;
   MovBits uqInReg.BIT[IPv6_FRAMELEN_ERR_OFFSET], 1, 1;


IPv6_EXT_HDR_OK:

Jmp GET_NEXT_HDR_LAB, NO_NOP;
   // update L3 header size
   Add uxTmpReg2, uxTmpReg2, uxTmpReg1, 2;    
   nop;                            


EXT_HEADER_FRAGMENT_LAB:        

Get uqTmpCtxReg1, IPv6_EXTENSION_FRAG_OFF_OFF(FMEM_BASE), 2, SWAP;    
Mov uxOffsetReg1.byte[IPv6_FRAG_OFFB], FMEM_BASE, 2; // save Ipv6 fragment offset
Mov ALU, 0xFFFE, 2;
And ALU, uqTmpCtxReg1, ALU, 2;

if (FLAGS.bit[F_ED]) jmp GET_NEXT_HDR_ERROR_LAB, NO_NOP;
   Mov uxTmpReg1, 0, 2;
   Mov CAMI, bytmp2, 1;


MovBits uqInReg.bit[FRAG_IPv6_OFFSET], 1, 1;
MovBits uqFramePrsReg.BIT[L3_NON_FIRST_FRAG_OFF], 1, 1;


//reuse global drop flag , to skip hlen in case of first frag
MovBits uqGcCtrlReg0.bit[GC_CNTRL_0_FRAME_ACTION_DROP] ,  1 , 1;




// For non first fragment clear all L4 fileds validation bits
if (!FLAGS.BIT[ F_ZR ]) PutKey UNF_FRAG_L4_MASK(COM_KBS), { (1<< L2_VLAN_VALIDATION_BIT) | (1<<PACKET_SIZE_VALIDATION_BIT) }, 1;

//if (!FLAGS.BIT[ F_ZR ]) Jmp PARSING_DONE_LAB, NO_NOP;
   MovBits uqFramePrsReg.BIT[L3_FRAG_OFF], 1, 1;
   Mov uqOffsetReg0.byte[L4_OFFB], 0, 2;

//MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3;        

//first fragment interpreted as regular
//MovBits uqFramePrsReg.BIT[L3_FRAG_OFF] ,0,1;
Mov PA_CASE , IC_CNTRL_0_IPV6_FIRST_FRAG , 2 , THROW( FLAGS.BIT[ F_ZR ] ); 

    MovBits uqFramePrsReg.BIT[L3_NON_FIRST_FRAG_OFF], 0, 1;// This is a first fragment packet
    Nop;

IPV6_FIRST_FRAG:
//MovBits uqInReg.BIT[FIRST_FRAG_OFFSET], FLAGS.BIT[F_ZR], 1;

Jmp GET_NEXT_HDR_LAB;
    Add FMEM_BASE, FMEM_BASE, 8, 1;
    Add uxTmpReg2, uxTmpReg2, 8, 2; // update L3 header size    


                  
EXT_HEADER_AUT_LAB:    

MovBits uxTmpReg1.BIT[2], bytmp3.BIT[0], 8;
nop;            
Add uxTmpReg1, uxTmpReg1, 8, 2;
nop;

Jmp GET_NEXT_HDR_LAB, NO_NOP;
   Add FMEM_BASE, FMEM_BASE, uxTmpReg1, 2; 
   Add uxTmpReg2, uxTmpReg2, uxTmpReg1, 2;// update L3 header size

// error occured during retrieving next header
GET_NEXT_HDR_ERROR_LAB:
// restore PC_STACK after jump
nop;
nop;
Mov PC_STACK, uqTmpReg5, 2;

jmp PARSING_DONE_LAB, NO_NOP;	
   MovBits uqInReg.BIT[IPv6_FRAMELEN_ERR_OFFSET], 1, 1; 
   Add FMEM_BASE, FMEM_BASE, uqOffsetReg0.byte[L3_OFFB], 2; // Restore pointer to L3, (clearing bits 8-15)




///////////////////////////////////
//          UDP Parse
///////////////////////////////////

UDP_DECODE_LAB:

//#define uqDip   uqTmpReg9;
//get   ALU, TCP_DPRT_OFF(FMEM_BASE), 4;
//fxor  uqCauiLagHash, uqDip, ALU, 4, MASK_0000FFFF, MASK_SRC2; //MB:2018: CAUI LAG Hash func calculation
//#undef uqDip;

//try known L7 types ( for TCP and UDP only currently supported L2TP and GTP protocols BGP and DNS for detection only )

//also build BDOS key based on this fetched ( L4 port ) fields

Get CAMI , UDP_SPRT_OFF(FMEM_BASE) , 4,SWAP;
LookCam CAMO, CAMI, TCAM64[L7_PROT_GRP], KEY_SIZE 4 ,WR_ENC_PRI;
Mov ALU , CAMI , 2 , RESET;
CmpSet ALU.byte[3] , ALU , 0 , RESULT 0x1;
Get uqTmpReg1, UDP_HLEN_OFF(FMEM_BASE), 2, SWAP;
Mov ALU , CAMI.byte[2] , 2;
MovBits FLAGS.bit[F_ED], 0, 1;
CmpSet ALU.byte[3] , ALU , 0 , RESULT 0x1;
Nop;
MovBits byTempCondByte1.byte[0] , ALU.byte[3] , 1;

Sub  ALU , uqTmpReg1 , 8 , 2 ;
 Copy CMP_BDOS_L4_CHECKSUM_OFF(COM_KBS), UDP_CHK_OFF(FMEM_BASE),   CMP_BDOS_L4_CHECKSUM_SIZE, SWAP;

Mov PA_CASE , IC_CNTRL_1_UDP_INC_HLEN , 2 , THROW( FLAGS.BIT[F_SN]  );   
    //if (uqGcCtrlReg0.bit[GC_CNTRL_0_FRAME_ACTION_DROP] ) - bit reused , indicate first fragment detection 
    Add ALU , uqTmpReg1 , uqOffsetReg0.byte[L4_OFFB] , 2;
    Nop;

if (!uqGcCtrlReg0.bit[GC_CNTRL_0_FRAME_ACTION_DROP]) Sub ALU, sHWD_uxFrameLen, ALU, 2;
Get uqTmpReg1, UDP_CHKSUM_OFF(FMEM_BASE), 2, SWAP;

Mov PA_CASE , IC_CNTRL_1_UDP_INC_HLEN , 2 , THROW( FLAGS.BIT[F_SN]  );
    MovBits uqGcCtrlReg0.bit[DETECT_L4WITH_PRTS] , 1, 1;
    //If (CAMO.bit[15]) MovBits uqGcCtrlReg0.bit[ GC_CNTRL_0_DNS_L4_PORT_DET ] , 1 , 1 ;
    Mov3Bits ENC_PRI.bits[15,14,13] , CAMO.bits[14 ,13,TRUE];
    //MovBits uqFramePrsReg.BIT[L4_MIN_LEN_OFF], UDP_BASE_SIZE, 5;

//HLEN action continue
UDP_INC_HLEN:

If ( byTempCondByte1.bit[0]) jmp LAND_IPLOCAL_L4ZERO;
    If (byTempCondByte1.bit[0]) Mov PA_CASE , IC_CNTRL_1_L4ZERO  , 2 ;
    If (byTempCondByte1.bit[0]) Mov PC_STACK , UDP_L4_ZERO , 2;  

UDP_L4_ZERO:
Sub ALU , uqTmpReg1 , 0  , 2;

//preliminary build BDOS L4 key ( could be used as Access list key in case of none tunnel packet ) 
Mov uxTmp2CtxReg2 , UDP_BASE_SIZE, 2  ;

Mov PA_CASE , IC_CNTRL_1_UDP_ZCHKSUM , 2 , THROW( FLAGS.BIT[F_ZR ] ); 
   copy  CMP_BDOS_L4_CHECKSUM_OFF (COM_KBS),   UDP_CHKSUM_OFF(FMEM_BASE), CMP_BDOS_L4_CHECKSUM_SIZE, SWAP;  
   nop;
 //Copy CMP_BDOS_L4_SRC_PORT_OFF(COM_KBS), UDP_SPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_SRC_PORT_SIZE, SWAP;
 //Copy CMP_BDOS_L4_DST_PORT_OFF(COM_KBS), UDP_DPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_DST_PORT_SIZE, SWAP;

UDP_ZERO_CHKSUM:

//Get ALU , UDP_DPRT_OFF(FMEM_BASE) , 2 , RESET;

//UDP end
jmul  L2TP_DET_LAB , GTP_CHECK_LAB , L4_PAYLOAD_LEN_CHECK_LAB , NO_NOP;
    Nop;    
    //LookCam CAMO , ALU , BCAM32[DNS_PORTS_CONFIGURATION_GRP] ;
    //LookCam CAMO , UDP_DPRT_OFF(FMEM_BASE), BCAM32[DNS_PORTS_CONFIGURATION_GRP] ,GET_SIZE 2 , MASK_0000FFFF , 0; 
    Nop;

L2TP_DET_LAB:

Get uqTmpReg3, UDP_SPRT_OFF(FMEM_BASE), 4, SWAP;
Add FMEM_BASE, FMEM_BASE, UDP_BASE_SIZE, 2; 
MovBits ENC_PRI.bit[13] , 0, 3;
 
// Check L2TP SrcPort value above PARSE_WELL_KNOWN_PORT_MAX
Mov ALU, { PARSE_WELL_KNOWN_PORT_MAX + 1 }, 2;

Get uqCondReg, L2TP_FLAGS_OFF(FMEM_BASE), 1;

Sub ALU, uqTmpReg3.byte[2], ALU, 2;
   Mov ALU, PARSE_L2TP_PORT, 2;
Movbits ENC_PRI.bit[14], FLAGS.BIT[F_SN], 1;

// Check L2TP DstPort value == PARSE_L2TP_PORT
Sub ALU, uqTmpReg3.byte[0], ALU, 2;
   
Mov FMEM_OFFSET1 , { L2TP_BASIC_HDR_SIZE}, 4;
If (!FLAGS.BIT[F_ZR]) Movbits ENC_PRI.bit[15], 1, 1;

// Check if control message
//Mov ALU, { 1 << L2TP_T_FLAG_BIT }, 4;
//And ALU, uqCondReg, ALU, 1;

Movbits ENC_PRI.bit[13], uqCondReg.BIT[L2TP_T_FLAG_BIT], 1;
If (uqCondReg.bit[L2TP_L_FLAG_BIT]) Add FMEM_OFFSET1, FMEM_OFFSET1, L2TP_LENGTH_FIELD_SIZE, 2; 

// In case packet is UDP but not L2TP -> continue to GTP parsing
Jmul L4_PAYLOAD_LEN_CHECK_LAB,            // If DstPort != PARSE_L2TP_PORT
     L4_PAYLOAD_LEN_CHECK_LAB,            // If SrcPort =< PARSE_WELL_KNOWN_PORT_MAX
     L4_PAYLOAD_LEN_CHECK_LAB, // If L2TP control message (jump here only if not jumped before, meaning this MUST be L2TP frame)
     NO_NOP;
     If (uqCondReg.bit[L2TP_S_FLAG_BIT]) Add FMEM_OFFSET1, FMEM_OFFSET1, L2TP_NS_NR_FIELD_SIZE,  2;
     Nop;


If ( !uqGcCtrlReg0.bit[GC_CNTRL_0_L2TP_TUN_CFG_BIT] ) Jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP; 
  //--bug , but not in this version , if possible tunnel disable , need to run syn res add uqGcCtrlReg0.bit[GC_CNTRL_0_L2TP_TUN_CFG_BIT] check   
  MovBits uqFramePrsReg.bit[SYN_TUN_FLAG_DIS_OFFSET], 1, 1;   //SYN and L2TP tunnel should not run together
  If (  uqCondReg.bit[L2TP_O_FLAG_BIT] ) Add FMEM_OFFSET1 , FMEM_OFFSET1 , 2 , 2;  

   
   MovBits uqFramePrsReg.bit[TUN_TYPE_OFF], L2TP_TUN_TYPE, 3; // Save tunnel type
   

PPP_TUN:
   //Input   FMEM_BASE + uqTmpReg1 - offset to PPP start 

   Mov uqTunnelOffsetReg.byte[L3_OFFB], uqOffsetReg0.byte[L3_OFFB], 2;
   
   Get uqTmpReg2, FMEM_OFFSET1(FMEM_BASE), 4 ,SWAP;
   //default 2 byte  
   Add ALU, FMEM_OFFSET1 , 2 ,   2; 
   Add FMEM_BASE, FMEM_BASE, ALU ,  2;

#define IPV4_PPP_PROT  0x0021
#define IPV6_PPP_PROT  0x0057
   
   Mov ALU , uqTmpReg2.byte[2] , 2;
   CmpSet ALU.byte[3] , ALU.byte[0] , IPV4_PPP_PROT ,  RESULT 0x1 ;
   CmpSet ALU.byte[3] , ALU.byte[0] , IPV6_PPP_PROT ,  RESULT 0x1 ;
   Mov ALU , uqTmpReg2.byte[0] , 2;
   CmpSet ALU.byte[3] , ALU.byte[0] , IPV4_PPP_PROT ,  RESULT 0x2 ;
   
   CmpSet ALU.byte[3] , ALU.byte[0] , IPV6_PPP_PROT ,  RESULT 0x2  ;

   Mov3Bits CAMO.bits[1,0,0] , ALU.byte[3].bits[1,1,0]; 
   MovBits ENC_PRI.bit[13] , 1 , 3;
   MovBits uqFramePrsReg.bit[TUN_EN_OFF], 1, 1; 
   xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 
 
   If (CAMO.bit[0]) jmp IP_PROT_DECODE_LAB , L131;
       If (CAMO.bit[1]) Add FMEM_BASE , FMEM_BASE , 2 , 2;
       If (CAMO.bit[0]) MovBits uqGcCtrlReg0.bit[ GC_CNTRL_GLOB_TUNNEL_STATUS_BIT ] , 1 , 1;     

///////////////////////////////////
//          TCP Parse
///////////////////////////////////
    
TCP_DECODE_LAB:

#define uqDip   uqTmpReg9;
//get   ALU, TCP_DPRT_OFF(FMEM_BASE), 4;
//fxor  uqCauiLagHash, uqDip, ALU, 4, MASK_0000FFFF, MASK_SRC2; //MB:2018: CAUI LAG Hash func calculation
#undef uqDip;

//Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;
MovBits FLAGS.bit[F_ED], 0, 1;  
MovBits uqGcCtrlReg0.bit[ GC_CNTRL_0_TCP_TYPE_DET ] , 1 , 1;
//MovBits uqFramePrsReg.bit[L4_MIN_LEN_OFF], TCP_BASE_SIZE, 5;

//set ICMP or BGP indication

//check flag validity
LookCam CAMO, TCP_FLAGS_OFF(FMEM_BASE), BCAM8[TCP_VALID_COMBINATION_GRP], GET_SIZE 2, MASK_0000001F, 0 /*, WR_ENC_PRI*/;
    Get ALU ,     TCP_DATAOFF_OFF(FMEM_BASE), 1 , RESET ;
    Copy CMP_BDOS_L4_TCP_SEQ_NUM_OFF(COM_KBS), TCP_SEQ_OFF(FMEM_BASE),   CMP_BDOS_L4_TCP_SEQ_NUM_SIZE, SWAP;

Decode_TCP 0(FMEM_BASE) , 16;

//detect tcp flags violation 
Mov PA_CASE , IC_CNTRL_1_TCP_FLAG , 2 ,THROW(!FLAGS.BIT[ F_MH ]);
    MovBits FMEM_OFFSET1.BIT[2], ALU.BIT[4], 4 , RESET ;
    MovBits uqFramePrsReg.BIT[L4_FLAGS_OFF], CAMI.bit[0], 5;

Sub  FMEM_OFFSET1 , FMEM_OFFSET1 , 1, 2;
PA_FLAGS_CONT:

Get CAMI , UDP_SPRT_OFF(FMEM_BASE) , 4,SWAP;
LookCam CAMO, CAMI, TCAM64[L7_PROT_GRP], KEY_SIZE 4 ;    
    Sub ALU , CAMI.byte[2] , ROUTING_BGP_TCP_TYPE , 2;
    //this command looks unnesesary , intention to set F_ED flag instead aritmetic FMEM_BASE+TCP_OFFSET>packet len
if (uqGcCtrlReg0.bit[GC_CNTRL_0_FRAME_ACTION_DROP]) jmp SKIP_TCP_HLEN_DET;
        Get ALU , FMEM_OFFSET1(FMEM_BASE) , 1;
        MovBits byCtrlMsgPrs3.bit[ROUTE_NETSTACK_ICMPBGP_OFF] , FLAGS.bit[F_ZR] , 1;
    //Pa anomaly case ( TCP_HLEN_ERR_LAB ) output
    Mov PA_CASE , IC_CNTRL_1_TCP_HLEN , 2 , THROW( FLAGS.BIT[F_ED]  );
    Mov PA_CASE , IC_CNTRL_1_TCP_HLEN , 2 , THROW( CAMO.BIT[16]  );    

SKIP_TCP_HLEN_DET:

Copy CMP_BDOS_L4_CHECKSUM_OFF(COM_KBS), TCP_CHK_OFF(FMEM_BASE),   CMP_BDOS_L4_CHECKSUM_SIZE, SWAP;
TCP_HLEN_CONT:
Mov ALU , HWD_REG4 , 2;
//Copy CMP_BDOS_L4_SRC_PORT_OFF(COM_KBS), UDP_SPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_SRC_PORT_SIZE, SWAP;
CmpSet ALU.byte[3] , ALU , 0 , RESULT 1 ;
//Copy CMP_BDOS_L4_DST_PORT_OFF(COM_KBS), UDP_DPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_DST_PORT_SIZE, SWAP;
Mov ALU , HWD_REG4.byte[2] , 2; 
CmpSet ALU.byte[3] , ALU , 0 ,  RESULT 1;
nop;
//PutHdr  HREG[ 1 ], COMP_SYN_PROT_LKP; // Only in TCP packet: perform syn prot search. 

MovBits CAMO.byte[0] , ALU.byte[3] , 1;

//save dns offset (  tcp also include len offset ( 2bytes in start )
Add uxTmp2CtxReg2 ,  HWD_REG5 , 2 , 2 ; 
If (CAMO.bit[0]) jmp LAND_IPLOCAL_L4ZERO; 
    If (CAMO.bit[0]) Mov PA_CASE , IC_CNTRL_1_L4ZERO  , 2 ;
    If (CAMO.bit[0]) Mov PC_STACK , TCP_L4_ZERO , 2;  

TCP_L4_ZERO:
//camo from last lookam  loaded with DNS, L2TP_DET_LAB , GTP_CHECK_LAB bitmask
If ( !CAMO.bit[13] ) jmp   L4_PAYLOAD_LEN_CHECK_LAB;
    //If (CAMO.bit[15]) MovBits uqGcCtrlReg0.bit[ GC_CNTRL_0_DNS_L4_PORT_DET ] , 1 , 1 ;
    MovBits uqGcCtrlReg0.bit[DETECT_L4WITH_PRTS] , 1, 1;
    Copy CMP_BDOS_L4_TCP_FLAGS_OFF(COM_KBS),   TCP_FLAGS_OFF(FMEM_BASE), CMP_BDOS_L4_TCP_FLAGS_SIZE; // size is '1'

jmp GTP_CHECK_LAB;
   // Mov uqFramePrsReg.byte[1] ,  HWD_REG5 , 1;
    MovBits uqFramePrsReg.byte[1], HWD_REG5, 6;
    nop;
    //Nop;
///////////////////////////////////
//   Manual Parse of L4 Protocol
///////////////////////////////////


///////////////////////////////////
//          SCTP Parse
///////////////////////////////////

SCTP_DECODE_LAB:



//Mov ALU , HWD_REG4 , 2;
Get ALU , 0(FMEM_BASE) , 2,SWAP , RESET;
CmpSet ALU.byte[3] , ALU , 0 , RESULT 1 ;
Get ALU , 2(FMEM_BASE) , 2 , SWAP;
CmpSet ALU.byte[3] , ALU , 0 ,  RESULT 1;
Nop;
MovBits CAMO.byte[0] , ALU.byte[3] , 1;

//save dns offset (  tcp also include len offset ( 2bytes in start )
Nop;
If (CAMO.bit[0]) jmp LAND_IPLOCAL_L4ZERO; 
    If (CAMO.bit[0]) Mov PA_CASE , IC_CNTRL_1_L4ZERO  , 2 ;
    If (CAMO.bit[0]) Mov PC_STACK , SCTP_L4_ZERO , 2;  

SCTP_L4_ZERO:

Add ALU, uqOffsetReg0.byte[L4_OFFB], SCTP_BASE_SIZE, 2;
Sub ALU, ALU, HWD_REG0.byte[2], 2;
Mov PA_CASE , IC_CNTRL_1_SCTP_HLEN , 2;

//continue lablel in this case will be L4_PAYLOAD_LEN_CHECK_LAB
//if(A) 
Ja GLOB_ANOMALY_LAB , L4_PAYLOAD_LEN_CHECK_LAB;
    MovBits uqGcCtrlReg0.bit[DETECT_L4WITH_PRTS] , 1, 1;
    Nop;


///////////////////////////////////
//         IPSEC Parse
///////////////////////////////////

IPSEC_DECODE_LAB:

//may be 9 label ENC_PRI would be preferable but I really don't care about IPv6 in IPv4 or IPSEC
Sub ALU , CAMI , 0x29 , 1;
Nop;
If (Z) jmp IPinIP_DECODE_LAB , NOP_2;

IPSEC_DECODE_LAB_IPV6_DET:

xor ALU, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // using MREG[10] 
And ALU, ALU, { 1 << IC_CNTRL_0_IPSEC_MODE_OFF }, 4;  
//MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3;

PutKey MSG_L3_USR_OFF(HW_KBS), uqOffsetReg0.byte[L3_OFFB], 4;

jz GLOB_ANOMALY_LAB , CONF_NETWORK_BYPASS_LAB   ;
//reload PA checkbase
    xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH; // TOPparse MREG[10]      
    Mov PA_CASE , IC_CNTRL_1_UNK_L4 , 2 ;
    //If ( FLAGS.bit[ F_ZR ] ) MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3; 

///////////////////////////////////
//      IPinIP Tunnel Parse
///////////////////////////////////

IPinIP_DECODE_LAB:

// Decode IPinIP header

MovBits uqFramePrsReg.bit[TUN_TYPE_OFF], IPinIP_TUN_TYPE, 3;  // Save tunnel type
MovBits uqFramePrsReg.bit[TUN_PA_SKIP ], 1, 1;                // AmitA: default value set to skip internal header check. if this tunnel is enabled (in configuration) this variable will soon be changed to 0.
MovBits uqFramePrsReg.BIT[L4_TYPE_OFF ], L4_IPinIP_TYPE, 3;   // Set L4 type
MovBits uqFramePrsReg.bit[SYN_TUN_FLAG_DIS_OFFSET], 1, 1;   //SYN and ip in ip tunnel should not run together

// If IPinIP tunnel disabled treat like regular L4 offset
if ( !uqGcCtrlReg0.bit[GC_CNTRL_0_IP_IN_IP_TUN_CFG_BIT] ) jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
   PutKey MSG_L3_TUN_OFF(HW_KBS), FMEM_BASE, 2; // ##TODO_BUG_FOUND (?) MSG_L3_TUN_OFF is initilized with FMEM_BASE only in IPinIP and GRE, is is not initilized in LT2P and GTP tunnels. it will be initialized in PARSING_DONE_LAB, just need to verify that it will reach there in all cases (and not exit the macro using a jump to NETWORK_BYPASS_LAB. if so then need to consider cancelling the existing initializations of MSG_L3_TUN_OFF at these locations and leave it to be performed for all tunnels in PARSING_DONE_LAB.
   Mov uqTunnelOffsetReg.byte[L3_OFFB], uqOffsetReg0.byte[L3_OFFB], 2;

Mov ALU, { 1 << TUN_EN_OFF }, 4; // Check if this packet have a tunnel that is also enabled
And ALU, uqFramePrsReg, ALU, 4;
   //set internal header check if tunnel enable
   MovBits uqFramePrsReg.bit[TUN_PA_SKIP], 0, 1;  // Mark that this packet contains tunnel that is configured as enabled, so PA should run on it.
//check IPinIP recognition to avoid double header parsing
Jz IPinIP_First_Tun_LAB;
    //set global tunnel indication
   MovBits uqGcCtrlReg0.bit[ GC_CNTRL_GLOB_TUNNEL_STATUS_BIT ] , 1 , 1;   
   Mov uxGreTunTmpOffReg, FMEM_BASE, 2;

// AmitA: This packet already met an enabled tunnel (not necesarily IPinIP tunnel)
// If we detected IPinIPinIP (which is not legal in our system) // ##TODO_GUY_BUG_FOUND (?) the comment is not exact - also other types of tunnels may set the TUN_EN_OFF bit. is this a problem with the comment or with the code?
// AmitA: probably the main idea for the use of uqFramePrsReg.bit[TUN_EN_OFF] is that the IPinIP tunnel is not the outer tunnel in the frame, then all deeper tunnels inspection should be stopped.
jmp GLOB_ANOMALY_LAB /*L4_PAYLOAD_LEN_CHECK_LAB - continue lab */;
   Mov PA_CASE , IC_CNTRL_1_UNK_L4 , 2 ;
   MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3;

IPinIP_First_Tun_LAB:


MovBits byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_L3_TUNNEL_EXISTS_BIT], 1, 1;

//next protocol is IP reload anomaly mask
xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 

// Handling of ip in ip header
MovBits uqFramePrsReg.bit[TUN_EN_OFF], 1, 1;	 // Packet has a tunnel that is also enabled (IPinIP in this case).

jmp IP_PROT_DECODE_LAB, NO_NOP;
   //save internal in case when jump take place
   Add uqOffsetReg0.byte[L3_OFFB], FMEM_BASE, 0,  2, MASK_0000007F, MASK_SRC1;
   PutKey MSG_L3_USR_OFF(HW_KBS), FMEM_BASE, 2;


///////////////////////////////////
//       GRE Tunnel Parse
///////////////////////////////////

GRE_DECODE_LAB:


// Calculate GRE header size (can be with variable size) in order to know where ipv4\ipv6 header starts
Mov     CAMI, 0, 4;
Mov     uqTmpReg6, PC_STACK, 2, RESET;
MovBits FLAGS.bit[F_ED], 0, 1;
MovBits uqFramePrsReg.BIT[TUN_TYPE_OFF], GRE_TUN_TYPE, 3; // Save tunnel type
MovBits uqFramePrsReg.bit[TUN_PA_SKIP], 1, 1;             // AmitA: default value set to skip internal header check. if this tunnel is enabled (in configuration) this variable will be changed to 0.
//MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_GRE_TYPE, 3;   // Save L4 type

//expected next protocol is IP



//set gre mark regardless to gre tunnel setings . In TopModify routing mode this
//mark will used with MY IP state
MovBits byCtrlMsgPrs3.bit[ROUTE_GRE_OFF] , 1 , 1;
// If GRE tunnel is disabled, treat GRE like regular L4 offset
if ( !uqGcCtrlReg0.bit[GC_CNTRL_0_GRE_TUN_CFG_BIT] ) jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
   Get    uqTmpReg5, GRE_FLAGS_OFF(FMEM_BASE), 4, SWAP; // Take first 4 bytes of GRE header 
   PutKey MSG_L3_TUN_OFF(HW_KBS), FMEM_BASE, 2;         // Save external only

MovBits CAMO.bit[29], byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_L3_TUNNEL_EXISTS_BIT] , 1;

//set global tunnel indication
MovBits uqGcCtrlReg0.bit[ GC_CNTRL_GLOB_TUNNEL_STATUS_BIT ] , 1 , 1;
//reload PA mask according to L3 parsing , GRE going to terminate in IP decode lab
//xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10]

//avoid secondary tunnel parse
If (CAMO.bit[29]) jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
    MovBits byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_L3_TUNNEL_EXISTS_BIT], 1, 1;
    Nop;



// If there is a problem with length calculation and we reach end of frame -> jump to GRE_HLEN_LAB
if ( FLAGS.bit[F_ED] ) jmp GRE_HLEN_LAB, NO_NOP;        // ##TODO_GUY_BUG_FOUND: (?) how was the GRE offset calculated? in what case will it be calculated and this will be the end (or close to the end) of the frame??? seems like a leftover.
   MovBits CAMI, uqTmpReg5.byte[3].bit[4], 4;           // Use C,R,K,S bits in BCAM16 to calculate header length
   MovBits uqFramePrsReg.bit[TUN_PA_SKIP], 0, 1;        // AmitA: Mark that this packet contains tunnel that is configured as enabled, so PA should run on it. // Set internal header check if tunnel enable

Sub ALU, uqTmpReg5.byte[2], 1, 1, MASK_00000007, MASK_SRC1;
Mov uqCondReg, uqTmpReg5.byte[2], 2;  // Used in GRE decoding scope (can be re-used after GRE decoding completes)



// If 'Version' is not '0' or '1' ('Version' field - 1 > 0) terminate protocol parsing
JA GRE_UNS_VER_LAB;    
    Mov     bytmp,  0, 4; // uqTmpReg2 - Clear status and PPP header size for version 0 and Version 1 Acknowledgment bit size
    Nop;

// If version is '0' ('Version' field - 1 < 0)
JB GRE_VERSION_0_DECODE_LAB, NO_NOP;
   Mov uqTunnelOffsetReg.byte[L3_OFFB], uqOffsetReg0.byte[L3_OFFB], 2;
   Mov uxGreTunTmpOffReg, FMEM_BASE, 2;   



Mov ALU, uqTmpReg5.byte[0] , 2;

//gre base size
MovBits CAMO.bit[26] , uqCondReg.bit[ GRE_A_FLAG_BIT] , 1;
CmpSet ALU.byte[3] , ALU   , L4_PPP_PROT_TYPE , RESULT 1;

Jmp GRE_DECODE_CONT_LAB;
    MovBits CAMO.bit[27] , ALU.byte[3].bit[0] , 1; 
    If (CAMO.bit[26]) Mov  bytmp2 , GRE_ACK_EXT_SIZE, 2;
    
GRE_VERSION_0_DECODE_LAB:

// Test GREv0 Protocol type (IPv4\IPv6 allowed only)
Mov     ALU, IPv4_TYPE, 2;                               // Check if Protocol field contains IPv4 protocol id (0x0800)
Sub     ALU, uqTmpReg5.byte[0], ALU, 2;  
   Mov     ALU, IPv6_TYPE, 2;                            // Check if Protocol field contains IPv6 protocol id (0x86DD)
MovBits bytmp.BIT[0], FLAGS.BIT[ F_ZR ], 1;              // If Protocol == IPv4 -> mark it in bytmp (used later to check 2 protocols in one operation)
Sub     ALU, uqTmpReg5.byte[0], ALU, 2;  


GRE_DECODE_CONT_LAB:
// common code to GRE version 0 and GRE version 1.

LookCam CAMO, CAMI, BCAM16[GRE_FLAG_HDR_SIZE_GRP];    // Get extension header fields size according to flags combination
   MovBits bytmp.BIT[1], FLAGS.BIT[ F_ZR ], 1;        // If Protocol == IPv6 -> mark it in bytmp (used later to check 2 protocols in one operation)
      Movbits uqFramePrsReg.bit[SYN_TUN_FLAG_DIS_OFFSET], 1, 1; //SYN and GRE tunnel can not work together
   And     ALU, bytmp, 0x3, 1;                        // Check if one of IPv4\IPv6\PPP protocol IDs are included in GRE header
      Nop;
                                                      // ##AMIT_GUY: why checking for IPv4/ipv6 in GRE version 0 and doing diferent checks in GRE version 1?
jz PARSING_DONE_LAB, NO_NOP;
   if (FLAGS.bit[F_ZR]) MovBits uqInReg.BIT[L3_UNS_PROT_OFFSET], 1, 1;
   Nop;

Mov ALU, bytmp2, 1, RESET; 

Add     FMEM_BASE, FMEM_BASE, ALU, 2;                                // Update if Version 1 Acknowledgment
Nop;
Add     FMEM_BASE, FMEM_BASE, CAMO, 2, MASK_0000007F, MASK_SRC2;     // Add extensions size (taken from CAMO according to enabled flags) 


// Disable Syn-Ack if outer header is IPv6
//Mov ALU, { 1 << L3_TYPE_OFF }, 4;
//And ALU, uqFramePrsReg, ALU, 4;
   Mov CNT, 3, 1;                                           // Init SRE loop counter: check if no GRE extension exist, check routing present
//if (!FLAGS.bit[F_ZR]) Movbits uqFramePrsReg.bit[SYN_TUN_FLAG_DIS_OFFSET], 1, 1;


if (!uqCondReg.bit[GRE_R_FLAG_BIT]) jmp SRE_RECORD_LOOP_END_LAB, NO_NOP;
   Nop;
   MovBits uqFramePrsReg.bit[TUN_EN_OFF], 1, 1;	// AmitA: Packet has a tunnel that is also enabled (GRE in this case)


// SRE Tunnel Parse
SRE_RECORD_LOOP_LAB:
// Check SRE subheader (part of the GRE header, may exist and may not, can be with variable size)
   nop;
Get uqTmpReg5, 0(FMEM_BASE), 4 ,SWAP;   // Get SRE record

if (FLAGS.bit[F_ED]) jmp GRE_HLEN_LAB, NO_NOP;
   Add FMEM_BASE, FMEM_BASE, 4, 2; 
   Sub ALU, uqTmpReg5.byte[0], 0, 1;
      nop;
jz SRE_RECORD_LOOP_END_LAB, NOP_2;   // not last record, continue loop

Loop SRE_RECORD_LOOP_LAB;
   Add FMEM_BASE, FMEM_BASE, uqTmpReg5.byte[0], 2, MASK_0000007F, MASK_SRC2;
   nop;

// GRE SRE number error
jmp L4_PAYLOAD_LEN_CHECK_LAB, NOP_1;
   MovBits uqInReg.BIT[GRE_SRE_NUM_ERR_OFFSET], 1, 1;

SRE_RECORD_LOOP_END_LAB:

// correct frame length with PPP header size
//Mov ALU, bytmp1, 1, RESET;
//Add FMEM_BASE, FMEM_BASE, ALU, 2;

If ( CAMO.bit[27] ) jmp PPP_TUN;
     Mov FMEM_OFFSET1 , 0 , 4;
     xor CTX_REG[15], ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // TOPparse MREG[10] 



//reload pa mask to MREG10 IP mask

//Nop;
Get uqTmpReg5, 0(FMEM_BASE), 4 ,SWAP;        // Get 4 bytes after GRE header
if (FLAGS.bit[F_ED]) 
   Jmp CHECK_FAIL_L2, NO_NOP; 
      if (FLAGS.bit[F_ED]) MovBits ENC_PRI.bit[13] , 1 , 3;  // Proceed as L2 unsupported in case PPP header problem
      Nop;

jmp IP_PROT_DECODE_LAB, NO_NOP;
   //Rewrite internal in case that we arived to SRE_RECORD_LOOP_END_LAB (i.e. no errors in GRE parsing (?))
   PutKey MSG_L3_USR_OFF(HW_KBS), FMEM_BASE, 2;
   Mov uqOffsetReg0.byte[L3_OFFB], FMEM_BASE, 2;

// If we jump here there was a problem with GRE version number
GRE_UNS_VER_LAB:
#define GRE_TUN_UNS_DET_MASK (0xFFFFFFFF - GRE_TUN_DET_MASK);
MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_GLOB_DESC_BIT], 1, 1;    //RT monitoring will be not supported for packets GRE version error
Mov ALU, GRE_TUN_UNS_DET_MASK, 4;
jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
   MovBits uqInReg.BIT[GRE_UNS_VER_OFFSET], 1, 1;
   And uqFramePrsReg, uqFramePrsReg, ALU, 4;

// If we jump here there was a problem in GRE length calculation (FLAGS.bit[F_ED])
GRE_HLEN_LAB:
jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
   Mov PC_STACK, uqTmpReg6, 2;
   MovBits uqInReg.BIT[GRE_HLEN_ERR_OFFSET], 1, 1;


///////////////////////////////////
//       GTP Tunnel Verify (check if the frame has GTP. If so, a proper handling will be done in GTP_DECODE_LAB later on).
///////////////////////////////////

GTP_CHECK_LAB:

Mov ALU, { PARSE_WELL_KNOWN_PORT_MAX + 1 }, 2;
Sub  ALU , CAMI.byte[0] , ALU.byte[0] , 2;
Mov ALU, { PARSE_WELL_KNOWN_PORT_MAX + 1 }, 2;
Js  L4_PAYLOAD_LEN_CHECK_LAB;
    Sub  ALU , CAMI.byte[0] , ALU.byte[0] , 2;
    MovBits FLAGS.bit[F_ED], 0, 1;

Js L4_PAYLOAD_LEN_CHECK_LAB;
    Nop;
    Nop;

Add FMEM_BASE , FMEM_BASE , uqFramePrsReg.byte[1] , 2 , MASK_0000007F, MASK_SRC2;   
///////////////////////////////////
//       GTP Tunnel Parse
///////////////////////////////////

//MovBits uqFramePrsReg.bit[TUN_PA_SKIP], 1, 1;		         // AmitA: default value set to skip internal header check. if this tunnel is enabled (in configuration) this variable will be changed to 0.

If (uqGcCtrlReg0.bit[ GC_CNTRL_GLOB_TUNNEL_STATUS_BIT ] ) Jmp L4_PAYLOAD_LEN_CHECK_LAB;
    Nop;
    Nop; //--could be optimaized , but who care about gtp perf    

if (FLAGS.bit[F_ED]) jmp GTP_HLEN_ERR_LAB;
    MovBits uqFramePrsReg.BIT[TUN_TYPE_OFF], GTP_TUN_TYPE, 3;	// Save tunnel type
    //set global tunnel indication
    MovBits uqGcCtrlReg0.bit[ GC_CNTRL_GLOB_TUNNEL_STATUS_BIT ] , 1 , 1;

Get uqCondReg, GTP_FLAGS_OFF(FMEM_BASE), 4, SWAP;   			// Used in GTP decoding scope (can be re-used after GTP decoding completes)

if (!uqGcCtrlReg0.bit[GC_CNTRL_0_GTP_TUN_CFG_BIT] ) Jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
   MovBits bytmp, uqCondReg.byte[3].bit[GTP_VER_OFF_BIT], 3;  
   Mov uqTmpReg3, 0, 4;

Mov uqTunnelOffsetReg.byte[L3_OFFB], uqOffsetReg0.byte[L3_OFFB], 2;
decode ALU, bytmp, 1, MASK_00000003, MASK_SRC1;
Mov uqTmpReg6, PC_STACK, 2, RESET;
MovBits ENC_PRI.bit[13], ALU.bit[0], 3;

MovBits byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_L3_TUNNEL_EXISTS_BIT], 1, 1;

// uqCondReg have already been updated, however we read this again to check end of packets (also used instead nop)
Get uqCondReg, GTP_FLAGS_OFF(FMEM_BASE), 4, SWAP;
if (FLAGS.bit[F_ED]) jmp GTP_HLEN_ERR_LAB, NO_NOP;
   And ALU, uqCondReg.byte[3], GTP_HDR_MASK, 1;
   Mov uxTmpReg1, 8, 2;

Jmul L4_PAYLOAD_LEN_CHECK_LAB,
     GTP_VER1_LAB,
     GTP_VER0_LAB;

jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
   MovBits uqInReg.BIT[GTP_UNS_VER_OFFSET], 1, 1;  
   MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_GLOB_DESC_BIT], 1, 1; //RT monitoring will be not supported for packets GTP version error

GTP_VER0_LAB:
jmp GTP_HDR_LEN_CALC_DONE, NO_NOP;
   Mov uxTmpReg1, 20, 2;
   nop;

GTP_VER1_LAB:
If (!FLAGS.BIT[ F_ZR ]) Mov uxTmpReg1, 12, 2;

GTP_HDR_LEN_CALC_DONE:

// Continue if message type 0xff detected 
Sub ALU, uqCondReg.byte[2], 0xff, 1;
nop;

// Support packet as GTP tunnel only if message type is 0xff, otherwise treat as normal packet
If (!FLAGS.BIT[ F_ZR ]) Jmp L4_PAYLOAD_LEN_CHECK_LAB, NOP_1;
   Add FMEM_BASE, FMEM_BASE, uxTmpReg1, 2;

// Message type is 0xff
MovBits uqFramePrsReg.bit[TUN_EN_OFF], 1, 1;	// AmitA: Packet has a tunnel that is also enabled (GTP in this case)
MovBits uqFramePrsReg.bit[SYN_TUN_FLAG_DIS_OFFSET], 1, 1; //SYN and GTP tunnel should not run together
MovBits uqFramePrsReg.bit[TUN_PA_SKIP], 0, 1;   // AmitA: Mark that this packet contains tunnel that is configured as enabled, so PA should run on it.

// Check GTPv0 type, in this case ENC_PRI bits == 0 ( possible values 0,1,2)
Sub ALU, bytmp, 0, 1, MASK_00000003, MASK_SRC1;
Mov uxTmpReg1, 0, 2;


// If version 0 detected skip extension header scan
jz IP_PROT_DECODE_LAB, NO_NOP;
   Get uqTmpReg5, 0(FMEM_BASE), 4, SWAP;
   Mov uqOffsetReg0.byte[L3_OFFB], FMEM_BASE, 2;
   
if (FLAGS.bit[F_ED]) jmp GTP_HLEN_ERR_LAB;
    Nop;
    Nop;


if (!uqCondReg.byte[3].bit[GTP_EXT_HEAD_FLG_BIT]) jmp IP_PROT_DECODE_LAB, NO_NOP;
   //rewrite internal in case when jump take place
   PutKey MSG_L3_USR_OFF(HW_KBS), FMEM_BASE, 2;
   Mov uqOffsetReg0.byte[L3_OFFB], FMEM_BASE, 2;


//////////////////////////////////////////////

// GuyE : may need to add code that was added to NP3 env only to avoid loops in the marked section
// EliR : done

//get extention header  length
Get uqTmpReg5 , 0(FMEM_BASE) , 1;
Mov uqTmpReg1 , 0 , 4;

//set maximum message header deep value
Mov CNT , 10 , 1;

GTP_SUBHDR_LAB:

if (FLAGS.bit[F_ED]) jmp GTP_HLEN_ERR_LAB, NO_NOP;
   MovBits uqTmpReg1.bit[2], uqTmpReg5.byte[0].bit[0], 8;
   nop;

//check if len value is zero
Sub ALU , uqTmpReg1 , 0 , 4;
Mov ALU, 1, 4;

jz GTP_HLEN_ERR_LAB; 
   //set pointer to last byte of subheader
   Sub ALU, uqTmpReg1, ALU, 4, MASK_0000FFFF, MASK_SRC1;
   nop;

Add FMEM_BASE, FMEM_BASE, ALU, 2;
   nop;

//manually check out of packet boarders condition
Sub ALU, HWD_REG0.byte[2], FMEM_BASE, 2;
   nop;
jbe GTP_HLEN_ERR_LAB, NOP_2;

//Get bytmp, 0(RD_PTR), 1, _JEOF_PRS;
Get bytmp, 0(FMEM_BASE), 1;
   nop;

if (FLAGS.bit[F_ED]) jmp GTP_HLEN_ERR_LAB, NO_NOP;
   Add FMEM_BASE, FMEM_BASE, 1, 2;  //restore rd_ptr  
   Sub ALU, bytmp, 0, 1;            //check next sub-header type

Mov uqTmpReg1, 0, 4; // ##TODO_OPTIMIZE - not sure why this line is needed. if removing it - need to replace it with a not or change the order of 2 actions above.


//ignore possible ie 
jz IP_PROT_DECODE_LAB, NO_NOP;  
   //rewrite internal in case when jump take place
   PutKey MSG_L3_USR_OFF(HW_KBS), FMEM_BASE, 2;
   Mov uqOffsetReg0.byte[L3_OFFB], FMEM_BASE, 2;

Loop GTP_SUBHDR_LAB, NO_NOP;
   //Get uqTmpReg5, 1(RD_PTR), 2, SWAP,_JEOF_PRS;
   Get uqTmpReg5, 0(FMEM_BASE), 1, SWAP;
   nop; 


GTP_HLEN_ERR_LAB:

jmp L4_PAYLOAD_LEN_CHECK_LAB, NO_NOP;
   Mov PC_STACK, uqTmpReg6, 2;
   MovBits uqInReg.BIT[GTP_HLEN_ERR_OFFSET], 1, 1;

//////////////////////////////////////////////


///////////////////////////////////
//  L4 - Payload Length Handling
///////////////////////////////////


L4_PAYLOAD_LEN_CHECK_LAB:

Nop;
#ifdef __nodns__
Get ALU , UDP_DPRT_OFF(FMEM_BASE) , 2 , RESET, SWAP;
#endif 
MovBits byTempCondByte4.bit[6]  , uqFramePrsReg.bit [ L3_TYPE_OFF ] , 4;   
#ifdef __nodns__
LookCam CAMO , ALU , BCAM32[DNS_PORTS_CONFIGURATION_GRP] ; 
#endif 
//   And bytmp, uqFramePrsReg, { 1 << L3_TYPE_OFF }, 4; // Check if IPv4 or IPv6
      //Get ALU, IP_LEN_OFF(FMEM_BASE), 2, SWAP;        // IPv4 total length contains payload + header length
//jz L4_PAYLOAD_LEN_CHECK_CONT_LAB, NOP_2;
Mov FMEM_BASE, uqOffsetReg0.byte[L3_OFFB], 2;

If ( !byTempCondByte4.bit[6] ) jmp L4_PAYLOAD_LEN_CHECK_CONT_LAB;
    //Nop;    
    Add FMEM_OFFSET1, uxTmp2CtxReg2 , 2 , 1 ;
    Get ALU, IP_LEN_OFF(FMEM_BASE), 2, SWAP;        // IPv4 total length contains payload + header length
    //Nop;    
    

// IPv6 type
Get ALU, IPv6_PAYLOAD_LEN_OFF(FMEM_BASE), 2, SWAP;
Add ALU, ALU, IPv6_BASE_SIZE, 2;                      // IPv6 payload length does not contain header length so we need to add it as well


L4_PAYLOAD_LEN_CHECK_CONT_LAB:
#ifdef __no_need???__
// Check whether L4 payload size is not below minimal size ("Minimal" is varied, according to L4 type)
Add ALU, ALU, uqOffsetReg0.byte[L3_OFFB], 2; // Add IP payload length + L3 offset (should give whole packet length)
Sub ALU, ALU, uqOffsetReg0.byte[L4_OFFB], 2; // Sub L4 offset from whole packet length (should give L4 payload length)
Sub ALU, ALU, uqFramePrsReg.byte[L4_MIN_LEN_OFFB], 2, MASK_0000001F, MASK_SRC2; // Sub minimal L4 size from calculated L4 size and verify it is not below that
#endif


Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;


// This is a no PA case, but continue check for first fragment
Mov ALU, {1 << FIRST_FRAG_OFFSET}, 4;
And ALU, uqInReg, ALU, 4;


// This is error case but for the first fragment is is a normal packet
//If (!FLAGS.BIT[F_ZR]) Jmp PARSING_DONE_LAB, NOP_2;

// Mark packet as PA

///////////////////////////////////
//       Parsing Complete
///////////////////////////////////


PARSING_DONE_LAB:
// RT monitoring receive counters update - moved to TOPresolve
// rtmCountersUpdate RT_MONITOR_BASE_CNTR; 

//Sub ALU, uqTunnelOffsetReg.byte[L3_OFFB], 0, 2;

//policy ipv4 mapping 
//Mov    uqTmpReg5 , IPV4_IPV6_MAPPING_4TH, 4;
Nop;

If (FLAGS.BIT[F_ZR]) MovBits uqInReg.BIT[L4_PAYLOAD_LEN_ERR_OFFSET], 1, 1;


Sub ALU, sHWD_uxFrameLen, PORT_CFG2.byte[JUMBO_PCKT_CREG2_OFF], 2;   // sHWD_uxFrameLen = HWD_REG0.byte[2] // ##AMIT_GUY is the value in PORT_CFG2.byte[JUMBO_PCKT_CREG2_OFF] folding the minimum size to define a jumbo frame?
   PutKey MSG_L3_USR_OFF(HW_KBS), uqOffsetReg0.byte[L3_OFFB], 4;     // initialize in the message both MSG_L3_USR_OFF and MSG_L4_USR_OFF from uqOffsetReg0.byte[L3_OFFB] and uqOffsetReg0.byte[L4_OFFB]

jb JUMBO_SKIP_LAB; // If not jumbo packet - skip jumbo handling 
   Nop;
   PutKey MSG_L3_TUN_OFF(HW_KBS), uqTunnelOffsetReg.byte[L3_OFFB], 2;

// This is a jumbo frame, mark as jumbo
or      uqFramePrsReg, uqFramePrsReg, {1 << JUMBO_PCKT_STATUS_OFF}, 4;
MovBits byCtrlMsgPrs0.BIT[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT], 1, 1; 

JUMBO_SKIP_LAB:

#undef IP_VERSION_BIT;


Mov PC_STACK , PC_STACK_STORE , 4;  
Get ALU , UDP_SPRT_OFF(FMEM_BASE) , 2 , RESET,SWAP;
Return;
    PutKey MSG_GRE_USR_OFF(HW_KBS), uxGreTunTmpOffReg, 2;
    Nop; 




CHECK_FAIL_L2:

If (!bitPRS_isRoutingMode)  jmp L131 , NOP_2;

/* Validate broadcast and Multicast only and L2 control */
Mov3Bits CAMO.bits[17,17,17] , sHWD9.bits[0,1,2];
Nop;
Nop;
If (CAMO.bit[17]) jmp XPY_XPY_LAB , NOP_2;


L131:
//clear policy search request l2 type none unicast  detected
If (bitPRS_isRoutingMode) MovBits uqGcCtrlReg0.bit[GC_CNTRL_0_POLICY_NON_EMPTY_BIT] , 0 , 1;

Mov IND_REG0, {15 << 5}, 2;             // Start with CTX_REG[15]

//BPDU_MCAST , MCAST , BCAST , L2_NONE_ETH , TEST_TUNNEL_AWARE_LAB , TEST_TUNNEL_AWARE_LAB , TEST_TUNNEL_AWARE_LAB;

MovMul PARSING_DONE_LAB , TEST_TUNNEL_AWARE_LAB , PARSING_DONE_LAB;
Mov PC_STACK , ENC_PRO , 2;

If (bitPRS_isRoutingMode)   Mov PC_STACK , PARSING_DONE_LAB , 2;


MovMul IC_CNTRL_0_L2_BROADCAST_OFF , IC_CNTRL_0_L2_BROADCAST_OFF  ,IC_CNTRL_0_L2_FORMAT_OFF ;
MovBits IND_REG0.bit[0] , ENC_PRO.bit[0] , 5 ;
MovMul  IS_L2_BRD_DRP , IS_L2_BRD_DRP , IS_UN_L2_DRP;

jmp  CHK_FAIL_LAB;
    MovBits bytmp1.BIT[0], CTX_REG[IND_REG0] , 2 , RESET;
    Mov uxTmpReg1, ENC_PRO, 2;

GLOB_ANOMALY_LAB:
//#define IC_CNTRL_1_TCP_FLAG             0x200 
//save ENC_PRI reg
Mov ENC_PRI_STORE , ENC_PRI , 2; 
MovBits ENC_PRI.bit[1] , PA_CASE.bit[1] , 15;
 
 
Mov IND_REG0, {15 << 5}, 2;             // Start with CTX_REG[15]


//actReg0 PA_FLAGS_CONT
MovMul IPv6_INC_PKTHDRLEN , FRAG_CONT , IPv4_FRAG ,L4_PAYLOAD_LEN_CHECK_LAB,
       UDP_INC_HLEN , UDP_ZERO_CHKSUM ,PA_FLAGS_CONT , TCP_HLEN_CONT , 
       L4_PAYLOAD_LEN_CHECK_LAB  ,TTL_CONT  ,IPv4_INCHLEN , IPv4_INC_CHEKSUM ,
       PARSING_DONE_LAB, IPV6_FIRST_FRAG , HOP_LIMIT;
       
Mov PC_STACK , ENC_PRO , 2;

//select indreg offset
MovMul IC_CNTRL_0_IPv4_INC_PKTHDRLEN_OFF , IC_CNTRL_0_FRAG_OFF , IC_CNTRL_0_FRAG_OFF ,IC_CNTRL_1_SCTP_HLEN_OFF,
       IC_CNTRL_1_UDP_INC_HLEN_OFF , IC_CNTRL_1_UDP_ZCHKSUM_OFF ,IC_CNTRL_1_TCP_FLAG_OFF , IC_CNTRL_1_TCP_HLEN_OFF , 
       IC_CNTRL_1_UNK_L4_OFF ,IC_CNTRL_0_INC_TTL_OFF  ,IC_CNTRL_0_IPv4_INC_PKTHDRLEN_OFF , IC_CNTRL_0_IPv4_INC_CHEKSUM_OFF ,
       IC_CNTRL_0_L3_UNK_OFF, IC_CNTRL_0_IPv6_FRAG_OFF , IC_CNTRL_0_IPv6_HLIM_OFF;

mov bytmp1, 0, 1;
MovBits IND_REG0.bit[0] , ENC_PRO.bit[0] , 5 ;

//select counter offset
MovMul IS_IP4_HE_DRP , IS_IP4_FRG_DRP , IS_IP4_FRG_DRP ,IS_SCTP_HLEN_DRP,
       IS_UDP_HE_DRP , IS_UDP_CZ_DRP ,IS_TCP_FL_DRP , IS_TCP_HE_DRP , 
       IS_UN_L4_DRP ,IS_IP4_TTL_DRP  ,IS_IP4_HE_DRP , IS_IP4_CK_DRP ,
       IS_UN_L3_DRP, IS_IP6_FRG_DRP , IS_IP6_HOP_DRP;

mov bytmp3, 0, 1;
MovBits bytmp1.BIT[0], CTX_REG[IND_REG0] , 2;
Mov uxTmpReg1, ENC_PRO, 2;

///////////////////////////////////
//   Packet Anomalies Failed
///////////////////////////////////
       
CHK_FAIL_LAB:

//if ENC_PRI bit 14 , 13 is none zero it's mean frag ipv4 detected , let's feel bdos 
//frag fields
Mov2Bits byTempCondByte1.bits[0,0] , ENC_PRI.bits[14,13]; 
MovBits ALU , sIpv4ProtDec_CAMO_bitsIpFlags , 3 , RESET;   

if (!byTempCondByte1.bit[0]) jmp CONT_ANOMALY;
//fill l4 fragment bdos fields
    Get  ALU.byte[2] , IP_FLAGS_OFF(FMEM_BASE), 2, SWAP;  
    //clear ip flag 
    MovBits ALU.byte[3].bit[5] , 0 , 3;

nop;
PutKey CMP_BDOS_L23_FRGMNT_OFF(COM_KBS),     ALU.byte[2], CMP_BDOS_L23_FRGMNT_SIZE;
PutKey CMP_BDOS_L23_FRGMNT_FLG_OFF(COM_KBS), ALU.byte[0], CMP_BDOS_L23_FRGMNT_FLG_SIZE;   // size is '1'     

CONT_ANOMALY:     

//decode the action for this anomaly (0:drop, 1:cont,2:bypass,3:to-cpu)
decode  ALU, bytmp1, 1, MASK_00000003, MASK_SRC1;

Mov     uqTmpReg4, 0, 4;
MovBits bytmp3, ENC_PRI.bit[13], 3;  // Save ENC_PRI register bits

MovBits ENC_PRI.bit[13], ALU, 3;//don't move bit 3, if other bits are 0, it must be 1, and will be handelled in Jmul fallback
Add     uqTmpReg4, uxTmpReg1, bytmp1, 2, MASK_00000003, MASK_SRC2;

Jmul PA_NET_BYPASS,       //Bypass
     NEXT_CHK_LAB,        //Continue
     PA_DRP_LAB, NO_NOP;   //Drop
   Mov uqTmpCtxReg1, IMM_CHK_SAM_TB, 4;//prepare token bucket address   
   And ALU, uqFramePrsReg, {1 << JUMBO_PCKT_STATUS_OFF}, 1;// Check whether packet is jumbo


LAND_IPLOCAL_L4ZERO:

Mov ENC_PRI_STORE , ENC_PRI , 2; 
MovBits ENC_PRI.bit[13] , PA_CASE.bit[13] , 3;
Mov IND_REG0, {15 << 5}, 2;
//-- no need do it mannually 
//MovMul PARSING_DONE_LAB , PARSING_DONE_LAB , LAND_CONT;    

//Mov PC_STACK , ENC_PRO , 2;      

MovMul IC_CNTRL_1_L4ZERO_PORT_OFF, IC_CNTRL_1_LOCALHOST_OFF ,IC_CNTRL_1_LAND_ATTACK_OFF ;
mov bytmp1, 0, 1;
MovBits IND_REG0.bit[0] , ENC_PRO.bit[0] , 5 ;
MovMul  IS_L4PRTZ_CK_DRP ,IS_L3_LOCAL_DRP, IS_L3_LAND_DRP ;     

mov bytmp3, 0, 1;
jmp  CHK_FAIL_LAB;
    MovBits bytmp1.BIT[0], CTX_REG[IND_REG0] , 2;
    Mov uxTmpReg1, ENC_PRO, 2;



////////////////////////////////////////////////////////////
//  Packet Anomalies Failure - Bypass / Drop / Cont Handling
////////////////////////////////////////////////////////////

indirect PA_DRP_LAB:
indirect PA_NET_BYPASS:
   // If sampling is not enabled continue to drop processing
   //if (!uqGcCtrlReg0.BIT[GC_CNTRL_0_IMMCHK_SAMPLENABLED_BIT]) jmp CHECK_TP_CONDITIONS_LAB, NO_NOP;
    MovBits ENC_PRI.BIT[14],ENC_PRI.BIT[15],1; // Jmul in HANDLE_DROPPED_PACKETS_LAB expects ENC_PRI[15..13]=[TRACE_ENABLE, NET_BYPASS_LAB, PA_DISCARD_LAB]
    Mov ALU,{ 1 << IC_CNTRL_0_JUMBOMODE_OFF },4;//Bypass enable: sampling of jumbo frame is allowed if IC_CNTRL_0_JUMBOMODE_OFF
    
   //if not Jumbo(logical operation was done in previous Jmul !!), continue to sampling token bucket 
   JNZ GLOB_CONF_NETWORK_BYPASS_LAB;
      // Check whether configuration allows to send Jumbo to CPU: 
      //             1 - No support for jumbo frames (i.e. jumbo frames are not sampled to CPU), 
      //             0 - Jumbo frames sample to CPU is allowed
      And ALU, ALU,ALU,4, IC_CNTRL_0_MREG,MASK_BOTH;
      PutKey  MSG_L3_USR_OFF(HW_KBS), uqOffsetReg0.byte[L3_OFFB], 4; // initialize in the message both MSG_L3_USR_OFF and MSG_L4_USR_OFF from uqOffsetReg0.byte[L3_OFFB] and uqOffsetReg0.byte[L4_OFFB]
   
   //this is a Jumbo packet
   //JNZ CHECK_TP_CONDITIONS_LAB, NOP_2;//no sampling of jumbo

//CHECK_SAM_TB:
   EZstatPutDataSendCmdIndexReg uqTmpCtxReg1, IMM_SAMP_SIZE_CONST, STS_GET_COLOR_CMD;
      nop;
      nop;

   EZwaitFlag F_SR;

   // Check CPU sampling Token Bucket state (color is also returned to UDB.bits[16,17])
   And ALU,STAT_RESULT_L, 1<<RED_FLAG_OFF, 1;// ALU.bit[1] = 0 if sample, 1 otherwise
   Nop;

   jz SAMPLE, NOP_2; // No sampling in case of RED color (i.e. drop\bypass), or in case of cont
   // Count dropped or bypassed packets and continue with drop handling
   EZstatIncrByOneIndexReg uqTmpReg4;
   
   Jmul PRS_DONE_LAB,   // in case of trace, cont. in order to perform the trace, even if the action is DROP
     CONF_NETWORK_BYPASS_LAB,       //BYPASS
     GLOB_CONF_DROP_LAB,NO_NOP; //DROP
     Nop;
     Nop;

SAMPLE:
   //we get here if RED==0 (sample) and action is drop or bypass
   // Sample packet to CPU (50 packets per second)

   EZstatIncrByOneIndexImm IS_SAMP_CPU;   
      // instead of NOP : if packet is sampled (not red), set bit in msg, used later if reaching default policy.
      Or byCtrlMsgPrs2,byCtrlMsgPrs2,{1<<MSG_CTRL_TOPPRS_2_PA_SAMPL_BIT},1;        
      nop; //##TODO_OPTIMIZE - check if this nop is needed.
   
   jmp HOST_P0_BYPASS_LAB, NOP_2;


//#undef icCtrlType;

////////////////////////////////////////////////
//   Packet Anomalies Failure - Continue Processing
////////////////////////////////////////////////
indirect NEXT_CHK_LAB:
MovBits ENC_PRI.bit[13], bytmp3, 3;//restore saved bits to ENC_PRI
EZstatIncrByOneIndexReg uqTmpReg4;
//restore ENC_PRI
Mov ENC_PRI , ENC_PRI_STORE  , 2;
Return;
   //Mov uxTmpReg2 , 0, 2;
   Mov bytmp1, 0, 1;
   Nop;

////////////////////////////////////////////////
//   Jmul fallback - 
//   Packet Anomalies Failure - Send to CPU Handling
////////////////////////////////////////////////
