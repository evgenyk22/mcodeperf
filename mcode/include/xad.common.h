/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.common.h
*
*  Usage:         Structures, mesage and general definitions file
*
*******************************************************************************/

#ifndef _XAD_COMMON_H_
#define _XAD_COMMON_H_

#define DNS_DROP1 1
//#define DEBUG_STAT_MODE 1

//#define AA_DEBUG_FORCE_ROUTING_MODE                 // overwrite value read from MREG with routing mode
//#define AA_DEBUG_FORCE_TRANSPARENT_MODE             // overwrite value read from MREG with transparent mode
//#define AA_DEBUG_DISABLE_MY_IP_TO_HOST_TB_MECHANISM // if defined - don't use TB for sending to the host - always send.


/******************************************************************************
                              Common Control Bits
*******************************************************************************/
// Common for all structures:
#define VALID_BIT    0
#define MATCH_BIT    4

// Messages

/////////////////////////////////////////////////////////////////////
// Structure 0 - General Message (between TOPparse and TOPresolve)
/////////////////////////////////////////////////////////////////////
#define MSG_STR         0
#define MSG_STR_CTRL_BITS_OFF                   0

// bytes 2,3 are relevant only for inter-link NP packets (packets from the other NP).
// In such case the MSG_STR contains the destination physical port numbers in the following 2 bytes.
// Each byte represents port number (bits (0:6) and valid bit (bit7)
#define MSG_CAUI_PORT_0_INFO_OFF             22     // bit(7) - valid, bits (0:6) - port number
#define MSG_CAUI_PORT_1_INFO_OFF             23     // bit(7) - valid, bits (0:6) - port number

#define     MSG_CONTROL_PROT_DEST_STR_BIT    2     // 1 bit, indicates that lookup was done in SYN_PROT_DEST_STR table (STR29)

// Message Fields Offsets
//#define MSG_HASH_2B_CORE_OFF                 1   //size 2, traffic distribution 2 bytes hash calculated by topresolve

//#define MSG_OUTP_OFF                         3    no need anymore
#define  MSG_CTRL_TOPPRS_3_OFF               3

//byte 4 - 3 bit for external l4 type rtc usage only (mb reused if rtpc disable)
#define EXTERNAL_HEADER_TYPE_RTPC            4

#define MSG_VIF_OFF                          5    //size 1, virtual interface for network bypass
#define MSG_TCP_SPORT_OFF                    6    //size 2

// NP4 HW Message bytes 8-15 (must remain in this offset)
#define MSG_CONTROL_HW_MSG_FR_PTR_OFF        8    //size 2, frame pointer
#define MSG_CONTROL_HW_MSG_FR_LEN_OFF        10   //size 2, frame length
#define MSG_CONTROL_HW_MSG_TIMESTAMP_OFF     12   //size 1, rx timestamp
#define MSG_CONTROL_HW_MSG_SRC_PORT_OFF      13   //size 1, rx source port
#define MSG_CONTROL_HW_MSG_CTX_LOAD_OFF      14   //size 2, context memory load data
#define MSG_POLICY_ID_OFF                    16   //size 2, policy id (0-103) to be used for Host metadata addition in TOPmodify
#define MSG_POLICY_VALIDATION_BITS_OFF       18   //size 1

// For Control Frames only
#define MSG_CONTROL_SEQUENCE_NUM             19   //size 4, unique offsets For Control Frames
#define MSG_CONTROL_NUM_OF_COMMANDS          23   //size 1, unique offsets For Control Frames

// For Control Frames or from CPU packets

#define MSG_INSTANCE_OFF                     19    //size 1, get instance


#define MSG_L4_VALIDATION_BITS_OFF           19   //size 1, validation bit for BDOS Signature controller

#define MSG_SRC_PORT_OFF                     20   //size 1, source port recived from internal vlan... GuyE: can it be replaced with HW_MSG equivalent field??? ##AMIT_GUY: AmitA: Not sure that you are correct: currently this DOS NOT hold the source port - it holds the result of port from the VIF lookup in TOPparse. if the meaning is to keep the actual source port, then this field should be deleted and instead use the HW_MSG. see all locations in the frame that uses MSG_SRC_PORT_OFF

#define MSG_IP_TTL_OFF                       21   //size 1, needed for RST validation in SYN Protection
#define MSG_SYN_COOKIE_VERIF_OFF             22   //size 1, for ACK - holds '0xFF' if cookie is verified, '0' otherwise
#define MSG_SYN_COOKIE_OFF                   23   //size 4, for SYN - this holds the cookie, for SYN-ACK - holds '0xFF' if cookie is verified, '0' otherwise
#define MSG_RST_COOKIE_OFF                   27   //size 3, for RST - this holds the cookie, '0' otherwise
#define     MSG_RST_COOKIE_PLUS_2_OFF        29   //size 1, internal offset within MSG_RST_COOKIE_OFF, needed for HighLearn in TOPresolve


// The following 2 bytes (MSG_CTRL_TOPPRS_0_OFF/MSG_CTRL_TOPRSV_0_OFF, and MSG_CTRL_TOPPRS_1_OFF) must remain adjacent since they are read and written together
#define MSG_CTRL_TOPPRS_0_OFF     30               //size 1, 1st byte of control bits in message from TOPparse to TOPresolve
#define     MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT         0 //1 bit, indicates whether to perform policy analyzing or not
#define     MSG_CTRL_TOPPRS_0_PERFORM_SYN_PROT_BIT       1 //1 bit, perform SYN Protection handling in TOPresolve
#define     MSG_CTRL_TOPPRS_0_ALST_EMPTY_BIT             2
#define     MSG_CTRL_TOPPRS_0_GLOB_DESC_BIT              3 //1 bit, indicates that packet desicion invicted by global mode configuration
#define     MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT           4 //1 bit, Jumbo packet detected and configuration indicates it needs to be handeled (IC_CNTRL_0_MREG.bit[IC_CNTRL_0_JUMBOMODE_OFF] == 1)
// TCP OOS Type bits, these 3 bits must remain together:
#define     MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT        5
#define     MSG_CTRL_TOPPRS_0_TCP_OOS_FIN_RST_BIT        6
#define     MSG_CTRL_TOPPRS_0_TCP_OOS_ACK_BIT            7

#define     LACP_FROM_SW   MSG_CTRL_TOPPRS_0_ALST_EMPTY_BIT

#define MSG_CTRL_TOPRSV_0_OFF     30               //size 1, control bits in message from TOPresolve to TOPmodify
// The following 3 bits must remain together for the Packet Trace feature:
#define     MSG_CTRL_TOPRSV_0_TP_COPY_PRT_BIT            0 //1 bit, discard vlan to port conversion and send to TP port only
#define     MSG_CTRL_TOPRSV_0_TP_COPY_BYPASS_PRT_BIT     1 //1 bit, follow port group result
#define     MSG_CTRL_TOPRSV_0_TP_EN_BIT                  2 //1 bit, follow TP logic, 0 - ignore all
#define     MSG_CTRL_TOPRSV_0_CPU_PORT_BIT               3 //1 bit, selection of CPU port per instance ('0' - port 0, '1' - port 1)
#define     MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS        4 //2 bits: 00 = SYN-ACK (T.Proxy case), 01 = ACK (Safe Reset case), 10 = RST (TCP Reset case)
#define     MSG_CTRL_TOPRSV_0_ALIST_SAMPL_BIT            6 //1 bit, access list sampling indication for TopModify, this bit triggers dest mac overwrite
#define     MSG_CTRL_TOPRSV_0_RTM_GLOB_BYPASS_BIT        7 //1 bit, indicate that GS_TMD_EX_TRN should be incremented in TopModify

// byCtrlMsgPrs1 bitmap
// This location in message is shared with MSG_CTRL_TOPRSV_1_OFF
#define MSG_CTRL_TOPPRS_1_OFF     31               //size 1, 2nd byte of control bits in message from TOPparse to TOPresolve
// The following 4 bits must remain together
#define     MSG_CTRL_TOPPRS_1_L3_TUNNEL_EXISTS_BIT       0 //1 bit, '1' packet with L3 tunnel
#define     MSG_CTRL_TOPPRS_1_ROUTING_EN_BIT             1 //1 bit, '1' Routing mode, '0' Transparent mode
// The following 2 bits must remain together
#define     MSG_CTRL_TOPPRS_1_IS_IPV4_BIT                2 //1 bit, set when IPv4
#define     MSG_CTRL_TOPPRS_1_IS_IPV6_BIT                3 //1 bit, set when IPv6
#define     MSG_CTRL_TOPPRS_1_USER_VLAN_IN_FRAME_BIT     4 //1 bit, set when user vlan exist in the rxed frame, i.e. more then 1 VLAN in the frame. passed from TOPparse but used in TOPmodify.
#define     MSG_CTRL_TOPPRS_1_RT_EN_BIT                  5 //1 bit, calculate RT in top resolve
#define     MSG_CTRL_TOPPRS_1_SYN_BITS                   6 //2 bits, 00b - packet type SYN, 01b - packet type RST, 10b - packet type ACK, 11b - packet type ACK+Payload

#define     MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT          6 //1 bit, only relevant if MSG_CTRL_TOPPRS_1_SYN_BITS == 1x (ACK packet)
#define     MSG_CTRL_TOPPRS_1_ACK_BIT                    7 //1 bit, set when packet type is ACK

// This location in message is shared with MSG_CTRL_TOPPRS_1_OFF
#define MSG_CTRL_TOPRSV_1_OFF     31               //size 1, 2nd byte of control bits in message from TOPresolve to TOPmodify
// The following 4 bits must remain together
#define     MSG_CTRL_TOPRSV_1_L3_TUNNEL_EXISTS_BIT       0 //1 bit, '1' packet with L3 tunnel
#define     MSG_CTRL_TOPRSV_1_ROUTING_EN_BIT             1 //1 bit, '1' Routing mode, '0' Transparent mode
// The following 2 bits must remain together
#define     MSG_CTRL_TOPRSV_1_IS_IPV4_BIT                2 //1 bit, set when IPv4
#define     MSG_CTRL_TOPRSV_1_IS_IPV6_BIT                3 //1 bit, set when IPv6
#define     MSG_CTRL_TOPRSV_1_USER_VLAN_IN_FRAME_BIT     4 //1 bit, set when user vlan exist in the rxed frame, i.e. more then 1 VLAN in the frame. passed from TOPparse but used in TOPmodify.

// The following 3 bits must remain together
/* --before merge
#define     MSG_CTRL_TOPRSV_1_HAS_RX_COPY_BIT            5 //1 bit, indicates whether to perform RX copy port or not
#define     MSG_CTRL_TOPRSV_1_DELAY_DROP_BIT             6 //1 bit, indicates that frame needs to be dropped
#define     MSG_CTRL_TOPRSV_1_INTERLINK_PACKET_BIT       7 //1 bit, indicates a packet from peer NP device
*/

// byCtrlMsgPrs2 bitmap
#define MSG_CTRL_TOPPRS_2_OFF     32               //size 1, 3rd byte of control bits in message from TOPparse to TOPresolve

// The following 4 bits must remain together
#define     MSG_CTRL_TOPPRS_2_HAS_RX_COPY_BIT            0 //1 bit, indicates whether to perform RX copy port or not
#define     MSG_CTRL_TOPPRS_2_DELAY_DROP_BIT             1 //1 bit, indicates that frame needs to be dropped
#define     MSG_CTRL_TOPPRS_2_INTERLINK_PACKET_BIT       2 //1 bit, indicates that the packet source in the 2nd NP.
#define     MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT           3 //1 bit, indicates that packet source is a CAUI port.

#define     MSG_CTRL_TOPPRS_2_SLT_VLAN_BIT               4 //1 bit, indicates whether to skip security or not
#define     MSG_CTRL_TOPPRS_2_IS_GRE_DECAP_REQUIRED_BIT  5 // Should be set when radwareGREtunnel exist with IPV4.DIP=IP_TO_ME.
#define     MSG_CTRL_TOPPRS_2_PA_SAMPL_BIT               6 //1 bit, if the packet was sampled during PA, bit is set.
#define     MSG_CTRL_TOPPRS_LACP_TYPE_BIT                7 //1 bit, indicate packet LACP type from Host

#define MSG_CTRL_TOPRSV_2_OFF     32               //size 1, 3rd byte of control bits in message from TOPresolve to TOPmodify

// The following 4 bits must remain together
#define     MSG_CTRL_TOPRSV_2_HAS_RX_COPY_BIT            0 //1 bit, indicates whether to perform RX copy port or not
#define     MSG_CTRL_TOPRSV_2_DELAY_DROP_BIT             1 //1 bit, indicates that frame needs to be dropped
#define     MSG_CTRL_TOPRSV_2_INTERLINK_PACKET_BIT       2 //1 bit, indicates a packet from peer NP device
#define     MSG_CTRL_TOPRSV_2_IS_CAUI_PORT_BIT           3 //1 bit, indicates that packet source is a CAUI port.




#define MSG_ACTION_ENC_OFF                   33   //size 1, encoding for Top parse what really to do with frame
#define MSG_L3_TUN_OFF                       34   //size 2, L3 offset of tunnel, in case a tunnel exist. (in case it exist, this will be the outer L3 offset).
#define MSG_L3_USR_OFF                       36   //size 2, L3 offset (Outer L3 offset, or inner L3 when tunnel exists). Keep together with MSG_L4_USR_OFF.

#define MSG_SPEC_SUB_ACTION                  36   //size 2, L3 offset of tunnel, in case a tunnel exist. (in case it exist, this will be the outer L3 offset).

#define MSG_L4_USR_OFF                       38   //size 2, L4 offset (inner label when tunnel exists).                  Keep together with MSG_L3_USR_OFF.
#define MSG_GRE_USR_OFF                      40   //size 2, GRE user offset
#define MSG_SRC_PRT_OFF                      42   //size 1, source port offset for RT Top resolve
#define MSG_HASH_CORE_OFF                    43   //size 1, traffic distribution hash calculated by topresolve

// Used in message between TOPparse to TOPresolve only:
#define MSG_RST_LEARN_KEY                    44   //size 16, DST IP (ipv6 format ) + DST port, needed in message between TOPparse to TOPresolve only!
#define MSG_GLOB_CONFIG_OFF                  60   //size 1, Global configuration
//#define MSG_CAUI_LAG_HASH_OFF                61   //size 1

//#define MSG_HASH_2B_CORE_OFF                 44   //size 2, traffic distribution 2 bytes hash calculated by topresolve
// Bytes 62..63 free

// The following bits compose MSG_GLOB_CONFIG_OFF
#define     MSG_GLOB_CONFIG_DROP_BIT         1 //1 bit, '1' for drop
#define     MSG_GLOB_CONFIG_ROUTING          4 //1 bit, '1' for routing mode
#define     MSG_GLOB_CONFIG_GRE_KEEPALIVE    5 //1 bit, '1' for GRE keepalive (request/reply)

// The following bit are in MSG_GLOB_CONFIG_OFF but belong to PA TP
#define     MSG_PA_TP_ACTION                 6 //1 bit, '0' for DROP (with trace), '1' for BYPASS (with trace)

// Used in message between TOPresolve to TOPmodify only:
#define MSG_ALIST_STAMP_INFO_TOP_MODIFY      44   //size 4, access list index from sampling action, from TResolve 2 TModify + 2 byte of mark
#define MSG_ALIST_SAMPL_INFO_TOP_MODIFY      48   //size 2, highest 2 byte of radware special indication mark

//shared with previous field . Dedicated only for packets comming from HOST to Network
// will be used for search in Table 6 ( Tx copy to implement egress pass switch function )
#define MSG_SWITCH_VLAN_FROM_HOST            48

//for top resolve only
#define MSG_NP5_INTERFACE_PORT_NUM_OFF       13 // HWD_REG1 from hw_msg
#define MSG_NP5_PPORT_NUM_OFF                62 // size 1 for NP5 fistly mac link should be selected this selection based on input port and choosed action
#define MSG_CORE_NUM_OFF                     63 // size 1, core distribution calculated by topresolve

//Used in message between TOPresolve to TOPModify only
#define MSG_METADATA_ETH_TYPE_VAL            52   //size 2 bytes
#define MSG_METADATA_RTPC_VAL                54   //size 1 bytes
#define MSG_METADATA_RTPC_FILTER_BITS_OFF  0   //size 5 bits
#define MSG_METADATA_RTPC_ENABLE_BIT_OFF   7   //size 1 bit

// Bytes 61..63 free
// Message Fields Offsets
#define MSG_HASH_2B_CORE_OFF                 1   //size 2, traffic distribution 2 

#define MSG_SIZE        64
#define HW_GEN_MSG_STR      MSG_STR // HW message structure number (first 16 bytes of MSG_STR, common for TOPparse, TOPresolve & TOPmodify)

