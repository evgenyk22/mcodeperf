/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Mdf.h
*
*  Usage:         xad.Mdf.asm include file
*
*******************************************************************************/

#ifndef _XAD_MDF_H_;
#define _XAD_MDF_H_;

// by - 1 byte
// ux - 2 bytes
// uq - 4 bytes

// Global & Local variables:
#define SYN_COOKIE_CONST_KEY_VAL       0x622B70F5;

#define byActionReg        UDB.byte[0];

// The following 3 bytes must remain adjacent since they are written together
#define byCtrlMsgMdf0      UDB.byte[1]; // Size 1, holds control bits in message from TOPresolve
#define byCtrlMsgMdf1      UDB.byte[2]; // Size 1, holds 2nd byte of control bits in message from TOPresolve
#define byCtrlMsgMdf2      UDB.byte[3]; // Size 1, holds 3rd byte of control bits in message from TOPresolve

#define uqTempCondReg      UREG[1];
#define byTempCondByte1    UREG[1].byte[0];
#define byTempCondByte2    UREG[1].byte[1];
#define byTempCondByte3    UREG[1].byte[2];
#define byTempCondByte4    UREG[1].byte[3]; // treat this as a free register - it is used only at the end of the code execution of TOPmodify, therfore most of the time can be used for other purposes.

#define uqTmpReg1          UREG[2];
#define uqTmpReg2          UREG[3];
#define uqTmpReg3          UREG[4];
#define uqTmpReg4          UREG[5];
#define uqTmpReg5          UREG[6];
#define uqTmpReg6          UREG[7];

#define uqTmpReg8         MEM_REG[11];
#define uqTmpReg7         MEM_REG[12];
#define uqTmpReg9         MEM_REG[13];
#define uqTmpReg10        MEM_REG[14];

// UREGs 8 & 9 are saved for statistics result

#define bytmp1             UREG[10].byte[0];
#define bytmp2             UREG[10].byte[1];
#define bytmp3             UREG[10].byte[2];
#define bytmp4             UREG[10].byte[3];

#define uxTmpReg1          UREG[11].byte[0]; // 2 bytes
#define uxTmpReg2          UREG[11].byte[2]; // 2 bytes

#define uqZeroReg          UREG[12];         // 4 bytes, used for zeroing fields in the packet, zeroed automatically for every frame by the HW so no need to do it manually

// UREG[13..14] free
#define byDstPortReg       UREG[15].byte[0]; // TODO: Not used. remove from code
#define byInfSrcReg        UREG[15].byte[1]; // ##TODO_OPTIMIZE: AmitA: this byte is not used for bitwize conditional tests, therefore it can be moved to another register and thus save a byte for use in bitwise register.


/* As OAM_RELEASED_BUFFER_PTR is not used for its purpose, it is a 16 bits RW register,
   and it is not cleared between frames, it will be used as a register that remembers that sequence number - uxMDF_IPv4HeaderIdentification. */
VarDef regtype uxMDF_IPv4HeaderIdentification OAM_RELEASED_BUFFER_PTR;


// Mask registers

LDREG MREG[0],             0x0000FFFF;
#define MASK_0000FFFF      MREG[0];

LDREG MREG[1],             0x000000FF;
#define MASK_000000FF      MREG[1];

LDREG MREG[2],             0x0000001F;
#define MASK_0000001F      MREG[2];

LDREG MREG[3],             0x00000003;
#define MASK_00000003      MREG[3];

LDREG MREG[4],             0x00000007;
#define MASK_00000007      MREG[4];

LDREG MREG[5],             0x00000002;
#define MASK_00000002      MREG[5];

LDREG MREG[6],             0x0000000F;
#define MASK_0000000F      MREG[6];

LDREG MREG[7],             0x0000003F;
#define MASK_0000003F      MREG[7];

#define NP_NUM               MREG[8];
// Host configuration registers

//Modify control register-2 copy port vlan
// SYN COOKIE timestamp
#define SC_CK_STMP_MREG       MREG[9];

// SYN_COOKIE Key for odd phase
#define SC_CK_KEY_P1_MREG     MREG[10];

// SYN_COOKIE Key for even phase
#define SC_CK_KEY_P0_MREG     MREG[11];

// control register-3 for NP numbering and traffic limit indication
LDREG MREG[12],            0x00000000;  //default
#define GC_CNTRL_MDF_3     MREG[12]; 

#define GC_CNTRL_MDF       MREG[13]; 

//Modify control register-2 copy port vlan
LDREG MREG[14],            0x40a;  //default
#define GC_CNTRL_MDF_2     MREG[14]; 

//Modify control register-1 - maximal packet size for copy port report
LDREG MREG[15],            0x40;   //default
#define GC_CNTRL_MDF_1     MREG[15]; 



