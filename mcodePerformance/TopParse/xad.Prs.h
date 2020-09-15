/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.h
*
*  Usage:         xad.Prs.asm include file
*
*******************************************************************************/

#ifndef _XAD_PRS_H_;
#define _XAD_PRS_H_;

// by - 1 byte
// ux - 2 bytes
// uq - 4 bytes
// bit - 1 bit
// bits2, bits3, bits4 etc... - sevral bits - 2,3,4 and so on.

// Microcode version number, label and basic description that can be read from the host.
description "Version 1.96.00.00 Generic Mode";

// Global & Local variables:

#define uqGcCtrlReg0                   UDB;  // 4 bytes, Host global configuration register, bitwise access register (i.e. each bit can be tested ugin if register.bit[x]....)

#define uqCondReg                      UREG[1];
#define byTempCondByte1                UREG[1].byte[0];
#define byTempCondByte2                UREG[1].byte[1];
#define byTempCondByte3                UREG[1].byte[2];
#define byTempCondByte4                UREG[1].byte[3];

#define uqTmpReg0                      CTX_REG[10] //UREG[3];
#define uqOffsetReg0                   UREG[4];
#define uqInReg                        CTX_REG[11] ; 


#define uqTmpReg3                      UREG[13];
#define uxTmpReg1                      UREG[13].byte[0];
#define uxTmpReg2                      UREG[13].byte[2];

#define uqTmpReg4                      CTX_REG[8]; //UREG[6];
#define uqTmpReg5                      CTX_REG[9]; //UREG[7];

#define uqFramePrsReg                  UREG[5];
                                                
#define uqTmpReg1                      UREG[14];
#define uqTmpReg2                      UREG[11];          //4bytes, Parsing errors indication register

#define bytmp                          uqTmpReg2.byte[0];
#define bytmp1                         uqTmpReg2.byte[1];
#define bytmp2                         uqTmpReg2.byte[2];
#define bytmp3                         uqTmpReg2.byte[3];


// UREGs 8 & 9 are saved for statistics result

#define uqTmpReg6                      UREG[10];


#define uqTmpReg7                      EXT_REG[9];
#define byL4Proto                      EXT_REG[9].byte[0];
//#define uqTmpReg8 obsolete

#define uxHash2BVal                    /*EXT_REG[10]*/UREG[3].byte[1];   //2 byte
/* 
   Netstack  indication
   ARP,
   Broadcast Mac,
   Multicast mac ipv6
   Ip to me:ICMP, ICMPV6, BGP
*/
#define ROUTE_NETSTACK_BRMCAST_OFF     0
/* GRE */
#define ROUTE_GRE_OFF                  1
#define ROUTE_NETSTACK_ICMPBGP_OFF     2
#define ROUTE_SUB_INF_DET_OFF          7

#define uqTmpReg9                      EXT_REG[11];
#define byFrameActionOverrideReg       EXT_REG[12].byte[0];//loaded with same actions as in byFrameActionReg

#define uqTmpReg11                     EXT_REG[13];
#define uqTmpReg12                     EXT_REG[14];
#define uqTmpReg13                     EXT_REG[15];

//#define byGlobConfReg                  UREG[10].byte[0];  

//#define uqInReg                        UREG[11];          //4 bytes, Parsing errors indication register
#define uqTunnelOffsetReg              UREG[12];          //4 bytes, Holds L3,L4 offsets (uqOffsetReg0) for outer label when parsing of inner label is needed. IMPORTANT: this register is zerod for each new frame, therfore clearing L3_TUN_OFF is not needed by the code. If changing this register then clear this field in entrance to TOPparse !
//#define uqOffsetReg0                   UREG[13];          //4 bytes, L3, L4 offset (2 bytes each)
#define uxOffsetReg1                   VQM_DATA0.byte[0]; //2 bytes for IPv6 frag offset, 2 upper bytes free
//#define uqFramePrsReg                  UREG[14];

// The following 2 bytes must remain adjacent since they are read together

#define byCtrlMsgPrs0                  /*UREG[15]*/UREG[2].byte[0];  //1 byte, holds 1st byte of control bits in message from TOPparse to TOPresolve
#define byCtrlMsgPrs1                  /*UREG[15]*/UREG[2].byte[1];  //1 byte, holds 2nd byte of control bits in message from TOPparse to TOPresolve
#define byCtrlMsgPrs2                              UREG[2].byte[2];  //1 byte, holds 3rd byte of control bits in message from TOPparse to TOPresolve
#define byCtrlMsgPrs3                /*CTX_REG[6]*/UREG[2].byte[3]; //compleate with next merge   



