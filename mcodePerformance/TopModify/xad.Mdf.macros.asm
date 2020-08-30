/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Mdf.Macros.asm
*
*  Usage:         TOPmodify macros file
*
*******************************************************************************/

            
//----------------------------------------------------//
//           MACRO CreateSynCookiePacket              //
//----------------------------------------------------//
MACRO CreateSynCookiePacket_gre;

// This is the second implementation:
// Here 
// 1. we leave the L2, L3 and L4 headers in place, but change
// The length of the packet.
// 2. We calculate TCP checksum from scratch
// 3. Cut off any data after TCP header.
// 4. If frame is too small, add trailer

// Generate syn cookie packet here,
// update send registers 
// swap MACs, IPs, TCP ports
// Remove TCP options - leave one MSS


// Reverse TCP ports
// Reverse MAC addr
// Reverse IP

// SEQ_NUM + 1 => ACK Num
// Turn on SYN + ACK flags
// Encode MSS or use default
// Write MSS option
// Write TCP Checksum
// Update TTL/ HOP limit ?
// Update Payload length/ Total length in IP


// IP Length field affects TCP checksum !

#define uqMSS_OPTION          uqTmpReg3;
#define uxMSS_VAL             uqTmpReg3.byte[0];
#define byMSS_CODE            uqTmpReg4.byte[2];
#define uxFRM_ADJUSTMENT_VAL  uqTmpReg4.byte[0];
#define IP_VERSION_BIT        byTempCondByte1.bit[0];
#define IP_TUN_VERSION_BIT    byTempCondByte2.bit[1];
#define byDATA_OFFSET         bytmp1;
VarDef RegType L3_TUN_FR_PTR  tmpFR_PTR;
vardef regtype uqSynCookie     uqTmpReg7.BYTE[0:3];

#define MIN_FRAME_LENGTH      64;
#define TCP_HEADER_LENGTH     24;

SynCookieCalc;

Mov     uqTmpReg3,      0, 4;
GetRes  uqTmpReg6,      MSG_GRE_USR_OFF(MSG_STR), 2;
//GetRes  uqTmpReg1,      MSG_L3_USR_OFF (MSG_STR), 2; // The reading used to initialized Lx_FR_PTRs that originaly was here, was moved to the beginning of mdf.asm
GetRes  $L3_TUN_FR_PTR, MSG_L3_USR_OFF (MSG_STR), 2;

Add sSend_uxFrameLen, L4_FR_PTR,  TCP_HEADER_LENGTH, 2, MASK_000000FF, MASK_SRC1; // Frame will end at end of TCP header
   Nop;

// Check if frame is too short
Sub ALU, ALU, MIN_FRAME_LENGTH, 4;  // ALU contains sSend_uxFrameLen
   Nop;
jnc NOT_TOO_SHORT, NO_NOP;
  xor CHK_SUM_TCP, ALU, ALU, 2;     // Start with Zero Checksum
  nop;

Add sSend_uxFrameLen, uqZeroReg, MIN_FRAME_LENGTH, 2; // Adjust frame to MIN_FRAME_LENGTH



NOT_TOO_SHORT:

#define CHECKSUM_ADJ_CONST (TCP_HEADER_LENGTH + 6 + 1); 
// Since TCP_CHECKSUM is now '0', we can safely add const to one byte without checking 
// overflow. L3 header length < 255

GetRes uqTmpReg5, MSG_SYN_COOKIE_OFF(MSG_STR), 4;  // Get SYN cookie calculated in TOPparse
/*
Mov  uqTmpReg5 , $uqSynCookie , 4;
*/
nop;
Movbits IP_VERSION_BIT, uqTmpReg5.bit[24], 1;

Sub uqTmpReg6, sSend_uxFrameLen, uqTmpReg6, 2, MASK_0000FFFF, MASK_BOTH;

if (IP_VERSION_BIT) jmp SKIP_IPV6_CHKSUM_ADJ, NOP_2;

Sub CHK_SUM_TCP.byte[1], CHK_SUM_TCP.byte[1], CHECKSUM_ADJ_CONST, 1; // Remove TCP length from checksum
Sub CHK_SUM_TCP.byte[0], CHK_SUM_TCP.byte[0], 1, 1;

SKIP_IPV6_CHKSUM_ADJ:

// Optimized for IPv4 (in IPv6, it will be removed later)

Sub sSend_ux1stBufLen, sSend_uxFrameLen, 1, 2; // Asuming only one buffer
Movbits ALU, sSend_byBuffNum, RFD_RD0_6_BITS;
Sub ALU, ALU, 1, 1, RFD_RD0_3F_MASK, MASK_SRC1;
   Nop;
jz SYN_COOKIE_ONE_BUFFER, NOP_2;

EZwaitFlag F_RD;

// Get next RFD pointer
EZrfdReadEntryOptimized;

// Recycle from second buffer <num of buffers – 1>
Sub sSend_byBuffNum, sSend_byBuffNum, 1, 1, RFD_RD0_3F_MASK, MASK_SRC1;
EZrfdRecycle RFD_RD0, sSend_byBuffNum, sSend_bySrcPort;
Movbits sSend_byBuffNum, 1, RFD_RD0_6_BITS;	// Set number of buffers to 1

SYN_COOKIE_ONE_BUFFER:

Get byDATA_OFFSET, TCP_DATAOFF_OFF( L4_FR_PTR ), 1;
   nop;
Movbits ALU, byDATA_OFFSET.bit[4], 4;
Movbits ALU.bit[4], 0, 4;

movbits uxMSS_VAL,  MSS_DEFAULT_RANGE, 16; // default MSS val, unless other will be found in TCP header
sub ALU, ALU, 6, 1;
   movbits byMSS_CODE, MSS_DEFAULT_CODE, 8; // default MSS code, unless other will be found in TCP header

jc SYN_COOKIE_WRITE_DEFAULT_MSS, NOP_2;

// Get the first TCP option (Currently we check only the first one)
Get uqTmpReg1, TCP_BASE_SIZE(L4_FR_PTR), 4, SWAP;
   nop;

Sub ALU,  uqTmpReg1.byte[3], 2, 1;
   nop;

jnz SYN_COOKIE_WRITE_DEFAULT_MSS, NOP_2;	// If First options kind is not '2' (MSS) write the default one

// Mov ALU,  MSS_RANGE_0_MIN, 4;
// nop;
// Mov uqTmpReg2, ALU, 2;
Add uqTmpReg2, uqZeroReg , MSS_RANGE_0_MIN, 2;   // Assuming MSS_RANGE_0_MIN < 255

#define IC_CNTRL_1_MDF_JUMBOMODE ( 1/*1 <<IC_CNTRL_0_JUMBOMODE_MDF_OFF*/);

xor uqTmpReg5, ALU, !ALU, 4, GC_CNTRL_MDF_2, MASK_BOTH;
   nop;
And ALU, uqTmpReg5.byte[2],  IC_CNTRL_1_MDF_JUMBOMODE, 1;
   nop;

jz JUMBO_MSS_CALC_LAB, NOP_2; 


MSS_TestRange MSS_RANGE_1_MIN, 0, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_2_MIN, 1, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_3_MIN, 2, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_4_MIN, 3, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_5_MIN, 4, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_6_MIN, 5, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_7_MIN, 6, SYN_COOKIE_WRITE_DEFAULT_MSS;

jmp  JUMBO_MSS_CALC_LAB_DONE | NOP_2;