//***********************************************************
//* Application sepcific defines
//*
//* 
#define bitMDF_isRoutingMode byCtrlMsgMdf1.bit[MSG_CTRL_TOPRSV_1_ROUTING_EN_BIT];

#define  bitMDF_isCAUIport byCtrlMsgMdf1.bit[MSG_CTRL_TOPPRS_1_L3_TUNNEL_EXISTS_BIT];
// MSS mapping table

// 8 Ranges
#define MSS_RANGE_0_MIN        64;      // 0  64
#define MSS_RANGE_1_MIN        256;     // 1  0
#define MSS_RANGE_2_MIN        512;     // 2  0
#define MSS_RANGE_3_MIN        536;     // 2  24
#define MSS_RANGE_4_MIN        1024;    // 4  0
#define MSS_RANGE_5_MIN        1440;    // 5  160
#define MSS_RANGE_6_MIN        1460;    // 5  180
#define MSS_RANGE_7_MIN        1500;    // 5  220

#define MSS_RANGE_0_JUMBO_MIN  64;      // 0  64
#define MSS_RANGE_1_JUMBO_MIN  512;     // 1  0
#define MSS_RANGE_2_JUMBO_MIN  536;     // 2  0
#define MSS_RANGE_3_JUMBO_MIN  1024;    // 2  24
#define MSS_RANGE_4_JUMBO_MIN  1440;    // 4  0
#define MSS_RANGE_5_JUMBO_MIN  1460;    // 5  160
#define MSS_RANGE_6_JUMBO_MIN  4312;    // 5  180
#define MSS_RANGE_7_JUMBO_MIN  8960;    // 5  220

#define MSS_DEFAULT_CODE       3;
#define MSS_DEFAULT_RANGE      MSS_RANGE_2_MIN;


// TTL and HOP Limit for Generated Syn Cookie:
#define SYN_COOKIE_TTL_VAL       65;
#define SYN_COOKIE_WINDOW_SIZE   1460;
#define SYN_COOKIE_URG_PTR       0;



// Protocol Pointers missing in network.h:
#define TCP_WINDOW_OFF       14;
#define TCP_URG_POINTER_OFF  18;

#define METADATA_HIGH_OFFS   (ETH_DA_OFF +  2);
#define METADATA_LOW_OFFS    ETH_DA_OFF /* 0*/;

#define HOST_METADATA_PROT_OFF   ETH_PTOT2_OFF;
#define HOST_METADATA_VAL_OFF    ETH_VID2_OFF;

/* FFT_VID_STR Result Format */
#define MDF_VLAN_TX_OFF             2;  // 2 byte Self port TX VLAN; Used for SYN challenge packets
#define MDF_VLAN_TP_AND_BYPASS_OFF  4;  // 2 byte Packet trace vlan
#define MDF_VIF_TX_VLAN_OFF         6;  // 2 byte FFT/SFT TX VLAN
#define MDF_VLAN_TP_ONLY_OFF        MDF_VLAN_TP_AND_BYPASS_OFF;  // 2 byte VLAN for TP only
#define MDF_VIF_INF_OFF             8;  // 1 byte VIF id; Outgoing VIF. ##AMIT_GUY: in routing mode this will not work, as the OUT_VID table may not hold correct values in it. this means that the per-vif counter will not gold correct value.

#define MDF_FFT_TX_COPY_INFO_OFF    11; // 4 bytes TX copy information
#define MDF_SMAC_LOW_OFF    9; // 32 byte Source MAC; Is needed to avoid base MAC configuration for TOPmodify
#define MDF_SMAC_HIGH_OFF  13; // 6 byte Source MAC high part; Is needed to avoid base MAC configuration for TOPmodify
#define MDF_DMAC_LOW_OFF   15; // 6 byte Destination MAC
#define MDF_DMAC_HIGH_OFF  19  // 2 byte Destination MAC high offset
#define MDF_VLAN_OFF       21; // 2 byte VLAN
#define MDF_VLAN_CONF_OFF  23; // 1 byte VLAN configuration: 0 - VLAN value; 1 - untagged; 2 - Any
#define MDF_MOD_OP_OFF     24; // 1 byte Mode operation: 1 - "routing"; 0 - "transparent" //AmitA: mode interpetation polarity was updated to fit existiong code. In actual this does not matter as this code is deprecated. routing mode is determined by MREG and not by the FFT lookup result.