#define byFrameActionReg               UREG[6].byte[0];  //1 byte, holds the action that should be performed on the frame
#define bySrcPortReg                   UREG[6].byte[1];  //1 byte, holds physical source port according to FFT lookup
#define byVifPortReg                   UREG[6].byte[2];
#define byHashVal                      UREG[6].byte[3];

#define R_PC                           UREG[7];

#define CNVI                           CTX_REG[0];
#define uqTmpCtxReg1                   CTX_REG[1];

#define uqTmpCtxReg2                   CTX_REG[2]; // AmitA: used for general purpose, but should be accessed with vardef and varundef to use it only in relevant places
   #define CTX_REG2_TUNNELS_LEFT_TO_INSPECT_BIT                     0 ; // 2 bits, currently not used. preperation fro Parser/PA separation. in place where used may be changed with zero as not inspected in current implementation. value // note: if updating this to be more then 2 bits, then need to update the vardef definition for $bits2TmpCtxReg2TunnelsLeftToInspect, and for the rest of the bits offset bellow.
   #define CTX_REG2_DID_PARSER_RUN_BIT                              2 ; // 1 bit,  currently not used. preperation fro Parser/PA separation.
   #define CTX_REG2_IS_SSPCTD_RDWRGRETUN_BIT                        3 ; // 1 bit,  currently not used. preperation fro Parser/PA separation.
   #define CTX_REG2_REMOVE_RDWRGRETUN_BIT                           4 ; // 1 bit
   #define CTX_REG2_DEFER_BYPASS_NW_UNTIL_BUILD_ROUTING_KEY_BIT     5 ; // 1 bit,  used to defer jump to NETWORK_BYPASS_LAB in routing mode in case that the routing key was not already built
   #define CTX_REG2_DEFER_PARSING_DONE_UNTIL_BUILD_ROUTING_KEY_BIT  6 ; // 1 bit
   #define CTX_REG2_IS_GRE_NEXT_PROTOCOL_TYPE_ZERO_BIT              7 ; // 1 bit,  currently not used. preperation fro Parser/PA separation. // TODO: pass over this list and mark which bits in this registers are currently used and which bits are written as a beginning of design and are currently not used.
   #define CTX_REG2_IS_GRE_NEXT_PROTOCOL_TYPE_IPV4_BIT              8 ; // 1 bit,  currently not used. preperation fro Parser/PA separation.
   #define CTX_REG2_IS_GRE_NEXT_PROTOCOL_TYPE_IPV6_BIT              9 ; // 1 bit,  currently not used. preperation fro Parser/PA separation.
   #define CTX_REG2_WAS_DIP_TCAM_KEY_WRITTEN_BIT                    10; // 1 bit
   #define CTX_REG2_PUNT_TO_HOST_BIT                                11; // 1 bit,  currently not used. preperation fro Parser/PA separation. // ##AMIT_TOCODE is it needed??? - if so need to find place for it. delete it if not needed after implementing the Parser-PA separation.
   #define CTX_REG2_RADWARE_GRE_TUN_AROUND_IPV4_BIT                 12; // 1 bit // Must be just before CTX_REG2_RADWARE_GRE_TUN_AROUND_IPV6_BIT. Marks that RadwareGRETunnel is in format IPv4.GRE.IPv4.*. Used to tell parser which IP type exists after the IPv4.GRE.
   #define CTX_REG2_RADWARE_GRE_TUN_AROUND_IPV6_BIT                 13; // 1 bit // Must be just after  CTX_REG2_RADWARE_GRE_TUN_AROUND_IPV4_BIT. Marks that RadwareGRETunnel is in format IPv4.GRE.IPv6.*. Used to tell parser which IP type exists after the IPv4.GRE.

