/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.Macros.asm
*
*  Usage:         TOPparse macros file
*
*******************************************************************************/

#define IPv6_FRGMNT_SIZE_OFF     2;
#define IPV6_FRAG_ID_OFF         4;
#define IP_ID_OFF                4;

//debug
//LDCAM BCAM8[0],0x10,0;
//LDCAM BCAM8[2],0x10,0x801;

///////////////////////////////////////////////////////////////////
//
//  ParseGlobalFilters_L23
//  Parses the L2 & L3 parts of the BDOS filters and creates Keys
//
///////////////////////////////////////////////////////////////////
MACRO ParseGlobalFilters_L23 Skip_BDOS_Lab, Err_Lab;

#define IP_VERSION_BIT byTempCondByte1;
movbits IP_VERSION_BIT,uqFramePrsReg.BIT[L3_TYPE_OFF],1;
// Set to start of L3 header (no needed when run after 'SetPolicyHeaders' )
//Add FMEM_BASE, uqOffsetReg0.byte[L3_OFFB] , 0, 2, MASK_0000001F, _ALU_FRST;
Mov FMEM_BASE.byte[0] , uqOffsetReg0.byte[L3_OFFB],2;


// First 3 bits of uqGcCtrlReg0 will be used by lookCAM search to indicate the group (0 or 1) according to phase
movbits uqGcCtrlReg0.bit[0], uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT], 1;
movbits uqGcCtrlReg0.bit[1], 0, 2;  // Search in group 0 or 1

// Filter to get only the phase bit in uqTmpReg1:
// Mov uqTmpReg2, 0, 1;
// Movbits uqTmpReg2, UDB.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT], 1;

// Calculate L3 Length:
Sub ALU, /* bdosFrameLenReg */sHWD_uxFrameLen, FMEM_BASE, 2;

// We assume CAMI still holds the key from ParseGlobalFilters_L4
// Search CAM again with second group
MovBits CAM_GROUP , uqGcCtrlReg0 , 3;
nop;
nop;
Lookcam CAMO, CAMI, BCAM8 [ CAM_GROUP ] ;

PutKey CMP_BDOS_L23_L3_SIZE_OFF(COM_KBS), ALU, CMP_BDOS_L23_L3_SIZE_SIZE; // (size: 2)
// add signature controller key
PutKey CMP_BDOS_L23_SIGNA_CNTRL_OFF(COM_KBS), CAMI, CMP_BDOS_L23_SIGNA_CNTRL_SIZE; // (size: 1)

if (IP_VERSION_BIT) jmp TREAT_IPV6, NOP_2;

// This is IPV4
#define CMP_BDOS_L23_SIP_OFF_2ND (CMP_BDOS_L23_SIP_OFF + 4);
#define CMP_BDOS_L23_SIP_OFF_3RD (CMP_BDOS_L23_SIP_OFF + 8);
#define CMP_BDOS_L23_SIP_OFF_4TH (CMP_BDOS_L23_SIP_OFF + 12);
#define CMP_BDOS_L23_DIP_OFF_2ND (CMP_BDOS_L23_DIP_OFF + 4);
#define CMP_BDOS_L23_DIP_OFF_3RD (CMP_BDOS_L23_DIP_OFF + 8);
#define CMP_BDOS_L23_DIP_OFF_4TH (CMP_BDOS_L23_DIP_OFF + 12);

Copy CMP_BDOS_L23_SIP_OFF (COM_KBS),  IP_SIP_OFF (FMEM_BASE), 4, SWAP;
Copy CMP_BDOS_L23_DIP_OFF (COM_KBS),  IP_DIP_OFF (FMEM_BASE), 4, SWAP;

// Fill in to form IPV6 key:
Mov ALU , IPV4_IPV6_MAPPING_2ND , 4;
nop;
PutKey CMP_BDOS_L23_SIP_OFF_2ND (COM_KBS), ALU, 4;
PutKey CMP_BDOS_L23_DIP_OFF_2ND (COM_KBS), ALU, 4;
Mov ALU , IPV4_IPV6_MAPPING_3RD , 4;
nop;
PutKey CMP_BDOS_L23_SIP_OFF_3RD (COM_KBS), ALU, 4;
PutKey CMP_BDOS_L23_DIP_OFF_3RD (COM_KBS), ALU, 4;
Mov ALU , IPV4_IPV6_MAPPING_4TH , 4; 
nop;
PutKey CMP_BDOS_L23_SIP_OFF_4TH (COM_KBS), ALU, 4;
PutKey CMP_BDOS_L23_DIP_OFF_4TH (COM_KBS), ALU, 4;

#undef CMP_BDOS_L23_SIP_OFF_2ND
#undef CMP_BDOS_L23_SIP_OFF_3RD
#undef CMP_BDOS_L23_SIP_OFF_4TH
#undef CMP_BDOS_L23_DIP_OFF_2ND
#undef CMP_BDOS_L23_DIP_OFF_3RD
#undef CMP_BDOS_L23_DIP_OFF_4TH


Get  uqTmpReg1, IP_FLAGS_OFF(FMEM_BASE), 2, SWAP;          
Copy CMP_BDOS_L23_TOS_OFF(COM_KBS),     IP_DSCP_OFF(FMEM_BASE), CMP_BDOS_L23_TOS_SIZE;           // size is '1'. no need for swap
Copy CMP_BDOS_L23_TTL_OFF(COM_KBS),     IP_TTL_OFF(FMEM_BASE),  CMP_BDOS_L23_TTL_SIZE;           // size is '1'. no need for swap
COPY CMP_BDOS_L23_L4_PROT_OFF(COM_KBS), IP_PRT_OFF(FMEM_BASE),  CMP_BDOS_L23_L4_PROT_SIZE;       // Size is '1'
Copy CMP_BDOS_L23_L3_SIZE_OFF(COM_KBS), IP_LEN_OFF(FMEM_BASE),  CMP_BDOS_L23_L3_SIZE_SIZE, SWAP; // Size is 2
Copy CMP_BDOS_L23_ID_NUM_OFF(COM_KBS),  IP_ID_OFF(FMEM_BASE),   CMP_BDOS_L23_ID_NUM_SIZE,  SWAP; // Id is 2

// Possible optimization: TTL and Protocol may be copied in one command.

