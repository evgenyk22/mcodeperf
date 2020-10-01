/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Rsv.h
*
*  Usage:         xad.Rsv.asm include file
*
*******************************************************************************/


#ifndef _XAD_RSV_H_;
#define _XAD_RSV_H_;

// by - 1 byte
// ux - 2 bytes
// uq - 4 bytes

// Global & Local variables:

// The following 2 bytes must remain adjacent since they are written together
#define byCtrlMsgPrs0               UREG[2].byte[0];      //1 byte, holds 1st byte of control bits in message from TOPparse to TOPresolve
#define byCtrlMsgPrs1               UREG[2].byte[1];      //1 byte, holds 2nd byte of control bits in message from TOPparse to TOPresolve

//directly mapped from topparse
#define uqFramePrsReg               UREG[5]
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


#define byCtrlMsgRsv0               CTX_REG[5].byte[0];
#define byCtrlMsgRsv1               CTX_REG[5].byte[1];
#define byCtrlMsgRsv2               CTX_REG[5].byte[2];
#define byCtrlMsgRsv3               CTX_REG[5].byte[3];
 

#define byPolicyValidBitsReg        UDB.byte[2];
#define byGlobalStatusBitsReg       UDB.byte[3];

#define byTempCondByte              UREG[1].byte[0];
#define byTempCondByte1             UREG[1].byte[1];
#define byTempCondByte2             UREG[1].byte[2];
#define byTempCondByte3             UREG[1].byte[3];

//#define uqBdosTempReg        UREG[2];          //4 bytes


#define uqTmpReg1                   UREG[10] //UREG[3];
#define uqTmpReg2                   UREG[13] //UREG[4];
#define uqTmpReg3                   CTX_REG[6] // UREG[5];
#define uqTmpReg4                   UREG[7]  //UREG[6];
#define uqTmpReg5                   CTX_REG[4];

#define uqTmpReg6                   SREG_HIGH[11];
#define uqTmpReg7                   SREG_HIGH[12];
#define uqTmpReg8                   SREG_HIGH[13];

#define byTemp3Byte0                 uqTmpReg8.byte[0];
#define byTemp3Byte1                 uqTmpReg8.byte[1];
#define byTemp3Byte2                 uqTmpReg8.byte[2];
#define byTemp3Byte3                 uqTmpReg8.byte[3];


#define uqTmpReg9                   SREG_HIGH[14];
#define uqTmpReg10                  UREG[14];
// UREGs 8 & 9 are saved for statistics result

#define uqTmpReg11                 CTX_REG[5] ;



#define bytmp0                      UREG[11].byte[0];
#define bytmp1                      UREG[11].byte[1];
#define bytmp2                      UREG[11].byte[2];

#define byCtrlMsgPrs2Rsv2           UREG[11].byte[3]; //1 byte, holds 3rd byte of control bits in message from TOPparse to TOPresolve, and from TOPresolve to TOPModify

#define uxEthTypeMetaData           UREG[12].byte[0] ; //2 bytes for the ethertype before send to MDF for metadata
#define byRTPCFlags                 UREG[12].byte[2] ; //5 bits for RTPC match filters
#define byRTPCPolicyFlags           UREG[12].byte[3] ; //5 bits for RTPC match policies

//#define RTPC_IS_RTPC_MARKED  7;  
#define RTPC_IS_ENABLED_BIT         byTempCondByte3.bit[2]; //if RTPC enabled it is marked with default or other
#define RTPC_IS_DOUBLE_COUNT_BIT    byTempCondByte3.bit[3];


#define uxTmpReg1                   CTX_REG[2].byte[0];
#define uxTmpReg2                   CTX_REG[2].byte[2];
                            

//#define             UREG[15].byte[0]; //1 byte, holds the action that should be performed on the frame
#define byPolicyOOSActionReg        UREG[15].byte[1]; //1 byte uses temporary as storage of OOS action set

// The following 2 bytes must remain adjacent since they are read\written together

#define uqGlobalStatusBitsReg       MEM_REG[12];