#define KMEM_RSV2SRH2_MSG_OFF                 0
#define KMEM_RSV2SRH2_FFT_KEY_OFF             (KMEM_RSV2SRH2_MSG_OFF + MSG_SIZE)
#define KMEM_RSV2SRH2_ROUTING_TABLE_KEY_OFF   (KMEM_RSV2SRH2_FFT_KEY_OFF + 16)   // FFT key size was 1, this have to be rounded up to multiple of 16.
#define KMEM_RSV2SRH2_RX_COPY_PORT_KEY_OFF    (KMEM_RSV2SRH2_ROUTING_TABLE_KEY_OFF + 32)


/////////////////////////////////////////////////////////////////////
// Structure 1 - Control message arriving from the host (for OOS feature only)
/////////////////////////////////////////////////////////////////////
#define CTRL_MSG_STR    1

#define CTRL_MSG_SIZE   64


// Structures

/////////////////////////////////////////////////////////////////////
// Structure 2 - BDOS Attack: Signature Summary L2/3
/////////////////////////////////////////////////////////////////////
#define BDOS_ATTACK_RESULTS_L23_STR      2

// The following determines the location of each field in the result To TOPresolve
// This needs to be consistent with BC_S0G0S0_SEL format with offset of '2'

#define     SIP_RES_OFF                       2  //IPv4
#define     IPV6_SIP_RES_OFF                  2
#define     DIP_RES_OFF                       6  //IPv4
#define     IPV6_DIP_RES_OFF                  6
#define     TOS_RES_OFF                       10 //IPv4
#define     IPV6_TRAFFIC_CLASS_RES_OFF        10
#define     IPID_RES_OFF                      14 //IPv4
#define     IPV6_FRGID_RES_OFF                14
#define     TTL_RES_OFF                       18 //IPv4
#define     IPV6_HOP_LIMIT_RES_OFF            18
#define     FRGFLG_RES_OFF                    22 //IPv4
#define     IPV6_FRGFLG_RES_OFF               22

            // Selector offsets definitions
#define     SIP_SEL_OFF                       0  //IPv4
#define     IPV6_SIP_SEL_OFF                  0
#define     DIP_SEL_OFF                       1  //IPv4
#define     IPV6_DIP_SEL_OFF                  1
#define     TOS_SEL_OFF                       2  //IPv4
#define     IPV6_TRAFFIC_CLASS_SEL_OFF        2
#define     IPID_SEL_OFF                      3  //IPv4
#define     IPV6_FRGID_SEL_OFF                3
#define     TTL_SEL_OFF                       4  //IPv4
#define     IPV6_HOP_LIMIT_SEL_OFF            4
#define     FRGFLG_SEL_OFF                    5  //IPv4
#define     IPV6_FRGFLG_SEL_OFF               5


/////////////////////////////////////////////////////////////////////
// Structure 3 - BDOS Attack: Signature Summary L2/3 - continue
/////////////////////////////////////////////////////////////////////
#define BDOS_ATTACK_RESULTS_L23_2_STR    3

// The following determines the location of each field in the result To TOPresolve
// This needs to be consistent with BC_S0G0S0_SEL format with offset of '2'

#define     FRGOFF_RES_OFF                    2  //IPv4
#define     IPV6_FRGOFF_RES_OFF               2
#define     L4_PROT_RES_OFF                   6  //IPv4
#define     IPV6_FLOW_LABEL_RES_OFF           6
#define     IPV4_L3_LENGTH_RES_OFF            10 //IPv4
#define     IPV6_L3_LENGTH_RES_OFF            10
            // Signature controller search offset
#define     SIGNA_CNTRL_RES_OFF               14

            // Selector offsets definitions
#define     FRGOFF_SEL_OFF                    6  //IPv4
#define     IPV6_FRGOFF_SEL_OFF               6
#define     L4_PROT_SEL_OFF                   7  //IPv4
#define     IPV6_FLOW_LABEL_SEL_OFF           7
#define     IPV4_L3_LENGTH_SEL_OFF            8  //IPv4
#define     IPV6_L3_LENGTH_SEL_OFF            8



/////////////////////////////////////////////////////////////////////
// Structure 4 - BDOS Attack: Signature Summary L4
/////////////////////////////////////////////////////////////////////

#define BDOS_ATTACK_RESULTS_L4_STR       4
            // Result offsets
#define     TCP_SPORT_RES_OFF                 2
#define     UDP_SPORT_RES_OFF                 2
#define     ICMP_TYPE_RES_OFF                 2
#define     IGMP_TYPE_RES_OFF                 2

#define     TCP_DPORT_RES_OFF                 6
#define     UDP_DPORT_RES_OFF                 6
#define     ICMP_CHKSUM_RES_OFF               6
#define     IGMP_CHKSUM_RES_OFF               6

#define     TCP_SEQNUM_RES_OFF                10
#define     UDP_CHKSUM_RES_OFF                10

#define     TCP_FLAGS_RES_OFF                 14
#define     TCP_CHKSUM_RES_OFF                18
            // Two fields L2
#define     PACKET_SIZE_RES_OFF               22
#define     L2_VLAN_RES_OFF                   26

            // Selector offsets definitions
#define     TCP_SPORT_SEL_OFF                 9
#define     UDP_SPORT_SEL_OFF                 9
#define     ICMP_TYPE_SEL_OFF                 9
#define     IGMP_TYPE_SEL_OFF                 9

#define     TCP_DPORT_SEL_OFF                 10
#define     UDP_DPORT_SEL_OFF                 10
#define     ICMP_CHKSUM_SEL_OFF               10
#define     IGMP_CHKSUM_SEL_OFF               10

#define     TCP_SEQNUM_SEL_OFF                11
#define     UDP_CHKSUM_SEL_OFF                11

#define     TCP_FLAGS_SEL_OFF                 12
#define     TCP_CHKSUM_SEL_OFF                13
            // Two fields L2
#define     PACKET_SIZE_SEL_OFF               14
#define     L2_VLAN_SEL_OFF                   15

#define     L7_DNS_REC_TYPE_SEL_OFF           16
#define     L7_DNS_OTHER_REC_TYPE_SEL_OFF     17
#define     L7_DNS_RESP_CODE_SEL_OFF		  18
#define     L7_DNS_TRANSACTION_ID_SEL_OFF	  19
#define     L7_DNS_QUERIES_COUNT_SEL_OFF	  20
#define     L7_DNS_ANSWERS_COUNT_SEL_OFF	  21
#define     L7_DNS_FLAGS_SEL_OFF		      22
#define     L7_DNS_MANUAL_QN_SEL_OFF		  23
#define     L7_DNS_BEHAVIOR_QN_SEL_OFF		  24
#define     L7_DNS_BEHAVIOR_DOMAIN_SEL_OFF	  25
#define     L7_DNS_BEHAVIOR_WL_SEL_OFF		  26
//----------      Below comment seems irrelevant !!!!!
//not that bits 26-31 are used as flags. see "BDOS configuration counter flags" below
//if more fields are required, move the flags to high 32bit of configuration counter

// BDOS result, applies both to
// BDOS_ATTACK_RESULTS_L23_STR and BDOS_ATTACK_RESULTS_L23_2_STR and BDOS_ATTACK_RESULTS_L4_STR
#define BDOS_ATTACK_RESULT_SIZE      32



/////////////////////////////////////////////////////////////////////
// Structure 80 - RX copy port Result
/////////////////////////////////////////////////////////////////////
#define RX_COPY_PORT_STR            5

#define RX_COPY_PORT_KEY_SIZE       1   // Key is physical port ID (5 bits)
#define RX_COPY_PORT_RES_SIZE       8

/////////////////////////////////////////////////////////////////////
// Structure 81 - TX copy port Result
/////////////////////////////////////////////////////////////////////
#define TX_COPY_PORT_STR            6

#define TX_COPY_PORT_KEY_SIZE       2   // Key is VLAN Id (12 bits)
#define TX_COPY_PORT_RES_SIZE       8

// The following bit offsets are relevant for each of the RX/TX copy port structures
#define COPY_PORT_MATCH_OFF               0  // match bit, size: 1 bit
#define COPY_PORT_CAUI_BITMAP_OFF         1  // bitmap of 100G ports, size: 4 bits
#define COPY_PORT_VALID_SWITCH_OFF        5  // network switch valid bit, size: 1 bit
#define COPY_PORT_TRUNK_VALID_OFF         6  // valid bit for each of the 2 possible trunks, size: 2 bits
#define COPY_PORT_SWITCH_VLAN_OFF         8  // switch VLAN, size: 12 bits
#define COPY_PORT_TRUNK_0_OFF             24 // first trunk bitmap, size: 4 bit
#define COPY_PORT_TRUNK_1_OFF             28 // second trunk bitmap, size: 4 bit

/////////////////////////////////////////////////////////////////////
// Structure 5 - BDOS Attack: Signature Summary L4_2
/////////////////////////////////////////////////////////////////////

#define BDOS_ATTACK_RESULTS_L4_2_STR       80

            // Two fields DNS
#define     L7_DNS_REC_TYPE_RES_OFF         2
#define     L7_DNS_RESP_CODE_RES_OFF        6
#define     L7_DNS_TRANSACTION_ID_RES_OFF   10
#define     L7_DNS_QUERIES_COUNT_RES_OFF    14
#define     L7_DNS_ANSWERS_COUNT_RES_OFF    18
#define     L7_DNS_FLAGS_RES_OFF            22

/////////////////////////////////////////////////////////////////////
// Structure xxxxx - BDOS Attack: Signature Summary Query Name
/////////////////////////////////////////////////////////////////////
#define BDOS_ATTACK_RESULTS_QN_STR       81

#define L7_DNS_MANUAL_QN_RES_OFF         2
#define L7_DNS_BEHAVIOR_QN_RES_OFF		  6
#define L7_DNS_BEHAVIOR_DOMAIN_RES_OFF	  10
#define L7_DNS_BEHAVIOR_WL_RES_OFF		  14

// Policy Structure:

/////////////////////////////////////////////////////////////////////
// Structure 8 - Policy Result
/////////////////////////////////////////////////////////////////////
#define POLICY_RES_STR              8

#define POLICY_RES_KEY_SIZE         3  // Key is the result of Ext.TCAM lookup
#define POLICY_RES_RES_SIZE         8


/////////////////////////////////////////////////////////////////////
// Structure 9 - Policy configuration Result
/////////////////////////////////////////////////////////////////////
#define POLICY_RES_CONF_STR             9

#define POLICY_RES_KEY_CONF_SIZE        2  // Key is the result of policy result lookup
#define POLICY_RES_RES_CONF_SIZE        32

#define POLICY_RES_CONF_STR_P0          POLICY_RES_CONF_STR
#define POLICY_RES_CONF_STR_P1          (POLICY_RES_CONF_STR + 32)

/////////////////////////////////////////////////////////////////////
// Structure 10 - Policy signatures hw ids configuration Result
/////////////////////////////////////////////////////////////////////
#define POLICY_RES_SIG_CONF_STR         10

#define POLICY_RES_KEY_SIG_CONF_SIZE    2  // Key is the result of policy result lookup
#define POLICY_RES_RES_SIG_CONF_SIZE    64 // represents array of 31 signatures hw ids

#define POL_RES_SIG_HW_ID_OFF           2  // size 2 bytes, represent signature 1 hw id

// Attack Structures:

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: Packet Common Values Signature Mapping
/////////////////////////////////////////////////////////////////////
#define PACKET_SIZE_STR             14
#define L3_LENGTH_STR               14
#define L2_VLAN_STR                 14
            // Result offsets
#define     PACKET_SIZE_RES_POS               3
#define     L3_LENGTH_RES_POS                 3
#define     L2_VLAN_RES_POS                   3
#define     L7_DNS_REC_TYPE_RES_POS			  3

            // Validation bits
#ifndef DNS_DROP1
#else
#define     PACKET_SIZE_VALIDATION_BIT        5  //PACKET_SIZE_STR  after TCPFLGS_VALIDATION_BIT
#define     L3_LENGTH_VALIDATION_BIT          15  //L3_LENGTH_STR
#define     L2_VLAN_VALIDATION_BIT            6  //L2_VLAN_STR
#endif
            // Field types
#define     PACKET_SIZE_FLD_TYP               0
#define     L3_LENGTH_FLD_TYP                 1
#define     IPV6_L3_LENGTH_FLD_TYP            2
#define     L2_VLAN_FLD_TYP                   3

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: IP Address Signature Mapping
/////////////////////////////////////////////////////////////////////
#define SIP_STR                     14   // For IPV4 lookup
#define DIP_STR                     14   // For IPV4 lookup
#define IPV6_SIP_STR                14   // For IPV6 lookup
#define IPV6_DIP_STR                14   // For IPV6 lookup
            // Result offsets
#define     SIP_RES_POS                       3
#define     DIP_RES_POS                       3
#define     IPV6_SIP_RES_POS                  3
#define     IPV6_DIP_RES_POS                  3
            // Validation bits
#define     SIP_VALIDATION_BIT                0  //SIP_STR
#define     DIP_VALIDATION_BIT                1  //DIP_STR
#define     IPV6_SIP_VALIDATION_BIT           0  //IPV6_SIP_STR
#define     IPV6_DIP_VALIDATION_BIT           1  //IPV6_DIP_STR
            // Field types
#define     SIP_FLD_TYP                       4
#define     DIP_FLD_TYP                       5
#define     IPV6_SIP_FLD_TYP                  6
#define     IPV6_DIP_FLD_TYP                  7

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: IP Header Fields Signature Mapping 1
/////////////////////////////////////////////////////////////////////
#define ICMP_TYPE_STR               14   // For ICMP lookup
#define IGMP_TYPE_STR               14   // For IGMP lookup
#define TOS_STR                     14   // For IPV4 lookup
#define IPV6_HOP_LIMIT_STR          14   // For IPV6 lookup
#define IPV6_TRAFFIC_CLASS_STR      14   // For IPV6 lookup
#define TCPFLGS_STR                 14   // For TCP  lookup
#define TTL_STR                     14   // For IPV4 lookup
#define L4PROT_STR                  14   // For IPV4 lookup
            // Result offsets
#define     TOS_RES_POS                       3
#define     TTL_RES_POS                       3
#define     L4PROT_RES_POS                    3
#define     TCPFLGS_RES_POS                   3
#define     IPV6_HOP_LIMIT_RES_POS            3
#define     IPV6_TRAFFIC_CLASS_RES_POS        3
#define     ICMP_TYPE_RES_POS                 3
#define     IGMP_TYPE_RES_POS                 3
            // Validation bits
#define     ICMP_TYPE_VALIDATION_BIT          		1  //ICMP_TYPE_STR
#define     IGMP_TYPE_VALIDATION_BIT          		1  //IGMP_TYPE_STR
#define     TOS_VALIDATION_BIT                		2  //TOS_STR
#define     IPV6_HOP_LIMIT_VALIDATION_BIT     		4  //IPV6_HOP_LIMIT_STR
#define     IPV6_TRAFFIC_CLASS_VALIDATION_BIT 		2  //IPV6_TRAFFIC_CLASS_STR
#define     TCPFLGS_VALIDATION_BIT            		4  //TCPFLGS_STR
#define     TTL_VALIDATION_BIT                		4  //TTL_STR
#define     L4PROT_VALIDATION_BIT             		14  //L4PROT_STR
//#define     L7_DNS_REC_TYPE_VALIDATION_BIT    		7
#ifndef DNS_DROP1
#define     L7_DNS_RESP_CODE_VALIDATION_BIT   		7
#define     L7_DNS_MANUAL_QN_VALIDATION_BIT   		7
#define     L7_DNS_BEHAVIOR_QN_VALIDATION_BIT   	7
#define     L7_DNS_BEHAVIOR_DOMAIN_VALIDATION_BIT   7
#define     L7_DNS_BEHAVIOR_WL_VALIDATION_BIT   	7
#else
#define     L7_DNS_RESP_CODE_VALIDATION_BIT   		 9
#define     L7_DNS_TRANSACTION_ID_VALIDATION_BIT    10
#define     L7_DNS_QUERIES_COUNT_VALIDATION_BIT     11
#define     L7_DNS_ANSWERS_COUNT_VALIDATION_BIT     12
#define     L7_DNS_FLAGS_VALIDATION_BIT             13
#define     L7_DNS_REC_TYPE_VALIDATION_BIT    		14

#define     L7_DNS_MANUAL_QN_VALIDATION_BIT   		4
#define     L7_DNS_BEHAVIOR_QN_VALIDATION_BIT   	1
#define     L7_DNS_BEHAVIOR_DOMAIN_VALIDATION_BIT  3
#define     L7_DNS_BEHAVIOR_WL_VALIDATION_BIT   	2
#endif