JUMBO_MSS_CALC_LAB:

MSS_TestRange MSS_RANGE_0_JUMBO_MIN, 0, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_2_JUMBO_MIN, 1, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_3_JUMBO_MIN, 2, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_4_JUMBO_MIN, 3, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_5_JUMBO_MIN, 4, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_6_JUMBO_MIN, 5, SYN_COOKIE_WRITE_DEFAULT_MSS;
MSS_TestRange MSS_RANGE_7_JUMBO_MIN, 6, SYN_COOKIE_WRITE_DEFAULT_MSS;

JUMBO_MSS_CALC_LAB_DONE:


Mov uxMSS_VAL, uqTmpReg2, 2;
movbits byMSS_CODE, 7, 3;

SYN_COOKIE_WRITE_DEFAULT_MSS:

//GetRes uqTmpReg2, MSG_SYN_COOKIE_OFF(MSG_STR), 4;  // Get SYN cookie calculated in TOPparse
Mov uqTmpReg2 , $uqSynCookie , 4; 
Add uqMSS_OPTION.byte[3],  uqZeroReg, 2, 1;
Add uqMSS_OPTION.byte[2],  uqZeroReg, 4, 1;

// Jump if SYN-ACK challenge case
if (!byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS]) jmp SYN_COOKIE_SKIP_RST_CHALLENGE, NO_NOP;
    //Movbits IP_VERSION_BIT, uqTmpReg2.bit[24], 1;   // The IP version bit was sent in the cookie (offset 24)
    Nop;
	if (!byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS]) Movbits uqTmpReg2.bit[24], byMSS_CODE, 3;     // Update MSS encoding in SYN cookie.

// For ACK challenge only: get Safe Reset cookie calculated in TOPparse
GetRes ALU, MSG_RST_COOKIE_OFF(MSG_STR), 3;       
Movbits uqTmpReg2.bit[16], uqTmpReg2.bit[6], 6;
Movbits uqTmpReg2.bit[ 6], ALU.bit[ 0], 10;
Movbits uqTmpReg2.bit[22], ALU.bit[10], 10;

SYN_COOKIE_SKIP_RST_CHALLENGE:

// If SYN-ACK challenge -> skip cookie window test (intended for Safe Reset only)
if (!byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS]) Jmp PREPARE_CHALLENGE_LAB, NO_NOP;
   Get uqTmpReg1, TCP_SEQ_OFF(L4_FR_PTR), 4, SWAP;					   // Get Seq number
   Put TCP_BASE_SIZE(L4_FR_PTR), uqMSS_OPTION, 4, SWAP, TCP_CHK;  // Write MSS option while updating checksum


//////////////////////////////////////////////////
//  Safe Reset: Check SYN Cookie and TCP window
//////////////////////////////////////////////////

// Check whether new Seq# (SYN Cookie) is within TCP Window or not

// Sub (NewSeq# - OldSeq#)
Sub uqTmpReg1, uqTmpReg2, uqTmpReg1, 4; 
Mov ALU, 0xFFFF0000, 4;
             
// If (NewSeq# - OldSeq#) >= 0 continue in label NEW_SYN_COOKIE_BIGGER
if (!C) jmp NEW_SYN_COOKIE_BIGGER, NOP_2;

// Case 1: (NewSeq# - OldSeq#) < 0
NEW_SYN_COOKIE_SMALLER:

// Check if (NewSeq# - OldSeq#) > 0xFFFF
Sub ALU, ALU, uqTmpReg1, 4; 
Mov ALU, RST_OUT_OF_WINDOW_VAL, 4; 

// If (NewSeq# + 0xFFFFFFFF - OldSeq#) > 0xFFFF do nothing
ja PREPARE_CHALLENGE_LAB, NOP_2; 

// If (NewSeq# + 0xFFFFFFFF - OldSeq#) =< 0xFFFF add magic number (RST_OUT_OF_WINDOW_VAL)
jmp PREPARE_CHALLENGE_LAB, NOP_1;    
    Add uqTmpReg2, uqTmpReg2, ALU, 4;


// Case 2: (NewSeq# - OldSeq#) >= 0
NEW_SYN_COOKIE_BIGGER:

Mov ALU, 0xFFFF, 4;

// Check if (NewSeq# - OldSeq#) > 0xFFFF
Sub ALU, uqTmpReg1, ALU, 4;
Mov ALU, RST_OUT_OF_WINDOW_VAL, 4;

// If (NewSeq# - OldSeq#) > 0xFFFF do nothing
ja PREPARE_CHALLENGE_LAB, NOP_2;

// If (NewSeq# - OldSeq#) =< 0xFFFF add magic number (RST_OUT_OF_WINDOW_VAL) 
Add uqTmpReg2, uqTmpReg2, ALU, 4;   


////////////////////////////////////////////////////
//  Modify specific challenge fields (ACK,SYN-ACK)
////////////////////////////////////////////////////

PREPARE_CHALLENGE_LAB:

Movbits ENC_PRI.bit[13], 0x1, 3; // Default challenge is SYN-ACK (if no other challenge chosen it will be the selected challenge)
Movbits ENC_PRI.bit[14], byCtrlMsgMdf0.bit[MSG_CTRL_TOPRSV_0_CHALLENGE_TYPE_BITS], 2;

Add uqTmpReg1, uqTmpReg1, 1, 4;  // Increment SEQ# by 1

#define CONST_DATA_OFFSET (( TCP_HEADER_LENGTH >> 2) << 4);
#define SYN_COOKIE_WINDOW_SIZE_SWAPPED ((SYN_COOKIE_WINDOW_SIZE >> 8) | ((SYN_COOKIE_WINDOW_SIZE << 8) & 0xFF00));
Put TCP_DATAOFF_OFF    (L4_FR_PTR), CONST_DATA_OFFSET,              1, TCP_CHK;
Put TCP_WINDOW_OFF     (L4_FR_PTR), SYN_COOKIE_WINDOW_SIZE_SWAPPED, 2, TCP_CHK;
Put TCP_URG_POINTER_OFF(L4_FR_PTR), SYN_COOKIE_URG_PTR,             2, TCP_CHK;  // Put constant (0) for Urgent Pointer

jmul PREPARE_RST_CHALLENGE_LAB,
     PREPARE_ACK_CHALLENGE_LAB,
     PREPARE_SYNACK_CHALLENGE_LAB,
     NOP_2;

// RST specific handling
PREPARE_RST_CHALLENGE_LAB:
Get uqTmpReg2, TCP_ACK_OFF(L4_FR_PTR), 4;        		                     // Get ACK#
Get ALU, TCP_SEQ_OFF(L4_FR_PTR), 4, SWAP;        		                     // Get SEQ#
Add ALU, ALU, 1, 4;                                                        // Increment SEQ# by 1
Put TCP_SEQ_OFF(L4_FR_PTR), uqTmpReg2, 4, TCP_CHK;        		            // Put original ACK# in SEQ# field
jmp SWAP_PACKET_FIELDS_LAB, NO_NOP;
    Put TCP_FLAGS_OFF(L4_FR_PTR), TCP_RST_ACK_FLAGS, 1, TCP_CHK;           // Update TCP flags to RST-ACK type
    Put TCP_ACK_OFF  (L4_FR_PTR), ALU,                 4, SWAP, TCP_CHK;   // Put incremented SEQ# field in ACK# place