// Split between Fragement offset and fragement flag
Mov ALU, 0x2000, 4;
And ALU, uqTmpReg1, ALU, 2;
Mov uqTmpReg2, 0, 4;
movbits uqTmpReg1.bit[13], 0, 3;    // Unset flags bits in Fragement Offset value.
//movbits uqTmpReg2, ALU.bit[13], 8;  // Get only one bit for fragement flag value. Rest is '0'.
// Changed By Alexander M 
// We need set up bit of found frag flag  if fragmented bit is ready 
movbits uqTmpReg2, uqFramePrsReg.BIT[L3_FRAG_OFF], 1;
// Question: Do we need to set Fragment flag (uqTmpReg2) if Fragment offset is other than zero (uqTmpReg1 > 0)?
PutKey CMP_BDOS_L23_FRGMNT_OFF(COM_KBS),     uqTmpReg1, CMP_BDOS_L23_FRGMNT_SIZE;
PutKey CMP_BDOS_L23_FRGMNT_FLG_OFF(COM_KBS), uqTmpReg2, CMP_BDOS_L23_FRGMNT_FLG_SIZE;   // size is '1'

Add COM_HBS, COM_HBS, 1, 1;
Add COM_KBS, COM_KBS, CMP_BDOS_L23_IPV4_KMEM_SIZE, 2;

if (!uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT]) jmp HZ2_P0_LAB;
   PutHdr HREG[ COM_HBS ], COMP_IPV4_HDR_P0;
   nop;

PutHdr HREG[ COM_HBS ], COMP_IPV4_HDR_P1;

HZ2_P0_LAB:

jmp CONT , NOP_2;


TREAT_IPV6:
// SIP search will be first in TOPsearch, and therefore can be placed in TREG.

#define CMP_BDOS_L23_IPV6_SIP_OFF_2ND  (CMP_BDOS_L23_IPV6_SIP_OFF + 8);
#define CMP_BDOS_L23_IPV6_DIP_OFF_2ND  (CMP_BDOS_L23_IPV6_DIP_OFF + 8);
#define IPv6_SIP_OFF_2ND  (IPv6_SIP_OFF + 8);
#define IPv6_DIP_OFF_2ND  (IPv6_DIP_OFF + 8);

Copy CMP_BDOS_L23_IPV6_SIP_OFF (COM_KBS),  IPv6_SIP_OFF_2ND (FMEM_BASE), 8, SWAP;
Copy CMP_BDOS_L23_IPV6_DIP_OFF (COM_KBS),  IPv6_DIP_OFF_2ND (FMEM_BASE), 8, SWAP;
Copy CMP_BDOS_L23_IPV6_SIP_OFF_2ND (COM_KBS),  IPv6_SIP_OFF (FMEM_BASE), 8, SWAP;
Copy CMP_BDOS_L23_IPV6_DIP_OFF_2ND (COM_KBS),  IPv6_DIP_OFF (FMEM_BASE), 8, SWAP;
Copy CMP_BDOS_L23_L3_SIZE_OFF(COM_KBS), IPv6_PAYLOAD_LEN_OFF(FMEM_BASE), CMP_BDOS_L23_L3_SIZE_SIZE, SWAP; // Size is 2
Mov uqTmpReg2, 0, 4;
// Traffic Class and Flow Label are in first 4 bytes of IP header
Get uqTmpReg1, 0(FMEM_BASE), 4, SWAP;

// Write Hop Limit
Copy CMP_BDOS_L23_IPV6_HOP_LIMIT_OFF (COM_KBS), IPv6_HOP_LIMIT_OFF (FMEM_BASE), CMP_BDOS_L23_IPV6_HOP_LIMIT_SIZE;

movbits uqTmpReg2, uqTmpReg1.bit[20], 8; // Traffic class
movbits uqTmpReg1.bit[20], 0, 12;        // Flow Label - Unset rest of register

PutKey CMP_BDOS_L23_IPV6_TRAFFIC_CLASS_OFF(COM_KBS), uqTmpReg2, CMP_BDOS_L23_IPV6_TRAFFIC_CLASS_SIZE;
PutKey CMP_BDOS_L23_IPV6_FLOW_LABEL_OFF(COM_KBS),    uqTmpReg1, CMP_BDOS_L23_IPV6_FLOW_LABEL_SIZE;

//Changed by E.R.
Mov uqCondReg, uqFramePrsReg, 4;   // .BIT[L3_FRAG_OFF]
Mov FMEM_BASE, uxOffsetReg1.byte[IPv6_FRAG_OFFB], 2;
if ( uqCondReg.BIT[L3_FRAG_OFF] ) Jmp CMP_BDOS_L23_IPV6_FRGMNT_FLG_CONT, NOP_2;

//packet doesn't fragmented
PutKey CMP_BDOS_L23_IPV6_FRGMNT_FLG_OFF(COM_KBS), 0, CMP_BDOS_L23_IPV6_FRGMNT_FLG_SIZE; 
Mov ALU, 0, CMP_BDOS_L23_IPV6_FRGMNT_ID_SIZE;

jmp CMP_BDOS_L23_IPV6_FRGMNT_FLG_DONE, NO_NOP;
   PutKey CMP_BDOS_L23_IPV6_FRGMNT_OFF(COM_KBS),      0, CMP_BDOS_L23_IPV6_FRGMNT_SIZE;
   PutKey CMP_BDOS_L23_IPV6_FRGMNT_ID_OFF(COM_KBS), ALU, CMP_BDOS_L23_IPV6_FRGMNT_ID_SIZE;


CMP_BDOS_L23_IPV6_FRGMNT_FLG_CONT:

//packet is fragmented
Get uqTmpReg1 , IPv6_FRGMNT_SIZE_OFF(FMEM_BASE) , 2, SWAP;
Mov ALU, 0, 4;
copy CMP_BDOS_L23_IPV6_FRGMNT_ID_OFF(COM_KBS), IPV6_FRAG_ID_OFF(FMEM_BASE), CMP_BDOS_L23_IPV6_FRGMNT_ID_SIZE,SWAP;

//copy 13 bits fragment offset only
MovBits ALU.BIT[0], uqTmpReg1.BIT[3], 13;
PutKey CMP_BDOS_L23_IPV6_FRGMNT_FLG_OFF(COM_KBS), 1, CMP_BDOS_L23_IPV6_FRGMNT_FLG_SIZE; 
PutKey CMP_BDOS_L23_IPV6_FRGMNT_OFF(COM_KBS),   ALU, CMP_BDOS_L23_IPV6_FRGMNT_SIZE;

CMP_BDOS_L23_IPV6_FRGMNT_FLG_DONE:

Add COM_HBS, COM_HBS, 1, 1;
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT]) jmp CONT;
   Add COM_KBS, COM_KBS, CMP_BDOS_L23_IPV6_KMEM_SIZE, 2;
   PutHdr HREG[ COM_HBS ], COMP_IPV6_HDR_P0;

PutHdr HREG[ COM_HBS ], COMP_IPV6_HDR_P1;


CONT:

// check CAM result and update validation bits
if (FLAGS.bit[F_MH]) PutHdrBits HREG[ COM_HBS ].bit[10], CAMO, 6;
//if (FLAGS.bit[F_MH]) PutKey MSG_L23_VALIDATION_BITS_OFF ( HW_KBS ), CAMO, 2;


#undef IP_VERSION_BIT;
#undef CMP_BDOS_L23_IPV6_SIP_OFF_2ND;
#undef CMP_BDOS_L23_IPV6_DIP_OFF_2ND;
#undef IPv6_SIP_OFF_2ND;
#undef IPv6_DIP_OFF_2ND;
END_OF_MACRO:
ENDMACRO; //ParseGlobalFilters_L23

///////////////////////////////////////////////////////////////////
//
//  ParseGlobalFilters_L4
//  Parses the L4 (& L7) parts of the BDOS filters and creates Keys
//
///////////////////////////////////////////////////////////////////

MACRO ParseGlobalFilters_L4 Skip_BDOS_Lab, Err_Lab;


// Find out L4 type and start processing
movbits uqTmpReg1, uqFramePrsReg.BIT[L4_TYPE_OFF], 3;
Mov     FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;
decode  ALU, uqTmpReg1, 1, MASK_00000007, MASK_SRC1;       // Convert L4 type to bitmap  (for jmul)

//????????????????????????????????????????????????????????????????
// First 3 bits of UDB will be used by lookCAM search to indicate the group (0 or 1) according to phase
mov uqGcCtrlReg0.byte[0], 0 , 1; // uqGcCtrlReg0 = UDB
//????????????????????????????????????????????????????????????????

// Filter to get only the phase bit in uqTmpReg1:

// Mov uqTmpReg2, 2, 1;
// Movbits uqTmpReg2, uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT], 1;
// Putkey CMP_BDOS_L4_PHASE(COM_KBS), uqTmpReg2, 1; 
// Putkey CMP_BDOS_L4_PHASE(COM_KBS), 0, 1; 

movBits ENC_PRI.bit[9], ALU, 7;
// PutKey CMP2_ALLWAYS_0(COM_KBS), 0, 1;
Mov CAMI, 0, 2;  // Initialize CAM just in case, (for bit 6 in TCP case)

 // First 3 bits of uqGcCtrlReg0 will be used by lookCAM search to indicate the group (0 or 1)
movbits uqGcCtrlReg0.bit[0], uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT], 1;
movbits uqGcCtrlReg0.bit[1], 1, 2;  // Search in group 2 or 3

Jmul ERR_LBL,
     ERR_LBL,
     IGMP_LBL, 
     ICMP_LBL, 
     UDP_LBL, 
     TCP_LBL, 
     ERR_LBL;
     nop;
     nop;
   

IGMP_LBL:

// Parse IGMP header if match in bcam8

Mov CAMI, IGMP_CONTROL, 1;
movbits CAMI.bit[7], uqFramePrsReg.BIT[L3_TYPE_OFF], 1; // Bit 7 in controller type defines IP version.
MovBits CAM_GROUP, uqGcCtrlReg0 , 3;
nop;
nop;
Lookcam CAMO, CAMI, BCAM8 [ CAM_GROUP ] ;

// IGMP_TYPE_OFFSET
copy  CMP_BDOS_L4_IGMP_TYPE_OFF(COM_KBS), IGMP_TYPE_OFFSET (FMEM_BASE) , CMP_BDOS_L4_IGMP_TYPE_SIZE; // (size is 1)
copy  CMP_BDOS_L4_CHECKSUM_OFF (COM_KBS), IGMP_CHCKSUM_OFFSET(FMEM_BASE), CMP_BDOS_L4_CHECKSUM_SIZE, SWAP; 
Add COM_HBS, COM_HBS, 1, 1;
nop;
nop;
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT]) jmp HZ3_P0_LAB;
   PutHdr   HREG[ COM_HBS ], COMP_IGMP_HDR_P0 ;
   nop;

PutHdr   HREG[ COM_HBS ], COMP_IGMP_HDR_P1;

HZ3_P0_LAB:

jmp  CHECK_CAM_RESULT , NOP_2;


ICMP_LBL:

// Parse ICMP header if match in bcam8

Mov CAMI, ICMP_CONTROL, 1;
movbits CAMI.bit[7], uqFramePrsReg.BIT[L3_TYPE_OFF], 1; // Bit 7 in controller type defines IP version.
MovBits CAM_GROUP, uqGcCtrlReg0 , 3;
nop;
nop;
Lookcam CAMO, CAMI, BCAM8 [ CAM_GROUP ];

copy  CMP_BDOS_L4_ICMP_TYPE_OFF(COM_KBS),   ICMP_TYPE_OFFSET (FMEM_BASE) , CMP_BDOS_L4_ICMP_TYPE_SIZE; // (size is 1)
copy  CMP_BDOS_L4_CHECKSUM_OFF (COM_KBS),   ICMP_CHCKSUM_OFFSET(FMEM_BASE), CMP_BDOS_L4_CHECKSUM_SIZE, SWAP; 
Add COM_HBS, COM_HBS, 1, 1;
nop;
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT]) jmp HZ4_P0_LAB;
   PutHdr   HREG[ COM_HBS ], COMP_ICMP_HDR_P0;

PutHdr   HREG[ COM_HBS ], COMP_ICMP_HDR_P1;

HZ4_P0_LAB:

jmp  CHECK_CAM_RESULT , NOP_2;



ERR_LBL:

// This could be IPV6 - ICMP
jmp Skip_BDOS_Lab | NOP_2;
// jmp Err_Lab |NOP_2;


      
// jmp  END_MACRO |NOP_2;

UDP_LBL:

// Parse UDP header if match in bcam8

Mov CAMI, UDP_CONTROL, 1;
movbits CAMI.bit[7], uqFramePrsReg.BIT[L3_TYPE_OFF], 1; // Bit 7 in controller type defines IP version.

MovBits CAM_GROUP, uqGcCtrlReg0 , 3;
nop;
nop;
Lookcam CAMO, CAMI, BCAM8 [ CAM_GROUP ] ;

