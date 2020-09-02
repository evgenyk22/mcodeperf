/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.asm
*
*  Usage:         TOPparse main file
*
*******************************************************************************/
 
Eztop Parse;

#include "EZcommon.h"      // Global definition file supplied with EZdesign, with predefined constants for NOPs, flags, etc. 
#include "EZparse.h"       // TOPparse definition file supplied, provides recognizable names for registers and flags.
#include "EZhwdreg.h"      // Hardware decoder definition file supplied, provides recognizable names for HD_REG.
#include "EZnetwork.h"
#include "EZrfd.h"
#include "EZstat.h"
#include "src_labels.h"
#include "portConfig.h"

#include "xad.common.h"
#include "xad.cntrBase.h"
#include "xad.portMap.h"
#include "xad.Prs.h"
#include "xad.Prs.Parser.h"
#include "xad.Prs.macros.asm"

#include "xad.prs.packetanomalies.h"
#include "xad.Prs.PacketAnomalies.asm"
#include "xad.Prs.Acl.asm"
//#include "portConfig.h"
/*
LdPortDir 103,2; 
LdPortDir 104,1; 
LdPortDir 105,2; 
LdPortDir 106,1; 
LdPortDir 107,2; 
LdPortDir 108,1; 
*/

//clear ALST , POL , BDOS + Msg
LDKmemRst 10;

#define IC_CNTRL_0_RT_EN_CNTR  (1 << IC_CNTRL_0_RT_EN_OFF);

#define GRE_TUN_DET_MASK       (GRE_TUN_TYPE    << TUN_TYPE_OFF);
#define GTP_TUN_DET_MASK       (GTP_TUN_TYPE    << TUN_TYPE_OFF);
#define IPinIP_TUN_DET_MASK    (IPinIP_TUN_TYPE << TUN_TYPE_OFF);
#define L2TP_TUN_DET_MASK      (L2TP_TUN_TYPE   << TUN_TYPE_OFF);
#define TUN_DET_MASK           ((GRE_TUN_DET_MASK)|(GTP_TUN_DET_MASK)|(IPinIP_TUN_DET_MASK)|(L2TP_TUN_DET_MASK));

#define UNF_PROT_DIP_OFF_2ND (UNF_PROT_DIP_OFF + 4 );
#define UNF_PROT_DIP_OFF_3RD (UNF_PROT_DIP_OFF + 8 );
#define UNF_PROT_DIP_OFF_4TH (UNF_PROT_DIP_OFF + 12);
#define UNF_PROT_SIP_OFF_2ND (UNF_PROT_SIP_OFF + 4 );
#define UNF_PROT_SIP_OFF_3RD (UNF_PROT_SIP_OFF + 8 );
#define UNF_PROT_SIP_OFF_4TH (UNF_PROT_SIP_OFF + 12);

#define IPv6_SIP_OFF_2ND  (IPv6_SIP_OFF +  4);
#define IPv6_DIP_OFF_2ND  (IPv6_DIP_OFF +  4);
#define IPv6_SIP_OFF_3RD  (IPv6_SIP_OFF +  8);
#define IPv6_DIP_OFF_3RD  (IPv6_DIP_OFF +  8);
#define IPv6_SIP_OFF_4TH  (IPv6_SIP_OFF + 12);
#define IPv6_DIP_OFF_4TH  (IPv6_DIP_OFF + 12);

#define UNF_CENTRALISED 1
#define IP_VERSION_BIT byTempCondByte1.bit[0];

#define MSG_SIP_OFF          (MSG_RST_LEARN_KEY     );
#define MSG_SIP_OFF_2ND      (MSG_RST_LEARN_KEY + 4 );
#define MSG_SIP_OFF_3RD      (MSG_RST_LEARN_KEY + 8 );
#define MSG_SIP_OFF_4TH      (MSG_RST_LEARN_KEY + 12);

//LDCAM BCAM32[0],0x9c4,1;
LDTCAM   TCAM64[0], "\ff\ff\01\00\00\00\00\00" , "00000000", 0x40;
LDTCAM   TCAM64[0], "\ff\ff\02\00\00\00\00\00" , "00000000", 0x80;
LDTCAM   TCAM64[0], "\ff\ff\03\00\00\00\00\00" , "00000000", 0xC0;
LDTCAM   TCAM64[0], "\ff\ff\04\00\00\00\00\00" , "00000000", 0x100;
LDTCAM   TCAM64[0], "\ff\ff\05\00\00\00\00\00" , "00000000", 0x200;

#define L7_PROT_GRP                 1

//L2TP   
LDTCAM   TCAM64[L7_PROT_GRP], "??\a5\06????", "ffffffff", 0x4000;
LDTCAM   TCAM64[L7_PROT_GRP], "\a5\06??????", "ffffffff", 0x4000;

LDTCAM   TCAM64[L7_PROT_GRP], "\3a\0d??????", "ffffffff", 0x2000;
LDTCAM   TCAM64[L7_PROT_GRP], "??\3a\0d????", "ffffffff", 0x2000;

LDTCAM   TCAM64[L7_PROT_GRP], "\4b\08??????", "ffffffff", 0x2000;
LDTCAM   TCAM64[L7_PROT_GRP], "??\4b\08????", "ffffffff", 0x2000;

LDTCAM   TCAM64[L7_PROT_GRP], "\68\08??????", "ffffffff", 0x2000;
LDTCAM   TCAM64[L7_PROT_GRP], "??\68\08????", "ffffffff", 0x2000;

#define RX_VLAN_0 0x9c4

LdLookasideNoWait TRUE; // In order to enable firing the type 1 or type 2 lookups LookAside search as soon as
                        //  HREG6/7 are written, without need to wait for the halt command.
/*						
#define OOS_ORDER_DOMAIN   1;
LdPortFlow PRT_CFG0 , OOS_ORDER_DOMAIN;
LdPortFlow PRT_CFG1 , OOS_ORDER_DOMAIN;
*/
LdPortFlow 102, 0;
LdPortFlow 103, 1;
LdPortFlow 104, 2;
LdPortFlow 105, 3;
LdPortFlow 106, 0;
LdPortFlow 107, 1;
LdPortFlow 116, 2;
LdPortFlow 117, 3;

//##TODO_OPTIMIZE - need to change the memory usage to X1.5 times ROM in order to avoid the ICS if possible.
//                                   ICS parse 2-->4K change just now at the end of the coding.
//                                   need to check how I can save some lines or use several pragmas for diferent ICS levels.
//##TODO_OPTIMIZE:  Pass over all the locations that uses OUT_VID_STR and see if it should be left as is or if it should be removed. if should be removed also in transparent mode - cancel the lookup and the relevant defines (search for /* FFT_VID_STR Result Format */).


// Input port encoding bit 7-6-5 Rx side 1 Tx side 4
// Modulo on random number (system clock) used for performing even distribution of traffic on all available interfaces towards the network (6)
// Modulo removed. used only for routing
//Modulo ALU, RTC, 6, 1, MASK_000000FF, MASK_SRC1;


/* Set default value - DON'T perform GRE Decapsulation (MSG_CTRL_TOPPRS_2_IS_GRE_DECAP_REQUIRED_BIT = 0).
   This will be overwritten later on if required conditions are met (RadwareGRETunnel frames is discovered).
   Note: Other bits are also set now to zero. this should be changed as soon as more bits will be populated to MSG_CTRL_TOPPRS_2_OFF */
MovBits CAMO.bit[16] , sHWD_bitsDirection, 5; 
PutKey MSG_CTRL_TOPPRS_2_OFF(HW_KBS), 0, 1;

//Decode_General 0(FMEM_BASE);	 // NP4 does not make HW parsing like NP3, that's why we use this command (we can optimize by removing decoding for packets arrived from CPU)


// Start to initialize registers
//Mov uqTmpReg1, PORT_CFG0, 4; // ##TODO_OPTIMIZE: probably not needed - comment and pass verifications then remove if not needed anymore. if removing this line need to write the next one 1 level in to show that the modulo command is not over yet (consumes 2 clocks), so ALU is ready for the Lookcam only after 2 clocks.

#define KBS_INIT_VAL (MSG_SIZE << 16);
// Lookcam removed. used only for routing
//Lookcam CAMO, ALU, BCAM32[CPU_2_NET_MAP_GRP]; // Lookcam to select NP's-to-NW output port (XAUI) according to a random function (RTC value) in order to load balance.

If (CAMO.bit[16]) Add FMEM_BASE , FMEM_BASE , 8 , 2;

   xor uqGcCtrlReg0, ALU, !ALU, 4, GC_CNTRL_0_MREG, MASK_BOTH; // using MREG[15] 
   Mov byCtrlMsgPrs0, 0,    4;    // Clears byCtrlMsgPrs0, byCtrlMsgPrs1, byFrameActionReg, bySrcPortReg
   Mov byCtrlFree,    0,    4;    // Clears byGlobFree, byCtrlMsgPrs2, byGlobConfReg, byCtrlMsgPrs3
   
   decode_general 0(FMEM_BASE);	 
   Mov byCtrlMsgPrs2, 0,    1;    // Clears byCtrlMsgPrs2
   Mov byGlobConfReg, 0,    1;    // Clear byGlobConfReg   
   Mov byFrameActionOverrideReg,0,1;// Clear byFrameActionOverrideReg   
   //ENC_PRI does not need the below init. JMUL ignores LSbits 
   //Mov    ENC_PRI,       0,    2;    // Clear ENC_PRI register
   Mov byHashVal, 0, 1;
// Feature disabling:
Mov ALU, { (1 << GC_CNTRL_0_IMMCHK_ENABLED_BIT) /*| (1 << GC_CNTRL_0_IMMCHK_DEFAULT_ACTION_BIT)*/ | (1 << GC_CNTRL_0_ALIST_ENABLED_BIT) /*| (1 << GC_CNTRL_0_VLAN_TUN_CFG_BIT)*/ | (1 << GC_CNTRL_0_BDOS_ENABLE_BIT) /*| (1 << GC_CNTRL_0_TCP_OOS_ENABLED_BIT)*/ | (1 << GC_CNTRL_0_ROUTING_ENABLED_BIT) }, 4;
And uqGcCtrlReg0, uqGcCtrlReg0, !ALU, 4;
Mov COM_HBS,       0,    1;    // Clear COM_HBS (HREG_BASE1 register)
Mov HW_KBS, KBS_INIT_VAL, 4; // init both KMEM_BASE0 (HW_KBS) and KMEM_BASE1 (COM_KBS) in one step.

// Fix KMEM HW reset issue by workaround 
//PutKey MSG_POLICY_ID_OFF(HW_KBS), DEF_POLICY_METADATA_ID, 2; // Init default policy ID value

decode byGlobConfReg, uqGcCtrlReg0, 1, MASK_00000003, MASK_SRC1; // See GC_CNTRL_0_MREG - TOPparse MREG[15] for bitmap in xad.common.h.
// Fix KMEM HW reset issue by workaround 
//PutKey MSG_NP5_INTERFACE_PORT_NUM_OFF(HW_KBS) , HWD_REG1.byte[1] , 1  ; //##TODO_OPTIMIZE: check all nops after JMULs and verify if this can be done in case of jump immediately after the JMUL.
MovBits ENC_PRI.bit[11], sHWD_bitsDirection, 5; // Get the type of the port that the frame arrvied from 
Xor ALU , ALU , !ALU , 4  ;
// Send calculated output port in internal message towards TOPmodify
//MSG_CTRL_TOPPRS_3_OFF is used only for routing
//PutKey MSG_CTRL_TOPPRS_3_OFF(HW_KBS), CAMO, 1;

// Start checking bits 20,21 for port drop priority congestion status - will be used in case of jumping to FRAME_FROM_NW_LAB or FRAME_FROM_HOST_LAB
MovBits ALU, SREG_HIGH[2].bit[20], 2; // sBdgtStatus2_bitsPortDropPri = SREG_HIGH[2].bit[20]

// reset condition bit in case frame arrives from network port
Mov byTempCondByte1, 0, 1;
   
// Jump to the relevant packet handling according to inerface type as defined input port data
// For a Jmul instruction with more than 3 labels, in case of match (jump), the two instructions that follow this instruction are not executed.
Jmul FRAME_FROM_2ND_NP_LAB,         // corresponds to port direction FRAME_FROM_2ND_NP (frame from interlink between 2 NPs)
     FRAME_FROM_NET_CAUI_LAB,       // corresponds to port direction PORT_DIR_NET_CAUI (frame from CAUI network port)
     FRAME_FROM_NW_LAB,             // corresponds to port direction PORT_DIR_NET_SWITCH (frame from switch network port)
     ERROR_HANDLING, // corresponds to port direction PORT_DIR_CTRL (frame from host control port)
     FRAME_FROM_HOST_LAB,           // corresponds to port direction PORT_DIR_HOST (frame from host ports)
     ERROR_HANDLING,                // error label 
     ERROR_HANDLING;                // error label                                                      
  