// ACK specific handling
PREPARE_ACK_CHALLENGE_LAB:
Put TCP_FLAGS_OFF(L4_FR_PTR), TCP_ACK_FLAGS, 1, TCP_CHK;                   // Update TCP flags to ACK type
jmp SWAP_PACKET_FIELDS_LAB, NO_NOP;
    Put TCP_SEQ_OFF(L4_FR_PTR), uqTmpReg2, 4, SWAP, TCP_CHK;               // Write cookie in SEQ# field
    Put TCP_ACK_OFF(L4_FR_PTR), uqTmpReg2, 4, SWAP, TCP_CHK;               // Write cookie in ACK# field

// SYN-ACK specific handling
PREPARE_SYNACK_CHALLENGE_LAB:
Put TCP_FLAGS_OFF(L4_FR_PTR), TCP_SYN_ACK_FLAGS, 1, TCP_CHK;               // Update TCP flags to SYN-ACK type
jmp SWAP_PACKET_FIELDS_LAB, NO_NOP; 
    Put TCP_SEQ_OFF(L4_FR_PTR), uqTmpReg2, 4, SWAP, TCP_CHK;               // Write cookie in SEQ# field
    Put TCP_ACK_OFF(L4_FR_PTR), uqTmpReg1, 4, SWAP, TCP_CHK; 	            // Update ACK# field to SEQ#+1


////////////////////////////////////////////////
//      Challenge packet - Swap fields
////////////////////////////////////////////////

SWAP_PACKET_FIELDS_LAB:

// Swap L4 Dst &  Src ports
Get uqTmpReg1, TCP_SPRT_OFF(L4_FR_PTR), 2;
Get uqTmpReg2, TCP_DPRT_OFF(L4_FR_PTR), 2;

if (IP_VERSION_BIT) jmp TREAT_IPV6, NO_NOP;  
  Put TCP_DPRT_OFF(L4_FR_PTR), uqTmpReg1, 2, TCP_CHK;
  Put TCP_SPRT_OFF(L4_FR_PTR), uqTmpReg2, 2, TCP_CHK;

// Swap IPv4 user fields

Get uqTmpReg1,  IP_SIP_OFF(L3_FR_PTR), 4;
Get uqTmpReg2,  IP_DIP_OFF(L3_FR_PTR), 4;
Get CHK_SUM_IP, IP_CHK_OFF(L3_FR_PTR), 2;   // Update only TCP checksum (TCP pseudoheader for chksum calculation)
Put IP_DIP_OFF(L3_FR_PTR), uqTmpReg1,  4, TCP_CHK;
Put IP_SIP_OFF(L3_FR_PTR), uqTmpReg2,  4, TCP_CHK;

// Check if tunnel exists
//If (!byCtrlMsgMdf1.bit[MSG_CTRL_TOPRSV_1_L3_TUNNEL_EXISTS_BIT]) jmp SKIP_TUN_L3_SWAP, NOP_2;

// Tunnel exists, now check if it's IPv6 tunnel
//if ( IP_TUN_VERSION_BIT ) Jmp IPV6_TUN_TYPE_LAB, NOP_2;

// Swap IPv4 tunnel fields

//Get uqTmpReg1, IP_SIP_OFF($L3_TUN_FR_PTR),  4;
//Get uqTmpReg2, IP_DIP_OFF($L3_TUN_FR_PTR),  4;
//Mov uqTmpReg3, CHK_SUM_IP, 2;
//Put IP_DIP_OFF($L3_TUN_FR_PTR), uqTmpReg1,  4;
//Put IP_SIP_OFF($L3_TUN_FR_PTR), uqTmpReg2,  4;
//Get CHK_SUM_IP, IP_CHK_OFF($L3_TUN_FR_PTR), 2;
//Add ALU, uqZeroReg, SYN_COOKIE_TTL_VAL, 1;
//nop; 
//Put IP_TTL_OFF(L3_FR_PTR), ALU, 1, IP_CHK; // TTL Does not affect TCP checksum.
//nop;
//nop;
//jmp SKIP_TUN_L3_SWAP, NO_NOP;
//Put IP_CHK_OFF(L3_FR_PTR), CHK_SUM_IP, 2;
//nop;
	//Mov CHK_SUM_IP, uqTmpReg3, 2;



// Update IP Length & TTL fields

Get uqTmpReg2, IP_LEN_OFF(L3_FR_PTR), 2, IP_CHK, SWAP; 
Get uqTmpReg1, IP_TTL_OFF(L3_FR_PTR), 1, IP_CHK;

// Calculate new IP Segment size
Add ALU, L4_FR_PTR, TCP_HEADER_LENGTH, 2;
Sub uqTmpReg2, ALU, L3_FR_PTR, 2;

Put IP_TTL_OFF(L3_FR_PTR), SYN_COOKIE_TTL_VAL, 1, IP_CHK; 	// TTL Does not affect TCP checksum
Put IP_LEN_OFF(L3_FR_PTR), uqTmpReg2, 2, SWAP, IP_CHK;     	// IP Length does not affect TCP checksum

jmp COMPLETE_COOKIE, NO_NOP;
  nop;
  Put IP_CHK_OFF(L3_FR_PTR), CHK_SUM_IP, 2;


TREAT_IPV6:

// Swap IPv6 user fields
      
#define  IPv6_SIP_OFF_2ND (IPv6_SIP_OFF + 4);
#define  IPv6_DIP_OFF_2ND (IPv6_DIP_OFF + 4);
#define  IPv6_SIP_OFF_3RD (IPv6_SIP_OFF + 8);
#define  IPv6_DIP_OFF_3RD (IPv6_DIP_OFF + 8);
#define  IPv6_SIP_OFF_4TH (IPv6_SIP_OFF + 12);
#define  IPv6_DIP_OFF_4TH (IPv6_DIP_OFF + 12);
#define  TCP_HEADER_LENGTH_SWAPPED ((TCP_HEADER_LENGTH >> 8) | ((TCP_HEADER_LENGTH << 8) & 0xFF00));

// TCP checksum correction: (30) includes TCP length (24) and protocol (6)
Mov ALU, 30, 4;

Put IPv6_HOP_LIMIT_OFF(L3_FR_PTR), SYN_COOKIE_TTL_VAL,   1;
Put IPv6_PAYLOAD_LEN_OFF(L3_FR_PTR), ALU, 2, SWAP, TCP_CHK;        // write first to update TCP checksum
Put IPv6_PAYLOAD_LEN_OFF(L3_FR_PTR), TCP_HEADER_LENGTH_SWAPPED, 2; // IP Length affects TCP checksum:

IPV6_IPV6_TUN_TYPE_SKIP_LAB:

// SWAP SIP & DIP while updating TCP checksum
Get uqTmpReg1, IPv6_SIP_OFF(L3_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF(L3_FR_PTR), 4;
Put IPv6_DIP_OFF(L3_FR_PTR), uqTmpReg1, 4, TCP_CHK;
Put IPv6_SIP_OFF(L3_FR_PTR), uqTmpReg2, 4, TCP_CHK;

Get uqTmpReg1, IPv6_SIP_OFF_2ND(L3_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF_2ND(L3_FR_PTR), 4;
Put IPv6_DIP_OFF_2ND(L3_FR_PTR), uqTmpReg1, 4, TCP_CHK;
Put IPv6_SIP_OFF_2ND(L3_FR_PTR), uqTmpReg2, 4, TCP_CHK;

Get uqTmpReg1, IPv6_SIP_OFF_3RD(L3_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF_3RD(L3_FR_PTR), 4;
Put IPv6_DIP_OFF_3RD(L3_FR_PTR), uqTmpReg1, 4, TCP_CHK;
Put IPv6_SIP_OFF_3RD(L3_FR_PTR), uqTmpReg2, 4, TCP_CHK;

Get uqTmpReg1, IPv6_SIP_OFF_4TH(L3_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF_4TH(L3_FR_PTR), 4;
Put IPv6_DIP_OFF_4TH(L3_FR_PTR), uqTmpReg1, 4, TCP_CHK;
Put IPv6_SIP_OFF_4TH(L3_FR_PTR), uqTmpReg2, 4, TCP_CHK;

// Swap IPs tunnel

// Check if L3 tunnel exists
If (!byCtrlMsgMdf1.bit[MSG_CTRL_TOPRSV_1_L3_TUNNEL_EXISTS_BIT]) jmp SKIP_IPV6_TUN_L3_SWAP, NOP_2;

if ( IP_TUN_VERSION_BIT ) Jmp IPV6_IPV6_TUN_TYPE_LAB, NOP_2;

get uqTmpReg1, IP_SIP_OFF($L3_TUN_FR_PTR), 4;
get uqTmpReg2, IP_DIP_OFF($L3_TUN_FR_PTR), 4;
Put  IP_DIP_OFF($L3_TUN_FR_PTR), uqTmpReg1, 4;

If (!byCtrlMsgMdf1.bit[MSG_CTRL_TOPRSV_1_L3_TUNNEL_EXISTS_BIT]) jmp SKIP_IPv4_L3_TUN_UPD, NO_NOP;
   Sub ALU, sSend_uxFrameLen, $L3_TUN_FR_PTR, 2, MASK_0000FFFF, MASK_BOTH;
   Put IP_SIP_OFF($L3_TUN_FR_PTR), uqTmpReg2, 4;

Put IP_LEN_OFF($L3_TUN_FR_PTR), ALU, 2,  SWAP, IP_CHK;     // IP Length does not affect TCP checksum:

// Put IP_PRT_OFF(L3_FR_PTR), uqTmpReg1, 1, _NO_CHK_MDF, TCP_CHK;  // This is just for calculation of TCP checksum, but Type will always be '6' (constant

jmp  SKIP_IPV6_TUN_L3_SWAP, NOP_2;

IPV6_IPV6_TUN_TYPE_LAB:



#define  IPv6_SIP_OFF_2ND (IPv6_SIP_OFF + 4);
#define  IPv6_DIP_OFF_2ND (IPv6_DIP_OFF + 4);
#define  IPv6_SIP_OFF_3RD (IPv6_SIP_OFF + 8);
#define  IPv6_DIP_OFF_3RD (IPv6_DIP_OFF + 8);
#define  IPv6_SIP_OFF_4TH (IPv6_SIP_OFF + 12);
#define  IPv6_DIP_OFF_4TH (IPv6_DIP_OFF + 12);

// SWAP SIP & DIP while updating TCP checksum

Get uqTmpReg1, IPv6_SIP_OFF($L3_TUN_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF($L3_TUN_FR_PTR), 4;
Put IPv6_DIP_OFF($L3_TUN_FR_PTR), uqTmpReg1, 4;
Put IPv6_SIP_OFF($L3_TUN_FR_PTR), uqTmpReg2, 4;

Get uqTmpReg1, IPv6_SIP_OFF_2ND($L3_TUN_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF_2ND($L3_TUN_FR_PTR), 4;
Put IPv6_DIP_OFF_2ND($L3_TUN_FR_PTR), uqTmpReg1, 4;
Put IPv6_SIP_OFF_2ND($L3_TUN_FR_PTR), uqTmpReg2, 4;

Get uqTmpReg1, IPv6_SIP_OFF_3RD($L3_TUN_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF_3RD($L3_TUN_FR_PTR), 4;
Put IPv6_DIP_OFF_3RD($L3_TUN_FR_PTR), uqTmpReg1, 4;
Put IPv6_SIP_OFF_3RD($L3_TUN_FR_PTR), uqTmpReg2, 4;

Get uqTmpReg1, IPv6_SIP_OFF_4TH($L3_TUN_FR_PTR), 4; 
Get uqTmpReg2, IPv6_DIP_OFF_4TH($L3_TUN_FR_PTR), 4;
Put IPv6_DIP_OFF_4TH($L3_TUN_FR_PTR), uqTmpReg1, 4;
Put IPv6_SIP_OFF_4TH($L3_TUN_FR_PTR), uqTmpReg2, 4;

#undef IPv6_SIP_OFF_2ND;
#undef IPv6_DIP_OFF_2ND;
#undef IPv6_SIP_OFF_3RD;
#undef IPv6_DIP_OFF_3RD;
#undef IPv6_SIP_OFF_4TH;
#undef IPv6_DIP_OFF_4TH;
VarUndef L3_TUN_FR_PTR;
varundef uqSynCookie;


SKIP_IPV6_TUN_L3_SWAP:
SKIP_IPv4_L3_TUN_UPD:
COMPLETE_COOKIE:



// Trailer is probably not needed for IPv6
Put TCP_HEADER_LENGTH(L4_FR_PTR), 0x0101, 2;
#define TRAILER_2 ( TCP_HEADER_LENGTH + 2);
#define TRAILER_3 ( TCP_HEADER_LENGTH + 4);
Put TRAILER_2(L4_FR_PTR), 0x0101, 2;
Put TRAILER_3(L4_FR_PTR), 0x0101, 2;
Put TCP_CHK_OFF(L4_FR_PTR), CHK_SUM_TCP, 2;


//##TODO_OPTIMIZE - for SYN protection: 1. check that the DMAC-SMAC swap actually works and make the optimized option work.
#ifdef OPT_FOR_HW;
#pragma EZ_Warnings_Off;
// With HW OPT, take advantage of Data Hazard for quick Swap
write ETH_DA_OFF(L2_FR_PTR),  ETH_SA_OFF(L2_FR_PTR), 6;
write ETH_SA_OFF(L2_FR_PTR),  ETH_DA_OFF(L2_FR_PTR), 6;
#pragma EZ_Warnings_On;
#else; // of #ifdef OPT_FOR_HW;
write -6        (L2_FR_PTR),  ETH_SA_OFF(L2_FR_PTR), 6; 
Nop;
write ETH_SA_OFF(L2_FR_PTR),  ETH_DA_OFF(L2_FR_PTR), 6;
nop;
write ETH_DA_OFF(L2_FR_PTR),  -6        (L2_FR_PTR), 6;
//nop;
#endif; // of #else; of #ifdef OPT_FOR_HW;
ENDMACRO; // of CreateSynCookiePacket_gre



MACRO MSS_TestRange RangeMin, Code, JmpLab;
    Mov ALU,  RangeMin, 4;
    Mov uxMSS_VAL, uqTmpReg2, 2;
    Mov uqTmpReg2, ALU, 2;
    // Add uqTmpReg2, uqZeroReg, RangeMin , 2; (An Imm operand cannot have a value more than 255)
    Sub ALU, uqTmpReg1.byte[0], ALU, 2;
    movbits byMSS_CODE, Code, 3;
    jc JmpLab, NOP_2;
ENDMACRO;

#define FIRST_SWITH_VLAN  0xa04
#define END_SWITH_VLAN    0xa1f

#define FIRST_END_SWITH_VLAN 0x0a1f0a04



/*******************************************************************************\
 * Description: Add TM header before the frame payload
 * Parameters:  No
 * Assumptions: sSend_byDstPort - holds Out port number
 * Affected:    uqTmpReg5/6 (UREG[ 6,7 ], ALU
\*******************************************************************************/


MACRO AddTMHeaderToSamePort;

VarDef RegType EZmdf_RegulTmHdr     sTmHdr   uqTmpReg6;

   sub      DISP_REG, DISP_REG, TM_HEADER_SIZE, 2;
   Mov uxTmpReg1 , uqZeroReg , 4;       
   mov      $sTmHdr.BYTE[ 0 ], uqZeroReg, 4;   
   mov      $sTmHdr.BYTE[ 4 ], uqZeroReg, 4;
   mov $sTmHdr.bySrcPort, sSend_byDstPort , 1;       

   sub      uxTmpReg1.byte[3] , sSend_byDstPort , 96 , 1;


   mov      ALU , 96 , 1; 
   sub      ALU , sSend_byDstPort  ,ALU , 2;
   Nop;
   MovBits  uxTmpReg1.byte[0] , ALU.bit[0] , 3; 

   //getres   $sTmHdr.bySrcPort, MSG_CONTROL_HW_MSG_SRC_PORT_OFF(MSG_STR) , 1;
   
   // Create FID = (destination port) * 64
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 4; s 8 na 8
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 5;
   //movbits  $sTmHdr.bitsFID[ 0 ], 928, 16; --na 9
   //movbits  $sTmHdr.bitsFID[ 0 ], 918, 16; -- na 9 
   //movbits  $sTmHdr.bitsFID[ 0 ], 800 , 16; -- na 9
   // movbits  $sTmHdr.bitsFID[ 0 ], 400 , 16; -- na 7 
   //movbits  $sTmHdr.bitsFID[ 0 ], 100 , 16; -- na 6 
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x400 , 16; -- na 10
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x500 , 16; --n 11
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x0 , 16; -- na CAUI 0
   
   Mov $sTmHdr.bySrcPort , sSend_byDstPort , 1;
   movbits  $sTmHdr.bitsFID[ 0 ], 400 , 16;

   movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 4;
   
   
   
    
   movbits  sSend_bitDstTm, TM_0, 1; // assuming all traffic goes to TM_0


   /*
   mov $sTmHdr.bitsFID[8], uxTmpReg1.byte[3] , 1;

   mov $sTmHdr.bitsFID[0], uxTmpReg1.byte[0] , 1;
   */


   // Put TM Interface Header Fields      
   put      0 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 0 ], 4, SWAP;  
   put      4 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 4 ], 4, SWAP; 
   put      8 ( FMEM_BASE0 ), uqZeroReg, 4;
   put      12( FMEM_BASE0 ), uqZeroReg, 4;

VarUnDef sTmHdr;

ENDMACRO;

/*******************************************************************************\
 * Description: Add TM header before the frame payload
 * Parameters:  No
 * Assumptions: sSend_byDstPort - holds Out port number
 * Affected:    uqTmpReg5/6 (UREG[ 6,7 ], ALU
\*******************************************************************************/


MACRO AddTMHeaderToOutPortMrq;


VarDef RegType EZmdf_RegulTmHdr     sTmHdr   uqTmpReg6;

   Mov uxTmpReg1 , 6 , 1;
   GetRes ALU , MSG_HASH_CORE_OFF(MSG_STR), 2; //get vif out from structure
   //LongDiv ALU, ALU, 6, 1;
   LongDiv ALU , ALU , uxTmpReg1 , 1;     
   Nop;
   Nop;
   Nop;

   Nop;
   Nop;
   Nop;
   Add  ALU , ALU , IF_PORT_NET1_SWITCH_MRQ , 1;
   Nop;
   //Mov sSend_byDstPort , ALU , 1;
   Add sSend_byDstPort , ALU , 1 , 1;

   //Mov sSend_byDstPort , 99 , 1;

   sub      DISP_REG, DISP_REG, TM_HEADER_SIZE, 2;

   Mov uxTmpReg1 , uqZeroReg , 4;
    
   //Add sSend_byDstPort , sSend_byDstPort , 2, 1;
   mov      $sTmHdr.BYTE[ 0 ], uqZeroReg, 4;

   mov      $sTmHdr.BYTE[ 4 ], uqZeroReg, 4;


   mov $sTmHdr.bySrcPort, sSend_byDstPort , 1;
   sub      uxTmpReg1.byte[3] , sSend_byDstPort , 97 , 1;
   Nop;
         
       
   //getres   $sTmHdr.bySrcPort, MSG_CONTROL_HW_MSG_SRC_PORT_OFF(MSG_STR) , 1;
   
   // Create FID = (destination port) * 64
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 4; s 8 na 8
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 5;
   //movbits  $sTmHdr.bitsFID[ 0 ], 928, 16; --na 9
   //movbits  $sTmHdr.bitsFID[ 0 ], 918, 16; -- na 9 
   //movbits  $sTmHdr.bitsFID[ 0 ], 800 , 16; -- na 9
   // movbits  $sTmHdr.bitsFID[ 0 ], 400 , 16; -- na 7 
   //movbits  $sTmHdr.bitsFID[ 0 ], 100 , 16; -- na 6 
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x400 , 16; -- na 10
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x500 , 16; --n 11
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x0 , 16; -- na CAUI 0

   
   movbits  sSend_bitDstTm, TM_0, 1; // assuming all traffic goes to TM_0
   mov $sTmHdr.bitsFID[8], uxTmpReg1.byte[3] , 1;

   mov $sTmHdr.bitsFID[0], uxTmpReg1.byte[0] , 1;

   // Put TM Interface Header Fields      
   put      0 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 0 ], 4, SWAP;  
   put      4 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 4 ], 4, SWAP; 
   put      8 ( FMEM_BASE0 ), uqZeroReg, 4;
   put      12( FMEM_BASE0 ), uqZeroReg, 4;

VarUnDef sTmHdr;

ENDMACRO;


MACRO AddTMHeaderToOutPortHtq;

VarDef RegType EZmdf_RegulTmHdr     sTmHdr   uqTmpReg6;

   sub      DISP_REG, DISP_REG, TM_HEADER_SIZE, 2;

   Mov uxTmpReg1 , uqZeroReg , 4;
    
   //Add sSend_byDstPort , sSend_byDstPort , 2, 1;
   mov      $sTmHdr.BYTE[ 0 ], uqZeroReg, 4;

   //substruct CAUI0 port number
   sub      uxTmpReg1.byte[3] , sSend_byDstPort , 116 , 1; 
   mov      $sTmHdr.BYTE[ 4 ], uqZeroReg, 4;
   JGE KR4_OQQ_END_LAB ;
       mov $sTmHdr.bySrcPort, sSend_byDstPort , 1;
       Get uqTmpReg2 , { ETH_VID_OFF + TM_HEADER_SIZE} (L2_FR_PTR), 2, SWAP;


   sub      uxTmpReg1.byte[3] , sSend_byDstPort , 100 , 1;
   Nop;
   mov      ALU , 0xa08 , 2; 
   sub      ALU , uqTmpReg2.byte[0]  ,ALU , 2;
   Nop;
   MovBits  uxTmpReg1.byte[0] , ALU.bit[0] , 3; 
         
KR4_OQQ_END_LAB:
       
   //getres   $sTmHdr.bySrcPort, MSG_CONTROL_HW_MSG_SRC_PORT_OFF(MSG_STR) , 1;
   
   // Create FID = (destination port) * 64
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 4; s 8 na 8
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 5;
   //movbits  $sTmHdr.bitsFID[ 0 ], 928, 16; --na 9
   //movbits  $sTmHdr.bitsFID[ 0 ], 918, 16; -- na 9 
   //movbits  $sTmHdr.bitsFID[ 0 ], 800 , 16; -- na 9
   // movbits  $sTmHdr.bitsFID[ 0 ], 400 , 16; -- na 7 
   //movbits  $sTmHdr.bitsFID[ 0 ], 100 , 16; -- na 6 
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x400 , 16; -- na 10
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x500 , 16; --n 11
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x0 , 16; -- na CAUI 0

   
   movbits  sSend_bitDstTm, TM_0, 1; // assuming all traffic goes to TM_0
   mov $sTmHdr.bitsFID[8], uxTmpReg1.byte[3] , 1;

   mov $sTmHdr.bitsFID[0], uxTmpReg1.byte[0] , 1;

   // Put TM Interface Header Fields      
   put      0 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 0 ], 4, SWAP;  
   put      4 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 4 ], 4, SWAP; 
   put      8 ( FMEM_BASE0 ), uqZeroReg, 4;
   put      12( FMEM_BASE0 ), uqZeroReg, 4;

VarUnDef sTmHdr;

ENDMACRO;


MACRO AddTMHeaderToOutPort;

   Mov ALU , {1 << 30 }, 4;
   Xor ALU, uqZeroReg, ALU, 4, NP_NUM, MASK_BOTH;
   Nop;
   
   JZ  NET_HTQ , NOP_2;

   AddTMHeaderToOutPortMrq;
   jmp SEND_NET_END , NOP_2;  

NET_HTQ:
   AddTMHeaderToOutPortHtq;

SEND_NET_END:

ENDMACRO;


#define IP_HEADER_SIZE 22
#define __distr_by_ip_h

MACRO AddTMHeaderToHostOutPortHtq;

VarDef RegType EZmdf_RegulTmHdr     sTmHdr   uqTmpReg6;
#define byMDF_SEARCH_MATCH_BITMAP   byTempCondByte3; // instead usage by $byMDF_TempCondByte4_SEARCH_MATCH_BITMAP

#ifdef __distr_by_ip_h

   //copy MAC's
   Write -IP_HEADER_SIZE( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   Mov byMDF_SEARCH_MATCH_BITMAP, SEARCH_MATCH_BITMAP, 1; // LSbits of the lookups that return result to Context lines.
   Mov ALU , 0x08004500 , 4;
   Nop;
   Put 12(L2_FR_PTR) , ALU, 4 , SWAP;

   Mov ALU , 0x00000000, 4; // Put default value. Note will get different cores on the diff devices.
   if (byMDF_SEARCH_MATCH_BITMAP.BIT[CTX_LINE_CORE2IP_DISTRIBUTION]) GetRes ALU, CORE2IP_IP_OFF(MDF_CORE2IP_DISTRIBUTION_STR), 4;;
   Nop;
   Put {IP_SIP_OFF +  0xe}(L2_FR_PTR) , ALU, 4 , SWAP;

   Mov ALU , 0x01010101 , 4;
   Nop;

   Put {IP_DIP_OFF +  0xe}(L2_FR_PTR) , ALU, 4 , SWAP;
   Put {IP_PRT_OFF +  0xe}(L2_FR_PTR) , 0xff, 1 , SWAP;
   Put {IP_TTL_OFF +  0xe}(L2_FR_PTR) , 0x40, 1 , SWAP;
   Put {IP_TTL_OFF +  0xe}(L2_FR_PTR) , 0x40, 1 , SWAP;
   Put {IP_LEN_OFF +  0xe}(L2_FR_PTR) , 0x0080, 2 , SWAP;

/******************************** distr test *****************************************************/
  /*  - test for encapsulation
   nop;
   nop;
   nop;
   Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   Nop;
   Nop;

   Put ETH_PTOT1_OFF( L2_FR_PTR ), 0x8100, 2, SWAP;
   Put ETH_VID1_OFF( L2_FR_PTR ), 0 , 2, SWAP;
   nop;
   nop;
   nop;
   nop;
   nop;

   Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   Nop;
   Nop;
   Put ETH_PTOT1_OFF( L2_FR_PTR ), 0x8100, 2, SWAP;
   Put ETH_VID1_OFF( L2_FR_PTR ), 0xff , 2, SWAP;
   nop;
   nop;
   nop;
   */

/************************************************************************************************/
#endif



   sub      DISP_REG, DISP_REG, TM_HEADER_SIZE, 2;

   //Add sSend_byDstPort , sSend_byDstPort , 2, 1;
   mov      $sTmHdr.BYTE[ 0 ], uqZeroReg, 4;

   //substruct CAUI0 port number
   sub      ALU , sSend_byDstPort , 116 , 1;
   mov      $sTmHdr.BYTE[ 4 ], uqZeroReg, 4;
   JGE KR4_OQQ_1END_LAB ;
       mov $sTmHdr.bySrcPort, sSend_byDstPort , 1;
       Nop;
   sub      ALU , sSend_byDstPort , 100 , 1;

KR4_OQQ_1END_LAB:

   //getres   $sTmHdr.bySrcPort, MSG_CONTROL_HW_MSG_SRC_PORT_OFF(MSG_STR) , 1;

   // Create FID = (destination port) * 64
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 4; s 8 na 8
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 5;
   //movbits  $sTmHdr.bitsFID[ 0 ], 928, 16; --na 9
   //movbits  $sTmHdr.bitsFID[ 0 ], 918, 16; -- na 9
   //movbits  $sTmHdr.bitsFID[ 0 ], 800 , 16; -- na 9
   // movbits  $sTmHdr.bitsFID[ 0 ], 400 , 16; -- na 7
   //movbits  $sTmHdr.bitsFID[ 0 ], 100 , 16; -- na 6
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x400 , 16; -- na 10
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x500 , 16; --n 11
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x0 , 16; -- na CAUI 0


   movbits  sSend_bitDstTm, TM_1, 1; // assuming all traffic goes to TM_0
   mov $sTmHdr.bitsFID[8], ALU , 1;

   // Put TM Interface Header Fields
   put      0 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 0 ], 4, SWAP;
   put      4 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 4 ], 4, SWAP;
   put      8 ( FMEM_BASE0 ), uqZeroReg, 4;
   put      12( FMEM_BASE0 ), uqZeroReg, 4;