Copy CMP_BDOS_L4_SRC_PORT_OFF(COM_KBS), UDP_SPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_SRC_PORT_SIZE, SWAP;
Copy CMP_BDOS_L4_DST_PORT_OFF(COM_KBS), UDP_DPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_DST_PORT_SIZE, SWAP;
Copy CMP_BDOS_L4_CHECKSUM_OFF(COM_KBS), UDP_CHK_OFF(FMEM_BASE),   CMP_BDOS_L4_CHECKSUM_SIZE, SWAP;

Add COM_HBS, COM_HBS, 1, 1;
// PutKey   MSG_RSV_BDOS_LAB_OFF( HW_KBS ), UDP_ANALYZE, 2;
nop;
nop;
// Build the search header according to the phase
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT]) jmp HZ5_P0_LAB;
   PutHdr   HREG[ COM_HBS ], COMP_UDP_HDR_P0;
   nop;

PutHdr   HREG[ COM_HBS ], COMP_UDP_HDR_P1;
HZ5_P0_LAB:

jmp  CHECK_CAM_RESULT | NOP_2;

TCP_LBL:

// Parse TCP header if match in bcam8

Mov uqCondReg , uqFramePrsReg , 4;
MovBits CAMI.BIT[0], uqFramePrsReg.BIT[L4_FLAGS_OFF],5;
if ( uqCondReg.BIT[L3_FRAG_OFF] ) Mov CAMI , 0x60 , 1;

movbits CAMI.bit[7], uqFramePrsReg.BIT[L3_TYPE_OFF], 1;
nop;
/*
Mov uqTmpReg5, 0, 4;
movbits uqTmpReg5.bit[5], uqFramePrsReg.BIT[L3_FRAG_OFF],1; // Writing first bit of L3 frag controller 
and  ALU, uqTmpReg5,0xFF, 1;
nop;
jz CAMI_FLAG_IN;
movbits uqTmpReg5.bit[6], uqFramePrsReg.BIT[L3_FRAG_OFF],1; // Writing first bit of L3 frag controller 
nop;
jmp CAMI_FRAGM | NOP_2;
CAMI_FLAG_IN:
MovBits CAMI.BIT[0], uqFramePrsReg.BIT[L4_FLAGS_OFF],5;
CAMI_FRAGM:
Mov CAMI, uqTmpReg5,2;
movbits CAMI.bit[7], uqFramePrsReg.BIT[L3_TYPE_OFF], 1;*/ // Bit 7 in controller type defines IP version.
// CAM group in UDB is '0' or '1' depending on phase

//Get CAMI, TCP_FLAGS_OFF(FMEM_BASE), 1; 
//MovBits CAMI.BIT[0], uqFramePrsReg.BIT[L4_FLAGS_OFF],5;
//movbits CAMI.bit[TCP_URG_FLAG_OFF], 0, 3;  // unset CWR, ECE and URG
//movbits CAMI.bit[7], uqFramePrsReg.BIT[L3_TYPE_OFF], 1; // Bit 7 in controller type defines IP version.
// CAM group in UDB is '0' or '1' depending on phase
MovBits CAM_GROUP , uqGcCtrlReg0 , 3;
nop;
nop;
Lookcam CAMO, CAMI, BCAM8 [ CAM_GROUP ]  ;

Copy CMP_BDOS_L4_SRC_PORT_OFF(COM_KBS), TCP_SPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_SRC_PORT_SIZE, SWAP;

/* DEBUG !!!!!!!!!!!!!! */
//Mov ALU , 0x1111 , 2;

Copy CMP_BDOS_L4_DST_PORT_OFF(COM_KBS), TCP_DPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_DST_PORT_SIZE, SWAP;
//PutKey CMP_BDOS_L4_SRC_PORT_OFF(COM_KBS), ALU , 2;

//PutKey CMP_BDOS_L4_DST_PORT_OFF(COM_KBS), ALU , 2;
/* DEBUG !!!!!!!!!!!!!! */

Copy CMP_BDOS_L4_TCP_SEQ_NUM_OFF(COM_KBS), TCP_SEQ_OFF(FMEM_BASE),   CMP_BDOS_L4_TCP_SEQ_NUM_SIZE, SWAP;
Copy CMP_BDOS_L4_TCP_FLAGS_OFF(COM_KBS),   TCP_FLAGS_OFF(FMEM_BASE), CMP_BDOS_L4_TCP_FLAGS_SIZE; // size is '1'
Copy CMP_BDOS_L4_CHECKSUM_OFF(COM_KBS), TCP_CHK_OFF(FMEM_BASE),   CMP_BDOS_L4_CHECKSUM_SIZE, SWAP;


// PutKey   MSG_RSV_BDOS_LAB_OFF( HW_KBS ), TCP_ANALYZE, 2;  

// Get CAMI, TCP_FLAGS_OFF(FMEM_BASE), 1; 
// movbits CAMI.bit[TCP_URG_FLAG_OFF], 0, 3; // unset 3 MSB
Add COM_HBS, COM_HBS, 1, 1;
// No need for jump. It is immediatly below
// jmp  CHECK_CAM_RESULT | _NOP0;
nop;
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_BDOS_ACTIVE_BIT]) Jmp HZ6_P0_LAB;
   PutHdr   HREG[ COM_HBS ], COMP_TCP_HDR_P0;
   nop;

PutHdr   HREG[ COM_HBS ], COMP_TCP_HDR_P1;

HZ6_P0_LAB:


CHECK_CAM_RESULT:

// If CAM match, override validation bits
// Movbits UDB.bit[1], 1, 1;
if (FLAGS.bit[F_MH]) PutHdrBits HREG[ COM_HBS ].bit[10], CAMO, 6;

// First 11 bits are validation bits for Search
// Last 4 bits are policy filter bits for TOPresolve
// They define which signatures are relevant for this controller type

if (!FLAGS.bit[F_MH]) jmp CANCEL_BDOS | NOP_2;
Add uqTmpReg2, CAMO, 0, 2; // If all empty, no need to run BDOS on this controller type. (It can be enough to check only 4 lats bits)
Putkey MSG_L4_VALIDATION_BITS_OFF (HW_KBS),  CAMO, 2;
// If no filters are to be applied, searches can be skipped alltogether.
jz CANCEL_BDOS |NOP_2;


