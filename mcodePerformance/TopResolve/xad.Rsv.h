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
#define byCtrlMsgPrs0               UDB.byte[0];      //1 byte, holds 1st byte of control bits in message from TOPparse to TOPresolve
#define byCtrlMsgPrs1               UDB.byte[1];      //1 byte, holds 2nd byte of control bits in message from TOPparse to TOPresolve

#define byPolicyValidBitsReg        UDB.byte[2];
#define byGlobalStatusBitsReg       UDB.byte[3];

#define byTempCondByte              UREG[1].byte[0];
#define byTempCondByte1             UREG[1].byte[1];
#define byTempCondByte2             UREG[1].byte[2];
#define byTempCondByte3             UREG[1].byte[3];

#define uqBdosL4ValidBitsReg        UREG[2];          //4 bytes

#define uqTmpReg1                   UREG[3];
#define uqTmpReg2                   UREG[4];
#define uqTmpReg3                   UREG[5];
#define uqTmpReg4                   UREG[6];
#define uqTmpReg5                   UREG[7];

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

#define uqTmpReg11                  UREG[10];

#define bytmp0                      UREG[11].byte[0];
#define bytmp1                      UREG[11].byte[1];
#define bytmp2                      UREG[11].byte[2];

#define byCtrlMsgPrs2               UREG[11].byte[3]; //1 byte, holds 3rd byte of control bits in message from TOPparse to TOPresolve

// UREG[12] free

#define uxTmpReg1                   UREG[13].byte[0];
#define uxTmpReg2                   UREG[13].byte[2];


#define byFrameActionReg            UREG[15].byte[0]; //1 byte, holds the action that should be performed on the frame
#define byPolicyOOSActionReg        UREG[15].byte[1]; //1 byte uses temporary as storage of OOS action set

// The following 2 bytes must remain adjacent since they are read\written together
#define byCtrlMsgRsv0               UREG[15].byte[2]; //1 byte, holds 1st byte of control bits to put in message from TOPresolve to TOPmodify
#define byCtrlMsgRsv1               UREG[15].byte[3]; //1 byte, holds 2nd byte of control bits to put in message from TOPresolve to TOPmodify

#define uqGlobalStatusBitsReg       /*CTX_REG[0]*/MEM_REG[12];

#define uxGlobalPolIdx              /*CTX_REG[1].byte[0]*/ MEM_REG[13].byte[0];  // 2 bytes policy Id
#define byFcfgTmpStorage            /* CTX_REG[1].byte[2]*/ MEM_REG[13].byte[2];

#define uqRSV_TempCTX_REG6          MEM_REG[14] /*CTX_REG[2]*/;          // will be used for several cases in well defined blocks using vardef in the code.
#define uqGlobalSignaBitsReg        MEM_REG[15] /*CTX_REG[3]*/;

#define HW_OBS                      KMEM_BASE0


// Mask registers

LDREG MREG[0],          0x0FFFFFFF;
#define MASK_0FFFFFFF   MREG[0];

LDREG MREG[1],          0x00000003;
#define MASK_00000003   MREG[1];

LDREG MREG[2],          0x00000007;
#define MASK_00000007   MREG[2];

LDREG MREG[3],          0x00FFFFFF;
#define MASK_00FFFFFF   MREG[3];
#define MASK_24BIT      MREG[3];

LDREG MREG[4],          0x0000FFFF;
#define MASK_0000FFFF   MREG[4];

LDREG MREG[5],          0x000000FF;
#define MASK_000000FF   MREG[5];

LDREG MREG[6],          0x000007FF;
#define MASK_000007FF   MREG[6];


// Host configuration registers

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
#define POLICY_OOS_SYNACK_STAT_BIT    POLICY_CNG_OOS_SYNACK_BIT;  // 1 bit SYN-ACK allow mode
#define POLICY_OOS_SYN_ACT_BIT        POLICY_CNG_OOS_ACK_ACT_BIT; // 2 bits TCP ACK packet SYN cookie is incorrect default action
#define POLICY_OOS_PT_STAT_BIT_MASK  (1<<POLICY_OOS_PT_STAT_BIT); // defines PT bit mask