//#define bits2TmpCtxReg2TunnelsLeftToInspect                  uqTmpCtxReg2.bit[CTX_REG2_TUNNELS_LEFT_TO_INSPECT_BIT:CTX_REG2_TUNNELS_LEFT_TO_INSPECT_BIT+1];
//#define bitTmpCtxReg2DidParserRun                            uqTmpCtxReg2.bit[CTX_REG2_DID_PARSER_RUN_BIT];
//#define bitTmpCtxReg2IsSuspectedRadwareGRETunnel             uqTmpCtxReg2.bit[CTX_REG2_IS_SSPCTD_RDWRGRETUN_BIT];
#define bitTmpCtxReg2RemoveRdwrGRETunnel                       uqTmpCtxReg2.bit[CTX_REG2_REMOVE_RDWRGRETUN_BIT];
#define bitTmpCtxReg2DeferBypassNetworkUntilBuildRoutingKey    uqTmpCtxReg2.bit[CTX_REG2_DEFER_BYPASS_NW_UNTIL_BUILD_ROUTING_KEY_BIT];    // using define for these 2 bits instead of vardef
#define bitTmpCtxReg2DeferParsingDoneUntilBuildRoutingKey      uqTmpCtxReg2.bit[CTX_REG2_DEFER_PARSING_DONE_UNTIL_BUILD_ROUTING_KEY_BIT]; // using define for these 2 bits instead of vardef
//#define bitTmpCtxReg2IsGreNxtProtTypeZero                    uqTmpCtxReg2.bit[CTX_REG2_IS_GRE_NEXT_PROTOCOL_TYPE_ZERO_BIT];
//#define bitTmpCtxReg2IsGreNxtProtTypeIPv4                    uqTmpCtxReg2.bit[CTX_REG2_IS_GRE_NEXT_PROTOCOL_TYPE_IPV4_BIT]; // use these bits for KeepAlive Request/Reply.
//#define bitTmpCtxReg2IsGreNxtProtTypeIPv6                    uqTmpCtxReg2.bit[CTX_REG2_IS_GRE_NEXT_PROTOCOL_TYPE_IPV6_BIT]; // use these bits for KeepAlive Request/Reply.
#define bitTmpCtxReg2WasRoutingTcamKeyWritten                  uqTmpCtxReg2.bit[CTX_REG2_WAS_DIP_TCAM_KEY_WRITTEN_BIT];
//#define bitTmpCtxReg2PuntToHost                              uqTmpCtxReg2.bit[CTX_REG2_PUNT_TO_HOST_BIT];
#define bitTmpCtxReg2RadwareGRETunnelAroundIPv4                uqTmpCtxReg2.bit[CTX_REG2_RADWARE_GRE_TUN_AROUND_IPV4_BIT];
#define bitTmpCtxReg2RadwareGRETunnelAroundIPv6                uqTmpCtxReg2.bit[CTX_REG2_RADWARE_GRE_TUN_AROUND_IPV6_BIT];

#define uxTmp2CtxReg2                  CTX_REG[2].byte[2];// 2 bytes for second temporary register 

// All locations that performed jump to PARSING_DONE_LAB from parser where inspected and found that either do not require building the key (L2 / L3 unsupported frames 
// will not be routed), or are performed AFTER the build key code was already called. therefore no need to make the same mechanism to defer jumping to PARSING_DONE_LAB until the key will be built.
//VarDef  RegType uxVlanTag0Id                   CTX_REG[3].byte[0:1];
//VarDef  RegType uxVlanTag1Id                   CTX_REG[3].byte[2:3];
#define uqTmpCtxReg4                           CTX_REG[4]; // AmitA: used for general purpose, but should be accessed with vardef and varundef to enforce using it only in relevant places
#define byCntrlOOSReg                          CTX_REG[5].byte[0];
#define byCntrlPayload                         CTX_REG[5].byte[1]; // YanivBe: bit[0] is set if a packet has payload
#define uxCntrlGenDecoder                      CTX_REG[5].byte[2]; // 2 bytes Store some General Decoder info
#define byCtrlFree                             CTX_REG[6].byte[0]; // 1 byte not in use


//#define bitPRS_hasRxCopyPort                   byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_HAS_RX_COPY_BIT];
//#define bitPRS_isSltVlanMode                   byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_SLT_VLAN_BIT];

#define byGlobConfReg                          CTX_REG[6].byte[2];

//                                             CTX_REG[8:15]; // used to read the lookup result in the IPv4_DIP LookAside. may be overwritten for any purpose of the application after the code finished the IPv4 LookAside in xad.Prs.asm.