VarUnDef sTmHdr;

ENDMACRO;

MACRO AddTMHeaderToHostOutPortMrq;

VarDef RegType EZmdf_RegulTmHdr     sTmHdr   uqTmpReg6;
#define byMDF_SEARCH_MATCH_BITMAP   byTempCondByte3; // instead usage by $byMDF_TempCondByte4_SEARCH_MATCH_BITMAP

#ifdef __distr_by_ip_h

   //copy MAC's 
   Write -IP_HEADER_SIZE( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE; 
   Mov byMDF_SEARCH_MATCH_BITMAP, SEARCH_MATCH_BITMAP, 1; // LSbits of the lookups that return result to Context lines.
   Mov ALU , 0x08004500 , 4;
   Nop;
   Put 12(L2_FR_PTR) , ALU, 4 , SWAP; 

   Mov ALU , 0x00000000, 4; // Put default value. Note will get different cores on the diff devices.
   if (byMDF_SEARCH_MATCH_BITMAP.BIT[CTX_LINE_CORE2IP_DISTRIBUTION]) GetRes ALU, CORE2IP_IP_OFF(MDF_CORE2IP_DISTRIBUTION_STR), 4;;
   Nop;
   Put {IP_SIP_OFF +  0xe}(L2_FR_PTR) , ALU, 4 , SWAP;
   Mov ALU , 0x01010101 , 4;
   Nop;
   Put {IP_DIP_OFF +  0xe}(L2_FR_PTR) , ALU, 4 , SWAP;
   Put {IP_PRT_OFF +  0xe}(L2_FR_PTR) , 0xff, 1 , SWAP;
   Put {IP_TTL_OFF +  0xe}(L2_FR_PTR) , 0x40, 1 , SWAP;
   Put {IP_TTL_OFF +  0xe}(L2_FR_PTR) , 0x40, 1 , SWAP;
   Put {IP_LEN_OFF +  0xe}(L2_FR_PTR) , 0x0080, 2 , SWAP;
   

/******************************** distr test *****************************************************/
  /*  - test for encapsulation
   nop;
   nop;
   nop;
   Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   Nop;
   Nop;

   Put ETH_PTOT1_OFF( L2_FR_PTR ), 0x8100, 2, SWAP;
   Put ETH_VID1_OFF( L2_FR_PTR ), 0 , 2, SWAP;
   nop;
   nop;
   nop;
   nop;
   nop;

   Write -4( L2_FR_PTR ), 0( L2_FR_PTR ), 12, DISP_UPDATE;
   Nop;
   Nop;
   Put ETH_PTOT1_OFF( L2_FR_PTR ), 0x8100, 2, SWAP;
   Put ETH_VID1_OFF( L2_FR_PTR ), 0xff , 2, SWAP;
   nop;
   nop;
   nop;
   */
/************************************************************************************************/
#endif

   GetRes ALU , 0xD(MSG_STR), 2; //get vif out from structure

   Modulo ALU, ALU, 3, 1;
   Nop;
   SHL ALU , ALU , 1 , 1;
   Add  ALU , ALU , IF_PORT_HOST_0_MRQ , 1;
   Nop;   

   //Mov sSend_byDstPort , ALU , 1;
   Add sSend_byDstPort , ALU , 1 , 1;


   //test 
   //Mov sSend_byDstPort , 98 , 1; --popal v 104
   //Mov sSend_byDstPort , {128 + 128} , 1; 

   //test end
   //Mov sSend_byDstPort , 98 , 1; --popal v 104

   //Mov sSend_byDstPort , 98 , 1; -- 97
   
   //Mov sSend_byDstPort , 100 , 1; --99
   //Mov sSend_byDstPort , 105 , 1;--new tm popal v 104 
   //Mov sSend_byDstPort , 106 , 1; --new tm popal v 105
   //Mov sSend_byDstPort , 107 , 1; --new tm popal v 106
   //Mov sSend_byDstPort , 108 , 1; --new tm popal v 107 
   //Mov sSend_byDstPort , 100 , 1; 
   sub      DISP_REG, DISP_REG, TM_HEADER_SIZE, 2;

   //Add sSend_byDstPort , sSend_byDstPort , 2, 1;
   mov      $sTmHdr.BYTE[ 0 ], uqZeroReg, 4;

   //substruct CAUI0 port number
   
   mov      $sTmHdr.BYTE[ 4 ], uqZeroReg, 4;
   
   mov $sTmHdr.bySrcPort, sSend_byDstPort , 1;
   Nop;

   sub      ALU , sSend_byDstPort , 97 , 1; 
         
KR4_OQQ_1END_LAB:
       
   //getres   $sTmHdr.bySrcPort, MSG_CONTROL_HW_MSG_SRC_PORT_OFF(MSG_STR) , 1;
   
   // Create FID = (destination port) * 64
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 4; s 8 na 8
   //movbits  $sTmHdr.bitsFID[ 6 ], sSend_byDstPort, 5;
   //movbits  $sTmHdr.bitsFID[ 0 ], 928, 16; --na 9
   //movbits  $sTmHdr.bitsFID[ 0 ], 918, 16; -- na 9 
   //movbits  $sTmHdr.bitsFID[ 0 ], 800 , 16; -- na 9
   // movbits  $sTmHdr.bitsFID[ 0 ], 400 , 16; -- na 7 
   //movbits  $sTmHdr.bitsFID[ 0 ], 100 , 16; -- na 6 
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x400 , 16; -- na 10
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x500 , 16; --n 11
   //movbits  $sTmHdr.bitsFID[ 0 ], 0x0 , 16; -- na CAUI 0

   
   movbits  sSend_bitDstTm, TM_1, 1; // assuming all traffic goes to TM_0
   mov $sTmHdr.bitsFID[8], ALU , 1;

   // Put TM Interface Header Fields      
   put      0 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 0 ], 4, SWAP;
   put      4 ( FMEM_BASE0 ), $sTmHdr.BYTE[ 4 ], 4, SWAP; 
   put      8 ( FMEM_BASE0 ), uqZeroReg, 4;
   put      12( FMEM_BASE0 ), uqZeroReg, 4;