// Fall through - unexpected - at least 1 of the bits should have been set in ENC_PRI.

#ifndef __SIM___
//ignore phys port in case of simulatior
jmp ERROR_HANDLING, NOP_2;

#else

jmp  FRAME_FROM_NW_LAB, NOP_2;

#endif


    

FRAME_FROM_HOST_LAB:   
if       ( !FLAGS.BIT [ F_MCC ] )  jmp   $, NO_NOP;
    Mov FMEM_BASE ,0 , 2;
    Nop;

MovBits ALU , sHWD_bitsLayer3Offset , 5 , RESET;
Add  uxCntrlGenDecoder , ALU , 8 , 2;

Get ALU , ETH_VID1_OFF(FMEM_BASE), 2, SWAP;
PutKey MSG_NP5_INTERFACE_PORT_NUM_OFF(HW_KBS) , HWD_REG1.byte[1] , 1  ; //##TODO_OPTIMIZE: check all nops after JMULs and verify if this can be done in case of jump immediately after the JMUL.
PutKey MSG_SWITCH_VLAN_FROM_HOST(HW_KBS) ,  ALU, 2;



// Waiting for decode_general to complete.
//EZwaitFlag F_MCC; - may be , but let's try without

//DE14254 4-April-2016 Motic: when the frame is MPLS, sHWD_byDipFolderXor and sHWD_bySipFolderXor are zero. 
//check if it's MPLS frame. 
//General decoder does not XOR [SIP,DIP] in case of MPLS, so we do this here.
And ALU, sHWD7.byte[1], 0x3,1;//MPLS Uni or Multi
//instead of NOP - get the bitfield: number of MPLS headers 
MovBits ENC_PRI.bit[ENC_PRI_SIZE_BITS-3], sHWD8.bit[0], 3;   

//if not MPLS, xor DIP,SIP and continue
JZ IP_PACKET_HASH_DONE, NO_NOP;   
   Mov FMEM_BASE, uxCntrlGenDecoder,2;
   Xor byHashVal , sHWD_byDipFolderXor , sHWD_bySipFolderXor , 1;

movMUL 12,8,4;
add FMEM_BASE,ENC_PRO, uxCntrlGenDecoder,1;
nop;
nop;//FMEM_BASE not ready yet
GET CAMI,IP_SIP_OFF(FMEM_BASE),8;
nop;

// if IPV4_PACKET (MPLS or not) - perform a hash based on frame, not General decoder
Fxor byHashVal,CAMI,CAMIH,4;

IP_PACKET_HASH_DONE:
MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_GLOB_DESC_BIT], 1, 1;



jmp PRS_DONE_LAB, NO_NOP;
   Mov byFrameActionReg, FRAME_HOST_BYPASS_2NETW, 1;
   MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_GLOB_DESC_BIT], 1, 1;
 

                           
FRAME_FROM_NET_CAUI_LAB:
   // Frame arrived from a CAUI direct network port

vardef regtype usrVlanTag    CTX_REG[3].byte[2:3];  // user vlan from packet

    Xor   $usrVlanTag  , ALU , ALU , 2;

   // set indication bit that the source port is CAUI
   MovBits byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT], 1, 1;
   
   // Save the related information from the CAUI port cfg SRAM in the CAMO register.
   // This is done is order to have common code for all traffic coomming from network 
   Mov CAMO, PORT_DATA3, 4;
   
   // set condition bit to indicate arrival from the CAUI ports label
   Mov byTempCondByte1, 1, 1;

   MovBits $usrVlanTag.bit[12]  ,  sHWD7.bit[sHWD_bitNoTags_off], 1 ;
   MovBits $usrVlanTag , sHWD_uxTag1Vid , 12; 

   
   
   // Fallthrough
   
FRAME_FROM_NW_LAB:
   // Frame arrived from on of the switch's network ports
   Xor ALU, ALU, !ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH; // ALU <- IC_CNTRL_0_MREG

   // RT monitoring Protocol type is unknown do it preliminary for GLOB_CONF_DROP_LAB
   MovBits uqFramePrsReg.BIT[L4_TYPE_OFF], L4_UNS_TYPE, 3; //Init as default L4_TYPE_OFF

   // Start preparing key for internal TCAM 64 Lookup (using TCAM since vlan can also include range)
   MovBits uqOffsetReg0.byte[L3_OFFB], sHWD_bitsLayer3Offset, 5, RESET;

   If (!FLAGS.BIT[ F_ZR ]) 
      MovBits byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_RT_EN_BIT], 1, 1; 

   //store hash in global variable
   Xor byHashVal , sHWD_byDipFolderXor , sHWD_bySipFolderXor , 1; 
   
   Mov FMEM_BASE, uqOffsetReg0.byte[L3_OFFB], 2;
   
   //Mov $uxVlanTag0Id , uqTmpReg7.byte[2] , 2;
   PutKey MSG_VIF_OFF(HW_KBS), PORT_DATA0, 1;
   PutKey MSG_POLICY_ID_OFF(HW_KBS), DEF_POLICY_METADATA_ID, 2; // Init default policy ID value
   PutKey MSG_NP5_INTERFACE_PORT_NUM_OFF(HW_KBS) , HWD_REG1.byte[1] , 1  ; //##TODO_OPTIMIZE: check all nops after JMULs and verify if this can be done in case of jump immediately after the JMUL.
    
   Mov byFrameActionReg, FRAME_BYPASS_HOST, 1;
   Copy   MSG_SIP_OFF(HW_KBS ), IP_SIP_OFF (FMEM_BASE),4, SWAP;
   
   If (byTempCondByte1.BIT[0])  
      jmp RESULT_IS_READY_IN_CAMO_LAB, NO_NOP;
         movbits IP_VERSION_BIT, sHWD_bitL3IsIpV6  , 1;  //Assume IPv4 , if no will be overrided by IPv6 flag  
         MovBits uqOffsetReg0.byte[L3_OFFB], sHWD_bitsLayer3Offset, 5, RESET;

SWITCH_TCAM_SEARCH_LAB:

   And ALU ,  sHWD7 , {7<< sHWD_bitTwoTags_off } , 1;
   MovBits $usrVlanTag , sHWD_uxTag2Vid , 12; 
   
   //set default vlan value 0x1000 if packet from switch  and no user vlan tag inside
   If (FLAGS.BIT[F_ZR]) MovBits $usrVlanTag.bit[12] , 1 , 1; 


   // Start calculating the src port 
   Mov CAMI, 0, 4; // Nop;
//   And ALU, HWD_REG7, {1 << sHWD_bitOneTag_off}, 1;
//   MovBits CAMI.BYTE[2] , sHWD_uxTag1Vid, 12; // Put Switch VLAN in CAMI.byte[2..3]

//Save the Switch vlan and the first User vlans.
/* Untagged case (i.e. only 1 VTAG in frame - the switch VLAN): in this case set the user VLAN to 0xFFFF and only keep the Switch VLAN */
//if (!FLAGS.BIT[F_ZR]) Mov     CAMI, 0xFFFF, 2;
/* Tagged case {more then 1 VLAN in frame - i.e. User VLAN exist (assuming that no VLAN Tags in frame at all is not an option)}. */
//if ( FLAGS.BIT[F_ZR]) MovBits CAMI, sHWD_uxTag2Vid, 12;
//##TODO_OPTIMIZE: There is no use of the inner VLAN, only using the outer, switch VLAN so why bother setting it in the TCAM? (the entries written to the TCAM64 are probably masked by the host, as they are configured now) - consider removing this code block. if removing it check that the current number of VLAN legality test is not harmed).

//#define VIF_GROUP_32    0;
// Result of CAM lookup is logical port (vif, low 5 bits, for optional 32 logical ports) used to locate the TX vlan when we want to send the frame back to the network. Bit 7 (5,6 not used) is used to indicate whether the port is in transparent mode (0) or FFT mode (1)
//LookCam CAMO, CAMI, TCAM64[ VIF_GROUP_32 ], KEY_SIZE 4;


   Mov ALU  , RX_VLAN_0 , 2;
   Sub CAMI , sHWD_uxTag1Vid , ALU , 2;
   LookCam CAMO, CAMI, BCAM8[ FFT_BCAM8_GRP ];



Mov FMEM_BASE, uqOffsetReg0.byte[L3_OFFB], 2;
Mov byFrameActionReg, FRAME_BYPASS_HOST, 1;
Nop; //movbits IP_VERSION_BIT, sHWD_bitL3IsIpV6  , 1;  //Assume IPv4 , if no will be overrided by IPv6 flag  

Copy   MSG_SIP_OFF(HW_KBS ), IP_SIP_OFF (FMEM_BASE),4, SWAP;
// The LookCam in TCAM64 took 4 clocks, so result is now ready.
//at this point TCAM search had been already completed - check if TCAM match.
if (!FLAGS.BIT[F_MH]) jmp TCAM_SEARCH_FAIL_LAB, NO_NOP;

RESULT_IS_READY_IN_CAMO_LAB:

   /* TCAM 64 MATCH ! */
   // read both "has RX copy" bit and "switch VLAN" bit to byCtrlMsgPrs2
   //MovBits byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_HAS_RX_COPY_BIT], CAMO.bit[FFT_VIF_DATA_HAS_RX_COPY_PORT_OFF], 1;
   //MovBits byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_SLT_VLAN_BIT], CAMO.bit[FFT_VIF_DATA_SWITCH_VLAN_OFF], 1;

     //clear routing mode selectin for SSL port type
   If (CAMO.bit[SSL_PORT_DET]) MovBits bitPRS_isRoutingMode , 0 ,1 ;

   //extract 5 bits VIF[10:6] from result
MovBits ALU, CAMO.bit[FFT_VIF_DATA_VIFID_OFF], FFT_VIF_DATA_VIFID_SIZE, RESET;
   //If (!bitPRS_isRoutingMode) jmp PER_VIF_COUNTING_LAB, NO_NOP; // In transparent mode the result of DMAC_NO_MATCH is ignored
      // Save physical port
MovBits bySrcPortReg, CAMO.bit[FFT_VIF_DATA_PHYSPRT_OFF], FFT_VIF_DATA_PHYSPRT_SIZE;
PutKey MSG_VIF_OFF(HW_KBS), ALU, 1;

PER_VIF_COUNTING_LAB:
/* Ariving here:
   (A) In trasparent mode, or
   (B) In case that all MAC validations passed ok, i.e. frame.DMAC has match with MY_MAC or MAC_BC or MAC_MC, or L2 control frame,
       and this is not a GRE KeepAlive request / reply frame (GRE KeepAlive frame may arrive here only in case that the host configured
       the mcode To disable the GRE KeepAlive and RadwareTunnelGRE frames handling).
   (C) In case that routing mode, MAC no match and not L2 control frame - but in this case the handling will be according to
        IC_CNTRL_1_DMAC_NO_MATCH_OFF configuration (in this case ENC_PRI is overwritten to fit DMAC_NO_MATCH handling) */
/* Increment the relevant vif input counter by 1 */


/* save global configuration (dsecoded) in message */
//PutKey MSG_GLOB_CONFIG_OFF(HW_KBS), byGlobConfReg, 1;// 0x1 - DROP, 0x2 - CONT, 0x4 - BYPASS_TO_NW, 0x8 - TO_CPU


// Save the physical port
//MovBits bySrcPortReg, CAMO.bit[FFT_VIF_DATA_PHYSPRT_OFF], FFT_VIF_DATA_PHYSPRT_SIZE;
//PutKey MSG_SRC_PORT_OFF(HW_KBS), bySrcPortReg, 1; // ##TODO_OPTIMIZE - check option to move this line to after the JMUL. also check if this can be repleaced with the source port from the HW_MSG (not the lookup result of the VIF table, as implemented today). see comment near the definition of the constant MSG_SRC_PORT_OFF.
   MovBits byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_IS_GRE_DECAP_REQUIRED_BIT], bitTmpCtxReg2RemoveRdwrGRETunnel, 1; 

   /* Populate ENC_PRI with global setting mode - Global (Send TO CPU / BYPASS to NW / Continue parsing frame / DROP) */
   //MovBits ENC_PRI.bit[9], byGlobConfReg.bit[0], 7;
   //Mov ALU ,  uqGcCtrlReg0.
   Putkey UNF_PROT_POLICY_PHASE_OFF(COM_KBS), uqGcCtrlReg0.byte[2], CMP_POLICY_PHASE_SIZE;  

   Mov ALU , PA_CHECK_ONLY , 4;
