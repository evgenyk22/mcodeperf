/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.Parser.h
*
*  Usage:         xad.Prs.Parser.asm include file
*
*******************************************************************************/

#ifndef _XAD_PRS_PARSER_H_;
#define _XAD_PRS_PARSER_H_;

// uqInReg - Parsing errors indication register

// L2 header error status bits             

// BCAST & MCAST bits must stay together (copied together from HWREG)
#define L2_BROADCAST_OFFSET         0     // L2
#define L2_MULTICAST_OFFSET         1     // L2 MAC_MC or L2 control frames.
#define L2_UNS_PROT_OFFSET          2     // L2 //##AMIT_GUY - check if the next bits are free, if so consider changing L2_UNS_PROT_OFFSET to bit 3 instead of 2 and use bit 2 for L2 control frames from the prorocol decoder. check how this affect the host code.

// L3, L4 & L7 header error status bits             
#define L3_IPv4_PROT_OPT_OFFSET     5     // L3
#define L3_UNS_PROT_OFFSET          6     // L3
#define L3_HLEN_ERR_OFFSET          7     // L3
#define IPv4_CHECKSUM_ERR_OFFSET    8     // L3
#define IPv4_TTL_EXP_OFFSET         9     // L3
#define IPv6_FRAMELEN_ERR_OFFSET    10    // L3
#define IPv6_HOP_EXP_OFFSET         11    // L3
#define GTP_UNS_VER_OFFSET          12    // L7
#define GTP_HLEN_ERR_OFFSET         13    // L7
#define GRE_UNS_VER_OFFSET          14    // L4
#define GRE_HLEN_ERR_OFFSET         15    // L4
#define GRE_SRE_NUM_ERR_OFFSET      16    // L4
#define GRE_L4_HDR_SKIP_OFFSET      17    // L4, skip Packet Anomalies for gre external header

// Fragmentation bits must stay together (copied together)
#define FIRST_FRAG_OFFSET           22    // L3
#define FRAG_IPv4_OFFSET            23    // L3
#define FRAG_IPv6_OFFSET            24    // L3

#define TCP_HLEN_ERR_OFFSET         27    // L4
#define SCTP_HLEN_ERR_OFFSET        28    // L4
#define L4_PAYLOAD_LEN_ERR_OFFSET   29    // L4

#define L3_SUPPORT_OFFSET           30    // defines if L3 offset is supported yet

// uqFramePrsReg - Stores data collected during parsing phase
// uqFramePrsReg offsets (Bits):
#define VLAN_TAG_NUM                0;  // 2 bit size, the number of VLANs in the frame.
#define L4_PROTOCOL_OTHER           1;  // 1 bit size, L4 proto is not in{TCP , UDP , ICMP , SCTP , IGMP , GRE , IPinIP, IPSEC}
#define L3_TYPE_OFF                 3;  // 1 bit size: 0-IPv4, 1-Ipv6
#define JUMBO_PCKT_STATUS_OFF       4;  // 1 bit size
#define TUN_EN_OFF                  5;  // 1 bit size, mark if frame has a tunnel that is also enabled (AmitA: probably the main idea for the use of uqFramePrsReg.bit[TUN_EN_OFF] is that the IPinIP tunnel is not the outer tunnel in the frame, then all deeper tunnels inspection should be stopped)
#define TUN_PA_SKIP                 6;  // 1 bit size, '0' marks that this packet contains tunnel that is configured as enabled, so PA should also run in one inner level of this frame. when set to '1' means skip packet anomaly for internal headers (the inner headers may not exist in the frame, or may exist but not be enabled).
#define L3_FRAG_OFF                 7;  // 1 bit size
#define L4_MIN_LEN_OFF              8;  // 6 bit size   //HWD_REG5 is 6 bits long
#define L3_NON_FIRST_FRAG_OFF       14; // 1 bit size, mark if it is a fragmented frame, but this is not the first fragment.
// 15 free
#define L4_TYPE_OFF                 16; // 3 bit size  // Important: Must remain in sync with L4_TYPE_OFFB
#define L4_FLAGS_OFF                19; // 5 bit size
#define TUN_TYPE_OFF                24; // 3 bit size, Type of tunnel: 001 - GRE, 010 - GTP, 011 - IPinIP, 100 - L2TP
#define SYN_TUN_FLAG_DIS_OFFSET     27; // 1 bit size: 1-tunnel flags disable syn/ack generation
#define TUN_L3_TYPE_OFF             28; // 1 bit size: 0-IPv4, 1-Ipv6
#define TUN_L4_TYPE_OFF             29; // 3 bit size 