#define     DNS_MANUAL_TYPE (1<<L7_DNS_MANUAL_QN_VALIDATION_BIT)
#define     DNS_BEH_QN_TYPE (1<<L7_DNS_BEHAVIOR_QN_VALIDATION_BIT)
#define     DNS_BEH_DOMAIN_TYPE (1<< L7_DNS_BEHAVIOR_DOMAIN_VALIDATION_BIT )
#define     DNS_BEH_WL_TYPE     (1<<L7_DNS_BEHAVIOR_WL_VALIDATION_BIT)


            // Field types
#define     TOS_FLD_TYP                       8
#define     TTL_FLD_TYP                       9
#define     L4PROT_FLD_TYP                    10
#define     TCPFLGS_FLD_TYP                   11
#define     IPV6_HOP_LIMIT_FLD_TYP            12
#define     IPV6_TRAFFIC_CLASS_FLD_TYP        13
#define     ICMP_TYPE_FLD_TYP                 14
#define     IGMP_TYPE_FLD_TYP                 15

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: IP Header Fields Signature Mapping 2
/////////////////////////////////////////////////////////////////////
#define TCPCHKSUM_STR               14   // For TCP lookup
#define UDPCHKSUM_STR               14   // For UDP lookup
#define IPID_STR                    14   // For IPV4 lookup
            // Result offsets
#define     IPID_RES_POS                      3
#define     TCPCHKSUM_RES_POS                 3
#define     UDPCHKSUM_RES_POS                 3
            // Validation bits
#define     TCPCHKSUM_VALIDATION_BIT          2  //TCPCHKSUM_STR
#define     UDPCHKSUM_VALIDATION_BIT          3  //UDPCHKSUM_STR
#define     IPID_VALIDATION_BIT               3  //IPID_STR
            // Field types
#define     IPID_FLD_TYP                      16
#define     TCPCHKSUM_FLD_TYP                 17
#define     UDPCHKSUM_FLD_TYP                 18

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: IP Header Fields Signature Mapping 3
/////////////////////////////////////////////////////////////////////
#define TCPSEQNUM_STR               14   // For TCP lookup
#define IPV6_FRGID_STR              14   // For IPV6 lookup
#define IPV6_FLOW_LABEL_STR         14   // For IPV6 lookup
            // Result offsets
#define     IPV6_FLOW_LABEL_RES_POS           3
#define     IPV6_FRGID_RES_POS                3
#define     TCPSEQNUM_RES_POS                 3
            // Validation bits
#define     TCPSEQNUM_VALIDATION_BIT          3  //TCPSEQNUM_STR
#ifndef DNS_DROP1

#else
#define     IPV6_FRGID_VALIDATION_BIT         3  //IPV6_FRGID_STR
#define     IPV6_FLOW_LABEL_VALIDATION_BIT    14 //IPV6_FLOW_LABEL_STR
#endif
            // Field types
#define     IPV6_FLOW_LABEL_FLD_TYP           19
#define     IPV6_FRGID_FLD_TYP                20
#define     TCPSEQNUM_FLD_TYP                 21

/////////////////////////////////////////////////////////////////////
// Structure 15/47 - BDOS Attack: Controllers table for BDOS MDOS and MDNS
/////////////////////////////////////////////////////////////////////
#define DDOS_CTRL_STR_PHASE0           (15)
#define DDOS_CTRL_STR_PHASE1           (DDOS_CTRL_STR_PHASE0 + 32)


/////////////////////////////////////////////////////////////////////
// Structure 19 - Out of State (OOS)
/////////////////////////////////////////////////////////////////////
#define TCP_OOS_STR                 19
#define     TCP_OOS_RES_CTRL_BITS_OFF        0
               // Control bits & Match Condition bits offsets
#define        TCP_OOS_CTRL_INST_0_BIT          5
#define        TCP_OOS_CTRL_INST_1_BIT          6
            // Result offsets
#define     TCP_OOS_RES_INST_0_CNT_OFF       2
#define     TCP_OOS_RES_INST_1_CNT_OFF       4

#define TCP_OOS_KEY_SIZE             40
#define TCP_OOS_RES_SIZE             16
#define TCP_OOS_LKP_SIZE             48          // padding KMEM for aligned to 16

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: Fragment Flags Signature Mapping
/////////////////////////////////////////////////////////////////////
#define IPV6_FRGFLG_STR             14   // For IPV6 lookup
#define FRGFLG_STR                  14   // For IPV4 lookup
            // Result offsets
#define     FRGFLG_RES_POS                    3
#define     IPV6_FRGFLG_RES_POS               3
            // Validation bits
#define     IPV6_FRGFLG_VALIDATION_BIT        5  //IPV6_FRGFLG_STR
#define     FRGFLG_VALIDATION_BIT             5  //FRGFLG_STR
            // Field types
#define     FRGFLG_FLD_TYP                    22
#define     IPV6_FRGFLG_FLD_TYP               23

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: Fragment Offset Signature Mapping
/////////////////////////////////////////////////////////////////////
#define FRGOFF_STR                  14   // For IPV4 lookup
#define IPV6_FRGOFF_STR             14   // For IPV6 lookup
            // Result offsets
#define     FRGOFF_RES_POS                    3
#define     IPV6_FRGOFF_RES_POS               3
            // Validation bits
#define     IPV6_FRGOFF_VALIDATION_BIT        13  //IPV6_FRGOFF_STR

#ifndef DNS_DROP1

#else
#define     FRGOFF_VALIDATION_BIT         13  //FRGOFF_STR
#endif
            // Field types
#define     FRGOFF_FLD_TYP                    24
#define     IPV6_FRGOFF_FLD_TYP               25

/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: IP Header Fields Signature Mapping 4
/////////////////////////////////////////////////////////////////////
#define TCPSPORT_STR                14   // For TCP lookup
#define TCPDPORT_STR                14   // For TCP lookup
#define UDPSPORT_STR                14   // For UDP lookup
#define UDPDPORT_STR                14   // For UDP lookup
#define ICMP_CHKSUM_STR             14   // For ICMP lookup
#define IGMP_CHKSUM_STR             14   // For IGMP lookup
#define L7_DNS_REC_TYPE_STR      	14   // For DNS lookup
#define L7_DNS_RESP_CODE_STR        14   // For DNS lookup
#define L7_DNS_TRANSACTION_ID_STR   14   // For DNS lookup
#define L7_DNS_QUERIES_COUNT_STR    14   // For DNS lookup
#define L7_DNS_ANSWERS_COUNT_STR    14   // For DNS lookup
#define L7_DNS_FLAGS_STR            14   // For DNS lookup

#define L7_DNS_MANUAL_QN_STR        0    // Place holder For DNS lookup, it's not really in hash table
#define L7_DNS_BEHAVIOR_QN_STR      0    // Place holder For DNS lookup, it's not really in hash table
#define L7_DNS_BEHAVIOR_DOMAIN_STR  0    // Place holder For DNS lookup, it's not really in hash table
#define L7_DNS_BEHAVIOR_WL_STR      0    // Place holder For DNS lookup, it's not really in hash table




		// Result offsets (not used in DP8)
#define     TCPSPORT_RES_POS                  3
#define     TCPDPORT_RES_POS                  3
#define     UDPSPORT_RES_POS                  3
#define     UDPDPORT_RES_POS                  3
#define     ICMP_CHKSUM_RES_POS               3
#define     IGMP_CHKSUM_RES_POS               3
#define     L7_DNS_REC_TYPE_RES_POS			  3
#define     L7_DNS_RESP_CODE_RES_POS          3
#define     L7_DNS_TRANSACTION_ID_RES_POS     3
#define     L7_DNS_QUERIES_COUNT_RES_POS      3
#define     L7_DNS_ANSWERS_COUNT_RES_POS      3
#define     L7_DNS_FLAGS_RES_POS              3
#define     L7_DNS_MANUAL_QN_RES_POS          3
#define     L7_DNS_BEHAVIOR_QN_RES_POS        3
#define     L7_DNS_BEHAVIOR_DOMAIN_RES_POS    3
#define     L7_DNS_BEHAVIOR_WL_RES_POS        3



            // Validation bits
#define     TCPSPORT_VALIDATION_BIT           0  //TCPSPORT_STR
#define     TCPDPORT_VALIDATION_BIT           1  //TCPDPORT_STR
#define     UDPSPORT_VALIDATION_BIT           0  //UDPSPORT_STR
#define     UDPDPORT_VALIDATION_BIT           1  //UDPDPORT_STR
#define     ICMP_CHKSUM_VALIDATION_BIT        2  //ICMP_CHKSUM_STR
#define     IGMP_CHKSUM_VALIDATION_BIT        2  //IGMP_CHKSUM_STR
            // Field types
#define     TCPSPORT_FLD_TYP                  26
#define     TCPDPORT_FLD_TYP                  27
#define     UDPSPORT_FLD_TYP                  28
#define     UDPDPORT_FLD_TYP                  29
#define     ICMP_CHKSUM_FLD_TYP               30
#define     IGMP_CHKSUM_FLD_TYP               31

#define     TCPSPORT_RANGE_VALIDATION_BIT           0
#define     TCPDPORT_RANGE_VALIDATION_BIT           1
#define     UDPSPORT_RANGE_VALIDATION_BIT           0
#define     UDPDPORT_RANGE_VALIDATION_BIT           1

#define     FIELD_RANGE_NOT_SUPPORTED_VALIDATION_BIT           3 //bit not used
/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: DNS fields mapping
/////////////////////////////////////////////////////////////////////
#define SIGNA_DNS_STR               14   // For DNS fields

            // Field types
#define     DNS_REC_TYPE_FLD_TYP              32
#define     DNS_RESP_FLD_TYP                  33
#define     DNS_TRANSACTION_ID_FLD_TYP        34
#define     DNS_QUERIES_COUNT_FLD_TYP         35
#define     DNS_ANSWERS_COUNT_FLD_TYP         36
#define     DNS_FLAGS_FLD_TYP                 37

#define     DNS_MAN_QN_FLD_TYP                38
#define     DNS_BEH_QN_FLD_TYP                39
#define     DNS_BEH_DOMAIN_FLD_TYP            40
#define     DNS_BEH_WL_FLD_TYP                41


/////////////////////////////////////////////////////////////////////
// Structure 14/46 - BDOS Attack: Signature controller field mapping
/////////////////////////////////////////////////////////////////////
#define SIGNA_CNTRL_STR             14   // For Sigature controller lookup
            // Result offsets
#define     SIGNA_CNTRL_RES_POS               3
            // Validation bits
#ifndef DNS_DROP1
#define     SIGNA_CNTRL_VALIDATION_BIT        7  // Unconditional search
#endif

/////////////////////////////////////////////////////////////////////
// Structure 16/48 - FastIP
// Structure 18/50 - FastIP
/////////////////////////////////////////////////////////////////////
#define TF_PORT_FASTIP_P0_STR       16
#define TF_PORT_HASH_P0_STR         18
#define TF_PORT_FASTIP_P1_STR       48
#define TF_PORT_HASH_P1_STR         50

/////////////////////////////////////////////////////////////////////
// Structure 24 - MY_IPS table.
/////////////////////////////////////////////////////////////////////
#define GRE_MY_IPS_TABLE_STR        24

/////////////////////////////////////////////////////////////////////
// Structure 25 - Routing table entries - holds the actual data on how to perform the route.
/////////////////////////////////////////////////////////////////////

#define CTX_ROUTE_OUT_IF                3   // line for sending route result from TOPsearch II to TOPmodify

#define ROUTING_TABLE_STR           25 // to be used for the lookup command
// Use MDF_ROUTING_TABLE_RSLT_STR to access the result in TOPmodify (As the result is written to the CTX, in order to access it, need to use "structure numbr" = CTX_LINE+8).
// See MDF_ROUTING_TABLE_RSLT_STR / ROUTING_TABLE_STR result bitmap under mdf.h: MDF_ROUTING_TABLE_RSLT__*(field names)


/////////////////////////////////////////////////////////////////////
// Structure 27 - AccessList Result Table
/////////////////////////////////////////////////////////////////////
#define ALST_RES_STR                27
            // Result offsets
#define     ALST_RES_ENTRY_TYPE_OFF           2  // Size 1
#define     ALST_RES_ENTRY_ID_OFF             3  // Size 4

#define ALST_KEY_SIZE                3  // Key is the result of Ext.TCAM lookup
#define ALST_RES_SIZE                8

/////////////////////////////////////////////////////////////////////
// Structure 28 - RTPC Result Table
/////////////////////////////////////////////////////////////////////
#define RTPC_RES_STR                28
            // Result offsets
#define RTPC_RES_CTRL_BYTE_OFF   0  // Size 1 byte

//result bits that will be written from the driver
#define RTPC_RES_IS_SRC_PORT_LKP_BIT_OFF   8  // Size 1b   RESERVED
#define RTPC_RES_IS_DST_PORT_LKP_BIT_OFF   9  // Size 1b   RESERVED
#define RTPC_RES_FWD_IP_BIT_OFF            10  // Size 5b, 1b per filter   RESERVED
#define RTPC_RES_BWD_IP_BIT_OFF            15  // Size 5b, 1b per filter   RESERVED
/*#define RTPC_RES_TCP_PROT_OFF              20  // Size 5b, 1b per filter
#define RTPC_RES_UDP_PROT_OFF              25  // Size 5b, 1b per filter
#define RTPC_RES_ICMP_PROT_OFF             30  // Size 5b, 1b per filter
#define RTPC_RES_OTHER_PROT_OFF            35  // Size 5b, 1b per filter
*/
//the results bits in bytes offsests
#define RTPC_RES_TCP_PROT_BYTE_OFF          4
#define RTPC_RES_UDP_PROT_BYTE_OFF          5
#define RTPC_RES_ICMP_PROT_BYTE_OFF         6
#define RTPC_RES_OTHER_PROT_BYTE_OFF        7

//result byte that TopSrh will be written and it will be read by TopRsv
#define RTPC_RES_RESULT_FOR_RESOLVE_OFF    7
//protocols bits


#define RTPC_KEY_SIZE                3  // Key is the result of Ext.TCAM lookup
#define RTPC_RES_SIZE                8

/////////////////////////////////////////////////////////////////////
// Structure 29 - SYN Protection Result
/////////////////////////////////////////////////////////////////////
#define SYN_PROT_DEST_STR           29

// Syn Protection Key (the result index of Internal CAM (STR65) lookup):

// SYN Protection Result:
#define SYN_PROT_CTRL_0_OFF             0  // size 1, includes Valid & Match bits
#define SYN_PROT_CTRL_1_OFF             1  // size 1, not used
#define SYN_PROT_CTRL_2_OFF             2  // size 1
        		// SYN_PROT_CTRL_2_OFF Control bits:
#define     SYN_PROT_CTRL_INST_0_BIT          	  0
#define    	SYN_PROT_CTRL_INST_1_BIT          	  1
#define 		SYN_PROT_CTRL_CONTENDER_MATCH_BIT     2  // Safe Reset Contender table Match bit, taken from SYN_PROT_CONT_STR.byte[SYN_PROT_CONT_CTRL_2_OFF].bit[CONTENDER_MATCH_BIT]

#define 		SYN_PROT_CTRL_CONTENDER_VALIDITY_BIT  3  // Safe Reset Contender table Validity bit, taken from SYN_PROT_CONT_STR.byte[SYN_PROT_CONT_CTRL_2_OFF].bit[CONTENDER_VALIDITY_BIT]
#define 		SYN_PROT_CTRL_TCP_RESET_MODE_BIT      3  // TCP Reset mode bit (Short ACK\Payload ACK)

#define 		SYN_PROT_CTRL_TCP_RESET_ACTIVE_BIT    4  // TCP Reset protection Enabled\Disabled bit
#define 		SYN_PROT_CTRL_AUTH_MATCH_BIT          5  // Authentication table Match bit
#define 		SYN_PROT_CTRL_AUTH_LKP_BIT            6  // Authentication table lookup bit
#define 		SYN_PROT_CTRL_CHALLENGE_BIT           7  // Challenge bit

        // Result offsets
#define SYN_PROT_RES_INST_0_CID_OFF       3 // size 2
#define SYN_PROT_RES_INST_1_CID_OFF       5 // size 2
#define SYN_PROT_RES_TS_OFF               7 // size 2, taken from SYN_PROT_CONT_STR.offset[SYN_PROT_CONT_TS_OFF]
#define SYN_PROT_RES_TTL_OFF              9 // size 1, taken from SYN_PROT_CONT_STR.offset[SYN_PROT_CONT_TTL_OFF]
#define SYN_PROT_RES_F1_OFF              10 // size 4, taken from SYN_PROT_CONT_STR.offset[SYN_PROT_CONT_F1_OFF]