// Moved this code (only the code regarding Vlan) here from syn protection
// This code was in 2 paths of syn-prot: syn packet and ack-rst packet
// code was moved here because it uses sHWD5 which is overriden in parseFrameWithPA
/*
#ifndef __SIM__ 
MovBits ALU.bit[12], sHWDall_bitOneTag, 1, RESET;
MovBits ALU, sHWD_uxTag2Vid, 12;
#else
MovBits ALU.bit[12], sHWDall_bitNoTag, 1, RESET;
MovBits ALU, sHWD_uxTag1Vid, 12;
#endif
*/
PutKey MSG_SRC_PORT_OFF(HW_KBS), bySrcPortReg, 1; // ##TODO_OPTIMIZE - check option to move this line to after the JMUL. also check if this can be repleaced with the source port from the HW_MSG (not the lookup result of the VIF table, as implemented today). see comment near the definition of the constant MSG_SRC_PORT_OFF.
// For port that has "SLT VLAN" attribute, there is no need to run packet anomalies, and any of the security features in TOP resolve.
// Instead, packets from this port will be treated as if the global processing mode is bypass (host or network)
// TODO: this part of code is here because hash calculations are required (in PARSE_AND_CALC_HASH).
//       In case there is no need for the hash value, move the below lines to be performed in the FRAME_CONT_ACTION_LAB label, before
//       running parsing code.
//movbits byTempCondByte1.BIT[MSG_CTRL_TOPPRS_2_SLT_VLAN_BIT], bitPRS_isSltVlanMode, 1;

PutKey UNF_PROT_VLAN_OFF (COM_KBS), $usrVlanTag , 2;

//If (byTempCondByte1.BIT[MSG_CTRL_TOPPRS_2_SLT_VLAN_BIT]) Jmp PRS_SLT_VLAN_LAB;
If (CAMO.bit [SSL_PORT_DET]) Mov uqGcCtrlReg0 , ALU  , 4;
If (CAMO.bit [SSL_PORT_DET]) Mov byFrameActionOverrideReg , FRAME_BYPASS_HOST  , 1;


Mov ALU,0,4; 
Mov4Bits ALU.bits[4,3,2,1] , uqGcCtrlReg0.bits[GC_CNTRL_0_ALIST_NONE_EMPTY_BIT,GC_CNTRL_0_POLICY_NON_EMPTY_BIT,GC_CNTRL_0_PROT_DST_NONE_EMPTY_BIT,GC_CNTRL_0_BDOS_EMPTY_SIG_BIT];
PutHdr  HREG[ 1 ], MAIN_LKP;
PutKey UNF_TASK_CNTR(COM_KBS), ALU , 1; 
 
   // following instructions are executed whether the jump is taken or not.
   // They are taken meaningfull only in the common path where there is no bypass feature


#include "xad.prs.parser.asm"
//parseFrame;

// This actually jumps according to 1 hot decoding of the 2 LSbits of MREG.
// ##TODO_OPTIMIZE - only set the upper bits of ENC_PRI and change the label so that the jump will be faster (as jump in JMUL for the 1st 3 labels is faster then to the next ones in line)...
/* Jump to the frame handling as set in MREG (allows global configuration of Bypass to host, Bypass to network, Drop and Continue that may change in runtime).
   This value can be overwritten in mcode in some cases as can be seen by direct write to ENC_PRI above. */
   /*
Jmul ERROR_HANDLING,                // Error:    Increment error counter and discard frame
     ERROR_HANDLING,                // Error:    Increment error counter and discard frame
     ERROR_HANDLING,                // Error:    Increment error counter and discard frame
     GLOB_CONF_BYPASS_HOST_LAB,     // TO CPU:   Send from Network port to Host port (action: FRAME_BYPASS_HOST)
     GLOB_CONF_NETWORK_BYPASS_LAB,  // BYPASS:   Send from Network port to Network port (action: FRAME_BYPASS_NETWORK). This will send to NW after running the parser, which assures that the routing key will be built (in case of routing mode).
     FRAME_CONT_ACTION_LAB,         // CONTINUE: Perform packet parsing (action: FRAME_CONT_ACTION)
     GLOB_CONF_DROP_LAB;            // DROP:     Increment RT counter and discard frame
   */
      
//##TODO_OPTIMIZE: (low proirity task) need to add code to catch unexpected fall though.

// Replace network default settings    
GLOB_CONF_NETWORK_BYPASS_LAB:
// RT monitoring will be supported for bypass global processing mode with really protocol type
jmp PARSE_AND_CALC_HASH, NO_NOP;
   Mov uqInReg, 0, 4;
   Mov PC_STACK, NETW_P0_BYPASS_LAB, 2;

indirect NETW_P0_BYPASS_LAB:
CONF_NETWORK_BYPASS_LAB: // This label is used to handle the Feature BYPASS
/* Note that in routing mode, in case of ((L3 != IP) or (any L2 issue)), the host code should avoid setting the action for the
   anomaly to "TO_NW", and may only punt the frame to the host or discard it. The mcode is counitng on it in order to function fine. */

// Increment number of external packets by-passed on TOP Parse by Global traffic processing mode  
// STAT_OPERATION GS_TPR_EX_PAS, 1, EZ_INCR_CMD_STS;
jmp PRS_DONE_LAB, NOP_1;
   Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;

// Increment specific counter for host/net drop
GLOB_CONF_DROP_HOST_LAB:
EZstatIncrByOneIndexImm CNT_PRS_HOST_LAB_DRP;    
jmp GLOB_CONF_DROP_LAB_CONT, NOP_2; 

GLOB_CONF_DROP_NET_LAB:	    
EZstatIncrByOneIndexImm CNT_PRS_NET_LAB_DRP;    
jmp GLOB_CONF_DROP_LAB_CONT, NOP_2; 

TCAM_SEARCH_FAIL_LAB:
// No match for Switch VLANn lookup (the TCAM64 lookup returned NO match)
EZstatIncrIndexReg FFT_VIF_NOT_FOUND_CNT, 1; // Increment counter when no match in CAM
   Nop; // to prevent data hazard for flag F_ST used in the macro in the next line.
   
GLOB_CONF_DROP_LAB:
// Drop the frame and increment the rx counter (bytes & packets, per port)
Mov ALU, IC_CNTRL_0_RT_EN_CNTR, 4; // ##TODO_OPTIMIZE: check if cant use byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_RT_EN_BIT] bit test, instead of doing the calculation (check if it will be initialized in all routes that will come to here).

Mov uqTmpReg3, 0, 4;
Mov uqTmpReg4, 0, 4;

And ALU, ALU, ALU, 4, IC_CNTRL_0_MREG, MASK_BOTH;
   Mov uqTmpReg2, RT_MONITOR_BASE_CNTR, 4;
jz SKIP_RT_CALC, NO_NOP;	// skip RT Monitor Counting
   MovBits uxTmpReg2.bit[1], uqFramePrsReg.BIT[L4_TYPE_OFF], 3;  // ##TODO_GUY_BUG_FOUND: L4_TYPE is not initialized, which is OK, but this now updates L4_UNS_TYPE. need to change the numbers for L4 options to include 0=uninitilized L4. check if need to do the same fix also for other Layers (L2, L3).
   MovBits uxTmpReg1.bit[4], bySrcPortReg, 5; //max phys port range 0-0xF //##TODO_GUY_BUG_FOUND (?): 1-0xf or 1-0x1f (4 or 5 bits? conflicts a comment in another place - search for all instances that uses bySrcPortReg)

Mov2Bits uqTmpReg4.BITS[2,2], byCtrlMsgPrs2.BITS[~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT,~MSG_CTRL_TOPPRS_2_IS_CAUI_PORT_BIT];
Add uqTmpReg2, uqTmpReg2, uxTmpReg2, 2, MASK_0000FFFF, MASK_BOTH;
Sub uqTmpReg4, sHWD_uxFrameLen, uqTmpReg4, 2; // sHWD_uxFrameLen = HWD_REG0.byte[2]
Add uqTmpReg2, uqTmpReg2, uxTmpReg1, 2, MASK_0000FFFF, MASK_BOTH;

MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received

EZstatPutDataSendCmdIndexReg uqTmpReg2, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1; // Increase Drop counter


SKIP_RT_CALC:
// Increment number of external packets dropped on TOP Parse by Global traffic processing mode
// STAT_OPERATION GS_TPR_EX_DRP, 1, EZ_INCR_CMD_STS;

// RT monitoring drop counters update

GLOB_CONF_DROP_LAB_CONT:
   MovBits  byTempCondByte1.BIT[0], byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_HAS_RX_COPY_BIT], 1; 
   Nop;
   
   // In case the packet is from port that has RX copy attributes, avoid discarding the packet
   // and just mark it as "to be discarded later" (it will be discarded in TOP Modify)
   If (byTempCondByte1.BIT[0])
      Jmp PRS_DONE_LAB, NOP_1;
         MovBits byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_DELAY_DROP_BIT], 1, 1;

   EZrfdRecycleOptimized;
   //##AMIT_TOCODE - maybe the following commented block should be uncommented and used when a LookAside will be invoked from TOPparse if I will not wait for the Lookup result (I am going to use the LookAside mechanism to test the IPv4.IsMyIP). Make this fix work this also in other places in the code before performing the halt.
   // For Ext.TCAM lookaside:
   //EZwaitFlag F_HREG7_REUSE;
   //PutHdrBits HREG[7].BIT[HREG_VALID_BIT], 0, 1; // Clear the valid bit of HREG[6], in order to prevent its lookup from being re-sent at the halt command.
//EZwaitFlag F_CTX_LA_RDY_0;
Halt DISC;


ICFDQ_ERR_DROP_LAB_CONT:
//Error was detected in ICFD increment counter and discard
MovBits ENC_PRI.byte[1].bit[5], PORT_DATA3.bit[0], 4;
   Nop;
//set counter id
MovMul CNT_PRS_ICFDQ_ERR_NET_DRP, 
       CNT_PRS_ICFDQ_ERR_HOST_DRP, 
       CNT_PRS_ICFDQ_ERR_CTRL_DRP; 

EZstatIncrByOneIndexReg ENC_PRO;
jmp GLOB_CONF_DROP_LAB_CONT, NO_NOP;
   Mov byCtrlMsgPrs2, 0,    1;    // clear RX_COPY bit that is used in discard label
   Nop;


GLOB_CONF_BYPASS_HOST_LAB:
// Frame arrives from network and sent to host      
// RT monitoring will be supported as really protocol type
// Perform parsing macro (includes hash calculation)    
jmp PARSE_AND_CALC_HASH, NO_NOP;
   Mov uqInReg, 0, 4;
   Mov PC_STACK, HOST_P0_BYPASS_LAB, 2;

// Build message to top resolve
indirect HOST_P0_BYPASS_LAB:    
jmp PRS_DONE_LAB, NO_NOP;
   Mov byFrameActionReg, FRAME_BYPASS_HOST, 1;
   PutHdr  HREG[ 1 ], 0; // Don't go through TOPsearch in this case

FRAME_CONT_ACTION_LAB:

/* This is the main data flow of the system, which means: apply the features configured on the frame */
#define IP_VERSION_BIT byTempCondByte1.bit[0];

   //jmp PARSE_AND_CALC_HASH, NO_NOP; // Perform packet parsing
#ifdef __SIM__
   PutKey UNF_CTX_STR_IDX(COM_KBS) , CTX_LINE_DUMMY_FOR_TCAM , 1;
#endif
   //Mov PC_STACK, PA_HANDLING_LAB, 2;

// For port that has "SLT VLAN" attribute, there is no need to run packet anomalies, and any of the security features in TOP resolve.
// Instead, packets from this port will be treated as if the global processing mode is bypass (host or network)
// TODO: this part of code is here because hash calculations are required (in PARSE_AND_CALC_HASH).
//       In case there is no need for the hash value, move the below lines to be performed in the FRAME_CONT_ACTION_LAB label, before
//       running parsing code.

   Xor ALU, $usrVlanTag, uqTmpReg1, 2;// Silicom packet check: Comparison
      movbits byTempCondByte1.BIT[MSG_CTRL_TOPPRS_2_SLT_VLAN_BIT], bitPRS_isSltVlanMode, 1;
   JZ HOST_P0_BYPASS_LAB, NO_NOP;       // Silicom packet check: TO_CPU if it is Silicom packet
      Xor ALU, byFrameActionOverrideReg, FRAME_BYPASS_HOST, 1;//check if an override action is set
      Mov byFrameActionReg, FRAME_CONT_ACTION, 1;
   JZ HOST_P0_BYPASS_LAB, NOP_2;       // Silicom packet check: TO_CPU if it is Silicom packet