// Support up to 2 levels inspection of encapsulated frames (RadwareGRETunnel, even if exist, does not count in this calculation, i.e. even if RadwareGRETunnel exist or does not
// exist in the frame, then the code will inspect up to 2 tunnel levels under it, if the user tunnel exists in the frame and is enabled by configuration).
#define MAX_SUPRTD_TUN_LVL             2; 

// Supported tunnels:
//       GRE                  - (0x2F)
//       L4_IPinIp_PROT_TYPE  - (0x04)
//       GTP                  - from many places, but not from MANUAL_L4_PROTOCOL_DECODE_LAB
//       LT2P                 - ? not seen in the code.


// Mask registers (MREG0..15)

LDREG MREG[0], 			0x0000001F;
#define MASK_0000001F	MREG[0];

LDREG MREG[1], 			0x0000007F;
#define MASK_0000007F	MREG[1];

LDREG MREG[2], 			0x000000FF;
#define MASK_000000FF	MREG[2];

LDREG MREG[3], 			0x00FFFFFF;
#define MASK_00FFFFFF	MREG[3];

LDREG MREG[4], 			0x00000007;
#define MASK_00000007	MREG[4];

LDREG MREG[5], 			0x00000003;
#define MASK_00000003	MREG[5];

LDREG MREG[6], 			0x0000FFFF;
#define MASK_0000FFFF	MREG[6];

LDREG MREG[7], 			0x0000000F;
//LDREG MREG[7], MASK_FOR_HWARE_L4_TYPE;
#define MASK_0000000F	MREG[7];

LDREG MREG[8], 			0x00001FFF;
#define MASK_00001FFF	MREG[8];

LDREG MREG[9], 			0x00000FFF;
#define MASK_00000FFF	MREG[9];


// Host configuration registers

// MREG[10] is reserved for Packet Anomalies control 0
#define IC_CNTRL_0_MREG       MREG[10];

// MREG[11] Key for Packet Anomalies control 0
#define IC_CNTRL_1_MREG       MREG[11];

// SYN COOKIE timestamp
#define SC_CK_STMP_MREG       MREG[12];

// SYN_COOKIE Key for odd phase
#define SC_CK_KEY_P1_MREG     MREG[13];

// SYN_COOKIE Key for even phase
#define SC_CK_KEY_P0_MREG     MREG[14];

// MREG[15] is reserved for host configuration 0
#define GC_CNTRL_0_MREG       MREG[15];


//***********************************************************
//* Application sepcific defines
//*
//* 
#define bitPRS_isRoutingMode uqGcCtrlReg0.bit[GC_CNTRL_0_ROUTING_ENABLED_BIT];


// Messages lookup headers
#define MSG_HDR 0xF3;
#define PRS_MSG_HDR                 (MSG_VALID | (MSG_STR      << HREG_STR_NUM_BIT) | (((MSG_SIZE - 1  )      >> 4) << HREG_MSG_SIZE_BIT));
LdMsgHdr PRS_MSG_HDR;  // This is used for copying HW_MSG (first 16 bytes of MSG_STR) from TOPparse to TOPresolve

#define CTRL_MSG_HDR                (MSG_VALID | (CTRL_MSG_STR << HREG_STR_NUM_BIT) | (((CTRL_MSG_SIZE - 1  ) >> 4) << HREG_MSG_SIZE_BIT));
#define CTRL_MSG_32_HDR             (MSG_VALID | (CTRL_MSG_STR << HREG_STR_NUM_BIT) | (((CTRL_MSG_SIZE - 1  ) >> 4) << HREG_MSG_SIZE_BIT));  // CTRL_MSG_32_HDR is for message structure 6 with size 32


// Keys lookup headers

#define COMP_POLICY_HDR             (LKP_VALID | (POLICY_START           << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_POLICY_KMEM_SIZE - 1)        >> 4) << HREG_KEY_SIZE_BIT));

#define COMP_ROUTING_HDR_P0         (LKP_VALID | (ROUTING_START_P0       << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_ROUTING_KMEM_SIZE - 1)         >> 4) << HREG_KEY_SIZE_BIT));
#define COMP_ROUTING_HDR_P1         (LKP_VALID | (ROUTING_START_P1       << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_ROUTING_KMEM_SIZE - 1)         >> 4) << HREG_KEY_SIZE_BIT));