/* ROUTING_TABLE_STR Result Format */
#define MDF_ROUTING_TABLE_RSLT__CONTROLS_OFF                                          0 ; // 1 Byte
#define MDF_ROUTING_TABLE_RSLT__APP_CONTROLS_OFF                                      1 ; // 1 Byte
#define MDF_ROUTING_TABLE_RSLT__DMAC_OFF                                              2 ; // 6 Bytes
#define MDF_ROUTING_TABLE_RSLT__SMAC_OFF                                              8 ; // 6 Bytes
#define MDF_ROUTING_TABLE_RSLT__PORT_OFF                                              14; // 2 Bytes, Switch VLAN Tag (Tag Control Information includes the VLAN ID, the PCP (Priority Code Point) and the DEI (Drop Eligible Indicator)).
#define MDF_ROUTING_TABLE_RSLT__USER_VLAN_ETHERTYPE_OFF                               16; // 2 Bytes, The Ethernet protocol type that describes the VLAN that should be set when adding or changing User VLAN.
#define MDF_ROUTING_TABLE_RSLT__USER_VLAN_TAG_OFF                                     18; // 2 Bytes, User VLAN Tag.
#define MDF_ROUTING_TABLE_RSLT__TUNNEL_SIP_OFF                                        20; // 4 Bytes
#define MDF_ROUTING_TABLE_RSLT__TUNNEL_DIP_OFF                                        24; // 4 Bytes
#define MDF_ROUTING_TABLE_RSLT__TX_COPY_INFO_OFF                                      28; // 4 bytes TX copy information

#define MDF_ROUTING_TABLE_RSLT__CONTROLS__VALID_BIT                                   VALID_BIT;
#define MDF_ROUTING_TABLE_RSLT__CONTROLS__MATCH_BIT                                   MATCH_BIT;

#define MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__IS_MY_IP_BIT                            0 ; // marks that the Frame.outer_DIP is targeted to me.
#define MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__USER_VLAN_ADD_OR_CHANGE_BIT             1 ; // When 1 add or change the VLAN (upon its existence), when 0 remove the User VLAN (if exists)
#define MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__IS_GRE_ENCAP_REQUIRED_BIT               2 ;
#define MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__DEBUG_ACTIVE_TABLE_PHASE_BIT            3 ; // Used for debug to mark if the entry belongs to table of Phase 0 or 1. Informative only and does not affect the code behavior.
#define MDF_ROUTING_TABLE_RSLT__APP_CONTROLS__RESERVED_BIT                            4 ;

// structure #25 - RoutingTable
//                                                              Lookup
//                                                              Controls (bit 0:Valid, bit 4:Match)
//                                                              |
//                                                              |  App
//                                                              |  Controls
//                                                              |  (bit 0: IsMyIP)
//                                                              |  (bit 1: UserVlanAddOrChange)
//                                                              |  (bit 2: IsGreEncapReq)
//                                                              |  (bit 3: DebugInfoActiveTablePhase)
//                                                              |  (bit 4..7: Unused, should be 0).
//                                                              |  |
//                                                              |  |  DMAC         SMAC
//                                                              |  |  |            |            Port (12 LSbits are VTag). MSbits should be zero (PCP, DEI)
//                                                              |  |  |            |            |
//                                                              |  |  |            |            |    User VLAN
//                                                              |  |  |            |            |    EtherType
//                                                              |  |  |            |            |    |
//                                                              |  |  |            |            |    |
//                                                              |  |  |            |            |    |    User
//                                                              |  |  |            |            |    |    Vlan TAG (12 LSbits are VTag). MSbits should be zero (PCP, DEI).
//                                                              |  |  |            |            |    |    |
//                                                              |  |  |            |            |    |    |    Tunnel
//                                                              |  |  |            |            |    |    |    SIP
//                                                              |  |  |            |            |    |    |    |        Tunnel
//                                                              |  |  |            |            |    |    |    |        DIP
//                                                              |  |  |            |            |    |    |    |        |        Reserved/Unused
//                                                              |  |  |            |            |    |    |    |        |        |
//                                                              |  |  |            |            |    |    |    |        |        |
//                                                              V  V  V            V            V    V    V    V        V        V
//  struct_number = 25, Partition = 0, Key = 0h0001, Result = 0h00 01 020304050607 080910111213 1415 1617 1819 20212223 24252627 28293031

/* RX_COPY_PORT_STR/TX_COPY_PORT_STR Result Format */
#define COPY_PORT_STR_INFO_BYTE_OFF       1;
#define COPY_PORT_STR_BYTE_SIZE           4;

#define COPY_PORT_MATCH_BIT_OFF           0;
#define COPY_PORT_CAUI0_BITMAP_BIT        1;
#define COPY_PORT_CAUI1_BITMAP_BIT        2;
#define COPY_PORT_CAUI2_BITMAP_BIT        3;
#define COPY_PORT_CAUI3_BITMAP_BIT        4;
#define COPY_PORT_SWITCH_VALID_BIT        5;
#define COPY_PORT_TRUNK0_VALID_BIT        6;
#define COPY_PORT_TRUNK1_VALID_BIT        7;