varundef usrVlanTag;


If (byTempCondByte1.BIT[MSG_CTRL_TOPPRS_2_SLT_VLAN_BIT]) Jmp PRS_SLT_VLAN_LAB, NOP_1;
   movbits IP_VERSION_BIT, sHWD_bitL3IsIpV6  , 1; //IP_VERSION_BIT (UREG[1].byte[0]) might be overridden in parseFrameWithPA


////////////////////////////////////////////////////////////
//          SYN Protection Handling
////////////////////////////////////////////////////////////
ALIST_START:
SYN_PROT_LAB:

//-Mov   ALU, IPV4_IPV6_MAPPING_2ND, 4;
  Mov   FMEM_BASE,  uqOffsetReg0.byte[L3_OFFB], 2;    

// 2ND: Bytes 4 - 7
//-PutKey UNF_PROT_DIP_OFF_2ND (COM_KBS), ALU, 4;                          // TREG.DIPv4[4-7]
//-PutKey UNF_PROT_SIP_OFF_2ND (COM_KBS), ALU, 4;                          // TREG.SIPv4[4-7]

// 1ST: Bytes 0 - 3
//-if (IP_VERSION_BIT) jmp TREAT_IPV6_LAB, NO_NOP;  
//-   Copy  UNF_PROT_SIP_OFF(COM_KBS), IP_SIP_OFF(FMEM_BASE),4, SWAP;      // TREG.SIP[0-3]
//-  Copy  UNF_PROT_DIP_OFF(COM_KBS), IP_DIP_OFF(FMEM_BASE),4, SWAP;     // TREG.DIP[0-3]

//PutKey MSG_SIP_OFF_2ND(HW_KBS ), ALU, 4;                                // MSG.SIP[4-7]

// 3RD: Bytes 8 - 11
//Mov    ALU, IPV4_IPV6_MAPPING_3RD, 4;
//Nop;
//PutKey UNF_PROT_DIP_OFF_3RD (COM_KBS), ALU, 4;                   // TREG.DIPv4[8-11]
//PutKey UNF_PROT_SIP_OFF_3RD (COM_KBS), ALU, 4;                   // TREG.SIPv4[8-11]

//PutKey MSG_SIP_OFF_3RD      (HW_KBS ), ALU, 4;                          // MSG.SIPv4[8-11]
//Copy   MSG_IP_TTL_OFF  (HW_KBS), IP_TTL_OFF(FMEM_BASE),    1;           // MSG.TTL

// 4TH: Bytes 12 - 15
//PutKey UNF_PROT_DIP_OFF_4TH (COM_KBS), ALU, 4;                          // TREG.DIPv4[12-15]

//-jmp UNF_KEY_BUILD_END, NO_NOP;
if (!IP_VERSION_BIT) jmp UNF_KEY_BUILD_END, NO_NOP;
//PutKey UNF_PROT_SIP_OFF_4TH (COM_KBS), ALU, 4;                          // TREG.SIPv4[12-15]
    nop;
    Copy   MSG_IP_TTL_OFF  (HW_KBS), IP_TTL_OFF(FMEM_BASE),    1;
    
    //PutKey MSG_SIP_OFF_4TH      (HW_KBS ), ALU, 4;                          // MSG.SIPv4[12-15]


TREAT_IPV6_LAB:

// Prepare IPv6 lookup key for in KMEM for SYN protection lookup
Copy UNF_PROT_DIP_OFF (COM_KBS), IPv6_DIP_OFF_3RD (FMEM_BASE), 8, SWAP; // TREG.DIPv6[0-7]
Copy UNF_PROT_DIP_OFF_3RD (COM_KBS), IPv6_DIP_OFF (FMEM_BASE), 8, SWAP; // TREG.DIPv6[8-15]

Copy UNF_PROT_SIP_OFF (COM_KBS), IPv6_SIP_OFF_3RD (FMEM_BASE), 8, SWAP; // TREG.SIPv6[0-7]
Copy UNF_PROT_SIP_OFF_3RD (COM_KBS), IPv6_SIP_OFF (FMEM_BASE), 8, SWAP; // TREG.SIPv6[8-15]

// Copy IPv6 source address to general message
Copy MSG_SIP_OFF (HW_KBS), IPv6_SIP_OFF_3RD(FMEM_BASE), 8, SWAP;        // TREG.SIPv6[0-7]
Copy MSG_SIP_OFF_3RD (HW_KBS), IPv6_SIP_OFF(FMEM_BASE), 8, SWAP;        // TREG.SIPv6[8-15]

Copy MSG_IP_TTL_OFF  (HW_KBS), IPv6_HOP_LIMIT_OFF(FMEM_BASE), 1;

UNF_KEY_BUILD_END:

MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT], uqGcCtrlReg0.bit[GC_CNTRL_0_POLICY_NON_EMPTY_BIT], 1; //update Policy existance bit
MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ALST_EMPTY_BIT], uqGcCtrlReg0.bit[GC_CNTRL_0_ALIST_NONE_EMPTY_BIT], 1; //update ACL active bit

#define tmp_FLAGS_REG  byTempCondByte2;
#define IP_VERSION_BIT byTempCondByte1.bit[0];
#define TCP_TYPE_PRS (1 << 16);

//Mov uqCondReg , sHWD7 , 4; 

// If Protected destination table is empty, skip.
if (!uqGcCtrlReg0.BIT[GC_CNTRL_0_PROT_DST_NONE_EMPTY_BIT]) 
    jmp SKIP_SYN_PROT;
    // TCP packet - now test for TCP type
        //MovBits FMEM_BASE,  sHWD_bitsL4Offset , 7 ;    
        Mov FMEM_BASE,  uqOffsetReg0.byte[L4_OFFB], 1;    
        Movbits uqGcCtrlReg0.BIT[GC_CNTRL_0_PROT_DST_NONE_EMPTY_BIT], 0, 1;  // Reset the bit (used to indicate later if a lookup in protected destination structure is about to be set)

// For now, we put physical port number

#If !UNF_CENTRALISED
//MovBits uqOffsetReg0.byte[L4_OFFB] , sHWD_bitsL4Offset , 7;  no need, done in parseFrameWithPA
//PutKey MSG_SIP_OFF_4TH  (HW_KBS ), ALU, 4;
Get     tmp_FLAGS_REG, TCP_FLAGS_OFF(FMEM_BASE), 1; 
movbits IP_VERSION_BIT, sHWD_bitL3IsIpV6  , 1;  //Assume IPv4 , if no will be overrided by IPv6 flag  
#else
//MovBits uqOffsetReg0.byte[L4_OFFB] , sHWD_bitsL4Offset , 7;  no need, done in parseFrameWithPA
Nop;
Get     tmp_FLAGS_REG, TCP_FLAGS_OFF(FMEM_BASE), 1; 
Nop;
#endif


xor ALU, tmp_FLAGS_REG, TCP_RST_ACK_FLAGS, 4, MASK_0000001F, MASK_SRC1;
nop;
jnz DBG_CONTINUE1;
     //check if tcp frame , if no skip the rest
    if(!uqCondReg.bit[25]) jmp  END_OF_SYN;
      Putkey UNF_PROT_PORT_OFF(COM_KBS), bySrcPortReg, CMP_POLICY_PORT_SIZE;  

MovBits tmp_FLAGS_REG.bit[TCP_ACK_FLAG_OFF], 0, 1;

DBG_CONTINUE1:

#define uqSynCookie           uqTmpReg1;
#define uqRstCookie           uqTmpReg5;

MovBits uqSynCookie.bit[24], IP_VERSION_BIT , 1;

if (tmp_FLAGS_REG.bit[TCP_SYN_FLAG_OFF]) jmp SKIP_ACK_RST_VER_LAB, NO_NOP;
   MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS], 0, 2;	//default syn type packet
   Get uqRstCookie,       TCP_SEQ_OFF(FMEM_BASE),  CMP_BDOS_L4_TCP_SEQ_NUM_SIZE, SWAP; // For safe reset cookie


Mov ALU, tmp_FLAGS_REG, 1;
Movbits ALU.bit[TCP_PSH_FLAG_OFF], 0, 1;	// In SYN Protection we need to disregard PUSH flag bit (and relate only to SYN\RST\ACK)
NumOnes ALU, ALU, 1, MASK_0000001F, MASK_SRC1;
MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS], 0, 2;	//default syn type packet
Sub ALU, ALU, 1, 1;
PutKey MSG_SYN_COOKIE_OFF(HW_KBS), uqSynCookie, 4;

jnz END_OF_SYN, NO_NOP;
	And ALU, tmp_FLAGS_REG, TCP_SYN_RST_ACK_FLAGS, 1, MASK_0000001F, MASK_SRC1;
	Mov uqTmpReg1, 0, 4;

jz END_OF_SYN;          // Jump if not SYN\RST\ACK
   Get uqTmpReg2.byte[0], TCP_SPRT_OFF(FMEM_BASE), CMP_BDOS_L4_SRC_PORT_SIZE, SWAP;
   Get uqTmpReg2.byte[2], TCP_DPRT_OFF(FMEM_BASE), CMP_BDOS_L4_DST_PORT_SIZE, SWAP;

if (tmp_FLAGS_REG.bit[TCP_SYN_FLAG_OFF]) jmp F1_COOKIE_CALC_LAB, NO_NOP;
   Modulo   ALU,          uqTmpReg2,     3,    1; // ALU <- (L4 SRC PORT)%3
   Get uqRstCookie,       TCP_SEQ_OFF(FMEM_BASE),  CMP_BDOS_L4_TCP_SEQ_NUM_SIZE, SWAP; // For safe reset cookie

//   Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;
//   Nop;


// This is TCP-SYN: Calculate SYN cookie

////////////////////////////////////////////////////////////
//       SYN Protection: Cookie calculation
////////////////////////////////////////////////////////////

// Stage 1:
// S1 = (SIP) xor (DIP) xor [(TCP sport) xor (TCP sport)>>8] xor [(TCP dport) xor (TCP dport)>>8] xor (TS) xor (0x622B70F5)
/*
#define SYN_PROT_DIP_OFF_2ND (SYN_PROT_DIP_OFF + 4 );
#define SYN_PROT_DIP_OFF_3RD (SYN_PROT_DIP_OFF + 8 );
#define SYN_PROT_DIP_OFF_4TH (SYN_PROT_DIP_OFF + 12);
#define SYN_PROT_SIP_OFF_2ND (SYN_PROT_SIP_OFF + 4 );
#define SYN_PROT_SIP_OFF_3RD (SYN_PROT_SIP_OFF + 8 );
#define SYN_PROT_SIP_OFF_4TH (SYN_PROT_SIP_OFF + 12);
*/


// uqSynCookie will contain accumulated calculation of the cookie
Mov uqSynCookie, 0, 4;

// XOR between TCP ports (2 bytes result)
xor uqSynCookie, uqTmpReg2.byte[0], uqTmpReg2.byte[2], 2;

// Get TCP source port & destination port
// Get uqRstCookie,       TCP_SEQ_OFF(FMEM_BASE),  CMP_BDOS_L4_TCP_SEQ_NUM_SIZE; // For safe reset cookie

// Move frame pointer to L3 offset
Mov FMEM_BASE.byte[0], uqOffsetReg0.byte[L3_OFFB], 2;

// XOR result (1 byte result)
xor uqSynCookie.byte[0], uqSynCookie.byte[0], uqSynCookie.byte[1], 1;

if (IP_VERSION_BIT) jmp SYN_TREAT_IPV6, NO_NOP;  
   // For safe reset cookie - move upper 20 bits to offset[0]
   Movbits uqRstCookie.bit[0],  uqRstCookie.bit[12], 10;
   Movbits uqRstCookie.bit[10], uqRstCookie.bit[22], 10;


   // SYN Treat for IPV4:

   // Get IPv4 address or IPv6 1st Quartet
   Get uqTmpReg2, IP_SIP_OFF(FMEM_BASE), 4, SWAP;

   // Prepare IPv4 lookup key in KMEM for SYN protection lookup and copy IPv4 source address to general message
   Get uqTmpReg3, IP_DIP_OFF(FMEM_BASE), 4, SWAP;

jmp SYN_HASH_CONT, NO_NOP;
  xor ALU, uqSynCookie, uqTmpReg2, 4; //XOR IPv4/IPv6 SIP with TCP port XOR result
  xor uqSynCookie, ALU, uqTmpReg3, 4; //XOR previous result with IPv4/IPv6 DIP