#define SYN_PROT_DEST_KEY_SIZE       3
#define SYN_PROT_DEST_RES_SIZE       16


/////////////////////////////////////////////////////////////////////
// Structure 62 - SYN Protection: Authentication
/////////////////////////////////////////////////////////////////////
#define SYN_PROT_AUT_STR            62
            // Control bits & Match Condition bits offsets

		  // Authentication Result:
#define SYN_PROT_AUT_CTRL_0_OFF         0  // size 1, includes Valid & Match bits
#define SYN_PROT_AUT_CTRL_1_OFF         1  // size 1, not used
#define SYN_PROT_AUT_CTRL_2_OFF         2  // size 1
        		// SYN_PROT_AUT_CTRL_2_OFF Control bits:
#define     SYN_PROT_AUT_CTRL_RSRVD_BIT           5
#define     SYN_PROT_AUT_CTRL_RST_PROT_BIT        6
#define     SYN_PROT_AUT_CTRL_ACK_PROT_BIT        7

#define SYN_PROT_AUT_LKP_SIZE        16
#define SYN_PROT_AUT_RES_SIZE        16
#define SYN_PROT_SEARCH_ENTRY_PROF   1  // search entry profile with aging enable

/////////////////////////////////////////////////////////////////////
// Structure 63 - SYN Protection: Contender
/////////////////////////////////////////////////////////////////////
#define SYN_PROT_CONT_STR            63

		  // Contender Result:
#define SYN_PROT_CONT_CTRL_0_OFF         0  // size 1, includes Valid & Match bits
#define SYN_PROT_CONT_CTRL_1_OFF         1  // size 1, not used
#define SYN_PROT_CONT_CTRL_2_OFF         2  // size 1
        		// SYN_PROT_CONT_CTRL_2_OFF Control bits:
#define 		CONTENDER_MATCH_BIT          2  // Safe Reset Contender table Match bit (equal to SYN_PROT_CTRL_CONTENDER_MATCH_BIT)
#define 		CONTENDER_VALIDITY_BIT       3  // Safe Reset Contender table Validity bit (equal to SYN_PROT_CTRL_CONTENDER_VALIDITY_BIT)

        // Result offsets
#define SYN_PROT_CONT_TS_OFF             4  // size 2
#define SYN_PROT_CONT_TTL_OFF            6  // size 1


#define SYN_PROT_CONT_LKP_SIZE           21
#define SYN_PROT_CONT_RES_SIZE           16

////////////////////////////////////////////////////////////////////
// Structure 61 - Virtual interface to Tx , Rx Vlan
/////////////////////////////////////////////////////////////////////
#define VIF2_TXVLAN_STR             61
#define FFT_VID_KEY_SIZE            1



/////////////////////////////////////////////////////////////////////
// Structure 64 - FFT
/////////////////////////////////////////////////////////////////////
#define FFT_VID_STR                 64
#define FFT_VID_KEY_SIZE            1

/////////////////////////////////////////////////////////////////////
// Structure 66 - Sub Interface indication in port
/////////////////////////////////////////////////////////////////////
#define SUB_INT_STR                 66


/////////////////////////////////////////////////////////////////////
// Structure 67 - Sub Interface vlan structure
/////////////////////////////////////////////////////////////////////
#define SUB_VID_STR                 67

/////////////////////////////////////////////////////////////////////
// Structure 68 - 100g none subinterface structure
/////////////////////////////////////////////////////////////////////
#define SUB_VID_CAUI_STR             68

#define PHYS_INTERFACE              0 // 1 byte size

/////////////////////////////////////////////////////////////////////
// Structure 65 - Internal TCAM (used for SYN Protection lookup)
/////////////////////////////////////////////////////////////////////
#define INT_TCAM_STR                65

// 26bytes Key offsets
#define SYN_PROT_DPORT_OFF                0  // size 2
#define SYN_PROT_VLAN_OFF                 2  // size 2
#define SYN_PROT_DIP_OFF                  4  // size 16
#define SYN_PROT_PORT_OFF                 20 // size 1
#define SYN_PROT_PHASE_OFF                21 // size 1 (for 2 phases use)
#define SYN_PROT_POLID_OFF                22 // size 2 (for polid )
// Bytes[22..25] - free


/////////////////////////////////////////////////////////////////////
// Structure 80 - External TCAM (used for AccessList lookup)
/////////////////////////////////////////////////////////////////////
#define EXT_TCAM_STR                80    //for ALST
#define EXT_TCAM_RTPC_STR           82    //for RTPC

            // AccessList Key offsets
#define     ALST_PROT_SIP_OFF                 0  // 16 bytes
#define     ALST_PROT_DIP_OFF                 16 // 16 bytes
#define     ALST_PHYSPRT_OFF                  32 // 1 byte
#define     ALST_PROT_TYPE_OFF                33 // 1 byte
#define     ALST_VLANID_OFF                   34 // 2 bytes
#define     ALST_L4PORT_OFF                   36 // 4 bytes
#define     ALST_RTPC_EN_BITS_OFF             40 // 1 byte: bit0 ACL, bit1 RTPC  :
#define     ALST_ENABLE_BIT_OFF  0
#define     RTPC_ENABLE_BIT_OFF  4     //for TopSearch usage it should be 0/4

#define CMP_ACL_KMEM_SIZE         48   // 40 bytes padded to the closest multiple of 16 bytes


/////////////////////////////////////////////////////////////////////
// Dummy Structure 81 - used to get the result of the TCAM lookup in TOPresolve, when performing the lookup with destination == CONTEXT (!= TREG, this is the our case).
/////////////////////////////////////////////////////////////////////
#define ROUTING_TABLE_INDEX_STR     81


/////////////////////////////////////////////////////////////////////
// TOPsearch-II Structures
/////////////////////////////////////////////////////////////////////

#define CTX_LINE_OUT_IF                0   // line for sending OUT_PORT result from TOPsearch II to TOPmodify
#define OUT_VID_STR                    (CTX_LINE_OUT_IF + 8)
#define MDF_TX_COPY_INFO_STR           OUT_VID_STR
#define CTX_LINE_OUT_IF_MASK           (1<<CTX_LINE_OUT_IF)

#define CTX_LINE_RX_COPY_INFO          1   // line for sending RX copy information; changed for context buffer 64B
#define MDF_RX_COPY_INFO_STR           (CTX_LINE_RX_COPY_INFO + 8)


#define CTX_LINE_ROUTING_TABLE_RSLT    2   // line for sending routing table result from TOPsearch II to TOPmodify; changed for context buffer 64B
#define MDF_ROUTING_TABLE_RSLT_STR     (CTX_LINE_ROUTING_TABLE_RSLT + 8)
#define TX_VLAN_ROUTING_TBL_OFFSET     0xe

#define PREPARSE_CTX_LINE              3
#define CTX_LINE_CORE2IP_DISTRIBUTION  3   // line for core distribution result
#define MDF_CORE2IP_DISTRIBUTION_STR   (CTX_LINE_CORE2IP_DISTRIBUTION + 8)



// Definition of validation bits
#define VLAN1_SEARCH_VALID_BIT       0
#define SIP_SEARCH_VALID_BIT         1
#define DIP_SEARCH_VALID_BIT         2
#define PORT_SEARCH_VALID_BIT        3


/////////////////////////////////////////////////////////////////////
// Internal/External TCAM Search Table line number definitions
/////////////////////////////////////////////////////////////////////
#define INT_TCAM_LINE_NUM_SYN_PROT       0 // internal TCAM profile of SYN protection
#define EXT_TCAM_LINE_NUM_ALST           1 // external TCAM profile of Access List
#define EXT_TCAM_LINE_NUM_POLICY_PHASE0  2 // external TCAM profile of phase 0 of policy
#define EXT_TCAM_LINE_NUM_POLICY_PHASE1  3 // external TCAM profile of phase 1 of policy
#define EXT_TCAM_LINE_NUM_ROUTING        4 // external TCAM profile of Routing
#define EXT_TCAM_LINE_NUM_RTPC           5 // external TCAM profile of RTPC


/////////////////////////////////////////////////////////////////////
// Definition policy configuration, based on the statistics counters:
// 64 bit counter divided on the 2 parts: low contains 32 BDOS signatures mask
// and high coontains other configuration
/////////////////////////////////////////////////////////////////////
#define POLICY_HW_ID_OFF             2   // defines policy HW id - 2B
#define POLICY_CONTROL_OFF           4   // Policy control 2B

#define   POLICY_CNG_OOS_BIT           0   // represents OOS feature config bit
#define   POLICY_CNG_BDOS_SIG_BIT      1   // represents BDOS feature any signatures config bit
#define   POLICY_RTM_EN_BIT            2   // Enable rtm in policy
#define   POLICY_CNG_ACTION_BIT        3   // 2 bits represent action
#define   POLICY_CNG_MANRULE_ACT_BIT   5   // 2 bits represent manual rule no match default action
// Following OOS definitions
#define   POLICY_CNG_OOS_TP_BIT        7   // OOS packet trace status enable/disable 1 bit

#define   POLICY_CNG_OOS_SYNACK_BIT    8   // OOS SynAck allow status enable/disable 1 bit
#define   POLICY_CNG_OOS_ACK_ACT_BIT   9   // OOS TCP ACK packet SYN cookie is incorrect action 2 bits
#define   POLICY_CNG_OOS_OTHER_ACT_BIT 11  // OOS Other packets not match action 2 bits
#define   POLICY_CNG_OOS_ACTIV_ACT_BIT 13  // OOS activation threshold action 2 bits
#define   POLICY_CNG_OOS_SAMPL_BIT     15  // OOS sampling status enable/disable 1 bit
#define   POLICY_CNG_OOS_ACTIV_BIT     15  // ???OOS activation threshold status enable/disable 1 bit

#define POLICY_USER_ID_OFF           6   // Policy Id user definition 2B and 10 bits is used for metadata

#define POLICY_ALL_NEGETIVE_SIGNATURES 8

#define POLICY_RTPC_FILTERS_BITMAP_OFF 12

//#define POLICY_CNG_MNRL_SIG_OFF      8   // defines offset for manual rules signatures bitmask - 4B
//#define POLICY_CNG_BDOS_SIG_OFF     12   // defines offset for BDOS signatures bitmask - 4B
//#define POLICY_CNG_BDNS_SIG_OFF     16   // defines offset for BDNS signatures bitmask - 4B
#define POLICY_CNG_SIG0_HW_ID_OFF   20   // defines first signature hw id - 2B
#define POLICY_SIG_CONTR_MATCH_OFF  22   // Signature controller match result placeholder - 6B
#define   POLICY_SIG_CONTR_QN_MASK_OFF  27 // Signature controller QN fields mask - 1B
#define POLICY_BLWL_MATCH_OFF       28   // BL/WL match result placeholder - 4B



/////////////////////////////////////////////////////////////////////
//    Compound Key Offsets in KMEM
/////////////////////////////////////////////////////////////////////

// Routing TCAM compound key
#define CMP_ROUTING_DIP_OFF  0  //  Size 16 bytes
   #define CMP_ROUTING_DIP_2ND_OFF       (CMP_ROUTING_DIP_OFF + 4);
   #define CMP_ROUTING_DIP_3RD_OFF       (CMP_ROUTING_DIP_OFF + 8);
   #define CMP_ROUTING_DIP_4TH_OFF       (CMP_ROUTING_DIP_OFF + 12);

#define CMP_ROUTING_KMEM_SIZE    16 // Actual size in KMEM


// Policy compound key

#define CMP_POLICY_SIP_OFF             0   // Size 16 bytes
#define CMP_POLICY_DIP_OFF             16  // Size 16 bytes
#define CMP_POLICY_VLAN_OFF            32  // Size 2 bytes
#define CMP_POLICY_PORT_OFF            34  // Size 1 byte
#define CMP_POLICY_DEFAULT_SET_OFF     35  // Size 1 byte
#define CMP_POLICY_L4_SPRT_SET_OFF     36  // Size 2 bytes
#define CMP_POLICY_L4_DPRT_SET_OFF     38  // Size 2 bytes
#define CMP_POLICY_CNG_PHASE_SET_OFF   40  // Size 4 bytes
#define CMP_POLICY_BDOS_CNG_PHASE_SET_OFF  44  // Size 2 bytes
#define FRAG_L4_MASK                       46  //if packet frag type ( and no ff unset l4 controllers bit from l4 controller ) 2 byte

// bytes 36..37 used for TREG_POLICY_SIP_DB_OFF

#define CMP_POLICY_SIP_SIZE            16
#define CMP_POLICY_DIP_SIZE            16
#define CMP_POLICY_VLAN_SIZE           2
#define CMP_POLICY_PORT_SIZE           1
#define CMP_POLICY_DEFAULT_SET_SIZE    1
#define CMP_POLICY_PHASE_SIZE          1

#define CMP_POLICY_KMEM_SIZE  48 // 38 bytes padded to the closest multiple of 16 bytes
#define BDOS_CNTR_KMEM_SIZE   16 // 16 bytes


// SYN Protection compound key

// Bytes[0..25] taken from INT_TCAM_STR key

#define SYN_PROT_SIP_OFF                 32 // size 16, offset on KMEM, used for compound lookup in structure 62 (SYN_PROT_AUT_STR)
#define SYN_PROT_CONT_SPORT_OFF_KMEM     48 // size 2,  offset on KMEM, used for compound lookup in structure 63 (SYN_PROT_CONT_STR)
#define SYN_PROT_CONT_COOKIE_OFF_KMEM    50 // size 3,  offset on KMEM, used for compound lookup in structure 63 (SYN_PROT_CONT_STR)

#define MAIN_KMEM_SIZE  96 // 53 bytes padded to the closest multiple of 16 bytes


// BDOS compound keys
#define L3_KEY_OFFSET                    0

// L3 fields offsets for IPV4:
//already in 

#define CMP_BDOS_L23_SIP_OFF           UNF_PROT_SIP_OFF  // Size 16 bytes
#define CMP_BDOS_L23_DIP_OFF           UNF_PROT_DIP_OFF  // Size 16 bytes


// L3 fields sizes for IPv6:
//#define CMP_BDOS_L23_IPV6_DIP_SIZE             16
//#define CMP_BDOS_L23_IPV6_SIP_SIZE             16
#define CMP_BDOS_L23_IPV6_HOP_LIMIT_SIZE       1
#define CMP_BDOS_L23_IPV6_TRAFFIC_CLASS_SIZE   1
#define CMP_BDOS_L23_IPV6_FLOW_LABEL_SIZE      4   // Although it is actually 3 (20 bits)
#define CMP_BDOS_L23_IPV6_FRGMNT_SIZE          2
#define CMP_BDOS_L23_IPV6_FRGMNT_FLG_SIZE      1
#define CMP_BDOS_L23_IPV6_FRGMNT_ID_SIZE       4


// L3 Common fields sizes
#define CMP_BDOS_L23_L3_SIZE_SIZE              2
            // signature controller size
#define CMP_BDOS_L23_SIGNA_CNTRL_SIZE          1

//15 bytes ipv4

#define CMP_BDOS_L23_IPV6_KMEM_SIZE      15 /*48*/  // 47 bytes padded to the closest multiple of 16 bytes

//2 -  policy id
#define L4_KEY_OFFSET                          ( 64 )
// L4 fields offsets
#define CMP_BDOS_L4_SRC_PORT_OFF               UNF_PROT_SPORT_OFF_KMEM   // Size 2 bytes
#define CMP_BDOS_L4_DST_PORT_OFF               UNF_PROT_DPORT_OFF   // Size 2 bytes

//#define CMP_BDOS_L7_DNS_FLAGS_OFF              18  // Size 2 bytes
//#define CMP_BDOS_L7_DNS_TRANSACTION_ID_OFF     20  // Size 2 bytes
//#define CMP_BDOS_L7_DNS_ANSWERS_COUNT_OFF      22  // Size 2 bytes
//#define CMP_BDOS_L7_DNS_QUERIES_COUNT_OFF      24  // Size 2 bytes

// L4 fields sizes
#define CMP_BDOS_L4_SRC_PORT_SIZE              2
#define CMP_BDOS_L4_DST_PORT_SIZE              2
#define CMP_BDOS_L4_CHECKSUM_SIZE              2
#define CMP_BDOS_L4_ICMP_TYPE_SIZE             1
#define CMP_BDOS_L4_IGMP_TYPE_SIZE             1
#define CMP_BDOS_L4_TCP_SEQ_NUM_SIZE           4
#define CMP_BDOS_L4_TCP_FLAGS_SIZE             1
//#define BDOS_L7_DNS_4_HEADER_FIELDS_SIZE	 	   CMP_BDOS_L7_DNS_TRANSACTION_ID_SIZE + CMP_BDOS_L7_DNS_QUERIES_COUNT_SIZE + CMP_BDOS_L7_DNS_ANSWERS_COUNT_SIZE + CMP_BDOS_L7_DNS_FLAGS_SIZE    // 8 Bytes