#define uxGlobalPolIdx              MEM_REG[13].byte[0];  // 2 bytes policy Id
#define byFcfgTmpStorage            MEM_REG[13].byte[2];
#define bySigNumTmpStorage          MEM_REG[13].byte[3];

#define uqRSV_TempCTX_REG6          MEM_REG[14];          // uqRSV_TempCTX_REG6 - will be used for several cases in well defined blocks using vardef in the code
#define uqGlobalSignaBitsReg        MEM_REG[15];

#define HW_OBS                      KMEM_BASE0

#define BDOS_SIG31_CFG_TSTORE        CTX_REG[0]                  
// Mask registers

LDREG MREG[0],          0x0FFFFFFF;
#define MASK_0FFFFFFF   MREG[0];

LDREG MREG[1],          0x00000003;
#define MASK_00000003   MREG[1];

LDREG MREG[2],          0x00000007;
#define MASK_00000007   MREG[2];

LDREG MREG[3],          0x03FFFFFF;
#define MASK_003FFFFF   MREG[3];

LDREG MREG[4],          0x0000FFFF;
#define MASK_0000FFFF   MREG[4];

LDREG MREG[5],          0x000000FF;
#define MASK_000000FF   MREG[5];

LDREG MREG[6],          0x000007FF;
#define MASK_000007FF   MREG[6];

LDREG MREG[7],          0x000003FFF;
#define MASK_00003FFF   MREG[7];


// Host configuration registers
#define RTPC_FILTER_EN      MREG[11];     //0-4 for the 5 filters, 5-9 for policy rtpc

#define SYN_PROT_TS_LIMITS_MREG    MREG[13];  // Reserved for SYN Protection: SYN timestamp validation Min (MREG[15].byte[0])\Max (MREG[15].byte[1]) values
LDREG   SYN_PROT_TS_LIMITS_MREG,   0xFF00;    // Default value - allow all (if not initialized by the driver)

#define GC_CNTRL_1_MREG     MREG[15];

#define GC_CNTRL_2_MREG     MREG[14];

#define TRAFFIC_ENGINE_NUMBER     MREG[12]; // Indicate number of currently availabled traffic engines cores ( NP5 )



//***********************************************************
//* Application sepcific defines
//*
//* 
#define bitRSV_isRoutingMode byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ROUTING_EN_BIT];


//***********************************************************
//* Policy  offsets   from xad.common
//*
//* 
#define POLICY_ID_BYTE0               0
#define POLICY_OOS_BIT                POLICY_CNG_OOS_BIT;    //OOS+BDOS4 8 bits
#define POLICY_ACTION_BIT             POLICY_CNG_ACTION_BIT; // Action 2 bit
#define POLICY_OOS_PT_STAT_BIT        POLICY_CNG_OOS_TP_BIT; // 1 bit Policy OOS PT status  , disable per policy 
#define POLICY_OOS_PT_STAT_BIT_MASK   (1<<POLICY_OOS_PT_STAT_BIT); // defines PT bit mask

#define POLICY_ID_BYTE1               1;
#define POLICY_ID_BYTE2SAMPL_STAT_BIT        (POLICY_CNG_OOS_SAMPL_BIT - 8); //1 bit sampling status
#define POLICY_ID_BYTE2ACTIVATE_THR_STAT_BIT (POLICY_CNG_OOS_ACTIV_BIT - 8); //1 bit Activation Threshold status 