VarUnDef sTmHdr;
#undef byMDF_SEARCH_MATCH_BITMAP;

ENDMACRO;

macro AddTMHeaderToHostOutPort;

   Mov ALU , {1 << 30 }, 4;
   Xor ALU, uqZeroReg, ALU, 4, NP_NUM, MASK_BOTH;
   Nop;
   
   JZ  HOST_HTQ , NOP_2;

   AddTMHeaderToHostOutPortMrq;
   jmp SEND_HOST_END , NOP_2;  

HOST_HTQ:
   AddTMHeaderToHostOutPortHtq;

SEND_HOST_END:

ENDMACRO;

/*==============================================================================
==============================================================================*/
MACRO InsertTagAfterMACs	uxFmemZeroBase , P_uxNewTag, P_TAG_TPID_MASK, P_INSERT_CMD;							

   // shift MACs 4 bytes left + update DISP_REG
   write -4(uxFmemZeroBase), 0(uxFmemZeroBase), 12, DISP_UPDATE; 
   nop;
   nop; 
   // insert TPID and Tag vlaue
   xor ALU, ALU, !ALU, 2, P_TAG_TPID_MASK, MASK_BOTH;
	  P_INSERT_CMD ETH_VID_OFF(uxFmemZeroBase), P_uxNewTag, 2, SWAP;
   put ETH_PROT_OFF(uxFmemZeroBase), ALU, 2, SWAP;