//9 byte extra


// L2 fields sizes
#define CMP_BDOS_L23_VLAN_SIZE                 2
#define CMP_BDOS_L23_PACKET_SIZE_SIZE          2

#define CMP_BDOS_KMEM_SIZE                    96  // 48 L3 BDOS size + 26 bytes +6 bytes L4 padded to the closest multiple of 16 bytes

#define CMP_BDOS_L4_KMEM_SIZE                 32
//#define  CMP_BDOS_L4_SIGNA_CNTRL_OFF           30

//BDOS configuration counter flags (relate to byte 3 of the low configuration counter)
#define BDOS_SIGNA_CONFIG_TB_GREEN_IS_YELLOW 14
#define BDOS_SIGNA_CONFIG_TB_GREEN_IS_RED    15
#define BDOS_SIGNA_CONFIG_PACKET_TRACE       16
#define BDOS_SIGNA_CONFIG_ACTION             17  /*2 bits*/
#define BDOS_SIGNA_CONFIG_NUM_GROUPS         19  /*2 bits*/
#define BDOS_SIGNA_CONFIG_TYPE               21 /* 2 bits */
#define BDOS_SIGNA_UID                       23 /* 4 bits */
#define BDOS_SIGNA_CONFIG_NEGATIVE           27
#define BDOS_SIGNA_CONFIG_BYTE3_NEGATIVE_BIT 3

#define MANUAL_TYPE_OFF                       1 /*bit 0 */

// OOS compound key

#define TCP_OOS_VLAN_OFF                       0   // Size 2 bytes
#define TCP_OOS_SIP_OFF                        4   // Size 16 bytes
#define TCP_OOS_DIP_OFF                        20  // Size 16 bytes
#define TCP_OOS_SPORT_OFF                      36  // Size 2 byte
#define TCP_OOS_DPORT_OFF                      38  // Size 2 byte

#define TCP_OOS_VLAN_SIZE                      4   // Size 4 bytes to alignment
#define TCP_OOS_PORT_SIZE                      2   // Size 2 byte

/////////////////////////////////////////////////////////////////////
//    Local TOPsearch TREG Offsets
/////////////////////////////////////////////////////////////////////

// Policies:

#define TREG_POLICY_SIP_DB_OFF         36  // Size 2 bytes
#define TREG_POLICY_DIP_DB_OFF         37  // Size 1 byte

// Policies and AccessList:


#define TREG_RTPC_RES_OFF              (TREG_TCAM_RESULT_OFF+4) // 52, size 8
#define TREG_RTPC_RES_FOR_RESOLVE_OFF  (TREG_RTPC_RES_OFF+RTPC_RES_RESULT_FOR_RESOLVE_OFF)

#define TREG_RTPC_PROT_SHL_OFF        (TREG_RTPC_RES_OFF+8)

#define TREG_RTPC_RES_TCP_PROT_BYTE_OFF          (TREG_RTPC_RES_OFF+RTPC_RES_TCP_PROT_BYTE_OFF)
#define TREG_RTPC_RES_UDP_PROT_BYTE_OFF          (TREG_RTPC_RES_OFF+RTPC_RES_UDP_PROT_BYTE_OFF)
#define TREG_RTPC_RES_ICMP_PROT_BYTE_OFF         (TREG_RTPC_RES_OFF+RTPC_RES_ICMP_PROT_BYTE_OFF)
#define TREG_RTPC_RES_OTHER_PROT_BYTE_OFF        (TREG_RTPC_RES_OFF+RTPC_RES_OTHER_PROT_BYTE_OFF)




#define TREG_DNS_CONTROL_BYTE_OFF          40
#define TREG_BDOS_CNTR_BYTE_OFF            41

//parameters from Top parse usage
#define TREG_ACL_RTPC_EN_BITS_OFF  ALST_RTPC_EN_BITS_OFF //40

// BDOS:


// Offset in TREG where we write temporary results of lookups in BDOS structures 14-23
#define TREG_TEMP_BDOS_LKP_RES_OFF     {TREG_BDOS_RES_OFF + 32} /*TREG_TEMP_BDOS_KEY_TYP_OFF*/ //(TREG_TEMP_BDOS_KEY_TYP_OFF + TREG_TEMP_BDOS_KEY_TYP_SIZE) // 48 + 16 = 64
#define TREG_TEMP_BDOS_LKP_RES_SIZE    8


// Offset in TREG where we copy results of lookups in BDOS structures 14-23.
// This will then be written to OREG as BDOS_ATTACK_RESULTS_L23_STR or BDOS_ATTACK_RESULTS_L4_STR
#define TREG_BDOS_RES_OFF              128/*96 */

#define TREG_BDOS_RES_SIZE             BDOS_ATTACK_RESULT_SIZE    // 32


// For Ext.TCAM lookaside:
//#define CTX_LINE_TCAM               2
//#define CTX_STR                     63

#define CTX_LINE_EZCH_SYSTEMS_IPV4DIP_LA 0 // changed for context buffer 64B
#define ENC_PRI_SIZE_BITS 16
#define MSG_TM_QUEUE_OFFSET 24

#define TREG_TIMER_COUNTER_OFF      160
#define TREG_TIMER_COUNTER_CALC_OFF 162
#define TREG_TIMER_COUNTER_VALUE    0xFF
#define EQUAL_MASK                  0x2


//#define SAVED_1_CMP_BDOS_L23_L3_SIZE_IPV6_PROT_IP_VER  192
//#define SAVED_2_CMP_BDOS_L23_L3_SIZE_IPV6_PROT_IP_VER  64

/*TREG_TIMER_COUNTER_OFF*/
// Controlers definition:

/* (This is taken from network.h file)
#define TCP_FIN_FLAG_OFF   0
#define TCP_SYN_FLAG_OFF   1
#define TCP_RST_FLAG_OFF   2
#define TCP_PSH_FLAG_OFF   3
#define TCP_ACK_FLAG_OFF   4
#define TCP_URG_FLAG_OFF   5
*/

// Need to duplicate controlers for IPV4 and IPV6



// Defines TCP flags, used for BDOS Controllers and SYN protection features

#define TCP_SYN_FLAGS                  ( 1 << TCP_SYN_FLAG_OFF )

#define TCP_RST_FLAGS                  ( 1 << TCP_RST_FLAG_OFF )

#define TCP_RST_ACK_FLAGS              ( ( 1 << TCP_RST_FLAG_OFF) | (1 << TCP_ACK_FLAG_OFF) )

#define TCP_SYN_RST_ACK_FLAGS          ( ( 1 << TCP_SYN_FLAG_OFF) | (1 << TCP_RST_FLAG_OFF) | (1 << TCP_ACK_FLAG_OFF) )

#define TCP_ACK_FLAGS                  ( 1 << TCP_ACK_FLAG_OFF )

#define TCP_PUSH_FLAGS                  ( 1 << TCP_PSH_FLAG_OFF )

#define TCP_FIN_FLAGS                  ( 1 << TCP_FIN_FLAG_OFF )

#define TCP_ACK_PUSH_FLAGS             ( ( 1 << TCP_ACK_FLAG_OFF) | (1 << TCP_PSH_FLAG_OFF) )
#define TCP_ACK_FIN_FLAGS              ( ( 1 << TCP_ACK_FLAG_OFF) | (1 << TCP_FIN_FLAG_OFF) )
#define TCP_ACK_PUSH_FIN_FLAGS         ( ( 1 << TCP_ACK_FLAG_OFF) | (1 << TCP_PSH_FLAG_OFF) | (1 << TCP_FIN_FLAG_OFF) )
#define TCP_SYN_ACK_FLAGS              ( ( 1 << TCP_SYN_FLAG_OFF) | (1 << TCP_ACK_FLAG_OFF) )


#define UDP_CONTROL                    (  0 << 0 )
#define ICMP_CONTROL                   (  1 << 0 )
#define IGMP_CONTROL                   (  2 << 0 )
#define OTHER_L4_PROTO_CONTROL         (  4 << 0 )
#define TCP_CONTROL                    (  1 << 5 )
#define FRAG_CONTROL                   (  1 << 6 )
#define IPV4_CONTROL                   (  0 << 7 )
#define IPV6_CONTROL                   (  1 << 7 )
#define DNS_QUERY_CONTROL              (  1 << 8 )
#define DNS_RESP_CONTROL               (  1 << 9 )
#define UDP_FRAG_CONTROL               (UDP_CONTROL | FRAG_CONTROL)
#define TCP_FRAG_CONTROL               (TCP_CONTROL | FRAG_CONTROL)

#define TCP_SYN_CONTROL                ( TCP_CONTROL | TCP_SYN_FLAGS )
#define TCP_RST_CONTROL                ( TCP_CONTROL | TCP_RST_FLAGS )
#define TCP_RST_ACK_CONTROL            ( TCP_CONTROL | TCP_RST_ACK_FLAGS )
#define TCP_SYN_RST_ACK_CONTROL        ( TCP_CONTROL | TCP_SYN_RST_ACK_FLAGS )
#define TCP_ACK_CONTROL                ( TCP_CONTROL | TCP_ACK_FLAGS )
#define TCP_ACK_PUSH_CONTROL           ( TCP_CONTROL | TCP_ACK_PUSH_FLAGS )
#define TCP_ACK_FIN_CONTROL            ( TCP_CONTROL | TCP_ACK_FIN_FLAGS )
#define TCP_ACK_PUSH_FIN_CONTROL       ( TCP_CONTROL | TCP_ACK_PUSH_FIN_FLAGS )
#define TCP_SYN_ACK_CONTROL            ( TCP_CONTROL | TCP_SYN_ACK_FLAGS )

#define IPV4_UDP_CONTROL               (IPV4_CONTROL | UDP_CONTROL)
#define IPV4_UDP_FRAG_CONTROL          (IPV4_CONTROL | UDP_CONTROL | FRAG_CONTROL)
#define IPV4_ICMP_CONTROL              (IPV4_CONTROL | ICMP_CONTROL)
#define IPV4_IGMP_CONTROL              (IPV4_CONTROL | IGMP_CONTROL)
#define IPV4_TCP_FRAG_CONTROL          (IPV4_CONTROL | TCP_CONTROL | FRAG_CONTROL)
#define IPV4_TCP_SYN_CONTROL           (IPV4_CONTROL | TCP_SYN_CONTROL)
#define IPV4_TCP_RST_CONTROL           (IPV4_CONTROL | TCP_RST_CONTROL)
#define IPV4_TCP_RST_ACK_CONTROL       (IPV4_CONTROL | TCP_RST_ACK_CONTROL)
#define IPV4_TCP_ACK_CONTROL           (IPV4_CONTROL | TCP_ACK_CONTROL)
#define IPV4_TCP_ACK_PUSH_CONTROL      (IPV4_CONTROL | TCP_ACK_PUSH_CONTROL)
#define IPV4_TCP_ACK_FIN_CONTROL       (IPV4_CONTROL | TCP_ACK_FIN_CONTROL)
#define IPV4_TCP_ACK_PUSH_FIN_CONTROL  (IPV4_CONTROL | TCP_ACK_PUSH_FIN_CONTROL)
#define IPV4_TCP_SYN_ACK_CONTROL       (IPV4_CONTROL | TCP_SYN_ACK_CONTROL)

#define IPV4_OTHER_L4_PROTO_CONTROL    (IPV4_CONTROL | OTHER_L4_PROTO_CONTROL)
#define IPV6_UDP_CONTROL               (IPV6_CONTROL | UDP_CONTROL)
#define IPV6_UDP_FRAG_CONTROL          (IPV6_CONTROL | UDP_CONTROL | FRAG_CONTROL)
#define IPV6_ICMP_CONTROL              (IPV6_CONTROL | ICMP_CONTROL)
#define IPV6_IGMP_CONTROL              (IPV6_CONTROL | IGMP_CONTROL)
#define IPV6_TCP_FRAG_CONTROL          (IPV6_CONTROL | TCP_CONTROL | FRAG_CONTROL)
#define IPV6_TCP_SYN_CONTROL           (IPV6_CONTROL | TCP_SYN_CONTROL)
#define IPV6_TCP_RST_CONTROL           (IPV6_CONTROL | TCP_RST_CONTROL)
#define IPV6_TCP_RST_ACK_CONTROL       (IPV6_CONTROL | TCP_RST_ACK_CONTROL)
#define IPV6_TCP_ACK_CONTROL           (IPV6_CONTROL | TCP_ACK_CONTROL)
#define IPV6_TCP_ACK_PUSH_CONTROL      (IPV6_CONTROL | TCP_ACK_PUSH_CONTROL)
#define IPV6_TCP_ACK_FIN_CONTROL       (IPV6_CONTROL | TCP_ACK_FIN_CONTROL)
#define IPV6_TCP_ACK_PUSH_FIN_CONTROL  (IPV6_CONTROL | TCP_ACK_PUSH_FIN_CONTROL)
#define IPV6_TCP_SYN_ACK_CONTROL       (IPV6_CONTROL | TCP_SYN_ACK_CONTROL)
#define IPV6_OTHER_L4_PROTO_CONTROL    (IPV6_CONTROL | OTHER_L4_PROTO_CONTROL)

#define DNSQ_IPV4_UDP_CONTROL               (DNS_QUERY_CONTROL | IPV4_CONTROL | UDP_CONTROL)
#define DNSQ_IPV4_UDP_FRAG_CONTROL          (DNS_QUERY_CONTROL | IPV4_CONTROL | UDP_CONTROL | FRAG_CONTROL)
#define DNSQ_IPV4_TCP_SYN_CONTROL           (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_CONTROL | TCP_SYN_CONTROL)
#define DNSQ_IPV4_TCP_RST_CONTROL           (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_CONTROL | TCP_RST_CONTROL)
#define DNSQ_IPV4_TCP_FRAG_CONTROL          (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_CONTROL | FRAG_CONTROL)
#define DNSQ_IPV4_TCP_RST_ACK_CONTROL       (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_RST_ACK_CONTROL)
#define DNSQ_IPV4_TCP_ACK_CONTROL           (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_ACK_CONTROL)
#define DNSQ_IPV4_TCP_ACK_PUSH_CONTROL      (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_ACK_PUSH_CONTROL)
#define DNSQ_IPV4_TCP_ACK_FIN_CONTROL       (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_ACK_FIN_CONTROL)
#define DNSQ_IPV4_TCP_ACK_PUSH_FIN_CONTROL  (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_ACK_PUSH_FIN_CONTROL)
#define DNSQ_IPV4_TCP_SYN_ACK_CONTROL       (DNS_QUERY_CONTROL | IPV4_CONTROL | TCP_SYN_ACK_CONTROL)

#define DNSQ_IPV6_UDP_CONTROL               (DNS_QUERY_CONTROL | IPV6_CONTROL | UDP_CONTROL)
#define DNSQ_IPV6_UDP_FRAG_CONTROL          (DNS_QUERY_CONTROL | IPV6_CONTROL | UDP_CONTROL | FRAG_CONTROL)
#define DNSQ_IPV6_TCP_SYN_CONTROL           (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_CONTROL | TCP_SYN_CONTROL)
#define DNSQ_IPV6_TCP_RST_CONTROL           (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_CONTROL | TCP_RST_CONTROL)
#define DNSQ_IPV6_TCP_FRAG_CONTROL          (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_CONTROL | FRAG_CONTROL)
#define DNSQ_IPV6_TCP_RST_ACK_CONTROL       (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_RST_ACK_CONTROL)
#define DNSQ_IPV6_TCP_ACK_CONTROL           (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_ACK_CONTROL)
#define DNSQ_IPV6_TCP_ACK_PUSH_CONTROL      (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_ACK_PUSH_CONTROL)
#define DNSQ_IPV6_TCP_ACK_FIN_CONTROL       (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_ACK_FIN_CONTROL)
#define DNSQ_IPV6_TCP_ACK_PUSH_FIN_CONTROL  (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_ACK_PUSH_FIN_CONTROL)
#define DNSQ_IPV6_TCP_SYN_ACK_CONTROL       (DNS_QUERY_CONTROL | IPV6_CONTROL | TCP_SYN_ACK_CONTROL)