// Policy context register definition
#ifdef __comment__
#define CTX_POLICY_WORD_0             8 // contains POLICY_HW_ID
#define CTX_POLICY_WORD_1             9 // contains POLICY_CONTROL & POLICY_USER_ID
#define CTX_POLICY_USER_ID_OFF        (POLICY_USER_ID_OFF - POLICY_CONTROL_OFF) // define offset user Is in bytes
#define CTX_POLICY_WORD_2            10 // contains POLICY_CNG_MNRL_SIG
#define CTX_POLICY_WORD_3            11 // contains POLICY_CNG_BDOS_SIG
#define CTX_POLICY_WORD_4            12 // contains POLICY_CNG_BDNS_SIG
#define CTX_POLICY_WORD_5            13 // contains POLICY_CNG_SIG0_HW_ID 2B and POLICY_SIG_CONTR 2B
#define CTX_POLICY_WORD_6            14 // contains POLICY_SIG_CONTR
#define CTX_POLICY_WORD_7            15 // contains POLICY_BLWL_MATCH
#endif 
//Policy configuration defines instead CTX . However still save CTX defines , may be use it for secondary lookaside
#define  POLICY_HW_ID_OFF          2 //size 2
#define  POLICY_CTRL_OFF           4 //size 2
#define  POLICY_UID_OFF            6 //size 2
#define  POLICY_MAN_OFF            8 //size 4
#define  POLICY_BDOS_OFF           8  //size 4
#define  POLICY_DNS_OFF            8  //size 4
#define  POLICY_SIG_HWID_OFF       20 //size 2

#define  RMEM_POLICY_WORD_1        POLICY_CTRL_OFF // contains POLICY_CONTROL & POLICY_USER_ID
#define  RMEM_POLICY_WORD_3        POLICY_BDOS_OFF 

/* ... too mach .... */

//this is actually not policy information , used temporary as storage of OOS action set
//moved to the special register byPolicyOOSActionReg, since POLICY_APPL_ID_BIT definition
#define OOS_ACT_SAMPL                       32;
#define POLICY_ID_BYTE3_OOS_ACT_BIT         24;  //8 bit BYPASS , 2 CPU , DROP , PT , SAMPLE
#define OOS_ACT_DROP                        16;  // match action DROP - high priority
#define OOS_ACT_BYPASS                       8;  // match action BYPASS - less then drop priority
#define OOS_ACT_2CPU                         4;  // match action or sampling less then bypass priority 
#define OOS_ACT_NBYPASS                      2;  // activation threshold low priority
#define OOS_POLICY_PT_BYPASS_BIT             0;  // least bit is used to store PT for bypass action

#define POLICY_ID_BYTE3_OOS_ACT_OFF          0;  //8 bit BYPASS , 2 CPU , DROP , PT 


//top resolve global status 8 bit
#define GRE_KEEPALIVE_BIT            0; //1bits
//#define POLICY_CONT_ACT_BIT          1; //1bits is free
#define SRC_100G_BIT                 2; //1bit, indicate policy OOS Packet Trace status for drop action
#define RTM_RECIVED_IND_BIT          3; //1bit , indicate that recive counter per policy has been already incremented                                        // 1 - not yet , 0 
#define RTM_RECIVE_DROP_IND_BIT      4; //1 bit size 0 - drop counter , 1 - recive
#define POLICY_LOOP_IND_BIT          5; //1bis 
#define POLICY_PHASE_BIT             6; //1bis 
#define ALIST_SAMPL_BIT              7; //1bis 

// Message header
#define LAST_KEY_BIT  5;
#define STRUC_NUM_BIT 6;
#define LKP_MSG_BIT   12;
  #define KEY_IS_MSG 0;
  #define KEY_IS_LKP 1;
#define KEY_IS_VALID_BIT 13;

//#define RSV_MSG_HDR       ( ((MSG_SIZE - 1)>> 3)   | (1<<4) |  (MSG_STR << STRUC_NUM_BIT)   | (KEY_IS_MSG << LKP_MSG_BIT) | (1 << KEY_IS_VALID_BIT) | (((MSG_SIZE - 1)>> 1)<<14) );
//#define RSV_MSG_HDR_LAST  ( RSV_MSG_HDR | (1<<LAST_KEY_BIT) );


#define RSV_FFT_VID_LKP_SIZE 1;
#define LKP_INVALID (1 << HREG_KEY_BIT); // used only to make place holder in KMEM
#define RSV_FFT_VID_LKP_HDR             (LKP_VALID   | ( SRC2_FFT_VID_START_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_VID_LKP_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_VID_LKP_INVALID_HDR     (LKP_INVALID | ( SRC2_FFT_VID_START_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_VID_LKP_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