SYN_TREAT_IPV6:

Get uqTmpReg2, IPv6_SIP_OFF_2ND (FMEM_BASE), 4, SWAP;
Get uqTmpReg3, IPv6_DIP_OFF_2ND (FMEM_BASE), 4, SWAP;
xor ALU, uqSynCookie, uqTmpReg2, 4;
xor ALU, ALU,         uqTmpReg3, 4;

Get uqSynCookie, IPv6_SIP_OFF (FMEM_BASE), 4, SWAP;
Get uqTmpReg2,   IPv6_DIP_OFF (FMEM_BASE), 4, SWAP;
xor ALU, ALU, uqSynCookie, 4;
xor ALU, ALU, uqTmpReg2,   4;

Get uqSynCookie, IPv6_SIP_OFF_3RD (FMEM_BASE), 4, SWAP;
Get uqTmpReg2,   IPv6_DIP_OFF_3RD (FMEM_BASE), 4, SWAP;
xor ALU, ALU, uqSynCookie, 4;
xor ALU, ALU, uqTmpReg2,   4;

Get uqSynCookie, IPv6_SIP_OFF_4TH (FMEM_BASE), 4, SWAP;
Get uqTmpReg2,   IPv6_DIP_OFF_4TH (FMEM_BASE), 4, SWAP;
xor ALU,         ALU, uqSynCookie, 4;
xor uqSynCookie, ALU, uqTmpReg2,   4;

// Now uqSynCookie == (SIP) xor (DIP) xor [(TCP sport) xor (TCP sport)>>8] xor [(TCP dport) xor (TCP dport)>>8] [4 bytes]

#If !UNF_CENTRALISED
// Prepare IPv6 lookup key for in KMEM for SYN protection lookup
Copy UNF_PROT_DIP_OFF (COM_KBS), IPv6_DIP_OFF_3RD (FMEM_BASE), 8, SWAP;
Copy UNF_PROT_DIP_OFF_3RD (COM_KBS), IPv6_DIP_OFF (FMEM_BASE), 8, SWAP;

Copy UNF_PROT_SIP_OFF (COM_KBS), IPv6_SIP_OFF_3RD (FMEM_BASE), 8, SWAP;
Copy UNF_PROT_SIP_OFF_3RD (COM_KBS), IPv6_SIP_OFF (FMEM_BASE), 8, SWAP;

// Copy IPv6 source address to general message
Copy MSG_SIP_OFF (HW_KBS), IPv6_SIP_OFF_3RD(FMEM_BASE), 8, SWAP;
Copy MSG_SIP_OFF_3RD (HW_KBS), IPv6_SIP_OFF(FMEM_BASE), 8, SWAP;
#endif

/*
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
*/

SYN_HASH_CONT:

#define TIMESTAMP       uqTmpReg6;
#define KEY             uqTmpReg3;

//In syn case skip calculation , it will be done in TopModify
//Sub ALU, tmp_FLAGS_REG, 2 , 1;
Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;
//JZ  SKIP_ACK_RST_VER_LAB;
// Get Timestamp from MREG
//if (tmp_FLAGS_REG.bit[TCP_SYN_FLAG_OFF]) jmp F1_COOKIE_CALC_LAB, NO_NOP;
//if (tmp_FLAGS_REG.bit[TCP_SYN_FLAG_OFF]) jmp SKIP_ACK_RST_VER_LAB, NO_NOP;
   xor TIMESTAMP, ALU, !ALU, 4, SC_CK_STMP_MREG, MASK_BOTH;
   Mov uqTmpReg0, uqSynCookie, 4; 
Mov CNT, 1, 1; // set loop iteration limit

HASH_CONT_OLD_TIMESTAMP:

// Check for timestamp LSBit to determine which key to take
movbits byTempCondByte1, TIMESTAMP.bit[0], 5;

// mark syn type packet for Top Resolve
MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS] , 0 , 2; 

// Case odd: Get key odd from MREG
if (byTempCondByte1.bit[0]) jmp KEY_DONE_LAB, NO_NOP;
   Mov uqSynCookie, uqTmpReg0, 4; 
   xor KEY, ALU, !ALU, 4, SC_CK_KEY_P1_MREG, MASK_BOTH;

// Case even: Get key even from MREG
xor KEY, ALU, !ALU, 4, SC_CK_KEY_P0_MREG, MASK_BOTH;
//Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;

KEY_DONE_LAB: 
// XOR cookie result with Timestamp and SYN_COOKIE_CONST_KEY_VAL (0x622B70F5)
Mov uqTmpCtxReg1, SYN_COOKIE_CONST_KEY_VAL, 4;
xor ALU, uqSynCookie, TIMESTAMP, 4;
xor uqSynCookie, ALU, uqTmpCtxReg1, 4;


// Stage 2:
// S2 = ( (S1 & 0xFFFF) | [((SeqNum >> 6) & 0xFF)<<16] ) & 0xFFFFFF

// Get original TCP Seq#, use 8 bits of the original Seq# in the SYN Cookie
Get uqTmpReg4, TCP_SEQ_OFF(FMEM_BASE), 4, SWAP;
movbits uqSynCookie.bit[24], 0, 8;
movbits uqSynCookie.bit[16], uqTmpReg4.bit[15], 8;
nop;

// Stage 3:
// S3 = S2 xor KEY

xor uqSynCookie, uqSynCookie, KEY, 4;


// Stage 4:
// Cookie = (S3 & 0xFFFFFF) | [(MSS & 0x7) << 24] | [(TS & 0x1F) << 27]

movbits uqSynCookie.bit[24], uqFramePrsReg.BIT[L3_TYPE_OFF], 1; // For now, transfer the IP version in bit 24
movbits uqSynCookie.bit[27], TIMESTAMP.bit[0], 5;               // (TS & 0x1F) << 27


////////////////////////////////////////////////////////////
//       SYN Protection: RST Cookie calculation
////////////////////////////////////////////////////////////

// F1 cookie algorithm: Swap Seq# (done before), take last 12 bits of Seq#, shift according to 
// SrcPort value (last 2 bits) and add to the remaining 20 bits of Seq#. This gives 20 bits F1 cookie

   Get uqTmpReg2.byte[0], TCP_SPRT_OFF(FMEM_BASE), CMP_BDOS_L4_SRC_PORT_SIZE, SWAP;
   Get uqRstCookie,       TCP_SEQ_OFF(FMEM_BASE),  CMP_BDOS_L4_TCP_SEQ_NUM_SIZE, SWAP; // For safe reset cookie
   Modulo   ALU,          uqTmpReg2,     3,    1; // ALU <- (L4 SRC PORT)%3
   Nop;

F1_COOKIE_CALC_LAB:
// Get last 2 bits of TCP source port to determine shift   
//Get ALU, TCP_SPRT_OFF(FMEM_BASE), 2, SWAP;
   SHL      ALU,           ALU,           2,    1; // ALU <- ((L4 SRC PORT)%3)*4
   SHR      uqTmpReg2,     uqRstCookie,   12,   4; // uqTmpReg2 <- uqRstCookie>>12
   SHL      uqRstCookie,   uqRstCookie,   ALU,  3; // uqRstCookie <- uqRstCookie << (((L4 SRC PORT)%3)*4)
   Nop;
   Add      uqRstCookie,   uqRstCookie,   uqTmpReg2, 3;

// If packet is SYN - skip packet cookie validation part
if (tmp_FLAGS_REG.bit[TCP_SYN_FLAG_OFF]) jmp SKIP_ACK_RST_VER_LAB, NO_NOP;
   MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS], 0 , 2; // Update packet type to SYN 
   Movbits  uqRstCookie.bit[20], 0, 12;            // Clear upper 12 bits, resulting in F1 cookie in the lower 20 bits

// If packet is ACK - jump to ACK validation part
if (tmp_FLAGS_REG.bit[TCP_ACK_FLAG_OFF]) jmp ACK_VERIFY_LAB, NOP_1;
   MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS], 2, 2;  // Update packet type to ACK   
   

#if 0
// Prepare ENC_PRI with SrcPort result
Mov ENC_PRI, 0x2000, 2;
Movbits ENC_PRI.bit[14], ALU, 2;
//Movbits ENC_PRI.bit[13], 1, 1;
//Movbits uqRstCookie.bit[0],  uqRstCookie.bit[12], 10;
//Movbits uqRstCookie.bit[10], uqRstCookie.bit[22], 10;
SHR   uqRstCookie, uqRstCookie, 12, 4;

// Get Seq# last 12bits to add to the remaining 20 bits 
Get ALU, TCP_SEQ_OFF(FMEM_BASE), CMP_BDOS_L4_TCP_SEQ_NUM_SIZE;            
//Nop;
//Movbits uqRstCookie.bit[20], ALU, 12;
//Mov ALU, 0, 4;

// Determine shift according to SrcPort result
JMul SAFE_RST_NIBBLE_2_ADD,  // If TCP source port bit[1] == 1
     SAFE_RST_NIBBLE_1_ADD,  // If TCP source port bit[0] == 1
     SAFE_RST_NIBBLE_0_ADD,  // If TCP source port bit[0] & bit[1] == 0 jump here
     NO_NOP;
     Movbits uqRstCookie.bit[20], ALU, 12;
     Nop;

// 2 nibbles shift
SAFE_RST_NIBBLE_2_ADD:
jmp SAFE_RST_FINALIZE, NO_NOP;
    Movbits ALU.bit[8],  uqRstCookie.bit[20],  12, RESET;
    Nop;

// 1 nibble shift
SAFE_RST_NIBBLE_1_ADD:
jmp SAFE_RST_FINALIZE, NO_NOP;
    Movbits ALU.bit[4],  uqRstCookie.bit[20],  12, RESET;
    Nop;

// Default: no shift
SAFE_RST_NIBBLE_0_ADD:
    Movbits ALU.bit[0],  uqRstCookie.bit[20],  12, RESET;
    Nop;

SAFE_RST_FINALIZE:
Add uqRstCookie, uqRstCookie, ALU, 4;  // Add last 12 bits to the remaining 20 bits (after shifting accordingly)
Movbits uqRstCookie.bit[20], 0, 12;    // Clear upper 12 bits, resulting in F1 cookie in the lower 20 bits


SAFE_RST_CALC_DONE:

// If packet is SYN - skip packet cookie validation part
if (tmp_FLAGS_REG.bit[TCP_SYN_FLAG_OFF]) jmp SKIP_ACK_RST_VER_LAB, NOP_1;
   MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS], 0 , 2; // Update packet type to SYN 

// If packet is ACK - jump to ACK validation part
if (tmp_FLAGS_REG.bit[TCP_ACK_FLAG_OFF]) jmp ACK_VERIFY_LAB, NOP_1;
   MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS], 2, 2;  // Update packet type to ACK   
#endif

////////////////////////////////////////////////////////////
//       SYN Protection: RST Cookie validation
////////////////////////////////////////////////////////////

Get uqTmpReg4, TCP_SEQ_OFF(FMEM_BASE), 4, SWAP; 
MovBits byCtrlMsgPrs1.BIT[MSG_CTRL_TOPPRS_1_SYN_BITS], 1, 2;     // Update packet type to RST

// SYN cookie = TcpSeq# bits[0..5,16..21]
Movbits ALU.bit[0], uqTmpReg4.bit[0],  6;
Movbits ALU.bit[6], uqTmpReg4.bit[16], 6;
 
// Validate SYN Cookie
Sub ALU, uqSynCookie, ALU, 2, MASK_00000FFF, MASK_BOTH;
Mov uqRstCookie, 0, 4;

jz VERIFIED_ACK_RST_LAB, NO_NOP;
    // Reset cookie = TcpSeq# bits[6..15,22..31]
    Movbits uqRstCookie.bit[0],  uqTmpReg4.bit[6],  10;
    Movbits uqRstCookie.bit[10], uqTmpReg4.bit[22], 10;

// Check if calculated cookie == (TcpSeq# - 2^20)
Mov ALU, RST_OUT_OF_WINDOW_VAL, 4;
Sub uqTmpReg4, uqTmpReg4, ALU, 4;   
nop;

// SYN cookie = (TcpSeq# - 2^20) bits[0..5,16..21]
Movbits ALU.bit[0], uqTmpReg4.bit[0],  6;
Movbits ALU.bit[6], uqTmpReg4.bit[16], 6;

// Validate SYN Cookie - 2^20
Sub ALU, uqSynCookie, ALU, 2, MASK_00000FFF, MASK_BOTH;
nop;