#define DNSR_IPV4_UDP_CONTROL               (DNS_RESP_CONTROL | IPV4_CONTROL | UDP_CONTROL)
#define DNSR_IPV4_UDP_FRAG_CONTROL          (DNS_RESP_CONTROL | IPV4_CONTROL | UDP_CONTROL | FRAG_CONTROL)
#define DNSR_IPV4_TCP_SYN_CONTROL           (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_CONTROL | TCP_SYN_CONTROL)
#define DNSR_IPV4_TCP_RST_CONTROL           (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_CONTROL | TCP_RST_CONTROL)
#define DNSR_IPV4_TCP_FRAG_CONTROL          (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_CONTROL | FRAG_CONTROL)
#define DNSR_IPV4_TCP_RST_ACK_CONTROL       (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_RST_ACK_CONTROL)
#define DNSR_IPV4_TCP_ACK_CONTROL           (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_ACK_CONTROL)
#define DNSR_IPV4_TCP_ACK_PUSH_CONTROL      (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_ACK_PUSH_CONTROL)
#define DNSR_IPV4_TCP_ACK_FIN_CONTROL       (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_ACK_FIN_CONTROL)
#define DNSR_IPV4_TCP_ACK_PUSH_FIN_CONTROL  (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_ACK_PUSH_FIN_CONTROL)
#define DNSR_IPV4_TCP_SYN_ACK_CONTROL       (DNS_RESP_CONTROL | IPV4_CONTROL | TCP_SYN_ACK_CONTROL)

#define DNSR_IPV6_UDP_CONTROL               (DNS_RESP_CONTROL | IPV6_CONTROL | UDP_CONTROL)
#define DNSR_IPV6_UDP_FRAG_CONTROL          (DNS_RESP_CONTROL | IPV6_CONTROL | UDP_CONTROL | FRAG_CONTROL)
#define DNSR_IPV6_TCP_SYN_CONTROL           (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_CONTROL | TCP_SYN_CONTROL)
#define DNSR_IPV6_TCP_RST_CONTROL           (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_CONTROL | TCP_RST_CONTROL)
#define DNSR_IPV6_TCP_FRAG_CONTROL          (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_CONTROL | FRAG_CONTROL)
#define DNSR_IPV6_TCP_RST_ACK_CONTROL       (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_RST_ACK_CONTROL)
#define DNSR_IPV6_TCP_ACK_CONTROL           (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_ACK_CONTROL)
#define DNSR_IPV6_TCP_ACK_PUSH_CONTROL      (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_ACK_PUSH_CONTROL)
#define DNSR_IPV6_TCP_ACK_FIN_CONTROL       (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_ACK_FIN_CONTROL)
#define DNSR_IPV6_TCP_ACK_PUSH_FIN_CONTROL  (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_ACK_PUSH_FIN_CONTROL)
#define DNSR_IPV6_TCP_SYN_ACK_CONTROL       (DNS_RESP_CONTROL | IPV6_CONTROL | TCP_SYN_ACK_CONTROL)


// Mapping between IPV4 and IPV6 addresses:
// 0:0:0:0:0:0:0:0:00:00:FF:FF:<IPV4_Address>
#define IPV4_IPV6_MAPPING_2ND            0x0000FFFF
#define IPV4_IPV6_MAPPING_3RD            0x0
#define IPV4_IPV6_MAPPING_4TH            0x0
#define IPV4_IPV6_MAPPING_3RD_AND_4TH    0x0


// Configuration Registers

// GC_CNTRL_0_MREG - TOPparse MREG[15]

// GuyE, 20.7.2013: First 3 bits of uqGcCtrlReg0 are used for BDOS signature lookup in TOPparse BCAM8.
// It uses GC_CNTRL_0_BDOS_ENABLE_BIT and overrides bit 3 (not affecting its content because it's currently
// used for IMMCHK which is performed before BDOS. This however should be fixed!!!

//mask all except bits 0-5
//set pa enable def action continue
#define PA_CHECK_ONLY     (  (1 << GC_CNTRL_0_VLAN_TUN_CFG_BIT ) | (1<<GC_CNTRL_0_IMMCHK_ENABLED_BIT ) | ( 1<< GC_CNTRL_0_IMMCHK_DEFAULT_ACTION_BIT) | ( 3));

#define GC_CNTRL_0_FRAME_ACTION_BITS_OFFSET        0
// The existing code of TOPparse will jump in frame_from_network flow as follows:
//         GC_CNTRL_0_FRAME_ACTION_BITS_OFFSET[1..0] value:

#define GC_CNTRL_0_cond_bit byGlobConfReg.bit[5];

#define GC_CNTRL_0_FRAME_ACTION_DROP               0 // 00 - GLOB_CONF_DROP_LAB;            // DROP:     Increment RT counter and discard frame
//reuse this bit to indicate l4 layer with ports was detected (tcp or udp sctp)
#define DETECT_L4WITH_PRTS                         0

#define GC_CNTRL_0_FRAME_ACTION_CONT               1 // 01 - FRAME_CONT_ACTION_LAB,         // CONTINUE: Continue TOPs action (action: FRAME_CONT_ACTION)
#define GC_CNTRL_0_FRAME_ACTION_BYPASS_NETWORK     2 // 10 - GLOB_CONF_NETWORK_BYPASS_LAB,  // BYPASS:   Send from Network port to Network port (action: FRAME_BYPASS_NETWORK)
#define GC_CNTRL_0_FRAME_ACTION_BYPASS_HOST        3 // 11 - GLOB_CONF_BYPASS_HOST_LAB,     // TO CPU:   Send from Network port to Host port (action: FRAME_BYPASS_HOST)


#define GC_CNTRL_0_IMMCHK_ENABLED_BIT              2
#define GC_CNTRL_0_IMMCHK_SAMPLENABLED_BIT         3
#define GC_CNTRL_0_IMMCHK_DEFAULT_ACTION_BIT       4  //##TODO_GUY_BUG_FOUND (if only 1 bit then mark bit5 as free) GuyE: check if its really 2 bits!!!!!!! packet anomalies action 2 bit
#define BDOS_GLOB_CNTR_MH                          5
#define GC_CNTRL_0_ALIST_ENABLED_BIT               6
#define GC_CNTRL_0_VLAN_TUN_CFG_BIT                7  //                    - to enable deeper packet inspection in case that frame has User VLAN header(s)

// The following 2 bits must remain together:
//#define GC_CNTRL_0_ALIST_DEFAULT_ACTION_BITS       8  // not supported more since continue action
#define GC_CNTRL_0_POL_CTRL_ACTIVE_BIT             16  // Policy configuration phase 1 bit
#define GC_CNTRL_0_TIN_LIN                         9  // Bit 9 used different way . It will be set if packet should go to DNS mitigation
//in latter stage this bit will be reused as combination of TUNEL_DEDECTED and TUNEL_DISABLE status in parse
#define GC_CNTRL_0_TUN_DET_DIS                     9

#define GC_CNTRL_0_ALIST_NONE_EMPTY_BIT            10 // Acc list data set to use
#define GC_CNTRL_0_RTPC_ENABLE_BIT                 11 // for RTPC
#define GC_CNTRL_0_SYN_ENABLE_BIT                  12 // Acc list data set to use
#define GC_CNTRL_0_IP_IN_IP_TUN_CFG_BIT            13 //                    - to enable deeper packet inspection in case that frame has IPinIP header
#define GC_CNTRL_0_MPLS_TUN_CFG_BIT                14 //                    - to enable deeper packet inspection in case that frame has MPLS header

// The following 2 bits must remain together:
//#define GC_CNTRL_0_SYN_DEFAULT_ACTION_BITS         15
#define GC_CNTRL_0_PROT_DST_NONE_EMPTY_BIT         17

#define GC_CNTRL_0_PROT_DST_PHASE_BIT              18 // SYN Protection phase bit ('0' - phase 0, '1' - phase 1)
#define GC_CNTRL_0_POLICY_NON_EMPTY_BIT            19 // At least one policy is defined
#define GC_CNTRL_0_POLICY_ACTIVE_BIT               20 // Policy phase set to use, GuyE: Not needed since we are working with 1 phase
#define GC_CNTRL_0_BDOS_ACTIVE_BIT                 21 // BDOS filters are enabled
#define GC_CNTRL_0_GRE_TUN_CFG_BIT                 22 // enable GRE channel - to enable deeper packet inspection in case that frame has GRE header
#define GC_CNTRL_0_PPS_POLICER_EN_BIT              23 // start limit the PPS traffic
#define GC_CNTRL_0_L2TP_TUN_CFG_BIT                24 //                    - to enable deeper packet inspection in case that frame has LT2P header
#define GC_CNTRL_0_BDOS_EMPTY_SIG_BIT              25 // BDOS signatures are empty
//#define GC_CNTRL_0_BDOS_ACTIVE_BIT                 26 // BDOS data set to use
//#define GC_CNTRL_0_TCP_OOS_ENABLED_BIT             27 // TCP OOS is enabled
#define GC_CNTRL_GLOB_TUNNEL_STATUS_BIT            27 // TCP OOS is enabled



#define GC_CNTRL_0_ROUTING_PHASE_BIT               28 // Phase bit for routing module, used to distinguish between the active routing table (0 - phase 0, 1 - phase 1), for double buffer
#define GC_CNTRL_0_GTP_TUN_CFG_BIT                 29 //                    - to enable deeper packet inspection in case that frame has GTP header
//this bit will set indicate if packet TCP type
#define GC_CNTRL_0_TCP_TYPE_DET                    30
//#define GC_CNTRL_0_TCP_OOS_DEFAULT_ACTION_BIT      30 // Use Policy Classification for TCP OOS
#define GC_CNTRL_0_ROUTING_ENABLED_BIT             31 // Determines whether routing mode enabled ('1') or disabled ('0', transparent mode)


// RTPC_CNTRL_MREG - TOPresolve MREG[11]
#define RTPC_FILTER_ENABLE_BIT                    0 //5 bits, one per filter

// GC_CNTRL_1_MREG - TOPresolve MREG[15]

#define GC_CNTRL_1_ALIST_SAMPLENABLED_BIT          3
#define GC_CNTRL_1_BDOS_SAMPLING_ENABLE            4
#define GC_CNTRL_1_CPU_INSTANCE_0_MASK_BIT         5
#define GC_CNTRL_1_CPU_INSTANCE_1_MASK_BIT         6
#define GC_CNTRL_1_UPD_POL_STATUS_BIT              7
#define GC_CNTRL_1_POLICY_CONFIG_ACTIVE_BIT        8
#define GC_CNTRL_1_BDOS_ACTIVE_BIT                 9 // BDOS phase

// Bits 8..15 free
#define GC_CNTRL_1_DEF_POLICY_ACTION_OFFSET        16 // not used in mcode, but is using direct access


// GC_CNTRL_2_MREG - TOPresolve MREG[14]

#define GC_CNTRL_2_ALST_TP_ACTION_OFFSET           0  // 1 bit, ACL TP status
#define GC_CNTRL_2_IMM_CHK_TP_ACTION_OFFSET        1  // 1 bit, Immediate Check TP status

// GC_CNTRL_3_MREG
#define GC_CNTRL_3_NP_ID_OFF                       31  // 1 bit - ID of the NP (0 or 1)
#define GC_CNTRL_3_DEV_TYPE_OFF                    30  // 1 bit - indicate HTQE or MRQ (0 or 1) device
#define GC_CNTRL_3_TRAFFIC_LIMIT_OFF               1   // 1 bit - indicates if traffic limit reached

//#define GC_CNTRL_1 - top modify
#define GC_CNTRL_0_COPY_PORT_EN_MDF 0 //1 bit, 1 - enable send to copy port
#define GC_CNTRL_0_SIZE_LIM_EN_MDF  1 //1 bit, 1 - packet size limitation enable


// Action encoding:
// GC_CNTRL_1 is defined in TOPresolve

#define FRAME_BYPASS_NETWORK_BIT       0 //Send from Network port to Network
#define FRAME_BYPASS_HOST_BIT          1 //Send from Network port to Host
#define FRAME_CONT_ACTION_BIT          2 //Continue  TOPS action (Continue scurity checks - next security feature)
#define FRAME_DROP_BIT                 3 //Drop, the drop action will be performed in the same TOP
#define FRAME_CONF_EXTRACT_BIT         4 //Packet from CPU, inbound configuration inside, for TOPparse, TOPresolve. conf message from host, used for OOS to activate high learn.
#define FRAME_SYN_COOKIE_GEN_BIT       5 //Generate SYN-Cookie action. TOPResolve -> TOPmodify
#define FRAME_HOST_BYPASS_2NETW_BIT    6 //Send from CPU 2 network
#define FRAME_HOST_BYPASS_2NETW_TP_BIT 7 //Packet Trace, replaces drop in packet anomalies - if this functions is enabled send from time to time to the host or send to another port.

#define FRAME_BYPASS_NETWORK           (1 << FRAME_BYPASS_NETWORK_BIT)
#define FRAME_BYPASS_HOST              (1 << FRAME_BYPASS_HOST_BIT)
#define FRAME_CONT_ACTION              (1 << FRAME_CONT_ACTION_BIT)
#define FRAME_DROP                     (1 << FRAME_DROP_BIT)
#define FRAME_CONF_EXTRACT             (1 << FRAME_CONF_EXTRACT_BIT)
#define FRAME_SYN_COOKIE_GEN           (1 << FRAME_SYN_COOKIE_GEN_BIT)
#define FRAME_HOST_BYPASS_2NETW        (1 << FRAME_HOST_BYPASS_2NETW_BIT)
#define FRAME_TP_BYPASS_2NETW          (1 << FRAME_HOST_BYPASS_2NETW_TP_BIT)

#define CTRL_PACKETS                   0
#define INB_DROP_ACT                   1

//special label control packets
#define SPEC_ROUTE_CTL            0
//special label inbound drop
#define SPEC_INB_DROP             1
#define SPEC_PPS_INB_DROP         2

//packet anomaly offload table
//this check going to be integrated in code as TROW selections
#define IC_CNTRL_0_IPv6_INC_HOPLIMIT    2 //1
#define IC_CNTRL_0_IPV6_FIRST_FRAG      4 //2
#define IC_CNTRL_0_L3_UNK               8 //4
#define IC_CNTRL_0_IPv4_INC_CHEKSUM     0x10 //8
#define IC_CNTRL_0_IPv4_INC_PKTHDRLEN   0x20  //10
#define IC_CNTRL_0_INC_TTL              0x40  //20

//mask 1 selection
#define IC_CNTRL_1_UNK_L4               0x80  // 40
#define IC_CNTRL_1_TCP_HLEN             0x100 // 80
#define IC_CNTRL_1_TCP_FLAG             0x200  // 100
#define IC_CNTRL_1_UDP_ZCHKSUM          0x400  // 200
#define IC_CNTRL_1_UDP_INC_HLEN         0x800  // 400
#define IC_CNTRL_1_SCTP_HLEN            0x1000 // 600
#define IC_CNTRL_0_FRAG                 0x2000
#define IC_CNTRL_0_FIRST_FRAG           0x4000
#define IC_CNTRL_0_IPv6_INC_PKTHDRLEN   0x8000


#define IC_CNTRL_1_LAND_ATTACK   0x2000
#define IC_CNTRL_1_SIPDIP_LOCAL  0x4000
#define IC_CNTRL_1_L4ZERO        0x8000


// IC as Immediate Checks.
// IC_CNTRL_0_MREG
#define IC_CNTRL_0_IPMODE_OFF               0  // 1bit 0 - combined IPv6/IPv4 , 1-IPv4 only
#define IC_CNTRL_0_JUMBOMODE_OFF            1  // Support handling of jumbo frames in TOPparse: 1 - allow sending to CPU, 0 - drop\bypass (according to case). This bit content is equivalent to IC_CNTRL_0_JUMBOMODE_MDF_OFF used in TOPmodify MREG.
//control bit for top modify , this bit request Top Modify to work with Jumbo MSS table
#define IC_CNTRL_0_JUMBOMODE_MDF_OFF       16  // Support handling of jumbo frames in TOPmodify. This bit content is equivalent to IC_CNTRL_0_JUMBOMODE_OFF used in TOPparse MREG.
#define IC_CNTRL_0_IPSEC_MODE_OFF           2  // 3   //IPSEC configuration mode
#define IC_CNTRL_0_L2_FORMAT_OFF            4  // 2
#define IC_CNTRL_0_L2_BROADCAST_OFF         6  // 2
#define IC_CNTRL_0_L3_UNK_OFF               8  // 2
#define IC_CNTRL_0_IPv4_INC_CHEKSUM_OFF    10  // 2
#define IC_CNTRL_0_IPv4_INC_PKTHDRLEN_OFF  12  // 2
#define IC_CNTRL_0_INC_TTL_OFF             14  // 2
#define IC_CNTRL_0_FRAG_OFF                16  // 2
#define IC_CNTRL_0_IPv6_INC_HDR_OFF        24  // 2
#define IC_CNTRL_0_IPv6_HLIM_OFF           26  // 2
#define IC_CNTRL_0_IPv6_FRAG_OFF           28  // 2
#define IC_CNTRL_0_RT_EN_OFF               30  // 1 bit, global counter, default disabled
#define IC_CNTRL_0_TUN_INNER_EN_OFF        31  // 1 bit, global counter, force inner header: 0 disable, 1 enable