#define RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN 0x10
#define RSV_RX_COPY_PORT_LKP_HDR        (LKP_VALID   | ( SRH2_RX_COPY_INFO_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_VID_LKP_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

#define RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE 4
#define RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN 0x10;
#define RSV_ROUTE_SYN_LKP_SIZE            3;

#define RSV_ROUTING_LKP_KEY_SIZE_KMEM_ALIGN 0x10;

#define RSV_FFT_SYN_LKP_HDR             (LKP_VALID   | ( SRH2_FFT_SYN_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_ALST_LKP_HDR             (LKP_VALID   | ( SRH2_FFT_ALST_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

#define RSV_ROUTE_ALST_LKP_HDR             (LKP_VALID   | ( SRH2_ROUTE_ALST_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

#define RSV_ROUTE_2HOST_LKP_HDR            (LKP_VALID   | ( SRH2_ROUTE_2HOST_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

#define RSV_ROUTE_SYN_LKP_HDR             (LKP_VALID   | ( SRH2_ROUTE_SYN_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_ROUTE_SYN_LKP_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

//#define RSV_FFT_TP_LKP_HDR              (LKP_VALID   | ( SRH2_FFT_TP_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_TX_LKP_HDR              (LKP_VALID   | ( SRH2_FFT_TX_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_VLAN_TP_ONLY_LKP_HDR    (LKP_VALID   | ( SRH2_FFT_TP_ONLY_VLAN_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_HOST_TX_LKP_HDR             (LKP_VALID   | ( SRH2_FFT_FRMHOSTTX_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

/*
#define RSV_FFT_VID_LKP_HDR       ( ((RSV_FFT_VID_LKP_SIZE -1)>>3) | (1<<4) |  (OUT_VID_STR << STRUC_NUM_BIT)  | (KEY_IS_LKP << LKP_MSG_BIT) | (1 << KEY_IS_VALID_BIT) | ((RSV_FFT_VID_LKP_SIZE - 1) << 14));
#define RSV_FFT_VID_LKP_HDR_LAST  ( RSV_FFT_VID_LKP_HDR | (1<<LAST_KEY_BIT) );
*/

#define RSV_ROUTING_TABLE_LKP_SIZE 2;
#define RSV_ROUTING_TABLE_LKP_HDR     (LKP_VALID | ( SRC2_ROUTING_TABLE_START_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_ROUTING_TABLE_LKP_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

#define RSV_MSG_SIZE 96

#define RSV_MSG_HDR   (MSG_VALID | (MSG_STR << HREG_STR_NUM_BIT)  | (((RSV_MSG_SIZE - 1  ) >> 4) << HREG_MSG_SIZE_BIT));
// #define SC_CK_KEY_CUR_MREG    MREG[14];
// #define SC_CK_KEY_PREV_MREG   MREG[13];
// #define SC_CK_STMP_MREG       MREG[12];

// #define SYN_COOKIE_CONST_KEY_VAL 0x622B70F5;


// Learn Headers:
#define ADD_OOS_LEN 14;//((TCP_OOS_KEY_SIZE + TCP_OOS_RES_SIZE - 1) >> 2 + 1);
#define OOS_ADD_HEADER   (((ADD_OOS_LEN) << LRNIF_LRN_INFO_LEN_BIT) | (TCP_OOS_STR << LRNIF_STR_NUM_BIT ) | (LRNIF_ADD_ENTRY << LRNIF_CMD_BIT) | (LRNIF_CREATE << LRNIF_OVERWRITE_MODE_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (1 << LRNIF_ENTRY_PROFILE_BIT) | (0 << LRNIF_UPDATE_ONLY_BIT) | (1 << LRNIF_ORDER_BIT) );