jz VERIFIED_ACK_RST_LAB, NO_NOP;
    // Reset cookie = (TcpSeq# - 2^20) bits[6..15,22..31]
    Movbits uqRstCookie.bit[0],  uqTmpReg4.bit[6],  10;
    Movbits uqRstCookie.bit[10], uqTmpReg4.bit[22], 10;

// If not validated loop through the cookie calculation again with TIMESTAMP - 1
loop HASH_CONT_OLD_TIMESTAMP;
    Sub TIMESTAMP, TIMESTAMP, 1, 4;
    nop;

// Cookie not validated
jmp END_OF_SYN, NOP_2;


ACK_VERIFY_LAB:

// Jump to ACK cookie validation

jmp CALC_HASH, NO_NOP;
   nop;  //   Mov UREG[11].byte[2], 0, 2;
   Mov PC_STACK, CALC_ACK_HASH_DONE, 2;

indirect CALC_ACK_HASH_DONE:  
PutKey MSG_SYN_COOKIE_VERIF_OFF(HW_KBS), bytmp2, 1;  
Sub ALU, bytmp2, 0xFF, 1;  // GuyE: bytmp2 manipulated in CONT_CHECK_COOKIE label, should be 0x00 if delta is bigger than ACK_NUM_1500, 0xFF otherwise
nop;
jnz END_OF_SYN, NOP_1;
Get bytmp,     TCP_DATAOFF_OFF(FMEM_BASE), 1;

// START of: Calc if TCP ACK has data or not
Mov FMEM_BASE, uqOffsetReg0.byte[L3_OFFB] , 2;
MovBits byTempCondByte1, uqFramePrsReg.BIT[L3_TYPE_OFF], 1;
SHL bytmp, bytmp, 2, 1; // bytmp = TCP header length (in bytes)
Get uqTmpReg4, IPv6_PAYLOAD_LEN_OFF(FMEM_BASE), 2, SWAP;  // Get IPv6 payload length
if (byTempCondByte1) jmp TCP_DECODE_DETECT_PAYLOAD_IPV6_LAB, NOP_2;

// Get IP header length
Get ALU, 0(FMEM_BASE), 1;
Mov uqTmpReg4, 0, 2;
Movbits uqTmpReg4.bit[2], ALU, 4; // uqTmpReg4 = IPv4 header length (in bytes)

jmp TCP_DECODE_DETECT_PAYLOAD_DONE_LAB, NO_NOP;
    Get ALU, IP_LEN_OFF(FMEM_BASE), 2, SWAP;    // Get IP total length
    Sub uqTmpReg4, ALU, uqTmpReg4, 2;           // uqTmpReg4 =  "IP payload length" - "IP header length"


TCP_DECODE_DETECT_PAYLOAD_IPV6_LAB:

// Check if IPv6 payload length equals 0 (jumbo frame)
Sub ALU, uqTmpReg4, 0, 2;
nop;
if (FLAGS.BIT[ F_ZR ]) Mov uqTmpReg4, 0xFFFF, 2;


TCP_DECODE_DETECT_PAYLOAD_DONE_LAB:                         

Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB] , 2;                                // restore L4 base for further use
Sub ALU, uqTmpReg4, bytmp, 2, MASK_000000FF, MASK_SRC2;                       // ALU = "Payload length" - "IP header length" - "TCP header length"
Nop;
If (A) Movbits byCtrlMsgPrs1.bit[MSG_CTRL_TOPPRS_1_ACK_WITH_DATA_BIT], 1, 1;  // Set '1' if ACK contains payload (Frame length - L4 offset - TCP header length > 0)
// END of: Calc if TCP ACK has data or not

SKIP_ACK_RST_VER_LAB:
VERIFIED_ACK_RST_LAB:


// Prepare lookup keys fields in KMEM
   MovBits uqSynCookie.bit[24], uqFramePrsReg.BIT[L3_TYPE_OFF] , 1; // uqSynCookie was deleted during CALC_HASH. restoring only IP_VERSION_BIT for TOP Modify usage
Mov2Bits byTempCondByte1.BITS[0,0], uqInReg.BITS[FRAG_IPv4_OFFSET,FRAG_IPv6_OFFSET];
   Add COM_HBS, COM_HBS, 1, 1;
If(!byTempCondByte1.BIT[0]) Jmp L4_PORT_KEY_UPDATE0, NO_NOP;
   Copy   UNF_PROT_DPORT_OFF(COM_KBS), TCP_DPRT_OFF(FMEM_BASE), 2, SWAP;
   Copy   UNF_PROT_SPORT_OFF_KMEM (COM_KBS), TCP_SPRT_OFF(FMEM_BASE), 2;

PutKey UNF_PROT_DPORT_OFF(COM_KBS), 0, 2;
PutKey UNF_PROT_SPORT_OFF_KMEM(COM_KBS), 0, 2;

L4_PORT_KEY_UPDATE0:

PutKey UNF_PROT_PORT_OFF (COM_KBS), bySrcPortReg, CMP_POLICY_PORT_SIZE;
//PutKey UNF_PROT_CONT_COOKIE_OFF_KMEM(COM_KBS), uqRstCookie, 4;
Copy   UNF_PROT_CONT_COOKIE_OFF_KMEM(COM_KBS), TCP_SEQ_OFF(FMEM_BASE),  CMP_BDOS_L4_TCP_SEQ_NUM_SIZE, SWAP; // For safe reset cookie

// Prepare message fields
Copy   MSG_TCP_SPORT_OFF (HW_KBS), TCP_SPRT_OFF(FMEM_BASE), 2;
PutKey MSG_RST_COOKIE_OFF(HW_KBS), uqRstCookie, 3;
PutKey MSG_SYN_COOKIE_OFF(HW_KBS), uqSynCookie, 4;

MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_PERFORM_SYN_PROT_BIT], 1, 1;

// Put phase identifier in the key
//Mov     ALU, 0, 4;
MovBits ALU, uqGcCtrlReg0.bit[GC_CNTRL_0_PROT_DST_PHASE_BIT], 1, RESET;
//PutHdr  HREG[ COM_HBS ], COMP_SYN_PROT_LKP;


//global access list is already constructed , compleate fields construction otherwise for access list
jmp  SYN_CREATED_GLOBAL_KEY , NO_NOP;   
   PutKey  UNF_PROT_PHASE_OFF(COM_KBS), ALU, 1;
   PutKey UNF_L4_TYPE(COM_KBS) , 1 , 1; // L4 is TCP for sure (?)
   
   
SKIP_SYN_PROT:
// only if supported type (i.e. no GRE, IPSEC, L2TP, IPinIP type)

END_OF_SYN:

//In case when access list is all alone I need re-construct key
//MovBits ALU.bit[0] , sHWD7.bit[25] , 4, RESET;  
MovBits ALU.bit[4] , uqFramePrsReg.BIT[L4_TYPE_OFF] , 3, RESET;  

//Copy   MSG_IP_TTL_OFF  (HW_KBS), IP_TTL_OFF(FMEM_BASE),    1; // Done before syn feature
Putkey UNF_PROT_PORT_OFF(COM_KBS), bySrcPortReg, CMP_POLICY_PORT_SIZE;  

PutKey UNF_L4_TYPE(COM_KBS) , ALU , 1;




// Prepare IPv4 lookup key in KMEM for SYN protection lookup and copy IPv4 source address to general message

#if !UNF_CENTRALISED
Mov    ALU, IPV4_IPV6_MAPPING_2ND, 4;
#endif
/*
#define MSG_SIP_OFF          (MSG_RST_LEARN_KEY     );
#define MSG_SIP_OFF_2ND      (MSG_RST_LEARN_KEY + 4 );
#define MSG_SIP_OFF_3RD      (MSG_RST_LEARN_KEY + 8 );
#define MSG_SIP_OFF_4TH      (MSG_RST_LEARN_KEY + 12);
*/
//Get uqTmpReg3, IP_DIP_OFF(FMEM_BASE), 4, SWAP;
//Putkey UNF_PROT_PORT_OFF(COM_KBS), bySrcPortReg, CMP_POLICY_PORT_SIZE;  

#if !UNF_CENTRALISED
PutKey MSG_SIP_OFF_2ND      (HW_KBS ), ALU, 4;
PutKey UNF_PROT_DIP_OFF_2ND (COM_KBS), ALU, 4;
PutKey UNF_PROT_SIP_OFF_2ND (COM_KBS), ALU, 4;
PutKey MSG_SIP_OFF_2ND      (HW_KBS ), ALU, 4;
PutKey UNF_PROT_DIP_OFF_2ND (COM_KBS), ALU, 4;
PutKey UNF_PROT_SIP_OFF_2ND (COM_KBS), ALU, 4;
#endif

// Get IPv4 address or IPv6 1st Quartet
//Get uqTmpReg2, IP_SIP_OFF(FMEM_BASE), 4, SWAP;

// Prepare IPv4 lookup key in KMEM for SYN protection lookup and copy IPv4 source address to general message
//Get uqTmpReg3, IP_DIP_OFF(FMEM_BASE), 4, SWAP;
//Copy   UNF_PROT_DIP_OFF     (COM_KBS), IP_DIP_OFF (FMEM_BASE),4, SWAP;

#if 0
#ifndef __SIM__ 
   MovBits ALU.bit[12], sHWDall_bitOneTag, 1;
   MovBits ALU, sHWD_uxTag2Vid, 11;
#else
   MovBits ALU.bit[12], sHWDall_bitNoTag, 1;
   MovBits ALU, sHWD_uxTag1Vid, 11;
#endif
#endif

/*
Copy   UNF_PROT_DPORT_OFF(COM_KBS), TCP_DPRT_OFF(FMEM_BASE), 2, SWAP;
#if 0
PutKey UNF_PROT_VLAN_OFF (COM_KBS), ALU, 2;
#endif

Add COM_HBS, COM_HBS, 1, 1;

Copy   UNF_PROT_SPORT_OFF_KMEM (COM_KBS), TCP_SPRT_OFF(FMEM_BASE), 2;
*/
// Prepare lookup keys fields in KMEM
//MovBits byTempCondByte1.BIT[0], uqFramePrsReg.BIT[L3_FRAG_OFF], 1;
//uqInReg.BIT[FRAG_IPv4_OFFSET] is set only if it is a non first fragment. same for uqInReg.BIT[FRAG_IPv6_OFFSET]
Mov2Bits byTempCondByte1.BITS[0,0], uqInReg.BITS[FRAG_IPv4_OFFSET,FRAG_IPv6_OFFSET];
   Add COM_HBS, COM_HBS, 1, 1;
If(!byTempCondByte1.BIT[0]) Jmp L4_PORT_KEY_UPDATE1, NO_NOP; // if first frag
   Copy   UNF_PROT_DPORT_OFF(COM_KBS), TCP_DPRT_OFF(FMEM_BASE), 2, SWAP;
   Copy   UNF_PROT_SPORT_OFF_KMEM (COM_KBS), TCP_SPRT_OFF(FMEM_BASE), 2;

PutKey UNF_PROT_DPORT_OFF(COM_KBS), 0, 2;
PutKey UNF_PROT_SPORT_OFF_KMEM(COM_KBS), 0, 2;

L4_PORT_KEY_UPDATE1:


// Prepare message fields
Copy   MSG_TCP_SPORT_OFF (HW_KBS), TCP_SPRT_OFF(FMEM_BASE), 2;

//PutHdr  HREG[ COM_HBS ], COMP_SYN_PROT_LKP;
PutKey  UNF_PROT_PHASE_OFF(COM_KBS), ALU, 1;

//Add COM_KBS, COM_KBS, CMP_SYN_PROT_DEST_KMEM_SIZE, 2;



#undef TIMESTAMP;
#undef IP_VERSION_BIT;
#undef uqSynCookie;


SYN_CREATED_GLOBAL_KEY:

Add COM_KBS, COM_KBS, MAIN_KMEM_SIZE, 2;      


// Support OOS feature after Policy/BDOS
//if (!uqGcCtrlReg0.bit[GC_CNTRL_0_TCP_OOS_ENABLED_BIT]) jmp TCP_OOS_DISABLED, NOP_2;

And ALU, uqFramePrsReg,  {1 << JUMBO_PCKT_STATUS_OFF}, 4;
   nop;
jnz PRS_DONE_LAB, NOP_2;

// Test that this is TCP
Mov ALU , 1 , 4;
Mov uqCondReg , uqFramePrsReg , 4;
xor ALU, uqFramePrsReg.byte[2] , ALU, 1 ,MASK_00000003 , MASK_SRC1;

//exit if fragment
if (uqCondReg.BIT[L3_FRAG_OFF]) jmp PRS_DONE_LAB , NOP_2;

jnz PRS_DONE_LAB , NOP_2;