#define COMP_IPV4_HDR_P0            (LKP_VALID | (ATTACK_IPV4_START_P0   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L23_IPV4_KMEM_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT));
#define COMP_IPV4_HDR_P1            (LKP_VALID | (ATTACK_IPV4_START_P1   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L23_IPV4_KMEM_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT));

#define COMP_IPV6_HDR_P0            (LKP_VALID | (ATTACK_IPV6_START_P0   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L23_IPV6_KMEM_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT));
#define COMP_IPV6_HDR_P1            (LKP_VALID | (ATTACK_IPV6_START_P1   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L23_IPV6_KMEM_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT));

#define COMP_TCP_HDR_P0             (LKP_VALID | (ATTACK_TCP_START_P0    << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));
#define COMP_TCP_HDR_P1             (LKP_VALID | (ATTACK_TCP_START_P1    << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));

#define COMP_UDP_HDR_P0             (LKP_VALID | (ATTACK_UDP_START_P0    << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));
#define COMP_UDP_HDR_P1             (LKP_VALID | (ATTACK_UDP_START_P1    << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));

#define COMP_IGMP_HDR_P0            (LKP_VALID | (ATTACK_IGMP_START_P0   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));
#define COMP_IGMP_HDR_P1            (LKP_VALID | (ATTACK_IGMP_START_P1   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));

#define COMP_ICMP_HDR_P0            (LKP_VALID | (ATTACK_ICMP_START_P0   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));
#define COMP_ICMP_HDR_P1            (LKP_VALID | (ATTACK_ICMP_START_P1   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_BDOS_L4_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT));

//#define COMP_SYN_PROT_LKP           (LKP_VALID | (SYN_PROT_DEST_START    << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_SYN_PROT_DEST_KMEM_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT));

//#define COMP_NON_SYN_PROT_LKP       (LKP_VALID | (NON_SYN_PROT_DEST_START<< HREG_FIRST_LINE_ADDR_BIT) | (((CMP_SYN_PROT_DEST_KMEM_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT));

#define ALST_MAIN_LKP               (LKP_VALID | (ALST_EXT_TCAM_LOOKUP   << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_ACL_KMEM_SIZE - 1)           >> 4) << HREG_KEY_SIZE_BIT) | (HREG_RES_DEST_RMEM_OR_CTX << HREG_RESULT_DEST_BIT) ) // HREG_RESULT_DEST_BIT and HREG_KEY_TYPE_BIT are the same

//#define OOS_LKP                     (LKP_VALID | (OOS_START              << HREG_FIRST_LINE_ADDR_BIT) | (((SIMP_OOS_LKP_SIZE - 1)           >> 4) << HREG_KEY_SIZE_BIT));

#define MAIN_LKP           (LKP_VALID | (MAIN_START    << HREG_FIRST_LINE_ADDR_BIT) | (((MAIN_KMEM_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT));


/* Parse IPv4 DIP LookAside.
   The Key is located in the last chunk of 16 bytes TOPparse of KMEM (bytes 368..383).
   The DIP is located in the first 4 bytes of this memory chunk. The bytes afterwards in this 16 bytes chunk in KMEM are not used.*/
#define KMEM_PRS_LA_IPV4_DIP_OFF         368;

#define KEY_PRS_LA_IPV4_DIP_SIZE  		16;
#define KEY_PRS_LA_IPV4_DIP_HDR          (LKP_VALID | (SRH_PRS_LA_IPV4_DIP_LOOKASIDE_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((KEY_PRS_LA_IPV4_DIP_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (HREG_RES_DEST_CTX_WAIT_READY << HREG_RESULT_DEST_BIT) | ((KMEM_PRS_LA_IPV4_DIP_OFF >> 4) << HREG_KMEM_OFFSET_BIT)); // HREG_RESULT_DEST_BIT and HREG_KEY_TYPE_BIT are the same.