#define POLICY_ID_BYTE1               1;
#define POLICY_ID_BYTE2SAMPL_STAT_BIT        (POLICY_CNG_OOS_SAMPL_BIT - 8); //1 bit sampling status
#define POLICY_ID_BYTE2ACTIVATE_THR_STAT_BIT (POLICY_CNG_OOS_ACTIV_BIT - 8); //1 bit Activation Threshold status 

#define  POLICY_HW_ID_OFF          2 //size 2
#define  POLICY_CTRL_OFF           4 //size 2
#define  POLICY_UID_OFF            6 //size 2
#define  POLICY_MAN_OFF            8 //size 4
#define  POLICY_BDOS_OFF           8  //size 4
#define  POLICY_DNS_OFF            8  //size 4
#define  POLICY_SIG_HWID_OFF       20 //size 2
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


// Top Resolve global status 8 bit
#define MSG_4TOP_MODIFY_BIT          0; //1bits
#define POLICY_CONT_ACT_BIT          1; //1bits
#define OOS_POLICY_PT_BIT            2; //1bit, indicate policy OOS Packet Trace status for drop action
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
#define RSV_FFT_SYN_LKP_HDR             (LKP_VALID   | ( SRH2_FFT_SYN_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_ALST_LKP_HDR             (LKP_VALID   | ( SRH2_FFT_ALST_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_TP_LKP_HDR              (LKP_VALID   | ( SRH2_FFT_TP_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_TX_LKP_HDR              (LKP_VALID   | ( SRH2_FFT_TX_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_FFT_VLAN_TP_ONLY_LKP_HDR    (LKP_VALID   | ( SRH2_FFT_TP_ONLY_VLAN_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));
#define RSV_HOST_TX_LKP_HDR             (LKP_VALID   | ( SRH2_FFT_FRMHOSTTX_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));

/*
#define RSV_FFT_VID_LKP_HDR       ( ((RSV_FFT_VID_LKP_SIZE -1)>>3) | (1<<4) |  (OUT_VID_STR << STRUC_NUM_BIT)  | (KEY_IS_LKP << LKP_MSG_BIT) | (1 << KEY_IS_VALID_BIT) | ((RSV_FFT_VID_LKP_SIZE - 1) << 14));
#define RSV_FFT_VID_LKP_HDR_LAST  ( RSV_FFT_VID_LKP_HDR | (1<<LAST_KEY_BIT) );
*/

#define RSV_ROUTING_TABLE_LKP_SIZE 2;
#define RSV_ROUTING_TABLE_LKP_HDR     (LKP_VALID | ( SRC2_ROUTING_TABLE_START_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_ROUTING_TABLE_LKP_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT));


#define RSV_MSG_HDR   (MSG_VALID | (MSG_STR << HREG_STR_NUM_BIT)  | (((MSG_SIZE - 1  ) >> 4) << HREG_MSG_SIZE_BIT));
// #define SC_CK_KEY_CUR_MREG    MREG[14];
// #define SC_CK_KEY_PREV_MREG   MREG[13];
// #define SC_CK_STMP_MREG       MREG[12];

// #define SYN_COOKIE_CONST_KEY_VAL 0x622B70F5;


// Learn Headers:
#define ADD_LEN ((TCP_OOS_KEY_SIZE + TCP_OOS_RES_SIZE) >> 2);
#define OOS_ADD_HEADER   (((ADD_LEN) << LRNIF_LRN_INFO_LEN_BIT) | (TCP_OOS_STR << LRNIF_STR_NUM_BIT ) | (LRNIF_ADD_ENTRY << LRNIF_CMD_BIT) | (1 << LRNIF_EN_MCODE_BIT) | (L_LRN_CREATE_OR_UPDATE_OOS_ENTRY << LRNIF_INIT_PC_BIT) | (LRNIF_CREATE << LRNIF_OVERWRITE_MODE_BIT) | (0 << LRNIF_ENTRY_PROFILE_BIT) | (0 << LRNIF_UPDATE_ONLY_BIT) | (1 << LRNIF_ORDER_BIT) );