// Test for TCP type
Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;
nop;
nop;
Get tmp_FLAGS_REG, TCP_FLAGS_OFF(FMEM_BASE), 1;
nop;
xor ALU, tmp_FLAGS_REG, TCP_SYN_ACK_FLAGS, 4, MASK_0000001F, MASK_SRC1;
movbits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT], MSG_CONTROL_TCP_OOS_TYPE_SYN_ACK, 3;
jz CALC_HASH_SYNACK , NOP_2;
movbits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT], MSG_CONTROL_TCP_OOS_TYPE_FIN_RST, 3;
if (tmp_FLAGS_REG.bit[TCP_FIN_FLAG_OFF]) jmp CALC_HASH_LOCAL, NOP_2;
if (tmp_FLAGS_REG.bit[TCP_RST_FLAG_OFF]) jmp CALC_HASH_LOCAL, NOP_2;
movbits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT], MSG_CONTROL_TCP_OOS_TYPE_ACK,     3;
if (tmp_FLAGS_REG.bit[TCP_ACK_FLAG_OFF]) jmp CALC_HASH_LOCAL, NOP_2;
// support PSH flag, not including ACK-PSH combination, support like FIN/RST
movbits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT], MSG_CONTROL_TCP_OOS_TYPE_FIN_RST, 3;
if (tmp_FLAGS_REG.bit[TCP_PSH_FLAG_OFF]) jmp CALC_HASH_LOCAL, NOP_2;

// No flags match. Skip OOS
// Although, if this is SYN, perhaps we still need to calculate 
// Hash function for SYN-Cookie calculation?

jmp PRS_DONE_LAB , NOP_1;
  // Unset OOS control bits
  movbits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT], 0, 3;
//  movbits uqGcCtrlReg0.bit[GC_CNTRL_0_TCP_OOS_POLICY_CLASS_BIT], 0, 1;

CALC_HASH_SYNACK:
// check if SYN-ACK allow mode is enable, forward the packet

CALC_HASH_LOCAL:

Mov PC_STACK, CALC_HASH_DONE, 2;
Jmp CALC_HASH, NOP_2;

indirect CALC_HASH_DONE:
Add COM_HBS, COM_HBS, 1, 1;
Mov ALU, 0, 4;
// Provide IP version for TOPmodify
MovBits ALU.bit[24], uqFramePrsReg.BIT[L3_TYPE_OFF] , 1;
PutKey 0(COM_KBS), CNVI, 4;
PutKey MSG_SYN_COOKIE_OFF(HW_KBS), ALU, 4;
//PutHdr HREG[ COM_HBS ], OOS_LKP;

Sub ALU, bytmp2, 0xFF, 1;  // GuyE: bytmp2 manipulated in CONT_CHECK_COOKIE label (should be 0x00 if delta is bigger than ACK_NUM_1500, 0xFF otherwise) and in COMPARE_PREV_TIMESTAMP label (should be 0x00 if TS difference bigger than 1, 0xFF otherwise)
Nop;
if (FLAGS.bit[F_ZR]) PutKey MSG_SYN_COOKIE_OFF(HW_KBS), 0xFF, 1;  //MSG_SYN_COOKIE_OFF is 4 bytes field but it was init a few lines before so we can put only 1 byte of 0xFF
//Add COM_KBS, COM_KBS, SIMP_OOS_LKP_SIZE, 2;

#undef tmp_FLAGS_REG 


PRS_DONE_LAB:

BuildMsg;

PutHdr HREG[ 0 ], PRS_MSG_HDR;   // Write the message header 

//TODO_OPTIMIZE: consider issueing the TCAM Lookup using LookAside (i.e. before the halt) in order to start it as soon as possible to minimize the latency.
// For Ext.TCAM lookaside:
//EZwaitFlag F_HREG7_REUSE;
//PutHdrBits HREG[7].BIT[HREG_VALID_BIT], 0, 1; // Clear the valid bit of HREG[6], in order to prevent its lookup from being re-sent at the halt command.
//EZwaitFlag F_CTX_LA_RDY_0;

Halt UNIC,HW_MSG_HDR;



BDOS_DISABLED:
// In case BDOS is disabled, perform configured default action (Drop or Continue)
jmp SKIP_BDOS, NOP_2;
jmp GLOB_CONF_DROP_LAB, NOP_2;

SKIP_BDOS:
// Check if we still need to perform policy (for OOS)
//if (uqGcCtrlReg0.bit[GC_CNTRL_0_TCP_OOS_POLICY_CLASS_BIT]) jmp SYN_PROT_LAB, NOP_1;
jmp SYN_PROT_LAB, NOP_1;
   // But make sure TOPresolve does not analyze the BDOS sets:
   Putkey MSG_L4_VALIDATION_BITS_OFF(HW_KBS), 0, 2;
 

      
//control error treatment 
indirect ERROR_HANDLING:
// In case frame was shorter than expected
EZstatIncrByOneIndexImm GC_ERROR_0;
jmp GLOB_CONF_DROP_LAB, NOP_2;

////////////////////////////////////////////////////////////
//  				     Packet Parsing
////////////////////////////////////////////////////////////                                    
PARSE_AND_CALC_HASH:
//parseFrame;
Nop;
JStack NOP_2;


////////////////////////////////////////////////////////////
//       SYN Protection: SYN-ACK Cookie validation
////////////////////////////////////////////////////////////

CALC_HASH:   

// Get IP version
movbits byTempCondByte1.bit[0], uqFramePrsReg.BIT[L3_TYPE_OFF], 1;

// Calculate hash and Add search header for Flow Table
Get uqTmpReg6.byte[0], TCP_SPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_SRC_PORT_SIZE, SWAP;
Get uqTmpReg6.byte[2], TCP_DPRT_OFF(FMEM_BASE),  CMP_BDOS_L4_DST_PORT_SIZE, SWAP;


Mov FMEM_BASE.byte[0] , uqOffsetReg0.byte[L3_OFFB],2;

if (byTempCondByte1.bit[0]) jmp TREAT_IPV6, NO_NOP;  
   xor  uqTmpReg6, uqTmpReg6.byte[0], uqTmpReg6.byte[2], 2; // uqTmpReg6.byte[0] contains xor of SPORT and DPORT (16 bits)
   Nop;

// IPV4:

Get uqTmpReg2,  IP_SIP_OFF (FMEM_BASE), 4, SWAP;
Get uqTmpReg3,  IP_DIP_OFF (FMEM_BASE), 4, SWAP;

jmp HASH_CONT , NOP_1;  
  xor uqTmpReg1, uqTmpReg2, uqTmpReg3, 4;

TREAT_IPV6:

#define  IPv6_SIP_OFF_2ND  (IPv6_SIP_OFF +  4);
#define  IPv6_DIP_OFF_2ND  (IPv6_DIP_OFF +  4);
#define  IPv6_SIP_OFF_3RD  (IPv6_SIP_OFF +  8);
#define  IPv6_DIP_OFF_3RD  (IPv6_DIP_OFF +  8);
#define  IPv6_SIP_OFF_4TH  (IPv6_SIP_OFF + 12);
#define  IPv6_DIP_OFF_4TH  (IPv6_DIP_OFF + 12);

nop;
Get uqTmpReg2,  IPv6_SIP_OFF_2ND (FMEM_BASE), 4, SWAP;
Get uqTmpReg3,  IPv6_DIP_OFF_2ND (FMEM_BASE), 4, SWAP;
   nop;
xor ALU, uqTmpReg2, uqTmpReg3, 4;
Get uqTmpReg1,  IPv6_SIP_OFF (FMEM_BASE), 4, SWAP;
Get uqTmpReg2,  IPv6_DIP_OFF (FMEM_BASE), 4, SWAP;
xor ALU, ALU, uqTmpReg1, 4;
xor ALU, ALU, uqTmpReg2, 4;
Get uqTmpReg1,  IPv6_SIP_OFF_3RD (FMEM_BASE), 4, SWAP;
Get uqTmpReg2,  IPv6_DIP_OFF_3RD (FMEM_BASE), 4, SWAP;
xor ALU, ALU, uqTmpReg1, 4;
xor ALU, ALU, uqTmpReg2, 4;
Get uqTmpReg1,  IPv6_SIP_OFF_4TH (FMEM_BASE), 4, SWAP;
Get uqTmpReg2,  IPv6_DIP_OFF_4TH (FMEM_BASE), 4, SWAP;
xor ALU, ALU, uqTmpReg1, 4;
xor uqTmpReg1, ALU, uqTmpReg2, 4;


#undef IPv6_SIP_OFF_2ND;
#undef IPv6_DIP_OFF_2ND;
#undef IPv6_SIP_OFF_3RD;
#undef IPv6_DIP_OFF_3RD;
#undef IPv6_SIP_OFF_4TH;
#undef IPv6_DIP_OFF_4TH;


HASH_CONT:

#define TIMESTAMP       uqTmpReg6;
#define ACK_NUM         uqTmpReg2;
#define ACK_NUM_1500    1501;

// now, ALU == uqTmpReg1 contains ip xor (either ipv4 or ipv6)
// uqTmpReg6 contains xor of SPORT and DPORT in first 2 bytes
nop; // this can be optimized by switching uqTmpReg1 with uqTmpReg4
Mov uqTmpReg4, uqTmpReg1, 4;
xor uqTmpReg4.byte[1], uqTmpReg1.byte[1], uqTmpReg6.byte[0], 2;
movbits uqTmpReg4.bit[31], 0, 1;
if (!UREG[1].byte[1].bit[4/* TCP_ACK_FLAG_OFF*/]) jmp END_OF_COOKIE_CHECK, NO_NOP;
   nop;
   Mov CNVI, uqTmpReg4, 4;

// In case of ACK, calculate syn cookie and compare with packet's

// For syn cookie

xor uqTmpReg6.byte[0], uqTmpReg6.byte[0], uqTmpReg6.byte[1], 1;
Mov FMEM_BASE, uqOffsetReg0.byte[L4_OFFB], 2;
xor uqTmpReg1.byte[0], uqTmpReg1.byte[0], uqTmpReg6.byte[0], 2;

xor KEY,       ALU, !ALU, 4, SC_CK_KEY_P0_MREG, MASK_BOTH;
Get ACK_NUM, TCP_ACK_OFF(FMEM_BASE), 4, SWAP;
xor TIMESTAMP, ALU, !ALU, 4, SC_CK_STMP_MREG,   MASK_BOTH;

// Compare ACK_NUM with current timestamp (5 bits)
movbits byTempCondByte1.bit[0], ACK_NUM.bit[27], 5;
xor ALU, ALU, !ALU, 4, SC_CK_KEY_P1_MREG, MASK_BOTH;
nop;
if (byTempCondByte1.bit[0]) Mov KEY, ALU, 4;	// If timestamp in packet is of phase 1, use key from SC_CK_KEY_P1_MREG 
Sub ALU, TIMESTAMP, byTempCondByte1, 4, MASK_0000001F, MASK_BOTH;
nop;
jz CONT_CHECK_COOKIE, NOP_2;


// Test if timestamp delta is greater than 1
COMPARE_PREV_TIMESTAMP:
// Compare with previous key & timestamp
// Last 'Sub' operation should have yielded '1'. Verify
Sub ALU, ALU, 1, 4;
nop;
jnz  END_OF_COOKIE_CHECK, NOP_2;

sub TIMESTAMP, TIMESTAMP, 1, 4;
nop;


// Test if ACK sequence number delta is greater than 1500
CONT_CHECK_COOKIE:

// Continue Stage 1
xor ALU, uqTmpReg1, TIMESTAMP, 4;
mov uqTmpReg1, SYN_COOKIE_CONST_KEY_VAL, 4;
nop;
xor uqTmpReg1, ALU, uqTmpReg1, 4;

// Stage 2

Get uqTmpReg4, TCP_SEQ_OFF(FMEM_BASE), 4, SWAP;
movbits uqTmpReg1.bit[24], 0, 8;
Sub  uqTmpReg4, uqTmpReg4, 1, 4; // Subtract one from sequence number (rare chance that it affects the 6th bit)
nop;
movbits uqTmpReg1.bit[16], uqTmpReg4.bit[15], 8;

// Stage 3
sub ACK_NUM, ACK_NUM, 1, 4;      // Subtract 1 from ACK NUM before comparison.
xor ALU, uqTmpReg1, KEY, 4;

// by Eli add ALU, ALU, ACK_NUM_1500, 4; // increment, since packet value may be biggest

// Compare 24 bits of ALU with ACK_NUM - substruct from packet ack field the new calculated cookie
sub ALU, ACK_NUM, ALU, 4, MASK_00FFFFFF, MASK_BOTH;
nop;
js END_OF_COOKIE_CHECK, NOP_2; 