// For Ext.TCAM lookaside:
//#define ALST_MAIN_LKP             (LKP_VALID | (ALST_SRH_READ_CTX_TCAM_RES << HREG_FIRST_LINE_ADDR_BIT) | (((ALST_MAIN_SIZE - 1)          >> 4) << HREG_KEY_SIZE_BIT) | (HREG_RES_DEST_RMEM_OR_CTX       << HREG_RESULT_DEST_BIT))
//#define ALIST_HDR7_NOWAIT_HDR     (LKP_VALID | (ALST_EXT_TCAM_LOOKUP       << HREG_FIRST_LINE_ADDR_BIT) | (((CMP_ACL_KMEM_SIZE - 1)       >> 4) << HREG_KEY_SIZE_BIT) | (HREG_RES_DEST_CTX_WAIT_READY    << HREG_RESULT_DEST_BIT) | (((MSG_SIZE) >> 4) << HREG_KMEM_OFFSET_BIT)) // HREG_RESULT_DEST_BIT and HREG_KEY_TYPE_BIT are the same
//#define KMEM_ALST_CTX_LINE_OFF 0


// Lookup sizes



// Packet offsets

// The folowing are from network.h:
/*
#define IP_DSCPOFF         1  ;
#define IP_LEN_OFF         2  ;
#define IP_TTL_OFF         8  ;
#define IP_PRT_OFF         9  ;
#define IP_CHK_OFF         10 ;
#define IP_SIP_OFF         12 ;
#define IP_DIP_OFF         16 ;

#define IP_BASE_SIZE       20 ;

*/

// IP definitions
#define IP_FLAGS_OFF        6;
#define UDP_CHK_OFF         6;
#define IP_TTL_EXPIRED_BIT 28;
#define IP_HDR_ERR_BIT     31;


// Offsets in L4 header
#define ICMP_TYPE_OFFSET     0;
#define ICMP_CHCKSUM_OFFSET  2;

#define IGMP_TYPE_OFFSET     0;
#define IGMP_CHCKSUM_OFFSET  2;


// Offsets in Control Frame:

#define CTRL_FRAME_ETH_HDR_SIZE        14;       
#define CTRL_FRAME_SEQ_NUM_OFF         (0 + CTRL_FRAME_ETH_HDR_SIZE);
#define CTRL_FRAME_MSG_SIZE_OFF        (4 + CTRL_FRAME_ETH_HDR_SIZE);
#define CTRL_FRAME_CMD_COUNT_OFF       (6 + CTRL_FRAME_ETH_HDR_SIZE);
#define CTRL_FRAME_FIRST_COMMAND_OFF   (8 + CTRL_FRAME_ETH_HDR_SIZE);

#define HW_KBS                               KMEM_BASE0;
#define COM_KBS                              KMEM_BASE1;
#define COM_HBS                              HREG_BASE1;

// offsets for Packet Payload control register
#define CTRL_PKT_PAYLOAD_OFF           0;    // Enabled bit represents a Packet with Payload. Disabled bit represents a Packet without Payload.

// According to configuration in xadDriver xadEzLowDrvHWParsePortSramConstInit():

/*
#define HOST_P0             1
#define HOST_P1             2
#define NET_P1              1
#define NET_P2              2
#define NET_P4              4
#define NET_P5              5
#define NET_P7              7
#define NET_P9              9

#define FRAME_CREG_NET      4;   // 100b
#define FRAME_CREG_HOST     2;   // 010b
#define FRAME_CREG_CTRL     1;   // 001b


#define  XAUI0_CREG_0       0                 // Not used
#define  XAUI0_CREG_1       NET_P1            // Not used: from host port 0 forward to net port 1
#define  XAUI0_CREG_3       FRAME_CREG_HOST

#define  XAUI1_CREG_0       0                 // Not used
#define  XAUI1_CREG_1       NET_P1            // Not used: from net port 1 bypass to net port 1
#define  XAUI1_CREG_3       FRAME_CREG_NET    

#define  XAUI2_CREG_0       0                 // Not used
#define  XAUI2_CREG_1       NET_P2            // Not used: from net port 2 bypass to net port 2
#define  XAUI2_CREG_3       FRAME_CREG_NET

#define  XAUI3_CREG_0       0                 // Not used
#define  XAUI3_CREG_1       NET_P4            // Not used: from host port 3 forward to net port 4
#define  XAUI3_CREG_3       FRAME_CREG_HOST

#define  XAUI4_CREG_0       0                 // Not used
#define  XAUI4_CREG_1       NET_P4            // Not used: from net port 4 bypass to net port 4
#define  XAUI4_CREG_3       FRAME_CREG_NET

#define  XAUI5_CREG_0       0                 // Not used
#define  XAUI5_CREG_1       NET_P5            // Not used: from net port 5 bypass to net port 5
#define  XAUI5_CREG_3       FRAME_CREG_NET

#define  XAUI6_CREG_0       0                 // Not used
#define  XAUI6_CREG_1       NET_P7            // Not used: from host port 6 forward to net port 7
#define  XAUI6_CREG_3       FRAME_CREG_HOST

#define  XAUI7_CREG_0       0                 // Not used
#define  XAUI7_CREG_1       NET_P7            // Not used: from net port 7 bypass to net port 7
#define  XAUI7_CREG_3       FRAME_CREG_NET

#define  XAUI8_CREG_0       0                 // Not used
#define  XAUI8_CREG_1       NET_P9            // Not used: from host port 8 forward to net port 9
#define  XAUI8_CREG_3       FRAME_CREG_HOST

#define  XAUI9_CREG_0       0                 // Not used
#define  XAUI9_CREG_1       NET_P9            // Not used: from net port 9 bypass to net port 9
#define  XAUI9_CREG_3       FRAME_CREG_NET

#define SGMII0_CREG_0       0x0810c000        // Not used
#define SGMII0_CREG_1       0                 // Not used
#define SGMII0_CREG_2       3                 // Not used
#define SGMII0_CREG_3       FRAME_CREG_CTRL

#define SGMII1_CREG_0       0x0810c001        // Not used
#define SGMII1_CREG_1       0                 // Not used
#define SGMII1_CREG_2       3                 // Not used
#define SGMII1_CREG_3       FRAME_CREG_CTRL
*/