Mov ALU, $uxVlanTag1Id, 2;
// add check if VLAN Tag exists ?
If ( !uqCondReg.BIT[VLAN_TAG_NUM+1] ) movbits ALU.bit[12], 1, 1;
jmp  END_OF_MACRO | NO_NOP;
   PutKey CMP_BDOS_L23_VLAN_OFF(COM_KBS), ALU, CMP_BDOS_L23_VLAN_SIZE; // (size: 2)
   PutKey CMP_BDOS_L23_PACKET_SIZE_OFF(COM_KBS),  bdosFrameLenReg, CMP_BDOS_L23_PACKET_SIZE_SIZE; // HD_REG2.Byte[0], 14 bits


CANCEL_BDOS:
jmp Skip_BDOS_Lab | NOP_1;
Sub COM_HBS, COM_HBS, 1, 1;


END_OF_MACRO:

Add COM_KBS, COM_KBS, CMP_BDOS_L4_KMEM_SIZE, 2;

ENDMACRO; //ParseGlobalFilters_L4




MACRO BuildMsg;

//assume that HWD_REG5 still contained hash core calculated by decode_ipv4 decode_ipv6
    PutKey   0(HW_KBS), MSG_HDR, 1;   // Put message header     // ##TODO_OPTIMIZE - when will have time for this - as this uses temp register from within a mcaro, add vardef for this register in all the locations that uses it.
// Put in the message the folded xor result of the IPv4 SIP + DIP hash result.
   //    Xor ALU, HWD_REG5.byte[0], HWD_REG5.byte[1], 1; // HWD_REG5.byte[0..1] = sIpv4ProtDec_HWD5_uxSipDipHashRes
   PutKey MSG_HASH_CORE_OFF( HW_KBS ), byHashVal, 1;
   PutKey   MSG_ACTION_ENC_OFF(HW_KBS), byFrameActionReg, 1;

   // Use hash value for deciding on FLOW number.NP5 has 16 flows
   MovBits FLOW_NUM, byHashVal, 4;
// calculate RT monitoring counter offset: [7:3] - physical port; [2:0] - protocol
   MovBits  byTempCondByte1.bit[0], uqFramePrsReg.BIT[L4_TYPE_OFF], 3;
   MovBits  byTempCondByte1.bit[3], bySrcPortReg, 5; //max phys port range 0-0x1f
   PutKey   MSG_CTRL_TOPPRS_0_OFF(HW_KBS), byCtrlMsgPrs0,   2; // Writing 2 ctrl bytes (both byCtrlMsgPrs0 and byCtrlMsgPrs1) in 1 operation to both MSG_CTRL_TOPPRS_0_OFF and MSG_CTRL_TOPPRS_1_OFF
   PutKey   MSG_CTRL_TOPPRS_2_OFF(HW_KBS), byCtrlMsgPrs2,   1; // Writing 3rd control bits
   PutKey   MSG_SRC_PRT_OFF (HW_KBS),      byTempCondByte1, 1;
   PutKey  MSG_L3_USR_OFF(HW_KBS), uqOffsetReg0.byte[L3_OFFB], 4; // initialize in the message both MSG_L3_USR_OFF and MSG_L4_USR_OFF from uqOffsetReg0.byte[L3_OFFB] and uqOffsetReg0.byte[L4_OFFB]

ENDMACRO; //BuildMsg

//-------------------------------------------------------//
//            MACRO SetPolicyHeaders                     //
//-------------------------------------------------------//
// This macro generates the lookup keys for the policy filters.

MACRO SetPolicyHeaders;

#define CMP_POLICY_SIP_OFF_2ND (CMP_POLICY_SIP_OFF + 4);
#define CMP_POLICY_SIP_OFF_3RD (CMP_POLICY_SIP_OFF + 8);
#define CMP_POLICY_SIP_OFF_4TH (CMP_POLICY_SIP_OFF + 12);
#define CMP_POLICY_DIP_OFF_2ND (CMP_POLICY_DIP_OFF + 4);
#define CMP_POLICY_DIP_OFF_3RD (CMP_POLICY_DIP_OFF + 8);
#define CMP_POLICY_DIP_OFF_4TH (CMP_POLICY_DIP_OFF + 12);
#define IPv6_SIP_OFF_2ND       (IPv6_SIP_OFF + 8);
#define IPv6_DIP_OFF_2ND       (IPv6_DIP_OFF + 8);
#define IP_VERSION_BIT         byTempCondByte1.bit[0];

////////////////////////////////////////////
#ifdef __no_policy__
Jmp POLICY_HDR_DONE_LAB, NO_NOP;
   Nop;//PutHdr HREG[ COM_HBS ], COMP_POLICY_HDR;
   Add    COM_KBS, COM_KBS, CMP_POLICY_KMEM_SIZE/*ALU*/, 2;
#endif

/*
Jmp POLICY_HDR_DONE_LAB, NO_NOP;
   PutHdr HREG[ COM_HBS ], COMP_POLICY_HDR;
   Add    COM_KBS, COM_KBS, CMP_POLICY_KMEM_SIZE, 2;
*/
////////////////////////////////////////////


Mov     uqTmpReg1, 0x7FF, 2; // Initial validation bits for policy: All Set by default
Movbits IP_VERSION_BIT, uqFramePrsReg.BIT[L3_TYPE_OFF], 1;

// Filter to get only the phase bit in uqTmpReg1: (required only if no VLAN)
Mov     uqTmpReg2, 0, 1;
Movbits uqTmpReg2, uqGcCtrlReg0.bit[GC_CNTRL_0_POLICY_ACTIVE_BIT], 1;   //GuyE: Probably GC_CNTRL_0_POLICY_ACTIVE_BIT not used 

// Set to start of L3 header
//Add FMEM_BASE, uqOffsetReg0.byte[L3_OFFB], 0, 2, MASK_0000001F, _ALU_FRST;
Mov FMEM_BASE, uqOffsetReg0.byte[L3_OFFB],2;

#define POLICY_SIP_DB_VAL 0x1
#define POLICY_DIP_DB_VAL 0x2  
#define POLICY_IP_DB_VAL    (POLICY_SIP_DB_VAL | (POLICY_DIP_DB_VAL << 8) );


// If IP_VERSION_BIT == 1 and we received ipv4 we need to convert the ipv4.SIP and IPv4.DIP to ipv6 representation
if (IP_VERSION_BIT) jmp TREAT_IPV6, NOP_2; // jump if IPv6

Mov  ALU, IPV4_IPV6_MAPPING_2ND, 4;
Copy CMP_POLICY_SIP_OFF(COM_KBS), IP_SIP_OFF(FMEM_BASE), 4, SWAP; 
Copy CMP_POLICY_DIP_OFF(COM_KBS), IP_DIP_OFF(FMEM_BASE), 4, SWAP; 

