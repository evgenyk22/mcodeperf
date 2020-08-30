/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.Acl.asm
*
*  Usage:         Access List macro file that handles TOPparse key preparation for ACL
*
*******************************************************************************/

MACRO SetAccessListHeader CONT_LAB;


#define aclOffsetReg         uqTmpReg6;     // Dedicated AccessList uqOffsetReg0
#define acluqFramePrsReg     uqTmpCtxReg1;  // Dedicated AccessList uqFramePrsReg

// ipv4 to ipv6 mapping
#define ALST_PROT_SIP_OFF_2ND (ALST_PROT_SIP_OFF + 4);
#define ALST_PROT_SIP_OFF_3RD (ALST_PROT_SIP_OFF + 8);
#define ALST_PROT_SIP_OFF_4TH (ALST_PROT_SIP_OFF + 12);
#define ALST_PROT_DIP_OFF_2ND (ALST_PROT_DIP_OFF + 4);
#define ALST_PROT_DIP_OFF_3RD (ALST_PROT_DIP_OFF + 8);
#define ALST_PROT_DIP_OFF_4TH (ALST_PROT_DIP_OFF + 12);


// AccessList uqFramePrsReg offsets (Bits):
#define ACL_VLAN_TAG_NUM      VLAN_TAG_NUM;     // offset 0,  2 bit size
#define ACL_L3_TYPE_OFF       L3_TYPE_OFF;      // offset 3,  1 bit size
#define ACL_TUN_EN_OFF        TUN_EN_OFF;       // offset 5,  1 bit size
#define ACL_INNER_EN_OFF      6;                // offset 6,  1 bit size
#define ACL_TUN_DECODE_OFF    8;                // offset 8,  8 bit size
#define ACL_L4_TYPE_OFF       L4_TYPE_OFF;      // offset 16, 3 bit size 
#define ACL_L4_DECODE_OFF     24;               // offset 24, 8 bit size


// If AccessList feature not available -> end macro
if (!uqGcCtrlReg0.bit[GC_CNTRL_0_ALIST_NONE_EMPTY_BIT]) jmp CONT_LAB, NOP_1;   
   MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ALST_EMPTY_BIT], uqGcCtrlReg0.bit[GC_CNTRL_0_ALIST_NONE_EMPTY_BIT], 1; 

// Check if L4 exist
Mov ALU, { 0x7 << L4_TYPE_OFF }, 4; // 0x00070000
And ALU, uqFramePrsReg, ALU, 4;
Mov uqTmpReg3, 0, 4;
Jz CONT_LAB, NOP_2;                 // End macro if L4_TYPE is zero (L4_UNS_TYPE)

// Init registers
Mov ALU, 0xFF07FFFF, 4;             // Init ALU with no L4 flags mask in frameParse ( 0xFFFFFFFF & (0 << L4_FLAGS_OFF) )
And uqCondReg, uqFramePrsReg, ALU, 4;
Mov aclOffsetReg, uqOffsetReg0, 4;
decode uqCondReg.bit[ACL_TUN_DECODE_OFF], uqFramePrsReg.bit[TUN_TYPE_OFF], 1; // Decode tunnel type

// Check if packet contains tunnel (GRE, GTP, IPinIP, L2TP), if not -> continue with single label
Mov ALU, { 0x7 << TUN_TYPE_OFF }, 4;
And ALU, uqFramePrsReg, ALU, 4;
MovBits uqTmpReg3.byte[1].bit[4], uqFramePrsReg.bit[L4_TYPE_OFF], 3;
Jz ACL_HANDLING_CONT, NOP_2;

// Check if tunnel is enabled & valid, and if inner flag is enabled, if yes -> continue with inner label
xor ALU, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH;
Mov acluqFramePrsReg, { (1<<ACL_TUN_EN_OFF) | (1<<ACL_INNER_EN_OFF) }, 4;
MovBits uqCondReg.bit[ACL_INNER_EN_OFF], ALU.bit[IC_CNTRL_0_TUN_INNER_EN_OFF], 1;
Nop;
And ALU, uqCondReg, acluqFramePrsReg, 4;
Sub ALU, ALU, acluqFramePrsReg, 4;
Nop;
Jz ACL_HANDLING_CONT, NOP_2;       // Continue with inner label handling

// Tunnel label handling

// If tunnel is not enabled no need for offset changes (parsing performed only on outer label)
If (!uqCondReg.bit[ACL_TUN_EN_OFF]) jmp ACL_HANDLING_CONT, NO_NOP;
   MovBits uqTmpReg3.byte[1].bit[0], uqFramePrsReg.bit[TUN_TYPE_OFF], 3;
   MovBits uqTmpReg3.byte[1].bit[4], 0, 3;

// If tunnel enabled change offsets to tunnel offsets
Mov aclOffsetReg.byte[L3_OFFB], uqTunnelOffsetReg.byte[L3_OFFB], 2;
MovBits uqCondReg.bit[ACL_L3_TYPE_OFF], uqFramePrsReg.bit[TUN_L3_TYPE_OFF], 1;
MovBits uqCondReg.bit[ACL_L4_TYPE_OFF], uqFramePrsReg.bit[TUN_L4_TYPE_OFF], 3;