// IC_CNTRL_1_MREG
#define IC_CNTRL_1_UNK_L4_OFF               0  // 2
#define IC_CNTRL_1_LAND_ATTACK_OFF          2  //
#define IC_CNTRL_1_TCP_HLEN_OFF             4  // 2
#define IC_CNTRL_1_TCP_FLAG_OFF             6  // 2
#define IC_CNTRL_1_L4ZERO_PORT_OFF          8  // 2
#define IC_CNTRL_1_UDP_ZCHKSUM_OFF         10  // 2
#define IC_CNTRL_1_UDP_INC_HLEN_OFF        12  // 2
#define IC_CNTRL_1_LOCALHOST_OFF           14  // 2
#define IC_CNTRL_1_SCTP_HLEN_OFF           16  // 2
#define IC_CNTRL_1_GRE_VERSION_OFF         18  // 3
#define IC_CNTRL_1_GRE_ROUTING_HDR_NUM_OFF 20  // 3
#define IC_CNTRL_1_GRE_INV_HDR_LEN_OFF     22  // 3
#define IC_CNTRL_1_INC_VER_GTP_OFF         24  // 3
#define IC_CNTRL_1_INC_HLEN_GTP_OFF        26  // 3
#define IC_CNTRL_1_CNTRL_3_GTP_OFF         28

// Global configuration bits, but placed in this registers
#define IC_CNTRL_1_TP_EN_OFF               30  // 1 bit, 0 - disable, 1 - enable
#define IC_CNTRL_1_DISRT_TYPE_OFF          31  // 1 bit, 0 - L3 type, 1 - L4 type

// TOPmodify Global configuration bits used in MREG[13] - GC_CNTRL_MDF
#define CNTRL_MDF_DSTR_TYPE_OFF           0  // 1 bit
#define CNTRL_MDF_FFT_NOMATCH_OFF         1  // 2 bits
#define CNTRL_MDF_METADATA_EN_OFF         3  // 1 bit
//Bits[4..31] free

#define RST_OUT_OF_WINDOW_VAL             0x100000    //2^20

// SYN Protection challenge type (used in MSG_CONTROL_CHALLENGE_TYPE_BITS)
#define SYN_PROT_SYNACK_CHALLENGE_TYPE    0x0
#define SYN_PROT_ACK_CHALLENGE_TYPE       0x1
#define SYN_PROT_RST_CHALLENGE_TYPE       0x2

#define METADATA_RDWR_STAMP               0x0103B2FF
#define METADATA_RDWR_STAMP_LOW16         0xB2FF
#define METADATA_RDWR_STAMP_HIGH16        0x0103

// CAUI ports definitions
#define NP_CAUI_0_PORT_NUMBER    0x74; // decimal port 116
#define NP_CAUI_1_PORT_NUMBER    0x75; // decimal port 117

#define NP_CAUI_PORT_VALID       0x80; // bit indication for CAUI port number validity

// Default Policy Metadata ID
#define DEF_POLICY_METADATA_ID            0x1FFF

// TB result color mapping:
// green 	0
// yellow 	1
// red		2
#define YELLOW_FLAG_OFF       0
#define RED_FLAG_OFF          1
#define YELLOW_COLOR_MASK_VAL (1<<YELLOW_FLAG_OFF)
#define RED_COLOR_MASK_VAL    (1<<RED_FLAG_OFF)


//FFT table support

#define FFT_VLAN_CONFIG_VALUE             0   // defines VLAN configuration - value
#define FFT_VLAN_CONFIG_UNTAG             1   // defines VLAN configuration - untagged
#define FFT_VLAN_CONFIG_ANY               2   // defines VLAN configuration - any

#define FFT_FORWARD_MODE_TRANSPARENT      0   // defines FFT table forwarding mode - transparent
#define FFT_FORWARD_MODE_ROUTING          1   // defines FFT table forwarding mode - routing

#define FFT_VIF_ENTRY_FORWARD_MODE_OFF    7   // represents forward mode in the TCAM result VIF field
                                               // 0 - transparent, 1 - routing
//FFT VIF TCAM result data format
#define FFT_VIF_STR                       64  // structure number for TOPsearch-2
//#define FFT_VIF_DATA_FRWMODE_OFF        0   // 1-bit  for transparent or routing // Amit: is now obsolete - instead, use relevant bit in MREG.
//#define FFT_VIF_DATA_MACOFFS_OFF        1   // 5-bits for MAC offset field       // Amit: is now obsolete - instead, DMAC is checked by the general decoder against configured value from NPsl or from Host.

#define FFT_VIF_DATA_HAS_RX_COPY_PORT_OFF 0   // 1-bit to indicate if port has RX copy port or not. The RX copy port(s) will be determined later
#define FFT_VIF_DATA_SWITCH_VLAN_OFF      1   // 1-bit to indicates that the packets from this port can be bypassed without security checks
//-- 2 _WTF??
#define SSL_PORT_DET                      3
#define FFT_VIF_ROUTE_ADDED_VLAN_OFF      4   // 1-bit to indicates that the virtual interface vlan was declared on port


#define FFT_VIF_DATA_VIFID_OFF            5   // 5-bits for VIF ID field
#define FFT_VIF_DATA_PHYSPRT_OFF          11  // 5-bits for Physical Port offset
//#define FFT_VIF_DATA_FRWMODE_MASK      (1<<FFT_VIF_DATA_FRWMODE_OFF)            // Amit: will be obsolete - instead use relevant bit in MREG.
//#define FFT_VIF_DATA_MACOFFS_SIZE       5   // 5-bits for MAC offset field
#define FFT_VIF_DATA_HAS_RX_COPY_PORT_SIZE 1   // 1-bit to indicate if port has RX copy port or not. The RX copy port(s) will be determined later
#define FFT_VIF_DATA_SWITCH_VLAN_SIZE      1   // 1-bit to indicates that the packets from this port can be bypassed without security checks

#define FFT_VIF_DATA_VIFID_SIZE           6   // 5-bits for VIF ID field
#define FFT_VIF_DATA_PHYSPRT_SIZE         5   // 5-bits for Physical Port offset

// TCP OOS Type values
#define MSG_CONTROL_TCP_OOS_TYPE_SYN_ACK              0x1 //001b
#define MSG_CONTROL_TCP_OOS_TYPE_FIN_RST              0x2 //010b
#define MSG_CONTROL_TCP_OOS_TYPE_ACK                  0x4 //100b


// Bitwise Stat Operations Data Register Bit Offsets
#define BW_CMD_SIZE_1               0
#define BW_CMD_SIZE_2               4

#define BW_OP_DATA_VALUE_BIT        0  // 16 bits
#define BW_OP_DATA_SIZE_BIT         16 // 3 bits
#define BW_OP_DATA_OFFSET_BIT       19 // 6 bits
#define BW_OP_DATA_RESERVED_BIT     25 // 7 bits

#define PRT_CFG0 64   // Host SGMII port #0
#define PRT_CFG1 65   // Host SGMII port #1


// Statistics definitions (that need to be defined in EZstat.h)

#define STS_READ_SYS_INFO_CMD__SRC_TM_FCU0      0; // 0000 - TM_FCU0
#define STS_READ_SYS_INFO_CMD__SRC_TM_FCU1      1; // 0001 - TM_FCU1
#define STS_READ_SYS_INFO_CMD__SRC_TM_FCU2      2; // 0010 - TM_FCU2
#define STS_READ_SYS_INFO_CMD__SRC_RTC          3; // 0011 - RTC (global real time counter)
#define STS_READ_SYS_INFO_CMD__SRC_RTC_VIDEO    4; // 0100 - RTC_VIDEO (video real time counters; see also bits 9:4 below)
#define STS_READ_SYS_INFO_CMD__SRC_RNG          5; // 0101 - RNG (random number generator)
#define STS_READ_SYS_INFO_CMD__SRC_TM_ALL_STS   6; // 0110 - TM_ALL_STS
#define STS_READ_SYS_INFO_CMD__SRC_OOB0         7; // 0111 - OOB0 (Out Of Band flow control status; see also bits 9:4 below)
#define STS_READ_SYS_INFO_CMD__SRC_OOB1         8; // 1000 - OOB1 (Out Of Band flow control status; see also bits 9:4 below)


// GRE decapsulation defenitions

#define RADWARE_TUNNEL_GRE_HEADER_SIZE       4; // RadwareTunnelGRE is according to RFC2784 with checksum = 0, meaning its size will always be 4 bytes.
#define IPV4_AND_RADWARE_TUNNEL_GRE_SIZE     IP_BASE_SIZE + RADWARE_TUNNEL_GRE_HEADER_SIZE; // 20 + 4 = 24
#define GRE_NXT_PROTOCOL_TYPE_OFF            2;



/******************************************************************************
                              Definitions used in xadDriver
*******************************************************************************/

#define XAD_EZLOW_DRV_IMMCHK_CNTRL_0_MASK ((1 << IC_CNTRL_0_IPMODE_OFF) | (1 << IC_CNTRL_0_TUN_INNER_EN_OFF) | (1 << IC_CNTRL_0_JUMBOMODE_OFF) | (1 << IC_CNTRL_0_IPSEC_MODE_OFF) | (1 << IC_CNTRL_0_RT_EN_OFF))
#define XAD_EZLOW_DRV_IMMCHK_CNTRL_1_MASK ((1 << IC_CNTRL_1_TP_EN_OFF ) | (1 << IC_CNTRL_1_DISRT_TYPE_OFF  ) )

#define JUMBO_PCKT_TST_SIZE   	1500
#define JUMBO_PCKT_CREG2_OFF  	2
#define JUMBO_PCKT_CREG2_FSIZE 	2
#define JUMBO_PCKT_CREG2_SHIFT   16

#define JUMBO_PCKT_CREG2_SIZE  (JUMBO_PCKT_SIZE<<JUMBO_PCKT_CREG2_SHIFT)
// ##AMIT_GUY: is the info in the following lines used as reference only? (this is OK if so) I dont see where it is used in the code to either init the values (probably initated by the host).
//           In addition, this info block is duplicated in 2 places in the code: xad.Prs.h and xad.common.h - before deleting need to merge the relevant comments to the place that will hold the final values.
#define HOST_P0             1
#define HOST_P1             2
#define NET_P1              1
#define NET_P2              2
#define NET_P4              4
#define NET_P5              5
#define NET_P7              7
#define NET_P9              9

#define FRAME_CREG_NP       8
#define FRAME_CREG_NET      4
#define FRAME_CREG_HOST     2
#define FRAME_CREG_CTRL     1

#define FRAME_CREG_INST0    0
#define FRAME_CREG_INST1    1

#define  XAUI0_CREG_0       0
#define  XAUI0_CREG_1       NET_P1            // from host port 0 forward to net port 1
#define  XAUI0_CREG_2       FRAME_CREG_INST0  // from host port 0 from instance 0
#define  XAUI0_CREG_3       FRAME_CREG_HOST

#define  XAUI1_CREG_0       0
#define  XAUI1_CREG_1       NET_P1            // from net port 1 bypass to net port 1
#define  XAUI1_CREG_2       0                 // from net port 1 - no instance
#define  XAUI1_CREG_3       FRAME_CREG_NET

#define  XAUI2_CREG_0       0
#define  XAUI2_CREG_1       NET_P2            // from net port 2 bypass to net port 2
#define  XAUI2_CREG_2       0                 // from net port 1 - no instance
#define  XAUI2_CREG_3       FRAME_CREG_NET

#define  XAUI3_CREG_0       0
#define  XAUI3_CREG_1       NET_P4            // from host port 3 forward to net port 4
#define  XAUI3_CREG_2       (FRAME_CREG_INST0 << 16) // from host port 3 from instance 0
#define  XAUI3_CREG_3       FRAME_CREG_HOST

#define  XAUI4_CREG_0       0
#define  XAUI4_CREG_1       NET_P4            // from net port 4 bypass to net port 4
#define  XAUI4_CREG_2       0                 // from net port 4 - no instance
#define  XAUI4_CREG_3       FRAME_CREG_NET

#define  XAUI5_CREG_0       0
#define  XAUI5_CREG_1       NET_P5            // from net port 5 bypass to net port 5
#define  XAUI5_CREG_2       0                 // from net port 5 - no instance
#define  XAUI5_CREG_3       FRAME_CREG_NET

#define  XAUI6_CREG_0       0
#define  XAUI6_CREG_1       NET_P7            // from host port 6 forward to net port 7
#define  XAUI6_CREG_2       FRAME_CREG_INST1  // from host port 6 from instance 1
#define  XAUI6_CREG_3       FRAME_CREG_HOST

#define  XAUI7_CREG_0       0
#define  XAUI7_CREG_1       NET_P7            // from net port 7 bypass to net port 7
#define  XAUI7_CREG_2       0                 // from net port 7 - no instance
#define  XAUI7_CREG_3       FRAME_CREG_NET

#define  XAUI8_CREG_0       0
#define  XAUI8_CREG_1       NET_P9            // from host port 8 forward to net port 9
#define  XAUI8_CREG_2       FRAME_CREG_INST1  // from host port 8 from instance 1
#define  XAUI8_CREG_3       FRAME_CREG_HOST

#define  XAUI9_CREG_0       0
#define  XAUI9_CREG_1       NET_P9            // from net port 9 bypass to net port 9
#define  XAUI9_CREG_2       0                 // from net port 9 - no instance
#define  XAUI9_CREG_3       FRAME_CREG_NET

#define SGMII0_CREG_0       0x0810c000
#define SGMII0_CREG_1       0
#define SGMII0_CREG_2       FRAME_CREG_INST1  // from host SGMII 64 from instance 1
#define SGMII0_CREG_3       FRAME_CREG_CTRL

#define SGMII1_CREG_0       0x0810c001
#define SGMII1_CREG_1       0
#define SGMII1_CREG_2       FRAME_CREG_INST0  // from host SGMII 65 from instance 0
#define SGMII1_CREG_3       FRAME_CREG_CTRL

#define KR4_1_CREG_0        0
#define KR4_1_CREG_1        0
#define KR4_1_CREG_2        0
#define KR4_1_CREG_3        FRAME_CREG_HOST

#define KR4_3_CREG_0        0
#define KR4_3_CREG_1        0
#define KR4_3_CREG_2        0
#define KR4_3_CREG_3        FRAME_CREG_HOST

#define KR4_5_CREG_0        0
#define KR4_5_CREG_1        0
#define KR4_5_CREG_2        0
#define KR4_5_CREG_3        FRAME_CREG_HOST


#define KR4_6_CREG_0        0
#define KR4_6_CREG_1        0
#define KR4_6_CREG_2        0
#define KR4_6_CREG_3        FRAME_CREG_NET

#define KR4_7_CREG_0        0
#define KR4_7_CREG_1        0
#define KR4_7_CREG_2        0
#define KR4_7_CREG_3        FRAME_CREG_NET
//FRAME_CREG_HOST

#define KR4_8_CREG_0        0
#define KR4_8_CREG_1        0
#define KR4_8_CREG_2        0
#define KR4_8_CREG_3        FRAME_CREG_NET

#define KR4_9_CREG_0        0
#define KR4_9_CREG_1        0
#define KR4_9_CREG_2        0
#define KR4_9_CREG_3        FRAME_CREG_NET

#define KR4_10_CREG_0       0
#define KR4_10_CREG_1       0
#define KR4_10_CREG_2       0
#define KR4_10_CREG_3       FRAME_CREG_NET

#define KR4_11_CREG_0       0
#define KR4_11_CREG_1       0
#define KR4_11_CREG_2       0
#define KR4_11_CREG_3       FRAME_CREG_NET
#define CAUI_0_CREG_0       0
#define CAUI_0_CREG_1       0
#define CAUI_0_CREG_2       0
#define CAUI_0_CREG_3       FRAME_CREG_NET

#define CAUI_1_CREG_0       0
#define CAUI_1_CREG_1       0
#define CAUI_1_CREG_2       0
#define CAUI_1_CREG_3       FRAME_CREG_NET

/* unified key layout for search in access list policy and synprotection */

/* unified block  1 */