#define DEL_OOS_LEN 10;//((TCP_OOS_KEY_SIZE - 1) >> 2 + 1);
#define OOS_DEL_HEADER   (((DEL_OOS_LEN) << LRNIF_LRN_INFO_LEN_BIT) | (TCP_OOS_STR << LRNIF_STR_NUM_BIT ) | (LRNIF_DEL_ENTRY << LRNIF_CMD_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (1 << LRNIF_ENTRY_PROFILE_BIT));


// SYN Protection Learn Headers

// Authentication table add headers
#define LRN_ADD_HDR_AUTH       ( ((((SYN_PROT_AUT_LKP_SIZE  + SYN_PROT_AUT_RES_SIZE  - 1) >> 2) + 1) << LRNIF_LRN_INFO_LEN_BIT) | (1 << LRNIF_ORDER_BIT) | (SYN_PROT_AUT_STR  << LRNIF_STR_NUM_BIT) | (LRNIF_ADD_ENTRY << LRNIF_CMD_BIT) | (LRNIF_CREATE << LRNIF_OVERWRITE_MODE_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (0 << LRNIF_ENTRY_PROFILE_BIT) | (0 << LRNIF_UPDATE_ONLY_BIT) );

// Contender table add headers
#define LRN_ADD_HDR_CONT       ( ((((SYN_PROT_CONT_LKP_SIZE + SYN_PROT_CONT_RES_SIZE - 1) >> 2) + 1) << LRNIF_LRN_INFO_LEN_BIT) | (1 << LRNIF_ORDER_BIT) | (SYN_PROT_CONT_STR << LRNIF_STR_NUM_BIT) | (LRNIF_ADD_ENTRY << LRNIF_CMD_BIT) | (LRNIF_CREATE << LRNIF_OVERWRITE_MODE_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (0 << LRNIF_ENTRY_PROFILE_BIT) | (0 << LRNIF_UPDATE_ONLY_BIT) );

// Contender table delete headers
#define LRN_DEL_HDR_CONT       ( ((((SYN_PROT_CONT_LKP_SIZE - 1) >> 2) + 1) << LRNIF_LRN_INFO_LEN_BIT) | (1 << LRNIF_ORDER_BIT) | (SYN_PROT_CONT_STR << LRNIF_STR_NUM_BIT) | (LRNIF_DEL_ENTRY << LRNIF_CMD_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (0 << LRNIF_ENTRY_PROFILE_BIT) ); 


#define POLICY_ID_OFFSET  3;   //policy id 2 bytes

#define POLICY_ID_SIZE    2;   //policy is size 

#define POLICY_ACTION_OFFSET 8; //2bits

#define HW_KBS                               KMEM_BASE0;
#define COM_KBS                              KMEM_BASE1;
#define COM_HBS                              HREG_BASE1;

//Metadada message format

//4-bit METADATA INDICATION ????????????????

//Summary 32bit

//byte 0
#define MDATA_RESONE_OFF 0;// 2bit Reason
#define MDATA_FID_OFF    2;// 4-bit Feature Id
#define MDATA_ACT_OFF    4;//2-bit Decided action

//byte 1
#define MDATA_PID_OFF    8; //8-bit Policy Id
#define MDATA_PID_BYTE_OFF    1; //8-bit Policy Id

//byte 2 
#define MDATA_FIT_OFF    16; //8-bit Feature data
#define MDATA_FIT_BYTE_OFF    2; //8-bit Feature data

//byte 3
#define MDATA_RES_OFF    24; //8-bit Reserved
#define MDATA_RES_BYTE_OFF 3; 

#define ROUTE_NETSTACK_OFF 2
#define ROUTE_NETSTACK_BRMCAST_OFF     0
#define ROUTE_GRE_OFF                  1
#define ROUTE_NETSTACK_ICMPBGP_OFF     2

//ICMP or BGP was detected in TopModify
#define ROUTE_NETSTACK_INDICATION (1<<ROUTE_NETSTACK_OFF)
#define ROUTE_NETSTACK_ICMPBGP_INDICATION (1<<ROUTE_NETSTACK_ICMPBGP_OFF)

/******************************************************************************
   Loading Commands
*******************************************************************************/