#define L3_TYPE_IPV4                0;
#define L3_TYPE_IPV6                1;


// L4 types (in uqFramePrsReg.BIT[L4_TYPE_OFF]):
#define L4_UNS_TYPE                 0;
#define L4_TCP_TYPE                 1;
#define L4_UDP_TYPE                 2;
#define L4_ICMP_TYPE                3;
#define L4_IGMP_TYPE                4;
#define L4_SCTP_TYPE                5;
#define L4_GRE_TYPE                 6;
#define L4_IPinIP_TYPE              7; 

// Tunnel types (in uqFramePrsReg.BIT[TUN_TYPE_OFF]):
#define GRE_TUN_TYPE                L4_GRE_TYPE;
#define IPinIP_TUN_TYPE             L4_IPinIP_TYPE;
#define GTP_TUN_TYPE                3;
#define L2TP_TUN_TYPE               4;

// uqFramePrsReg offsets (Bytes):
#define L4_MIN_LEN_OFFB             1;
#define L4_TYPE_OFFB                2; // Important: Must remain in sync with L4_TYPE_OFF

// uqOffsetReg0 offsets
#define L3_OFFB                     0;
#define L4_OFFB                     2;

// uxOffsetReg1 offsets
#define IPv6_FRAG_OFFB              0;


//#define PA_L2_L3_MASK             0x187fff
#define PA_L2_L3_MASK    (1 << IPv6_FRAMELEN_ERR_OFFSET ) | ( 1 << GRE_UNS_VER_OFFSET) | (1 << GRE_SRE_NUM_ERR_OFFSET) | (1 << GRE_HLEN_ERR_OFFSET) | (1 << L3_UNS_PROT_OFFSET)  | (1 << L2_UNS_PROT_OFFSET)  | (1 << L2_BROADCAST_OFFSET) | (1 << L2_MULTICAST_OFFSET) | (1 << GTP_UNS_VER_OFFSET)  | (1 << GTP_HLEN_ERR_OFFSET) 

/******************************************************************************
// L4 Protocol types
******************************************************************************/
// Other L4 types (mapped to the above L4 types)
#define L4_IPinIp_PROT_TYPE         0x04   // L4_IPinIP_TYPE
#define L4_IPSEC1_PROT_TYPE         0x33   // L4_UNS_TYPE
#define L4_IPSEC2_PROT_TYPE         0x32   // L4_UNS_TYPE


/******************************************************************************
// GRE Protocol definitions
******************************************************************************/
#define GRE_FLAGS_OFF      0;
   #define GRE_A_FLAG_BIT     7;
   #define GRE_S_FLAG_BIT     12;
   #define GRE_R_FLAG_BIT     14;


#define GRE_CHKSUM_OFF     8; // ##AMIT_GUY: undestand why offset of checksum is set to 8.

#define GRE_ACK_EXT_SIZE   4;
#define GRE_SEQ_EXT_SIZE   4;

/******************************************************************************
// GTP Protocol definitions
******************************************************************************/
#define GTP_FLAGS_OFF            0;
   #define GTP_VER_OFF_BIT       5;

#define GTP_HDR_MASK             0x7;
#define GTP_EXT_HEAD_FLG_BIT     2;