#define DEL_LEN ((TCP_OOS_KEY_SIZE) >> 2);
#define OOS_DEL_INST_0_HEADER   (((DEL_LEN) << LRNIF_LRN_INFO_LEN_BIT) | (TCP_OOS_STR << LRNIF_STR_NUM_BIT ) | (LRNIF_DEL_ENTRY << LRNIF_CMD_BIT) | (1 << LRNIF_EN_MCODE_BIT) | (L_LRN_DELETE_OOS_ENTRY_INST_0 << LRNIF_INIT_PC_BIT) );
#define OOS_DEL_INST_1_HEADER   (((DEL_LEN) << LRNIF_LRN_INFO_LEN_BIT) | (TCP_OOS_STR << LRNIF_STR_NUM_BIT ) | (LRNIF_DEL_ENTRY << LRNIF_CMD_BIT) | (1 << LRNIF_EN_MCODE_BIT) | (L_LRN_DELETE_OOS_ENTRY_INST_1 << LRNIF_INIT_PC_BIT) );


// SYN Protection Learn Headers

// Authentication table add headers
#define LRN_ADD_HDR_AUTH       ( ((((SYN_PROT_AUT_LKP_SIZE  + SYN_PROT_AUT_RES_SIZE  - 1) >> 2) + 1) << LRNIF_LRN_INFO_LEN_BIT) | (1 << LRNIF_ORDER_BIT) | (SYN_PROT_AUT_STR  << LRNIF_STR_NUM_BIT) | (LRNIF_ADD_ENTRY << LRNIF_CMD_BIT) | (LRNIF_CREATE << LRNIF_OVERWRITE_MODE_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (0 << LRNIF_ENTRY_PROFILE_BIT) | (0 << LRNIF_UPDATE_ONLY_BIT) );

// Contender table add headers
#define LRN_ADD_HDR_CONT       ( ((((SYN_PROT_CONT_LKP_SIZE + SYN_PROT_CONT_RES_SIZE - 1) >> 2) + 1) << LRNIF_LRN_INFO_LEN_BIT) | (1 << LRNIF_ORDER_BIT) | (SYN_PROT_CONT_STR << LRNIF_STR_NUM_BIT) | (LRNIF_ADD_ENTRY << LRNIF_CMD_BIT) | (LRNIF_CREATE << LRNIF_OVERWRITE_MODE_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (0 << LRNIF_ENTRY_PROFILE_BIT) | (0 << LRNIF_UPDATE_ONLY_BIT) );

// Contender table delete headers
#define LRN_DEL_HDR_CONT       ( ((((SYN_PROT_CONT_LKP_SIZE - 1) >> 2) + 1) << LRNIF_LRN_INFO_LEN_BIT) | (1 << LRNIF_ORDER_BIT) | (SYN_PROT_CONT_STR << LRNIF_STR_NUM_BIT) | (LRNIF_DEL_ENTRY << LRNIF_CMD_BIT) | (0 << LRNIF_EN_MCODE_BIT) | (0 << LRNIF_ENTRY_PROFILE_BIT) ); 


#define POLICY_ID_OFFSET  3;   

#define POLICY_ID_SIZE    2;   //policy id size in bytes

#define POLICY_ACTION_OFFSET  (POLICY_ID_OFFSET + POLICY_ID_SIZE)
#define POLICY_ACTION_SIZE    1 // one byte is enough (only 2 bits are needed)

#define POLICY_USER_ID_OFFSET  (POLICY_ACTION_OFFSET + POLICY_ACTION_SIZE)
#define POLICY_USER_ID_SIZE    2 // 2 bytes are enough (only 10 bits are needed)
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


/******************************************************************************
   Loading Commands
*******************************************************************************/

// This is used for copying HW_MSG (first 16 bytes of MSG_STR) from TOPresolve to TOPmodify
#define  RSV_HW_MSG_HDR    (MSG_VALID | (MSG_STR << HREG_STR_NUM_BIT) | (((MSG_SIZE - 1  ) >> 4) << HREG_MSG_SIZE_BIT));
LdMsgHdr RSV_HW_MSG_HDR;   

// This is used for loading the HW_MSG that was copied from TOPparse to TOPresolve
LdMsgStr HW_GEN_MSG_STR; 

/*******************************************************************************/

#endif; // of #ifndef _XAD_RSV_H_