ENDMACRO;

/*==============================================================================
==============================================================================*/
MACRO AppendTag	P_uxNewTag, P_TAG_TPID_MASK, P_INSERT_CMD;							

   // append TPID and Tag vlaue
   xor ALU, ALU, !ALU, 2, P_TAG_TPID_MASK, MASK_BOTH;
	  P_INSERT_CMD -2(uxFmemZeroBase), P_uxNewTag, 2, SWAP;
   put -4(uxFmemZeroBase), ALU, 2, SWAP;
   sub DISP_REG, DISP_REG, 4, 2;

ENDMACRO;

/*==============================================================================
==============================================================================*/
MACRO removeTagAfterMACs	uxFmemZeroBase ;							

   // shift MACs 4 bytes left + update DISP_REG
   write 4(uxFmemZeroBase), 0(uxFmemZeroBase), 12, DISP_UPDATE; 
   nop;
   nop; 
   // insert TPID and Tag vlaue
 
ENDMACRO;


MACRO  SynCookieCalc;

#define IP_VERSION_BIT        byTempCondByte1.bit[0];

//vardef regtype uqSynCookie     uqTmpReg6.BYTE[0:3];
vardef regtype TIMESTAMP       uqTmpReg1.BYTE[0:3];
vardef regtype KEY             uqTmpReg4.BYTE[0:3];

    GetRes uqTmpReg5, MSG_SYN_COOKIE_OFF(MSG_STR), 4;  // Get SYN cookie calculated in TOPparse
    nop;
    Movbits IP_VERSION_BIT, uqTmpReg5.bit[24], 1;

    //Mov $uqSynCookie, 0  , 4;
    Xor $uqSynCookie , ALU , ALU , 4;
    Get uqTmpReg2.byte[0], TCP_SPRT_OFF(L4_FR_PTR), 2, SWAP;
    Get uqTmpReg2.byte[2], TCP_DPRT_OFF(L4_FR_PTR), 2, SWAP;
    Nop;
    xor $uqSynCookie, uqTmpReg2.byte[0], uqTmpReg2.byte[2], 2;
    Nop;
    // XOR result (1 byte result)
    xor $uqSynCookie.byte[0], $uqSynCookie.byte[0], $uqSynCookie.byte[1], 1;

      // Get IPv4 address
    if (IP_VERSION_BIT) jmp SYN_TREAT_IPV6, NOP_2;

    Get uqTmpReg2, IP_SIP_OFF(L3_FR_PTR), 4, SWAP;
    Get uqTmpReg3, IP_DIP_OFF(L3_FR_PTR), 4, SWAP;

    jmp SYN_HASH_CONT, NO_NOP;
    	xor ALU, $uqSynCookie, uqTmpReg2, 4; //XOR IPv4/IPv6 SIP with TCP port XOR result
	xor $uqSynCookie, ALU, uqTmpReg3, 4; //XOR previous result with IPv4/IPv6 DIP