ACL_HANDLING_CONT:

Mov FMEM_BASE, aclOffsetReg.byte[L3_OFFB], 2;
MovBits uqTmpReg3.byte[0], bySrcPortReg, 5;

// Decode L4 type
decode uqCondReg.bit[ACL_L4_DECODE_OFF], uqCondReg.bit[ACL_L4_TYPE_OFF], 1;                      

if( uqCondReg.BIT[ACL_L3_TYPE_OFF] ) jmp ACL_IPV6_LAB, NO_NOP;
   PutKey {ALST_PHYSPRT_OFF  }(COM_KBS), uqTmpReg3.byte[0], 1;
   PutKey {ALST_PROT_TYPE_OFF}(COM_KBS), uqTmpReg3.byte[1], 1;


// IPv4 handling

ACL_IPV4_LAB:

// Mapping between IPV4 and IPV6 addresses:
// 0:0:0:0:0:0:0:0:00:00:FF:FF:<IPV4_Address>

Mov    ALU, IPV4_IPV6_MAPPING_2ND, 4;
Copy   ALST_PROT_DIP_OFF(COM_KBS), IP_DIP_OFF (FMEM_BASE), 4, SWAP;
Copy   ALST_PROT_SIP_OFF(COM_KBS), IP_SIP_OFF (FMEM_BASE), 4, SWAP;
PutKey ALST_PROT_DIP_OFF_2ND (COM_KBS), ALU, 4;
PutKey ALST_PROT_SIP_OFF_2ND (COM_KBS), ALU, 4;
Mov    ALU, IPV4_IPV6_MAPPING_3RD, 4;
nop; 
PutKey ALST_PROT_DIP_OFF_3RD (COM_KBS), ALU, 4;
PutKey ALST_PROT_SIP_OFF_3RD (COM_KBS), ALU, 4;
Mov    ALU, IPV4_IPV6_MAPPING_4TH, 4;

jmp ACL_VLAN_HANDLING, NO_NOP;
   PutKey ALST_PROT_DIP_OFF_4TH (COM_KBS), ALU, 4;
   PutKey ALST_PROT_SIP_OFF_4TH (COM_KBS), ALU, 4;


// IPv6 handling

ACL_IPV6_LAB:

Copy 0 (COM_KBS), {IPv6_SIP_OFF + 8}(FMEM_BASE), 8, SWAP;
Copy 8 (COM_KBS), {IPv6_SIP_OFF + 0}(FMEM_BASE), 8, SWAP;
Copy 16(COM_KBS), {IPv6_DIP_OFF + 8}(FMEM_BASE), 8, SWAP;
Copy 24(COM_KBS), {IPv6_DIP_OFF + 0}(FMEM_BASE), 8, SWAP; 


// Vlan Handling

ACL_VLAN_HANDLING:

// If frame contains no Vlan skip Vlan handling
If ( !uqCondReg.BIT[ACL_VLAN_TAG_NUM+1] ) jmp ACL_L4_PROT_HANDLING, NO_NOP;
   Mov FMEM_BASE, aclOffsetReg.byte[L4_OFFB], 2;
   PutKey {ALST_VLANID_OFF }(COM_KBS), 0x1000, 2;

// Tagged handling
PutKey {ALST_VLANID_OFF    }(COM_KBS), $uxVlanTag1Id.byte[0], 1;
PutKey {ALST_VLANID_OFF + 1}(COM_KBS), $uxVlanTag1Id.byte[1], 1;


// L4 Protocol handling

ACL_L4_PROT_HANDLING:

#define L4_PORT_TUN_MASK      ( (1<<GTP_TUN_TYPE) | (1<<L2TP_TUN_TYPE) );                     // Check existence of GTP, L2TP type
#define L4_PORT_PROT_MASK     ( (1<<L4_TCP_TYPE ) | (1<<L4_UDP_TYPE  ) | (1<<L4_SCTP_TYPE) ); // Check existence of TCP, UDP, SCTP L4 protocol type
#define L4_EXIST_MASK         ( (L4_PORT_TUN_MASK<<ACL_TUN_DECODE_OFF) | (L4_PORT_PROT_MASK<<ACL_L4_DECODE_OFF) );

Mov ALU, L4_EXIST_MASK, 4;
And ALU, uqCondReg, ALU,  4; 
Mov uqTmpReg1, 0, 4;
jz ACL_L4_FINISH, NOP_2;   // L4 protocol does not exists - clear L4 ports field in KMEM key and end macro


ACL_L4_PROT_EXIST:

// Get L4 source & dest ports
Get uqTmpReg1.byte[0], TCP_SPRT_OFF(FMEM_BASE), 2;
Get uqTmpReg1.byte[2], TCP_DPRT_OFF(FMEM_BASE), 2;


ACL_L4_FINISH:

Add COM_HBS, COM_HBS, 1, 1;   // Increment HREG counter
PutKey ALST_L4PORT_OFF(COM_KBS), uqTmpReg1, 4;
       
jmp CONT_LAB, NO_NOP;
   Add COM_KBS, COM_KBS, CMP_ACL_KMEM_SIZE, 2;
   PutHdr HREG[ COM_HBS ], ALST_MAIN_LKP;



ENDMACRO;