/******************************************************************************
// L2TP Protocol definitions
*****************************************************************************/
#define L2TP_FLAGS_OFF           0;
   #define L2TP_O_FLAG_BIT    1;   // 'Offset' + 'Offset pad' fields are present
   #define L2TP_S_FLAG_BIT    3;   // Sequence - 'Ns' + 'Nr' fields are present
   #define L2TP_L_FLAG_BIT    6;   // 'Length' field is present (total message length)
   #define L2TP_T_FLAG_BIT    7;   // 'Type' of message (0 = data, 1 = control)

#define L2TP_BASIC_HDR_SIZE      6;
#define L2TP_LENGTH_FIELD_SIZE   2;
#define L2TP_NS_NR_FIELD_SIZE    4;
#define L2TP_OFFSET_FIELD_SIZE   2;


/******************************************************************************
// PPTP Protocol definitions
******************************************************************************/
#define L4_PPP_PROT_TYPE            0x880B;
#define PPP_BASIC_HDR_SIZE          4;
#define PPP_HDR_DEFAULT_CTRL_VALUE  0x3;

/*****************************************************************************
// L4 Protocol ports
******************************************************************************/
#define PARSE_WELL_KNOWN_PORT_MAX   0x03FF
#define PARSE_L2TP_PORT             0x06A5
#define PARSE_GTP_V0_PORT           0x0D3A
#define PARSE_GTP_V1_C_PORT         0x084B                
#define PARSE_GTP_V1_U_PORT         0x0868                 


/*****************************************************************************
// L4 Protocol header sizes
******************************************************************************/
#define SCTP_BASE_SIZE              16
#define ICMP_BASE_SIZE              8
#define IGMP_BASE_SIZE              8


////////////////////////////////
//          BCAM8
////////////////////////////////

// GuyE, 12.6.2013: we have a bug with xadEzLowDrvBDOSPhaseDelete overriding some of the BCAM8 entries when deleting
// so do not configure BCAM8 entries using LDCAM until this problem is resolved!!


// For Packet Anomalies use:

#define TCP_VALID_COMBINATION_GRP   2;

/* By E.R. updated by driver in the xadEzLowDrvImmChkCreate()
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x10, 1;
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x12, 1;
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x18, 1;
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x19, 1;
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x4 , 1;
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x14, 1;
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x11, 1; //SYN
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x2 , 1; //SYN
LDCAM BCAM8[TCP_VALID_COMBINATION_GRP], 0x84, 1; //SYN
*/


////////////////////////////////
//          BCAM16
////////////////////////////////

// GRE Tunnel definitions

#define SYN_PROT_EN                    0;
#define SYN_PROT_DIS                   0x8000;             // Set bit[15] to '1' (not needed for size result, used to indicate whether to proceed with SYN protection or not)

#define GRE_NO_EXT_HEAD_P              (SYN_PROT_EN | 4);  // For this flag combination SYN Protection is enabled
#define GRE_KEY_P                      (SYN_PROT_EN | 8);  // For this flag combination SYN Protection is enabled
#define GRE_SEQ_P                      (SYN_PROT_DIS| 8);
#define GRE_CHKSUM_OFFSET_P            (SYN_PROT_DIS| 8);
#define GRE_KEY_SEQ_P                  (SYN_PROT_DIS|12);
#define GRE_CHKSUM_OFFSET_SEQ_P        (SYN_PROT_DIS|12);
#define GRE_CHKSUM_OFFSET_KEY_P        (SYN_PROT_DIS|12);
#define GRE_CHKSUM_OFFSET_KEY_SEQ_P    (SYN_PROT_DIS|16);

#define GRE_FLAG_HDR_SIZE_GRP 0;

LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x0, GRE_NO_EXT_HEAD_P;           // No Extensions, 4 bytes size
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x1, GRE_SEQ_P;                   //  8 bytes size: Seq
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x2, GRE_KEY_P;                   //  8 bytes size: Key
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x3, GRE_KEY_SEQ_P;               // 12 bytes size: Key, Seq
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x4, GRE_CHKSUM_OFFSET_P;         //  8 bytes size: Checksum, Offset
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x5, GRE_CHKSUM_OFFSET_SEQ_P;     // 12 bytes size: Checksum, Offset, Seq
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x6, GRE_CHKSUM_OFFSET_KEY_P;     // 12 bytes size: Checksum, Offset, Key
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x7, GRE_CHKSUM_OFFSET_KEY_SEQ_P; // 16 bytes size: Checksum, Offset, Key, Seq
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x8, GRE_CHKSUM_OFFSET_P;         //  8 bytes size: Checksum, Offset
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0x9, GRE_CHKSUM_OFFSET_SEQ_P;     // 12 bytes size: Checksum, Offset, Seq
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0xa, GRE_CHKSUM_OFFSET_KEY_P;     // 12 bytes size: Checksum, Offset, Key
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0xb, GRE_CHKSUM_OFFSET_KEY_SEQ_P; // 16 bytes size: Checksum, Offset, Key, Seq
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0xc, GRE_CHKSUM_OFFSET_P;         //  8 bytes size: Checksum, Offset
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0xd, GRE_CHKSUM_OFFSET_SEQ_P;     // 12 bytes size: Checksum, Offset, Seq
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0xe, GRE_CHKSUM_OFFSET_KEY_P;     // 12 bytes size: Checksum, Offset, Key
LDCAM BCAM16[GRE_FLAG_HDR_SIZE_GRP], 0xf, GRE_CHKSUM_OFFSET_KEY_SEQ_P; // 16 bytes size: Checksum, Offset, Key, Seq


////////////////////////////////
//          BCAM32
////////////////////////////////

// Map between SIP/DIP hash function and XAUI network interfaces

// Key: Modulo 6 on random number (system clock), Result: XAUI network interface

/* Not used more
#define CPU_2_NET_MAP_GRP 0;

LDCAM BCAM32[CPU_2_NET_MAP_GRP], 0, XAUI_NET_PORT_1;
LDCAM BCAM32[CPU_2_NET_MAP_GRP], 1, XAUI_NET_PORT_2;
LDCAM BCAM32[CPU_2_NET_MAP_GRP], 2, XAUI_NET_PORT_4;
LDCAM BCAM32[CPU_2_NET_MAP_GRP], 3, XAUI_NET_PORT_5;
LDCAM BCAM32[CPU_2_NET_MAP_GRP], 4, XAUI_NET_PORT_7;
LDCAM BCAM32[CPU_2_NET_MAP_GRP], 5, XAUI_NET_PORT_9;
*/

// For IPv6 Subheader parsing use:

#define PARSE_EXT_HEADER_HOP_BY_HOP       0;
#define PARSE_EXT_HEADER_ROUTE            43;
#define PARSE_EXT_HEADER_FRAGMENT         44;
#define PARSE_EXT_HEADER_ESP              50;
#define PARSE_EXT_HEADER_AUTHENTICATION   51;
#define PARSE_EXT_HEADER_DEST_OPTS        60;

#define LACP_GROUP                  0
#define L7_PROT_GRP                 1
/* By E.R. updated by driver in the xadEzLowDrvStart()
LDCAM BCAM32[IPv6_SUBHEAD_ID_GRP], PARSE_EXT_HEADER_HOP_BY_HOP,     1;
LDCAM BCAM32[IPv6_SUBHEAD_ID_GRP], PARSE_EXT_HEADER_ROUTE,          1;
LDCAM BCAM32[IPv6_SUBHEAD_ID_GRP], PARSE_EXT_HEADER_DEST_OPTS,      1;
LDCAM BCAM32[IPv6_SUBHEAD_ID_GRP], PARSE_EXT_HEADER_FRAGMENT,       2;
LDCAM BCAM32[IPv6_SUBHEAD_ID_GRP], PARSE_EXT_HEADER_ESP,            8;
LDCAM BCAM32[IPv6_SUBHEAD_ID_GRP], PARSE_EXT_HEADER_AUTHENTICATION, 4;
*/


#define uqTunInReg               uqTmpReg0;
#define uxGreTunTmpOffReg        uqTmpReg4;

LdThrowLabel GLOB_ANOMALY_LAB; 

#endif; // of #ifndef _XAD_PRS_PARSER_H_