SYN_TREAT_IPV6:

#define IPv6_SIP_OFF_2ND  (IPv6_SIP_OFF +  4);
#define IPv6_DIP_OFF_2ND  (IPv6_DIP_OFF +  4);
#define IPv6_SIP_OFF_3RD  (IPv6_SIP_OFF +  8);
#define IPv6_DIP_OFF_3RD  (IPv6_DIP_OFF +  8);
#define IPv6_SIP_OFF_4TH  (IPv6_SIP_OFF + 12);
#define IPv6_DIP_OFF_4TH  (IPv6_DIP_OFF + 12);

//   xor ALU, $uqSynCookie, uqTmpReg2, 4; //XOR IPv4/IPv6 SIP with TCP port XOR result
//   xor $uqSynCookie, ALU, uqTmpReg3, 4; //XOR previous result with IPv4/IPv6 DIP

   Get uqTmpReg2, IPv6_SIP_OFF_2ND (L3_FR_PTR), 4, SWAP;
   Get uqTmpReg3, IPv6_DIP_OFF_2ND (L3_FR_PTR), 4, SWAP;
   xor ALU, $uqSynCookie, uqTmpReg2, 4;
   xor ALU, ALU,         uqTmpReg3, 4;

   Get $uqSynCookie, IPv6_SIP_OFF (L3_FR_PTR), 4, SWAP;
   Get uqTmpReg2,   IPv6_DIP_OFF (L3_FR_PTR), 4, SWAP;
   xor ALU, ALU, $uqSynCookie, 4;
   xor ALU, ALU, uqTmpReg2,   4;

   Get $uqSynCookie, IPv6_SIP_OFF_3RD (L3_FR_PTR), 4, SWAP;
   Get uqTmpReg2,   IPv6_DIP_OFF_3RD (L3_FR_PTR), 4, SWAP;
   xor ALU, ALU, $uqSynCookie, 4;
   xor ALU, ALU, uqTmpReg2,   4;

   Get $uqSynCookie, IPv6_SIP_OFF_4TH (L3_FR_PTR), 4, SWAP;
   Get uqTmpReg2,   IPv6_DIP_OFF_4TH (L3_FR_PTR), 4, SWAP;
   xor ALU,         ALU, $uqSynCookie, 4;
   xor $uqSynCookie, ALU, uqTmpReg2,   4;

#undef IPv6_SIP_OFF_2ND;
#undef IPv6_SIP_OFF_3RD;
#undef IPv6_SIP_OFF_4TH;
#undef IPv6_DIP_OFF_2ND;
#undef IPv6_DIP_OFF_3RD;
#undef IPv6_DIP_OFF_4TH;
#undef SYN_PROT_SIP_OFF_2ND
#undef SYN_PROT_SIP_OFF_3RD
#undef SYN_PROT_SIP_OFF_4TH
#undef SYN_PROT_DIP_OFF_2ND
#undef SYN_PROT_DIP_OFF_3RD
#undef SYN_PROT_DIP_OFF_4TH
#undef MSG_SIP_OFF_2ND
#undef MSG_SIP_OFF_3RD
#undef MSG_SIP_OFF_4TH
       
SYN_HASH_CONT:

   // Get Timestamp from MREG
   xor $TIMESTAMP, ALU, !ALU, 4, SC_CK_STMP_MREG, MASK_BOTH;
   //Mov uqTmpReg7, $uqSynCookie, 4; 
   Nop; 
   // Check for timestamp LSBit to determine which key to take
   movbits byTempCondByte1, $TIMESTAMP.bit[0], 5;

   // Case odd: Get key odd from MREG
   xor $KEY, ALU, !ALU, 4, SC_CK_KEY_P1_MREG, MASK_BOTH;

   if (byTempCondByte1.bit[0]) jmp KEY_DONE_LAB, NOP_2;

   // Case even: Get key even from MREG
   xor $KEY, ALU, !ALU, 4, SC_CK_KEY_P0_MREG, MASK_BOTH;
   nop;

   KEY_DONE_LAB: 

// XOR cookie result with Timestamp and SYN_COOKIE_CONST_KEY_VAL (0x622B70F5)
   Mov uqTmpReg3, SYN_COOKIE_CONST_KEY_VAL, 4;
   xor ALU, $uqSynCookie, $TIMESTAMP, 4;
   xor $uqSynCookie, ALU, uqTmpReg3, 4;

// Get original TCP Seq#, use 8 bits of the original Seq# in the SYN Cookie
   Get uqTmpReg3, TCP_SEQ_OFF(L4_FR_PTR), 4, SWAP;
   movbits $uqSynCookie.bit[24], 0, 8;
   movbits $uqSynCookie.bit[16], uqTmpReg3.bit[15], 8;
   nop;

// Stage 3:
// S3 = S2 xor KEY

   xor $uqSynCookie, $uqSynCookie, $KEY, 4;


// Stage 4:
// Cookie = (S3 & 0xFFFFFF) | [(MSS & 0x7) << 24] | [(TS & 0x1F) << 27]

   movbits $uqSynCookie.bit[24], IP_VERSION_BIT , 1; // For now, transfer the IP version in bit 24
   movbits $uqSynCookie.bit[27], $TIMESTAMP.bit[0], 5;               // (TS & 0x1F) << 27

//varundef uqSynCookie;
varundef TIMESTAMP;
varundef KEY;



ENDMACRO; // mdfSynCkyCalc