#define PORT_CFG0                            PORT_DATA0;          // 4 bytes, free

#define PORT_CFG1                            PORT_DATA1;
   #define PORT_CFG1_OUTP_OFF                PORT_DATA1.byte[0];  // 1 byte, free: predefined destination port, not in use now (after distribution)
   #define PORT_CFG1_LSB_MAC_OFF             PORT_DATA1.byte[1];  // 3 bytes, lower 3 bytes of port MAC address. Example: For MAC 0x010203040506 - 040506

#define PORT_CFG2                            PORT_DATA2;
   #define PORT_CFG2_FREE_OFF                PORT_DATA2.byte[0];  // 2 bytes, free
   #define PORT_CFG2_MAX_PACKET_SIZE_OFF     PORT_DATA2.byte[2];  // 2 bytes, maximum allowed packet size per port

#define PORT_CFG3                            PORT_DATA3;
   #define PORT_CFG3_IF_TYPE_OFF             PORT_DATA3.byte[0];  // 1 byte, port interface type: 4 - Network port, 2 - Host port, 1 - Host configuration port (messages from host)
   #define PORT_CFG3_MSB_MAC_OFF             PORT_DATA3.byte[1];  // 3 bytes, upper 3 bytes of port MAC address. Example: For MAC 0x010203040506 - 010203

#define JUMBO_PCKT_CREG2_OFF     2; //##AMIT_GUY this is defined in 2 places - xad.prs.h and xad.common.h. double definition is not recommended and should be defined in a single place. see also its 'JUMBO - friends'.


//Global controller bits in Byte[1]
#define GLOBAL_CTRLR1_TCP_5FLAGS    0
#define GLOBAL_CTRLR1_FRAG          6
//global inf encoding
#define FRAME_NET1     1;
#define FRAME_NET2     2;
#define FRAME_NET3     4;
#define FRAME_HOST_0   8;
#define FRAME_HOST_1   0x10;

#define FRAME_HOST_CFG 0x20;

#define SYN_COOKIE_CONST_KEY_VAL       0x622B70F5;

/* Error was detected in ICFD: Increment a counter, recycle and discard the packet. */
LdIcfdErrLabel ICFDQ_ERR_DROP_LAB_CONT;

#define PC_STACK_STORE CTX_REG[14];
#define ENC_PRI_STORE  CTX_REG[13];
#define PA_CASE        CTX_REG[12]; 


//Global controller bits in Byte[0]
#define GLOBAL_CTRLR0_IP_VERSION 7
#define GLOBAL_CTRLR0_IP_VERSION_CLEAR_BIT 0x7F
#define PER_POLICY_CTRLR_IP_VERSION 15  //bit count in CAMI 

//Global controller bits in Byte[1]
#define GLOBAL_CTRLR1_TCP_5FLAGS    0
#define GLOBAL_CTRLR1_FRAG          6 

#endif; // of #ifndef _XAD_PRS_H_