PutKey CMP_POLICY_SIP_OFF_2ND(COM_KBS), ALU, 4;
PutKey CMP_POLICY_DIP_OFF_2ND(COM_KBS), ALU, 4;

Mov    ALU, IPV4_IPV6_MAPPING_3RD, 4;
Nop;

PutKey CMP_POLICY_SIP_OFF_3RD(COM_KBS), ALU, 4;
PutKey CMP_POLICY_DIP_OFF_3RD(COM_KBS), ALU, 4;
Mov    ALU, IPV4_IPV6_MAPPING_4TH, 4;

jmp CONT, NO_NOP;
  PutKey CMP_POLICY_SIP_OFF_4TH(COM_KBS), ALU, 4;
  PutKey CMP_POLICY_DIP_OFF_4TH(COM_KBS), ALU, 4;


TREAT_IPV6:
Copy CMP_POLICY_SIP_OFF(COM_KBS), IPv6_SIP_OFF_2ND (FMEM_BASE), 8, SWAP;
Copy CMP_POLICY_DIP_OFF(COM_KBS), IPv6_DIP_OFF_2ND (FMEM_BASE), 8, SWAP;
Copy CMP_POLICY_SIP_OFF_3RD(COM_KBS), IPv6_SIP_OFF (FMEM_BASE), 8, SWAP;
Copy CMP_POLICY_DIP_OFF_3RD(COM_KBS), IPv6_DIP_OFF (FMEM_BASE), 8, SWAP;


CONT:

// Put the VLAN TAG. In case of no User VALN, this may contain garbage
If ( uqCondReg.BIT[VLAN_TAG_NUM+1] ) PutKey CMP_POLICY_VLAN_OFF (COM_KBS), $uxVlanTag1Id, CMP_POLICY_VLAN_SIZE; 

// For now, we put physical port number
Putkey CMP_POLICY_PORT_OFF(COM_KBS), bySrcPortReg, CMP_POLICY_PORT_SIZE; 

Add COM_HBS, COM_HBS, 1, 1;

// Find out number of VLAN tags
MovBits ALU, uqFramePrsReg.BIT[VLAN_TAG_NUM], 2;
sub ALU, ALU, 2, 1, MASK_00000003, MASK_SRC1;

Movbits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT], 1, 1;

// If less than 2 tags, disable VLAN search in TOPsearch:
jb POLICY_WOUT_UVLAN_LAB, NOP_2; 
    jmp POLICY_HDR_DONE_LAB, NOP_1;
    PutHdr HREG[ COM_HBS ], COMP_POLICY_HDR;


POLICY_WOUT_UVLAN_LAB:
movbits uqTmpReg1.bit[VLAN1_SEARCH_VALID_BIT], 0, 1;
PutKey  CMP_POLICY_VLAN_OFF (COM_KBS), 0x1000, CMP_POLICY_VLAN_SIZE; // set default VLAN id
PutHdr  HREG[ COM_HBS ], COMP_POLICY_HDR;


POLICY_HDR_DONE_LAB:

// Just for testing with SmartBits: Temporary override to use first tag
#ifdef USE_FIRST_VLAN_TAG
  PutKey CMP_POLICY_VLAN_OFF (COM_KBS), $uxVlanTag0Id, CMP_POLICY_VLAN_SIZE; // From HD_REG it is copied without priority bits.
  movbits uqTmpReg1.bit[VLAN1_SEARCH_VALID_BIT], 1, 1;
#endif

Putkey CMP_POLICY_DEFAULT_SET_OFF (COM_KBS), uqTmpReg2, 1;     // Also need to write key for default VLAN result
PutKey MSG_POLICY_VALIDATION_BITS_OFF(HW_KBS), uqTmpReg1, 1;   // Place the Policy Validation bits also in message. First byte is enough:
Add    COM_KBS, COM_KBS, CMP_POLICY_KMEM_SIZE, 2;


#undef IP_VERSION_BIT;
#undef IPv6_SIP_OFF_2ND;
#undef IPv6_DIP_OFF_2ND;
#undef CMP_POLICY_SIP_OFF_2ND;
#undef CMP_POLICY_SIP_OFF_3RD;
#undef CMP_POLICY_SIP_OFF_4TH;
#undef CMP_POLICY_DIP_OFF_2ND;
#undef CMP_POLICY_DIP_OFF_3RD;
#undef CMP_POLICY_DIP_OFF_4TH;

ENDMACRO; //SetPolicyHeaders


//-------------------------------------------------------//
//                MACRO SynFloodPrs                      //
//-------------------------------------------------------//
// Note: I do not mind duplicating code for Cookie calculation,
// Because Syn-Flood protection and TCP OOS will never both be performed for 
// the same packet.

MACRO SynFloodPrs;
ENDMACRO; //SynFloodPrs



//-------------------------------------------------------//
//            MACRO ParseControlMessage                  //
//-------------------------------------------------------//

// This macro is used to parse the message that arrives from the host (for OOS feature only), 
// it looks for up to 15 keys (4 bytes each, 4x15 = 60 bytes) and then allocates a message 
// to be sent to TOPresolve and there to be learned by High learn

MACRO ParseControlMessage Err_Handler, DISCARD_LAB;

vardef volatile regtype GC_INB_REPRT_REG  uqTmpReg4;
vardef volatile regtype GC_INB_ERROR_REG  uqTmpReg5; 
#define MSG_COMMANDS_MAX 4;


Get uqTmpReg2, CTRL_FRAME_SEQ_NUM_OFF  (0), 4; // Do we need to swap here?
Mov ALU, HWD_REG1.byte[1] , 1; // get physical port
Sub ALU, ALU, PRT_CFG1, 1;     // Check whether control message arrived from Host instance (interface) 0 or 1


Mov uqTmpReg6, uqTmpReg2.byte[3], 1; // Get counter id


Mov $GC_INB_REPRT_REG, GC_INB_REPRT, 4;
Mov $GC_INB_ERROR_REG, GC_INB_ERROR, 4;

jz OOS_CNTR_MSG_CONT, NOP_2;

Mov $GC_INB_REPRT_REG, GC_INB_REPRT_INST1, 4;
Mov $GC_INB_ERROR_REG, GC_INB_ERROR_INST1, 4;

OOS_CNTR_MSG_CONT:


Add $GC_INB_REPRT_REG, $GC_INB_REPRT_REG, uqTmpReg6, 4;