#define UNF_PROT_DPORT_OFF                0  // size 2
#define UNF_PROT_VLAN_OFF                 2  // size 2
#define UNF_PROT_DIP_OFF                  4  // size 16
#define UNF_PROT_PORT_OFF                 20 // size 1   offset on KMEM, used for piggy-back policy calculation
#define UNF_PROT_PHASE_OFF                21 // size 1 (for 2 phases use)
#define UNF_PROT_POLICY_PHASE_OFF         22 // size 1
//#define UNF_L4_TYPE                       22 //protocol type for access list unified key

//23 -31 empty space

#define UNF_CTX_STR_IDX                   31 //TREG offset index of Contex register structure

/* unified block 2 */
#define UNF_PROT_SIP_OFF                 32 // size 16, offset on KMEM, used for compound lookup in structure 62 (SYN_PROT_AUT_STR)
#define UNF_PROT_SPORT_OFF_KMEM          48 // size 2,  offset on KMEM, used for compound lookup in structure 63 (SYN_PROT_CONT_STR)
#define UNF_L4_TYPE                      50 //protocol type for access list unified key

// Offset in TREG where we write temporary key type value of lookups in BDOS structures 14-23
#define TREG_TEMP_BDOS_KEY_TYP_OFF     96 // Since IPv6 compound key is larger then IPv4 key
#define TREG_TEMP_BDOS_KEY_TYP_SIZE    16
#define UNF_PROT_CONT_COOKIE_OFF_KMEM    52 // size 3,  offset on KMEM, used for compound lookup in structure 63 (SYN_PROT_CONT_STR)
#define UNF_FRAG_L4_MASK                 55  // size 1 , unf bdos controller
#define UNF_POLICY_BDOS_CNG              56 //2 byte , controller + protocol encoding 
#define UNF_TASK_CNTR                    58 // size 1


//#define CMP_POLICY_BDOS_CFG_PHASE_OFF 42

//#define GLOBAL_RTM_IN_TOP_MODIFY 1

#define UNF_BDOS_L3_KEY_OFFSET           ( UNF_TASK_CNTR  + 1 ) //60  

#define CMP_BDOS_L23_L3_SIZE_OFF         UNF_BDOS_L3_KEY_OFFSET   //60  Size 2 bytes

#define CMP_BDOS_L23_L4_PROT_OFF         UNF_L4_PROT 

#define CMP_BDOS_L23_ID_NUM_OFF        ( 2 + UNF_BDOS_L3_KEY_OFFSET )  // 62 Size 2 bytes
#define CMP_BDOS_L23_TOS_OFF           ( 4 + UNF_BDOS_L3_KEY_OFFSET ) //  64 Size 1 byte
#define CMP_BDOS_L23_TTL_OFF           ( 5 + UNF_BDOS_L3_KEY_OFFSET ) //  65 Size 1 byte
#define CMP_BDOS_L23_FRGMNT_OFF        ( 6 + UNF_BDOS_L3_KEY_OFFSET ) //  66 Size 2 bytes
#define CMP_BDOS_L23_FRGMNT_FLG_OFF    ( 8 + UNF_BDOS_L3_KEY_OFFSET )  // 68 Size 1 byte

/*
IP_TOS_OFF                  1             ;
#define IP_LEN_OFF                  2             ;
#define IP_FRG_ID_OFF               4             ;
#define IP_TTL_OFF                  8             ;
*/
//+9 bytes Ipv4  


// L3 fields sizes for IPV4:
#define CMP_BDOS_L23_SIP_SIZE          16
#define CMP_BDOS_L23_DIP_SIZE          16
/*
#define CMP_BDOS_L23_IPV6_SIP_SIZE          16
#define CMP_BDOS_L23_IPV6_DIP_SIZE          16
*/
#define CMP_BDOS_L23_ID_NUM_SIZE       2
#define CMP_BDOS_L23_TOS_SIZE          1
#define CMP_BDOS_L23_TTL_SIZE          1
#define CMP_BDOS_L23_L4_PROT_SIZE      1
#define CMP_BDOS_L23_FRGMNT_SIZE       2
#define CMP_BDOS_L23_FRGMNT_FLG_SIZE   1

// IPV4 L23 size 7 


#define CMP_BDOS_L23_IPV6_HOP_LIMIT_OFF        (2 + UNF_BDOS_L3_KEY_OFFSET )  //  62  Size 1 byte
#define CMP_BDOS_L23_IPV6_TRAFFIC_CLASS_OFF    (3 + UNF_BDOS_L3_KEY_OFFSET )  //  63 Size 1 byte
#define CMP_BDOS_L23_IPV6_FLOW_LABEL_OFF       (4 + UNF_BDOS_L3_KEY_OFFSET )  //  64 Size 4 bytes -- wrong , this 63 
#define CMP_BDOS_L23_IPV6_FRGMNT_OFF           (8 + UNF_BDOS_L3_KEY_OFFSET )  //  68 Size 2 bytes
#define CMP_BDOS_L23_IPV6_FRGMNT_FLG_OFF       (10 + UNF_BDOS_L3_KEY_OFFSET )  // 70 Size 1 byte
#define CMP_BDOS_L23_IPV6_FRGMNT_ID_OFF        (11 + UNF_BDOS_L3_KEY_OFFSET )  // 71 Size 4 bytes
//Ipv6 L32 size 15 byte  end 78

#define UNF_BDOS_L4_KEY_OFFSET   (CMP_BDOS_L23_IPV6_FRGMNT_ID_OFF + 4) // 78

#define CMP_BDOS_L4_CHECKSUM_OFF       ( 0 + UNF_BDOS_L4_KEY_OFFSET )  //  75 Size 2 bytes
#define CMP_BDOS_L4_ICMP_TYPE_OFF      ( 2 + UNF_BDOS_L4_KEY_OFFSET )   // 77 Size 1 byte, ICMP Fields
#define CMP_BDOS_L4_IGMP_TYPE_OFF      ( 3 + UNF_BDOS_L4_KEY_OFFSET )   // 78 Size 1 byte, IGMP Fields
#define CMP_BDOS_L4_TCP_SEQ_NUM_OFF    ( 4 + UNF_BDOS_L4_KEY_OFFSET )   // 79 Size 4 bytes, TCP Fields
#define CMP_BDOS_L4_TCP_FLAGS_OFF      ( 8 + UNF_BDOS_L4_KEY_OFFSET )  //  83 Size 1 byte,  TCP Fields
// L2 fields offsets
#define CMP_BDOS_L23_VLAN_OFF          (UNF_PROT_VLAN_OFF + L4_KEY_OFFSET )  // 84 Size 2 bytes
#define CMP_BDOS_L23_PACKET_SIZE_OFF   ( 9 + UNF_BDOS_L4_KEY_OFFSET )  // 86 Size 2 bytes
// DNS numeric fields offsets
#define  CMP_BDOS_L4_CNTRL_OFF         ( 11 + UNF_BDOS_L4_KEY_OFFSET )  // 88 Size 4 bytes metadata will be replaced in TS

//15 bytes

#define  UNF_L4_PROT   ( 15 + UNF_BDOS_L4_KEY_OFFSET ) // 89 byte
//2 byte for protocols

#define UNF_VIF_OFF   ( 16 + UNF_BDOS_L4_KEY_OFFSET ) //  90 size 1
//#define UNF_HASH_CORE_OFF   ( 17 + UNF_BDOS_L4_KEY_OFFSET ) //  91 size 2


#define CMP_BDOS_L23_IPV4_KMEM_SIZE      48  // 47 bytes padded to the closest multiple of 16 bytes


// L3 fields offsets for IPv6:
//#define CMP_BDOS_L23_IPV6_DIP_OFF              (0 + L3_KEY_OFFSET )   // Size 16 bytes
//#define CMP_BDOS_L23_IPV6_SIP_OFF              (16 + L3_KEY_OFFSET )   // Size 16 bytes

// L3 Common fields offsets (shared with IPv4 key & IPv6 key)
/*
#define L3_COMMON_FLD_L3_SIZE_OFFSET      0
#define L3_COMMON_FLD_IPV6_L4_PROT_OFFSET 2
#define L3_COMMON_FLD_IP_VER_OFFSET       3
*/
//#define CMP_BDOS_L23_L3_SIZE_OFF               (45 + L3_COMMON_FLD_L3_SIZE_OFFSET + L3_KEY_OFFSET )  // Size 2 bytes

//#define CMP_BDOS_L23_IPV6_L4_PROT_OFF             (45 + L3_COMMON_FLD_IPV6_L4_PROT_OFFSET + L3_KEY_OFFSET )  // Size 1 bytes
            // signature controller offset
//#define CMP_BDOS_L23_IP_VER_OFF                (45 + L3_COMMON_FLD_IP_VER_OFFSET + L3_KEY_OFFSET )  // Size 1 byte ( 4 bit phase , 4 bit ipv4/ipv6 )













// General Decoder HWD_REG9 Offsets
#define L2_BCAST                    0
#define L2_MCAST                    1
#define L2_CONTROL                  2
#define L2_MORE_THAN_3_VLAN_TAGS    12
#define L2_MACinMAC                 18
#define L2_ARP                      19
#define L2_PPPoE                    20
#define L2_MORE_THAN_4_MPLS_LABELS  27
#define L3_IPv4_TTL_EXP             28
#define L3_IPv4_INV_PCKT_OR_HDR_LEN_CHECK_OFF 31



#define GLOBAL_RTM_IN_TOP_MODIFY 0


//#define CTX_LINE_DUMMY_FOR_TCAM           3





#define CTX_STR                           2
#define CTX_LINE_TCAM                     3
#define CTX_LINE3_TCAM                    1

#define TREG_DUMMY_OFF           0;


#define TREG_DNS_L4SRCDST_TMP_BASE             64
//look aside context line 96...128 32 byte
#define ALST_RES_OFF                   124
#define ALST_RES_TMP_OFF               92
#define POL_LKSD_RES_OFF               96


#define DNS_FIRST_HASH_STR                          69
#define DNS_SEC_HASH_STR                            70

#define DNS_FIRST_HASH_P1_STR                       101

#define TREG_TCAM_LKSD_RESULT_DNS_OFF_48B   64
#define TREG_TCAM_CTX_REG_EXP_KEY32         96
#define CTX_DNS_LINE                        3
#define CTX_UP96B_LINE                      4
#define CTX_DNS_KEY_STR                     2
#define KMEM_DNS_CTX_LINE_SIZE              32


#define TREG_TCAM_LKSD_RESULT_DNS_OFF_64B      96
#define TREG_RESULT_DNS_OFF_64B                0x70
#define DNS_SUMMARY_RESULT_OFF                 96  /* 18 byte of accamulated  result 2system + 3 bit masks */
#define TREG_DNS_TCAM_TMP_RES                  88
#define TREG_RESULT_DNS_CURR_OFF               112 /* 16 byte current  result */
#define TREG_TCAM_LKSD_RESULT_DNS_OFF_REG_EXP_64B      80
#define TREG_IND_REG_DNS_OFF_64B               108

#define TREG_TCAM_LKSD_RESULT_DNS_OFF2_64B     32

#define TREG_SHIFT_BASE_OFFSET                 64

#define TREG_DNS_KEY64_TMP_BASE                104

#define KMEM_MAIN_CTX_LINE_OFF                 128 /*TREG_BDOS_RES_OFF + 32*/

#define KMEM_DNS_CTX_LINE_SIZE                 32

#define DNS_REG_EXP_RES_STR                    70

#define TREG_DNS_L4SRCDST_TMP_BASE             64

#define DNS_L4PORT_DET_STR                     71
#define DNS_ENTRY_ID_OFF                       2

/////////////////////////////////////////////////////////////////////
// Dummy Structure 81 - used to get the result of the TCAM lookup in TOPresolve, when performing the lookup with destination == CONTEXT (!= TREG, this is the our case).
/////////////////////////////////////////////////////////////////////
#define DNS_TABLE_INDEX_STR                    81

//#define DNS_REG_EXP_RES_STR                    71

#define REG_EXP_32_KEY_FIRST_PART              0
#define REG_EXP_32_KEY_FIRST_PART_SIZE         32
#define REG_EXP_32_KEY_SEC_PART                32
#define REG_EXP_32_KEY_SEC_PART_SIZE            8



//#define TREG_TCAM_LKSD_RESULT_DNS_OFF_48B      64



#define KMEM_MAIN_CTX_LINE_SIZE                4



#define TREG_DNS_KEY64_TMP_BASE                104


#define ALST_KMEM_PROF_OFF                     45
#define POL_KMEM_PROF_OFF                     44
#define __LOOK_ASIDE_POC__

#define POLICY_PROFILE_ID                     2
#define ALST_PROFILE_ID                       0
#define DNS_PROFILE_ID                        3

#define DNS_ZERO_RES_STRUCT                   75
//current key layout byte 3-2 ( byte3 0 , byte2 BDOS cntr phase , byte 1 DNS_CNTR , byte 0 BDOS cntr
#define DNS_CNT_KEY_OFF     1
#define BDOS_PHASE_KEY_OFF  2
#define BDOS_CNTR_KEY_OFF   0
#define BDOS_CNTR_KEY_BASE  0
//#define CMP_POLICY_CFG_PHASE_OFF 0


//#define CMP_POLICY_CFG_PHASE_OFF 40
//#define CMP_POLICY_BDOS_CFG_PHASE_OFF 42

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                           BCAM8
///////////////////////////////////////////////////////////////////////////////////////////////////////

//32 port entries
#define FFT_BCAM8_GRP                  6 //32 entries
#define TCP_VALID_COMBINATION_GRP      2 //9 entries
#define L4_HDR_TYPES_COMBINATION_GRP   3 //10 entries


////////////////////////////////
//          BCAM32
////////////////////////////////
//dns ports configuration 32 entries
#define DNS_PORTS_CONFIGURATION_GRP    0 //16 bit per group
#define IPv6_SUBHEAD_ID_GRP            1 //6  entries



#define TCAM64_BDOS_GLOB_CNTR_GRP      2

#define DNS_1_HASH_P1_STR 101
#define DNS_2_HASH_P1_STR 102
#define DNS_3_HASH_P1_STR  103

#define TX_VLAN_BASE 0xA04
#define RX_VLAN_BASE 0x9C4

//bit 19 PORT_DATA3
#define  SRAM_HAS_DTRUNK_PORT_OFF 19
#define LACP_TYPE_BYPASS_STAT 0x80
#define ARP_TYPE_BYPASS_STAT  0x40
#define MIP_OFF               0x20
#define LOCAL6                0x10


/////////////////////////////////////////////////////////////////////
// Structure 105 - Cores distribution
/////////////////////////////////////////////////////////////////////
#define  CORE2IP_STR          105
#define  CORE2IP_KEY_SIZE     1
#define  CORE2IP_RESULT_SIZE  8
#define  CORE2IP_IP_OFF       4   // 4 bytes

#define RTPC_DPE_METADATA_TYPE_OFFSET  12
#define RTPC_DPE_ACTION_OFFSET   10
#define RTPC_DPE_FEATURE_OFFSET  7

#define RTPC_STANDART_ETH_TYPE   0x8100
#define RTPC_DPE_ACTION_DROP     0
#define RTPC_DPE_ACTION_BYPASS   (1<<RTPC_DPE_ACTION_OFFSET)
#define RTPC_DPE_ACTION_PROCESS  (3<<RTPC_DPE_ACTION_OFFSET)
#define RTPC_DPE_FEATURE_LEGIT            0
#define RTPC_DPE_FEATURE_BLACK            (1<<RTPC_DPE_FEATURE_OFFSET)
#define RTPC_DPE_FEATURE_WHITE            (2<<RTPC_DPE_FEATURE_OFFSET)
#define RTPC_DPE_FEATURE_SYN_PROTECT      (3<<RTPC_DPE_FEATURE_OFFSET)
#define RTPC_DPE_FEATURE_SYN_CHALLENGE    (4<<RTPC_DPE_FEATURE_OFFSET)
#define RTPC_DPE_FEATURE_SYN_FAIL         (5<<RTPC_DPE_FEATURE_OFFSET)
#define RTPC_DPE_FEATURE_BDOS             (6<<RTPC_DPE_FEATURE_OFFSET)
#define RTPC_DPE_FEATURE_TF               (7<<RTPC_DPE_FEATURE_OFFSET)
#define RTPC_DPE_METADATA_RTPC            (1<<RTPC_DPE_METADATA_TYPE_OFFSET) //define metadata feature type RTPC
#define RTPC_MATCH_SYN_CHALLENGE  (RTPC_DPE_FEATURE_SYN_CHALLENGE | RTPC_DPE_ACTION_DROP | RTPC_DPE_METADATA_RTPC);


#define L4SRCPRT_STR 106
#define L4DSTPRT_STR 107

#define  L4RTPC_KEY_SIZE     2


#define TX_COPY_IN_VID 10
#define TX_COPY_SYN_IN_VID 24


#endif // _XAD_COMMON_H_