// This is used for copying HW_MSG (first 16 bytes of MSG_STR) from TOPresolve to TOPmodify
#define  RSV_HW_MSG_HDR    (MSG_VALID | (MSG_STR << HREG_STR_NUM_BIT) | (((MSG_SIZE - 1  ) >> 4) << HREG_MSG_SIZE_BIT));
LdMsgHdr RSV_HW_MSG_HDR;   

// This is used for loading the HW_MSG that was copied from TOPparse to TOPresolve
LdMsgStr HW_GEN_MSG_STR; 

/*******************************************************************************/

//RTPC definitions
#define RTPC_MATCH_DEFAULT     (RTPC_DPE_FEATURE_LEGIT | RTPC_DPE_ACTION_PROCESS | RTPC_DPE_METADATA_RTPC)
#define RTPC_POLICY_EXC_DROP   (RTPC_DPE_FEATURE_LEGIT | RTPC_DPE_ACTION_DROP | RTPC_DPE_METADATA_RTPC)
#define RTPC_POLICY_EXC_BYPASS (RTPC_DPE_FEATURE_LEGIT | RTPC_DPE_ACTION_BYPASS | RTPC_DPE_METADATA_RTPC)

//RTPC ACL
#define RTPC_BLACK_LIST_LEGIT (RTPC_DPE_FEATURE_LEGIT | RTPC_DPE_ACTION_PROCESS | RTPC_DPE_METADATA_RTPC)
#define RTPC_BLACK_LIST_DROP  (RTPC_DPE_FEATURE_BLACK | RTPC_DPE_ACTION_DROP | RTPC_DPE_METADATA_RTPC)
#define RTPC_WHITE_BYPASS     (RTPC_DPE_FEATURE_WHITE | RTPC_DPE_ACTION_BYPASS | RTPC_DPE_METADATA_RTPC)
//#define RTPC_DPE_ACTION_2CPU   (2<<RTPC_DPE_ACTION_OFFSET)   ->not is use 
#define RTPC_BDOS_DROP    (RTPC_DPE_FEATURE_BDOS | RTPC_DPE_ACTION_DROP | RTPC_DPE_METADATA_RTPC)

#define RTPC_TF_DROP      (RTPC_DPE_FEATURE_TF | RTPC_DPE_ACTION_DROP | RTPC_DPE_METADATA_RTPC)
#define RTPC_BDOS_BYPASS  (RTPC_DPE_FEATURE_BDOS | RTPC_DPE_ACTION_BYPASS | RTPC_DPE_METADATA_RTPC)
#define RTPC_TF_BYPASS    (RTPC_DPE_FEATURE_TF   | RTPC_DPE_ACTION_BYPASS | RTPC_DPE_METADATA_RTPC)
#define RTPC_BDOS_SAMPLE  (RTPC_DPE_FEATURE_LEGIT | RTPC_DPE_ACTION_PROCESS | RTPC_DPE_METADATA_RTPC)
#define RTPC_TF_SAMPLE    (RTPC_DPE_FEATURE_LEGIT | RTPC_DPE_ACTION_PROCESS | RTPC_DPE_METADATA_RTPC)
#define RTPC_TF_GREEN     (RTPC_DPE_FEATURE_LEGIT | RTPC_DPE_ACTION_PROCESS | RTPC_DPE_METADATA_RTPC)
#define RTPC_TF_PROCESS   (RTPC_DPE_FEATURE_TF | RTPC_DPE_ACTION_PROCESS | RTPC_DPE_METADATA_RTPC)

#define RTPC_SYN_PRO_FAIL_DROP (RTPC_DPE_FEATURE_SYN_FAIL | RTPC_DPE_ACTION_DROP | RTPC_DPE_METADATA_RTPC)
#define RTPC_SYN_PRO_DROP      (RTPC_DPE_FEATURE_SYN_PROTECT | RTPC_DPE_ACTION_DROP | RTPC_DPE_METADATA_RTPC)

                              
#endif; // of #ifndef _XAD_RSV_H_