SHL uqTmpReg6, uqTmpReg6, 19, 4; // prepare STAT_REG1 format bit offset[24:19]; size[18:17] = 0(1 bit); value - 0/1


// Start critical region
//EZwaitFlag F_ORD;

//for debug: EZstatSendCmdIndexReg $GC_INB_REPRT_REG, STS_READ_CMD;      // Read Seq. number counter    
EZstatSendCmdIndexReg $GC_INB_REPRT_REG, STS_INCR_BY_1_READ_CMD;  // increment and read old number counter 

// End critical region
//Mov ORDERING_REG, 1, 1;

Get uqTmpReg1, CTRL_FRAME_CMD_COUNT_OFF(0), 2, RESET;
Get uqTmpReg3, CTRL_FRAME_MSG_SIZE_OFF(0), 2, RESET;
Mov uqTmpReg2.byte[3], 0, 1;
Mov FMEM_BASE, CTRL_FRAME_FIRST_COMMAND_OFF, 2;
Mov ALU, uqTmpReg2, 4;

// Wait until counter value is ready
if (!FLAGS.bit[F_SR]) Jmp $, NOP_2;     


Sub ALU, ALU, 1, 4;
Sub ALU, ALU, STAT_RESULT_L , 4, MASK_00FFFFFF, MASK_BOTH;  // Check if Seq. number == read counter + 1 
Nop;

jz CORRECT_SEQUENCE, NOP_1;

   Mov uqTmpReg6.byte[0], 0, 1;

// for debug jmp CORRECT_SEQUENCE, NOP_2;


EZstatDecrByOneIndexReg $GC_INB_REPRT_REG;
Mov uqTmpReg6.byte[0], 1, 1;
EZstatPutDataSendCmdIndexReg $GC_INB_ERROR_REG, uqTmpReg6, STS_BW_WR_CMD; // If Seq. number is not correct - increment error counter and quit

Nop;
Nop;


jmp DISCARD_LAB, NOP_2;

// clear speacial bit
CORRECT_SEQUENCE:

EZstatPutDataSendCmdIndexReg $GC_INB_ERROR_REG, uqTmpReg6, STS_BW_WR_CMD; // If Seq. number is not correct - increment error counter and quit

Nop;
Nop;

varundef GC_INB_REPRT_REG;
varundef GC_INB_ERROR_REG;

Add COM_HBS, COM_HBS, 1, 1;

EXT_LOOP:
Mov ALU , 0x11 , 4;
Nop;
PutKey 0(COM_KBS)+, ALU, 4;                    // Valid + Match bits

sub ALU, uqTmpReg1, uqTmpReg3, 4;
Mov CNT, uqTmpReg3, 1;
JNS CONT_LOOP, NOP_2;

Mov CNT, uqTmpReg1, 1;
Nop;

CONT_LOOP:
MovBits SIZE_REG.bit[2], CNT, 8;
PutKey MSG_CONTROL_NUM_OF_COMMANDS(HW_KBS), CNT, 1;
Sub uqTmpReg1, uqTmpReg1, CNT, 4;

Copy 0(COM_KBS), 0(FMEM_BASE)+, SIZE_REG, NO_SWAP;    // Do we need to swap?

PutHdr HREG[ COM_HBS ], CTRL_MSG_HDR;          // Set control default header

Sub ALU, uqTmpReg1, 0, 4;
Mov COM_KBS, MSG_SIZE, 2;                      // init offset to the start first message
JZ STOP_LO0P, NOP_2;                           // for the last portion halt will regular

// create HW message parameters
Mov byFrameActionReg, FRAME_CONF_EXTRACT, 1;
BuildMsg;

PutHdr HREG[ 0 ], PRS_MSG_HDR;   // Write the message header 
   Nop;
Halt CONTINUE,
   HW_MSG_HDR;
   Nop;
Jmp EXT_LOOP, NOP_2;

STOP_LO0P:

// Release RFD immediately
EZrfdRecycleOptimized;

#undef MSG_COMMANDS_MAX;

ENDMACRO; //ParseControlMessage

MACRO semtakeTP;

wait_sem11:

   EZwaitFlag F_ST;
   nop;
   Mov        ALU ,   0x00001 , 4;
   nop;
   mov        sStat_uqData, ALU, 4;
   mov        sStat_uqDataMsb, 0x00, 4;
   mov        ALU , CNT_SEMAPHORE_BASE , 4;
   nop;
   mov        sStat_3byAddress, ALU, 3;
   mov        sStat_byCommand, STS_BW_SET_READ_CMD, 1;
   nop;
   Nop;
   EZwaitFlag F_SR;

   if( FLAGS.bit[F_SO]  ) jmp wait_sem11 , NOP_2;

ENDMACRO; //semtakeTP
       
MACRO semgiveTP;

   EZwaitFlag F_ST;
   nop;
   Mov        ALU ,   0x00001 , 4;
   nop;
   mov        sStat_uqData, ALU, 4;
   mov        sStat_uqDataMsb, 0x00, 4;
   mov        ALU , CNT_SEMAPHORE_BASE , 4;
   nop;
   mov        sStat_3byAddress, ALU, 3;
   mov        sStat_byCommand, STS_BW_CLR_CMD, 1;
   //nop;
   //EZwaitFlag F_ST;

ENDMACRO; //semgiveTP