#define COPY_PORT_SWITCH_VLAN_BIT_OFF     8;
#define COPY_PORT_SWITCH_VLAN_SIZE        12;
        
#define COPY_PORT_TRUNK0_BITMAP_BIT_OFF   24;
#define COPY_PORT_TRUNK1_BITMAP_BIT_OFF   28;
#define COPY_PORT_TRUNK_BITMAP_SIZE       4;



#define MaxBufSize             448;
#define TM_HDR_SIZE            16;

// All FMEM_BASE registers are initilized to zero for each new frame.
#define tmpFR_PTR             FMEM_BASE0;
#define L2_FR_PTR             FMEM_BASE1;
#define L3_FR_PTR             FMEM_BASE2;
#define L4_FR_PTR             FMEM_BASE3;

#define RFD_FRST_BSIZE (512-64);
#define RFD_BSIZE       512;

#define RFD_SND_2BUFF  (RFD_FRST_BSIZE+RFD_BSIZE);
#define RFD_SND_3BUFF  (RFD_FRST_BSIZE+RFD_BSIZE+RFD_BSIZE);

#define RFD_RD0_3F_MASK    MASK_0000003F
#define RFD_RD0_6_BITS        6


////////////////////////////////
//          BCAM8
////////////////////////////////


#define LINK_DISTRIBUTION_GRP 0

// Represent delta from the base link number
// this is right for HOST (103, 105) and Switch (104, 106)
// for CAUI it isn't used
// for NP peer will be used as trigger bit only
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x00, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x01, (2); //
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x02, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x03, (2); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x04, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x05, (2); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x06, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x07, (2); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x08, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x09, (2); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x0A, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x0B, (2); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x0C, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x0D, (2); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x0E, (0); // 
LDCAM BCAM8[LINK_DISTRIBUTION_GRP], 0x0F, (2); // 



////////////////////////////////
//          TM port mapping
////////////////////////////////
#ifdef __comment__

#define IF_PORT_CAUI_0              116;                 // CAUI-0
#define IF_PORT_CAUI_1              117;                 // CAUI-1
#define IF_PORT_CAUI_BASE           IF_PORT_CAUI_0;

#define IF_PORT_NET_SWITCH_0        106;                 // XLAUI-8
#define IF_PORT_NET_SWITCH_1        106;                 // XLAUI-10
#define IF_PORT_NET_SWITCH_BASE     IF_PORT_NET_SWITCH_0;

#define IF_PORT_PEER_NP_0           102;                 // XLAUI-6
#define IF_PORT_PEER_NP_1           107;                 // XLAUI-11
#define IF_PORT_PEER_NP_BASE        IF_PORT_PEER_NP_0;

#define IF_PORT_HOST_0              97                 // XLAUI-1
#define IF_PORT_HOST_1              99                 // XLAUI-3
#define IF_PORT_HOST_3              101                // XLAUI-5
#define IF_PORT_HOST_BASE           IF_PORT_HOST_0;

#endif 

#define IF_PORT_CAUI_0              116;                 // CAUI-0
#define IF_PORT_CAUI_1              117;                 // CAUI-1
#define IF_PORT_CAUI_BASE           IF_PORT_CAUI_0;


#define IF_PORT_NET_SWITCH_0_MRQ        106;                 // XLAUI-8
#define IF_PORT_NET_SWITCH_0_HTQE       104;                 // XLAUI-8

#define IF_PORT_NET_SWITCH_1        106;                 // XLAUI-10
#define IF_PORT_NET_SWITCH_BASE     IF_PORT_NET_SWITCH_0;

#define IF_PORT_PEER_NP_0           102;                 // XLAUI-6
#define IF_PORT_PEER_NP_1           107;                 // XLAUI-11
#define IF_PORT_PEER_NP_BASE        IF_PORT_PEER_NP_0;

#define IF_PORT_HOST_0_MRQ          97                 // XLAUI-1
#define IF_PORT_HOST_0_HTQE         103                 // XLAUI-1

#define IF_PORT_HOST_1_MRQ          99                 // XLAUI-3
#define IF_PORT_HOST_1_HTQE         105                // XLAUI-3


#define IF_PORT_HOST_3              101                // XLAUI-5
#define IF_PORT_HOST_BASE           IF_PORT_HOST_0;

#define NET_SWITCH_TO_HOST

#define IF_PORT_NET1_SWITCH_MRQ     102;                 

#endif; // of #ifndef _XAD_MDF_H_