// by Eli if (FLAGS.bit[F_SN_PRS]) Mov UREG[11].byte[2] , 0xff,1;
Mov uqTmpReg1, ACK_NUM_1500, 2;
nop;
sub ALU, ALU, uqTmpReg1, 4, MASK_0000FFFF, MASK_SRC2; // decrement, to check delta more or less than 1500
nop; 
if (FLAGS.bit[F_SN]) jmp END_OF_COOKIE_CHECK_OK, NOP_1;
   Mov bytmp2, 0xFF, 1;

// If cookie is correct, perhaps we can also invalidate the last lookup key:
// Sub COM_HBS, COM_HBS, 1, 1;
// Sub COM_KBS, COM_KBS, SIMP_OOS_LKP_SIZE, 2;

END_OF_COOKIE_CHECK:
Mov bytmp2, 0x00, 1; // Fix reusing in the uqTmpReg2 problem; clear for cookie non validated

END_OF_COOKIE_CHECK_OK:

#undef TIMESTAMP               
#undef ACK_NUM         
#undef KEY             

JStack;
nop;
nop;
/*
if (OOS_CALC_BIT) jmp CALC_HASH_DONE , NOP_2;
jmp CALC_ACK_HASH_DONE , NOP_2;
*/                                      


UNEXPECTED_FRAME_NO_VLANS_AT_ALL_LAB:
/* Frame contains no VLANs at all, i.e. even no switch VLAN in the frame - this case should never occure. */
EZstatIncrByOneIndexImm ROUTING__L_CNTR__SUBIF;

jmp GLOB_CONF_DROP_LAB_CONT, NOP_2;


PRS_SLT_VLAN_LAB:
   
   Jmp PRS_DONE_LAB, NOP_1;
      Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;


////////////////////////////////////////////////////////////
//  Label to handle frames arrived from peer NP.
//  Processing on the Frame was already done in the peer NP and all
//  there is to do is to extract frame's header which CAUI ports
//  are targeted (could be either CAUI0 or CAUI1 (or both)).
//  major work needs to be done in TOP modify where possible
//  replication is required
////////////////////////////////////////////////////////////
FRAME_FROM_2ND_NP_LAB:

// Based on the frame's metadata sent from other NP, determine which CAUI ports should be targeted.
Get UREG[1], ETH_VID_OFF(FMEM_BASE), 2, SWAP;
Mov uqTmpReg2, 0, 2; // reset bytmp and bytmp1

If (UREG[1].BIT[0])   
   Mov bytmp, (NP_CAUI_0_PORT_NUMBER | NP_CAUI_PORT_VALID), 1;

If (UREG[1].BIT[1])   
   Mov bytmp1, (NP_CAUI_1_PORT_NUMBER | NP_CAUI_PORT_VALID), 1;

Mov byFrameActionReg, FRAME_BYPASS_NETWORK, 1;
PutKey MSG_NP5_INTERFACE_PORT_NUM_OFF(HW_KBS) , HWD_REG1.byte[1] , 1  ; //##TODO_OPTIMIZE: check all nops after JMULs and verify if this can be done in case of jump immediately after the JMUL.

Jmp PRS_DONE_LAB, NO_NOP;
   // Set control message bit to indicate that the packet is from peer NP device.
   MovBits byCtrlMsgPrs2.BIT[MSG_CTRL_TOPPRS_2_INTERLINK_PACKET_BIT], 1, 1;
   
   // write both bytmp and bytmp1 to message
   PutKey   MSG_CAUI_PORT_0_INFO_OFF(HW_KBS), uqTmpReg2, 2; 




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
   if (!uqGcCtrlReg0.BIT[GC_CNTRL_0_IMMCHK_SAMPLENABLED_BIT]) jmp CHECK_TP_CONDITIONS_LAB, NO_NOP;
      MovBits ENC_PRI.BIT[14],ENC_PRI.BIT[15],1; // Jmul in HANDLE_DROPPED_PACKETS_LAB expects ENC_PRI[15..13]=[TRACE_ENABLE, NET_BYPASS_LAB, PA_DISCARD_LAB]
      Mov ALU,{ 1 << IC_CNTRL_0_JUMBOMODE_OFF },4;//Bypass enable: sampling of jumbo frame is allowed if IC_CNTRL_0_JUMBOMODE_OFF
   
   //if not Jumbo(logical operation was done in previous Jmul !!), continue to sampling token bucket 
   JZ CHECK_SAM_TB, NO_NOP;
      // Check whether configuration allows to send Jumbo to CPU: 
      //             1 - No support for jumbo frames (i.e. jumbo frames are not sampled to CPU), 
      //             0 - Jumbo frames sample to CPU is allowed
      And ALU, ALU,ALU,4, IC_CNTRL_0_MREG,MASK_BOTH;
      PutKey  MSG_L3_USR_OFF(HW_KBS), uqOffsetReg0.byte[L3_OFFB], 4; // initialize in the message both MSG_L3_USR_OFF and MSG_L4_USR_OFF from uqOffsetReg0.byte[L3_OFFB] and uqOffsetReg0.byte[L4_OFFB]
   
   //this is a Jumbo packet
   JNZ CHECK_TP_CONDITIONS_LAB, NOP_2;//no sampling of jumbo

CHECK_SAM_TB:
   EZstatPutDataSendCmdIndexReg uqTmpCtxReg1, IMM_SAMP_SIZE_CONST, STS_GET_COLOR_CMD;
      nop;
      nop;

   EZwaitFlag F_SR;

   // Check CPU sampling Token Bucket state (color is also returned to UDB.bits[16,17])
   And ALU,STAT_RESULT_L, 1<<RED_FLAG_OFF, 1;// ALU.bit[1] = 0 if sample, 1 otherwise
   Nop;

   jnz CHECK_TP_CONDITIONS_LAB, NOP_2; // No sampling in case of RED color (i.e. drop\bypass), or in case of cont

   //we get here if RED==0 (sample) and action is drop or bypass
   // Sample packet to CPU (50 packets per second)

   EZstatIncrByOneIndexImm IS_SAMP_CPU;   
      // instead of NOP : if packet is sampled (not red), set bit in msg, used later if reaching default policy.
      Or byCtrlMsgPrs2,byCtrlMsgPrs2,{1<<MSG_CTRL_TOPPRS_2_PA_SAMPL_BIT},1;        
      nop; //##TODO_OPTIMIZE - check if this nop is needed.
   
   jmp HOST_P0_BYPASS_LAB, NOP_2;

//Check Packet trace 
CHECK_TP_CONDITIONS_LAB:
   // Check if Trace is activated
   xor uqCondReg, ALU, !ALU, 4, IC_CNTRL_1_MREG, MASK_BOTH;
   MovBits uqCondReg.bit[0], ENC_PRI.bit[13], 3;
   If(uqCondReg.bit[IC_CNTRL_1_TP_EN_OFF]) Mov byFrameActionReg, FRAME_TP_BYPASS_2NETW, 1;
   If(uqCondReg.bit[0]) Movbits byGlobConfReg.bit[MSG_PA_TP_ACTION], 0, 1;// DROP with trace (will be used only if trace is enabled)
   If(uqCondReg.bit[2]) Movbits byGlobConfReg.bit[MSG_PA_TP_ACTION], 1, 1;// BYPASS with trace (will be used only if trace is enabled)
   MovBits ENC_PRI.bit[15], uqCondReg.bit[IC_CNTRL_1_TP_EN_OFF],1; // in case of trace, cont. in order to perform the trace, even if the action is DROP
   PutKey MSG_GLOB_CONFIG_OFF(HW_KBS), byGlobConfReg, 1;// if bit 6 is 0: DROP with trace. if bit 6 is 1: BYPASS with trace. 

// Count dropped or bypassed packets and continue with drop handling
EZstatIncrByOneIndexReg uqTmpReg4;

Jmul PRS_DONE_LAB,   // in case of trace, cont. in order to perform the trace, even if the action is DROP
     CONF_NETWORK_BYPASS_LAB,       //BYPASS
     GLOB_CONF_DROP_LAB,NO_NOP; //DROP
     Nop;
     Nop;

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

SEND_TO_CPU_LAB:

EZstatIncrByOneIndexReg uqTmpReg4;

// Decode IC_CNTRL type (offset bit [0..31], saved previously) to bitmap in ALU (4 bytes)
decode ALU, icCtrlType,  4,   MASK_0000001F, MASK_SRC1;
And    ALU, actRegMask0, ALU, 4; // AND mask of allowed types with ALU bitmap

Mov byFrameActionReg, FRAME_BYPASS_HOST, 1;

// GuyE: Need to be set from the driver!!!!!
if (!FLAGS.bit[F_ZR]) movbits uqGcCtrlReg0.bit[GC_CNTRL_0_SYN_ENABLE_BIT], 0, 1;

// Case 1: Frames that passed the mask (in tunnels case - also MUST have tunnel indication bit OFF) - need to lookup policy before sending to CPU
// Applies to tunneled frames: IC_CNTRL_1_GRE_VERSION_OFF, IC_CNTRL_1_GRE_ROUTING_HDR_NUM_OFF, IC_CNTRL_1_GRE_INV_HDR_LEN_OFF, IC_CNTRL_1_INC_VER_GTP_OFF, IC_CNTRL_1_INC_HLEN_GTP_OFF
// Applies to specific frames: IC_CNTRL_0_INC_TTL_OFF, IC_CNTRL_0_FRAG_OFF, IC_CNTRL_0_IPv6_HLIM_OFF, IC_CNTRL_0_IPv6_FRAG_OFF, IC_CNTRL_1_UNK_L4_OFF, IC_CNTRL_1_TCP_HLEN_OFF, IC_CNTRL_1_TCP_FLAG_OFF, IC_CNTRL_1_UDP_ZCHKSUM_OFF, IC_CNTRL_1_UDP_INC_HLEN_OFF, IC_CNTRL_1_SCTP_HLEN_OFF
//if (!FLAGS.bit[F_ZR]) jmp ALIST_START, HOST_P0_BYPASS_LAB ,NOP_2;    // POLICY_HANDLING_LAB
JNZ ALIST_START, HOST_P0_BYPASS_LAB ,NOP_2;    // POLICY_HANDLING_LAB

//disable policy search 
    MovBits uqGcCtrlReg0.bit[GC_CNTRL_0_POLICY_NON_EMPTY_BIT] , 0 , 1;
    Nop;
 

XPY_XPY_LAB:
    //set type ARP 
Mov ALU , ARP_TYPE_BYPASS_STAT , 1; 
    //PutKey MSG_L3_TUN_OFF(HW_KBS), ARP_TYPE_BYPASS_STAT, 2;
SEND_CONX_EXT: 

//arp lacp, send it to CPU via special link
If ( uqCondReg.bit[ 26 ] ) Mov ALU , LACP_TYPE_BYPASS_STAT , 1;                                             
PutKey   0(HW_KBS), MSG_HDR, 1;   // Put message header     // ##TODO_OPTIMIZE - when will have time for this - as this uses temp register from within a mcaro, add vardef for this register in all the locations that uses it.
PutKey MSG_L3_TUN_OFF(HW_KBS), ALU , 2;
PutKey MSG_HASH_CORE_OFF( HW_KBS ), 0, 1;
PutKey MSG_HASH_2B_CORE_OFF( HW_KBS ), 0, 2;
PutKey   MSG_ACTION_ENC_OFF(HW_KBS), FRAME_CONF_EXTRACT, 1;

PutKey   MSG_SPEC_SUB_ACTION(HW_KBS), SPEC_ROUTE_CTL , 1;


PutKey MSG_RST_LEARN_KEY( HW_KBS ), 4 , 1;

MovBits  byTempCondByte1.bit[3], bySrcPortReg, 5; //max phys port range 0-0x1f

PutKey   MSG_CTRL_TOPPRS_2_OFF(HW_KBS), byCtrlMsgPrs2,   1; // Writing 3rd control bits
PutKey   MSG_SRC_PRT_OFF (HW_KBS),      byTempCondByte1, 1;   
PutKey   MSG_CTRL_TOPPRS_0_OFF(HW_KBS), byCtrlMsgPrs0,   2; // Writing 2 ctrl bytes (both byCtrlMsgPrs0 and byCtrlMsgPrs1) in 1 operation to both MSG_CTRL_TOPPRS_0_OFF and MSG_CTRL_TOPPRS_1_OFF
PutHdr HREG[ 0 ], PRS_MSG_HDR;                 // Write the message header 
Halt UNIC,HW_MSG_HDR;