// ##TODO_OPTIMIZE: unify the IPv4/IPv6 buildKey macros to one, make it a function call (using PC_STACK if possible), and call it from another place instead of the loacation it is called from now.
// the parser will return the following data for use for the routiung procedure:
// 1. IPv4/6 type
// 2. FMEM_BASE of the L3 offset that will be used to extract the DIP for the routing lookup.
// 3. Return the retult about if this is RadwareTunnelGRE (this may be passed from Parse instead of from Parser).
MACRO BuildTcamRoutingTableIndexKeyFromIPv4DIP  JUMP_LABEL_AT_END_OF_MACRO, 
                                                JUMP_LABEL_NETWORK_BYPASS, 
                                                JUMP_LABEL_PARSING_DONE; // ##TODO_OPTIMIZE: instead of implement in a macro - implement in a function call using PC_STACK. before that need to check if PC_STACK is not used at this time

   // Inhabit the key value for the TCAM routing DIP lookup with the outer DIP (in this case IPv4 converted to IPv6 notation)
   // Mapping between IPV4 and IPV6 addresses:
   // 0:0:0:0:0:0:0:0:00:00:FF:FF:<IPV4_Address>
   Add COM_HBS, COM_HBS, 1, 1; //##GUY need to verify that COM_HBS is not exhausted (fully used) for all keys combinations. the solution can be to combine the lookup of the routing table with other lookups on the same key, or just to combine any other set of lookups to use the same key.
   Mov ALU, IPV4_IPV6_MAPPING_2ND, 4;
      Copy CMP_ROUTING_DIP_OFF    (COM_KBS), IP_DIP_OFF(FMEM_BASE), 4, SWAP;
   PutKey  CMP_ROUTING_DIP_2ND_OFF(COM_KBS), ALU, 4;
   Mov ALU, IPV4_IPV6_MAPPING_3RD_AND_4TH, 4;
      PutHdr HREG[COM_HBS], COMP_ROUTING_HDR_P0; // Set PHASE_0 as default value. // Nop;
   PutKey CMP_ROUTING_DIP_3RD_OFF(COM_KBS), ALU, 4;
   PutKey CMP_ROUTING_DIP_4TH_OFF(COM_KBS), ALU, 4;
   Add COM_KBS, COM_KBS, CMP_ROUTING_KMEM_SIZE, 2; // to prepare the pointer to the next feature, add the size of the current key. //Nop;

   If (!uqGcCtrlReg0.bit[GC_CNTRL_0_ROUTING_PHASE_BIT]) jmp BUILD_IPV4_KEY_SKIP_OVERITE_TO_PHASE_1, NO_NOP;
      Mov ENC_PRI, 0, 2;
      MovBits ENC_PRI.BIT[14], bitTmpCtxReg2DeferBypassNetworkUntilBuildRoutingKey, 2; // loads also bit bitTmpCtxReg2DeferParsingDoneUntilBuildRoutingKey

   // Phase bit is 1 - overwrite the default that was set few lines above.
   PutHdr HREG[COM_HBS], COMP_ROUTING_HDR_P1;

BUILD_IPV4_KEY_SKIP_OVERITE_TO_PHASE_1:
      Nop;
   Jmul JUMP_LABEL_PARSING_DONE,
        JUMP_LABEL_NETWORK_BYPASS,
        JUMP_LABEL_AT_END_OF_MACRO,
        NOP_2;

   Jmp JUMP_LABEL_AT_END_OF_MACRO, NOP_2;
ENDMACRO; // BuildTcamRoutingTableIndexKeyFromIPv4DIP



MACRO BuildTcamRoutingTableIndexKeyFromIPv6DIP  JUMP_LABEL_AT_END_OF_MACRO, 
                                                JUMP_LABEL_NETWORK_BYPASS, 
                                                JUMP_LABEL_PARSING_DONE; // ##TODO_OPTIMIZE: instead of implement in a macro - implement in a function call using PC_STACK. before that need to check if PC_STACK is not used at this time

   // Inhabit the key value for the TCAM routing DIP lookup with the outer DIP
   Add COM_HBS, COM_HBS, 1, 1; //##TODO_OPTIMIZE - move down to use nop time //##GUY need to verify that COM_HBS is not exhausted (fully used) for all keys combinations. the solution can be to combine the lookup of the routing table with other lookups on the same key, or just to combine any other set of lookups to use the same key.
      Copy CMP_ROUTING_DIP_OFF    (COM_KBS), {IPv6_DIP_OFF+8}(FMEM_BASE), 8, SWAP;
   Copy    CMP_ROUTING_DIP_3RD_OFF(COM_KBS), {IPv6_DIP_OFF+0}(FMEM_BASE), 8, SWAP;
   PutHdr HREG[COM_HBS], COMP_ROUTING_HDR_P0; // Set PHASE_0 as default value.
   Add COM_KBS, COM_KBS, CMP_ROUTING_KMEM_SIZE, 2; // to prepare the pointer to the next feature, add the size of the current key. //Nop;

   If (!uqGcCtrlReg0.bit[GC_CNTRL_0_ROUTING_PHASE_BIT]) jmp BUILD_IPV6_KEY_SKIP_OVERITE_TO_PHASE_1, NO_NOP;
      Mov ENC_PRI, 0, 2;
      MovBits ENC_PRI.BIT[14], bitTmpCtxReg2DeferBypassNetworkUntilBuildRoutingKey, 2; // loads also bit bitTmpCtxReg2DeferParsingDoneUntilBuildRoutingKey

   // Phase bit is 1 - overwrite the default that was set few lines above (if arriving to here).
   PutHdr HREG[COM_HBS], COMP_ROUTING_HDR_P1;
  
BUILD_IPV6_KEY_SKIP_OVERITE_TO_PHASE_1:
      Nop;
   Jmul JUMP_LABEL_PARSING_DONE,
        JUMP_LABEL_NETWORK_BYPASS,
        JUMP_LABEL_AT_END_OF_MACRO,
        NOP_2;

   Jmp JUMP_LABEL_AT_END_OF_MACRO, NOP_2;
ENDMACRO; // BuildTcamRoutingTableIndexKeyFromIPv6DIP




/*==============================================================================
macro PRSWaitForEndOfLookAside
==============================================================================*/
// Wait in TOPparse for the LookAside that was invoked to end.
/// This is necessary in 1 cases:
// 1. Before using the LA result.
// 2. Before halting the TOPparse program - in case that microcode invoked LA - need to wait for it to finish.
MACRO PRSWaitForEndOfIpv4DipLookAside;
   /* Wait for CTX line of the LA */
   EZwaitFlag F_CTX_LA_RDY_0; // Wait for flag that marks that the LookAside was ended.
   EZwaitFlag F_CTX_IF_1;     // Wait until the context interface is ready for GetCtx command to be executed.

L_PRS_READ_CTX_LINE:

   GetCtx uqPRS_IPv4DIP_LookAsideResult    , CTX_LINE_EZCH_SYSTEMS_IPV4DIP_LA;
      Nop;
      Nop;
      Nop; // Another nop for extra caution - may be not necesarry but should not affect timing as reading the context will
           // consume about 15 clock cycles anyway so busy wait would be performed anyway.
   EZwaitFlag F_CTX_IF_1; // Wait until context holds the value that was read using the GetCtx command.
   If (!FLAGS.bit[F_CTX_VALID_1]) // Test if the context already holds the result of the LA that was performed.
      Jmp L_PRS_READ_CTX_LINE, NOP_2; // in case that it is not valid - the search result write to the CTXT
                                      // was not finished yet - repeat reading the context line.
ENDMACRO;


