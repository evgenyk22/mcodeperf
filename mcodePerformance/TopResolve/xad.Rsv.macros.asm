/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Rsv.Macros.asm
*
*  Usage:         TOPresolve macros file
*
*******************************************************************************/


MACRO PrepareRsvMsg;

   // Calculate the host port used to send the frame

   //xor uqTmpReg6 , uqTmpReg6,uqTmpReg6,4;

   if (!byGlobalStatusBitsReg.bit[ALIST_SAMPL_BIT]) jmp SKIP_ALIST_SAMPL_MARK_LAB, NO_NOP;
      GetRes ALU.byte[0], ALST_RES_ENTRY_ID_OFF(ALST_RES_STR), 2;
      Mov bytmp1, 0, 2; // Clears bytmp1 and bytmp2

   //prepare whole value for TopModify 
   Mov ALU.byte[2], METADATA_RDWR_STAMP_LOW16, 2;

   PutKey MSG_ALIST_SAMPL_INFO_TOP_MODIFY(HW_OBS), METADATA_RDWR_STAMP_HIGH16, 2;
   PutKey MSG_ALIST_STAMP_INFO_TOP_MODIFY(HW_OBS), ALU.byte[0], 4;

SKIP_ALIST_SAMPL_MARK_LAB:

   //xor uqTmpReg7, ALU, !ALU, 4, TRAFFIC_ENGINE_NUMBER, MASK_BOTH; // using MREG[12] 
   //GetRes  uqTmpReg6, MSG_HASH_CORE_OFF(MSG_STR), 1; // Note: frames that are not IP (i.e. L2 control frames e.g. ARP, etc) will probably always have 0 hash function result. this does not give distribution.
   // 8 bit hash mapped there
   //Mov  uqTmpReg6, UREG[6].byte[3] , 1; 
   Putkey MSG_HASH_CORE_OFF(HW_OBS), UREG[6].byte[3] ,  1;
   PutKey  MSG_ACTION_ENC_OFF(HW_OBS), byFrameActionReg, 1;      
   //Modulo  ALU, bytmp0, uqTmpReg6.byte[0] , 1;
   //LongDiv uqTmpReg6 , uqTmpReg6 , uqTmpReg7 , 2;     
   //MovBits ENC_PRI.bit[13], byFrameActionReg.bit[0], 3;
   //traffic engine number should start from 1


/************************************** New for NP5 *************************************/
/************** MAC selection based  on input port number *************************/

   //MovBits ENC_PRI.bit[9] , byFrameActionReg.bit[0] , 7; 
   //GetRes uqTmpReg1.byte[3] , MSG_NP5_INTERFACE_PORT_NUM_OFF(MSG_STR) , 1;

/*
#define FRAME_BYPASS_NETWORK           (1 << FRAME_BYPASS_NETWORK_BIT)
#define FRAME_BYPASS_HOST              (1 << FRAME_BYPASS_HOST_BIT)
#define FRAME_CONT_ACTION              (1 << FRAME_CONT_ACTION_BIT)
#define FRAME_DROP                     (1 << FRAME_DROP_BIT)
#define FRAME_CONF_EXTRACT             (1 << FRAME_CONF_EXTRACT_BIT)
#define FRAME_SYN_COOKIE_GEN           (1 << FRAME_SYN_COOKIE_GEN_BIT)
#define FRAME_HOST_BYPASS_2NETW        (1 << FRAME_HOST_BYPASS_2NETW_BIT)
#define FRAME_TP_BYPASS_2NETW          (1 << FRAME_HOST_BYPASS_2NETW_TP_BIT)
*/
   //MovMul  1 , 0 , 0 , 0 ,255 ,255 ,0; /*-1 , -1 , 1;*/
   //wait longdiv to compleate
   //EZwaitFlag F_ITR;
   //Xor uqTmpReg1.byte[0] ,uqTmpReg1.byte[0]  , uqTmpReg1.byte[0] , 2;
   //Add ALU.byte[0] ,uqTmpReg1.byte[3] , ENC_PRO , 1 ;
   copy    56(HW_OBS),  56(MSG_STR), 8;
   //MovBits uqTmpReg1.byte[0].bit[6] , ALU.byte[0].bit[0] , 8;      
   //PutKey  MSG_NP5_PPORT_NUM_OFF(HW_OBS),ALU.byte[0] , 1;
   //PutKey  MSG_NP5_INTERFACE_PORT_NUM_OFF(HW_OBS), uqTmpReg1.byte[0], 2;  

UPDATE_MSG_CTRL_TOPRSV_0_1_LAB:

vardef regtype uqRSV_INDIRECT_CTX_LOAD    INDIRECT_CTX_LOAD.byte[0:1];  // INDIRECT_CTX_LOAD register (UREG[12]): bits 8:15 (ignore_rdy_bits) part of this register should always be zero in order to assure that TOPmodify will start ONLY when the relevant context lines marked in bits 7:0 (load_context_bitmap) part of the register are valid.

   //PutKey MSG_CTRL_TOPPRS_3_OFF(HW_OBS), uqTmpReg9.byte[0], 1;   // Writing 2 ctrl bytes (byCtrlMsgRsv0 and byCtrlMsgRsv1) in 1 operation 
   //Wait for the end of LongDiv Instruction -- bit 22   F_CTX_LA_RDY_1 the same as F_ITR
   //EZwaitFlag F_CTX_LA_RDY_1;
   //PutKey  MSG_CORE_NUM_OFF(HW_OBS),  uqTmpReg6, 1;

//add route table search in case of send packet to CPU
// I need it for correct packet marking
    Mov2Bits byTempCondByte1.bits[0, 0], byFrameActionReg.bits[FRAME_BYPASS_HOST_BIT, FRAME_CONT_ACTION_BIT];
    if (!bitRSV_isRoutingMode) jmp SKIP_MYIP_DETECTION;
        Nop;
        GetRes uqTmpReg6 , 0(INT_TCAM_STR), 3 ;

    If (!byTempCondByte1.bit[0]) Jmp SKIP_CORE_DISTRIBUTION;
        Sub ALU, uqTmpReg6.byte[0], 0x51, 1; // check match from the TCAM lookup, with support future enhancement for concurrent parallel lookups.
        Nop; 
   
    
    if (!FLAGS.bit[F_ZR]) Mov uqTmpReg6.byte[1] , 0xFFFF , 2;  

    
    PutHdr HREG[ COM_HBS ], RSV_ROUTE_2HOST_LKP_HDR;

    and ALU, uqTmpReg6.byte[1], uqTmpReg6.byte[1] , 2, MASK_000007FF, MASK_BOTH;    
    Nop;
    PutKey KMEM_OFFSET ( HW_OBS ),  ALU, 2;
    Add COM_HBS  , COM_HBS ,  1 , 1;
    MovBits byTemp3Byte0.bit[/*(CTX_LINE_OUT_IF*/CTX_LINE_ROUTING_TABLE_RSLT]  , 1 , 1;    
    Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;


SKIP_MYIP_DETECTION:

    //Jmp SKIP_CORE_DISTRIBUTION, NOP_2;
   
    //PutHdr HREG[ COM_HBS ], ((LKP_VALID  | ( CORE_DISTR_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT))) ;
    //MovBits byTemp3Byte0.bit[CTX_LINE_CORE2IP_DISTRIBUTION], 1, 1;
    //Add COM_HBS  , COM_HBS ,  1 , 1;

    //xor ALU, ALU, !ALU, 4, TRAFFIC_ENGINE_NUMBER, MASK_BOTH; // using MREG[12] 
    //GetRes uqTmpReg6.byte[0] , MSG_HASH_CORE_OFF(MSG_STR), 1;
    //Copy { KMEM_RSV2SRH2_FFT_KEY_OFF+RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN + 2} ( HW_OBS ),  MSG_HASH_CORE_OFF(MSG_STR), 1;
    //Mov uqTmpReg6.byte[2] , ALU , 1; 
    //Nop;
    //PutKey KMEM_OFFSET( HW_OBS ),  uqTmpReg6 , 4;
    //Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

SKIP_CORE_DISTRIBUTION:

   Mov ALU , /*MSG_CTRL_TOPRSV_2_OFF(MSG_STR)*/byCtrlMsgRsv2 , 1;

   movbits $uqRSV_INDIRECT_CTX_LOAD , byTemp3Byte0 , 4;   

   //restore bit 2,3 from top parse information 
   MovBits byCtrlMsgPrs2Rsv2.bit[2] , ALU.bit[2] , 2;   
   //change beheviour of this bit to indicate RTPC/Marking status
   MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPPRS_0_ANALYZE_POLICY_BIT], RTPC_IS_ENABLED_BIT, 1;
    
   PutKey MSG_CTRL_TOPRSV_0_OFF(HW_OBS) , UREG[2] , 3;
   PutKey   MSG_CTRL_TOPPRS_3_OFF(HW_KBS), UREG[2].byte[3],   1;
   PutKey MSG_CTRL_TOPRSV_0_OFF(HW_OBS), byCtrlMsgRsv0, 2;  // Writing 2 ctrl bytes (byCtrlMsgRsv0 and byCtrlMsgRsv1) in 1 operation  
   PutKey MSG_CTRL_TOPRSV_2_OFF(HW_OBS), byCtrlMsgPrs2Rsv2, 1;// Writing last ctrl byte
   
varundef uqRSV_INDIRECT_CTX_LOAD;

ENDMACRO; //PrepareRsvMsg



// Description: only for debug purposes increment policy debug counters for debug only
// used       : uqTmpReg4 and uqTmpReg1 registers
MACRO PolicyCounterUpdate MatchPolicy, POL_COUNTER_BASE;
//validate if not zero
or ALU, MatchPolicy, MatchPolicy, 4;
nop;
jz POL_COUNT_END | NOP_2;
POL_COUNT_CONT:
encode uqTmpReg4, MatchPolicy, 4, MASK_00000003, _ALU_NONE;
nop;
nop;
add uqTmpReg1, uqTmpReg4, POL_COUNTER_BASE, 4;
EZstatIncrIndexReg uqTmpReg1 , 1;
decode uqTmpReg1, uqTmpReg4, 4, MASK_00000003, _ALU_NONE;
nop;
and MatchPolicy, MatchPolicy, !uqTmpReg1, 4, MASK_00000003, _ALU_NONE; 
nop;
jnz POL_COUNT_CONT | NOP_2;
//nop;
POL_COUNT_END:
ENDMACRO; // PolicyCounterUpdate


MACRO TestPolicyExpression Offset, P_SIP_STR, P_DIP_STR, P_VLAN_STR, P_PORT_STR, P_DEFAULT_STR, SKIP_LAB;

#define next_Offset (Offset + 4);

Mov ALU, 0xFFFFFFFF, 4;
if ( byPolicyValidBitsReg.bit[SIP_SEARCH_VALID_BIT]) getRes ALU,     Offset( P_SIP_STR ) , 4;
if ( byPolicyValidBitsReg.bit[VLAN1_SEARCH_VALID_BIT]) getRes uqTmpReg2, Offset( P_VLAN_STR ) , 4;
if (!byPolicyValidBitsReg.bit[VLAN1_SEARCH_VALID_BIT]) getRes uqTmpReg2, Offset( P_DEFAULT_STR ) , 4;
getRes uqTmpReg4, Offset( P_PORT_STR ) , 4;
getRes uqTmpReg1, Offset( P_DIP_STR ) , 4;
and ALU, ALU, uqTmpReg2, 4;
if ( byPolicyValidBitsReg.bit[PORT_SEARCH_VALID_BIT]) and ALU, ALU, uqTmpReg4, 4;
if ( byPolicyValidBitsReg.bit[DIP_SEARCH_VALID_BIT]) and uqTmpReg3, ALU, uqTmpReg1, 4;
nop; // This is a false warning. this nop can be removed.
if (!byPolicyValidBitsReg.bit[DIP_SEARCH_VALID_BIT]) Mov uqTmpReg3, ALU, 4;


Mov ALU, 0xFFFFFFFF, 4;
if (byPolicyValidBitsReg.bit[SIP_SEARCH_VALID_BIT]) getRes ALU,     next_Offset( P_SIP_STR ) , 4;
getRes uqTmpReg1, next_Offset( P_DIP_STR ) , 4;
if ( byPolicyValidBitsReg.bit[VLAN1_SEARCH_VALID_BIT]) getRes uqTmpReg2, next_Offset( P_VLAN_STR ) , 4;
if (!byPolicyValidBitsReg.bit[VLAN1_SEARCH_VALID_BIT]) getRes uqTmpReg2, next_Offset( P_DEFAULT_STR ) , 4;
if ( byPolicyValidBitsReg.bit[DIP_SEARCH_VALID_BIT]) and ALU, ALU, uqTmpReg1, 4;
getRes uqTmpReg4, next_Offset( P_PORT_STR ) , 4;
and ALU, ALU, uqTmpReg2, 4;
if ( byPolicyValidBitsReg.bit[PORT_SEARCH_VALID_BIT]) and ALU, ALU, uqTmpReg4, 4;
#ifdef	DEBUG_STAT_MODE;
//must be for debug only
nop;
Mov uqTmpReg2, ALU, 4;
#endif;
or  ALU, ALU, uqTmpReg3, 4;

nop;
jz SKIP_LAB | NOP_2;

#ifdef	DEBUG_STAT_MODE;
// Temporary code to validate policy Id match, 4 bytes, no mask for debug only
PolicyCounterUpdate uqTmpReg2, GS_POL_32_BASE;
PolicyCounterUpdate uqTmpReg3, GS_POL_00_BASE;
#endif;

#undef next_Offset;
ENDMACRO; // TestPolicyExpression


// Macro AnalyzeBdosResult: 
// Test if BDOS result match the signature.
// Note that this macro is duplicated 8 times in the code space

   //uqTmpReg6 - first signature configuration ( 32 bit )
   //uqTmpReg7 - poicy base
   //uqTmpReg8 - policy global sig and more ..... 

MACRO AnalyzeBdosResult SigNum, foreignNegativeSignaturesBitmask;

#define BDOS_RESULT_REG       uqTmpReg4;
#define BDOS_SIGNA_WORD_SEL   uqTmpReg9;
#define BDOS_SIGNA_CONF       uqTmpReg10;

Decode ALU,SigNum,4;
//If ( byTempCondByte3.bit[0] ) jmp BDOS_RESULT_CALCULATED;
    MovBits  byTempCondByte3.bit[0] , 1 , 1;//moti: to check - seemd not needed
And ALU,ALU,foreignNegativeSignaturesBitmask,4;
// Prepare indirect registers for access to special signature result
    Mov 	IND_REG0, &uqTmpReg1, 2;      // Prepare indirect register pointer for uqTmpReg1
JNZ NEG_SIGNA_IMMEDIATE_ACTION;//foreiegn snegative signature, it's a match.
   MovBits IND_REG0.bit[0], SigNum, 5;   // Prepare byte and bits indexes
   Mov 	IND_REG1, &uqTmpReg2, 2;      // Prepare indirect register pointer for uqTmpReg2
MovBits IND_REG1.bit[0], SigNum, 5;   // Prepare byte and bits indexes

Mov BDOS_RESULT_REG, 0, 4;

// My tests - Consolidate results of signature
getRes  uqTmpReg1, SIP_RES_OFF         (BDOS_ATTACK_RESULTS_L23_STR), 4;
getRes  uqTmpReg2, DIP_RES_OFF         (BDOS_ATTACK_RESULTS_L23_STR), 4;
MovBits BDOS_RESULT_REG.bit[SIP_SEL_OFF], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[DIP_SEL_OFF], UREG[IND_REG1], 1;

getRes  uqTmpReg1, TOS_RES_OFF         (BDOS_ATTACK_RESULTS_L23_STR), 4;
getRes  uqTmpReg2, IPID_RES_OFF        (BDOS_ATTACK_RESULTS_L23_STR), 4;
MovBits BDOS_RESULT_REG.bit[TOS_SEL_OFF ], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[IPID_SEL_OFF], UREG[IND_REG1], 1;

getRes  uqTmpReg1, TTL_RES_OFF         (BDOS_ATTACK_RESULTS_L23_STR), 4;
getRes  uqTmpReg2, FRGFLG_RES_OFF      (BDOS_ATTACK_RESULTS_L23_STR), 4;
MovBits BDOS_RESULT_REG.bit[TTL_SEL_OFF   ], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[FRGFLG_SEL_OFF], UREG[IND_REG1], 1;

getRes  uqTmpReg1, FRGOFF_RES_OFF      (BDOS_ATTACK_RESULTS_L23_2_STR), 4;
getRes  uqTmpReg2, L4_PROT_RES_OFF     (BDOS_ATTACK_RESULTS_L23_2_STR), 4;
MovBits BDOS_RESULT_REG.bit[FRGOFF_SEL_OFF ], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[L4_PROT_SEL_OFF], UREG[IND_REG1], 1;

getRes  uqTmpReg1, IPV4_L3_LENGTH_RES_OFF (BDOS_ATTACK_RESULTS_L23_2_STR), 4;
getRes  uqTmpReg2, L2_VLAN_RES_OFF        (BDOS_ATTACK_RESULTS_L4_STR   ), 4;
MovBits BDOS_RESULT_REG.bit[IPV4_L3_LENGTH_SEL_OFF], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[L2_VLAN_SEL_OFF       ], UREG[IND_REG1], 1;

getRes  uqTmpReg1, TCP_SPORT_RES_OFF   (BDOS_ATTACK_RESULTS_L4_STR), 4;
getRes  uqTmpReg2, TCP_DPORT_RES_OFF   (BDOS_ATTACK_RESULTS_L4_STR), 4;
MovBits BDOS_RESULT_REG.bit[TCP_SPORT_SEL_OFF], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[TCP_DPORT_SEL_OFF], UREG[IND_REG1], 1;

getRes  uqTmpReg1, TCP_SEQNUM_RES_OFF  (BDOS_ATTACK_RESULTS_L4_STR), 4;
getRes  uqTmpReg2, TCP_FLAGS_RES_OFF   (BDOS_ATTACK_RESULTS_L4_STR), 4;
MovBits BDOS_RESULT_REG.bit[TCP_SEQNUM_SEL_OFF], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[TCP_FLAGS_SEL_OFF ], UREG[IND_REG1], 1;



getRes  uqTmpReg1, TCP_CHKSUM_RES_OFF  (BDOS_ATTACK_RESULTS_L4_STR), 4;
getRes  uqTmpReg2, PACKET_SIZE_RES_OFF (BDOS_ATTACK_RESULTS_L4_STR), 4;
MovBits BDOS_RESULT_REG.bit[TCP_CHKSUM_SEL_OFF ], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[PACKET_SIZE_SEL_OFF], UREG[IND_REG1], 1;

#ifdef DNS_ENABLE

getRes  uqTmpReg1, L7_DNS_REC_TYPE_RES_OFF  (BDOS_ATTACK_RESULTS_L4_2_STR), 4;
getRes  uqTmpReg2, L7_DNS_RESP_CODE_RES_OFF (BDOS_ATTACK_RESULTS_L4_2_STR), 4;
MovBits BDOS_RESULT_REG.bit[L7_DNS_REC_TYPE_SEL_OFF ], UREG[IND_REG0], 1;
//Mov2Bits BDOS_RESULT_REG.bits[L7_DNS_REC_TYPE_SEL_OFF,L7_DNS_OTHER_REC_TYPE_SEL_OFF],BDOS_RESULT_REG.bits[L7_DNS_REC_TYPE_SEL_OFF, ~L7_DNS_REC_TYPE_SEL_OFF];
MovBits BDOS_RESULT_REG.bit[L7_DNS_RESP_CODE_SEL_OFF], UREG[IND_REG1], 1;
Mov2Bits BDOS_RESULT_REG.bits[L7_DNS_REC_TYPE_SEL_OFF,L7_DNS_OTHER_REC_TYPE_SEL_OFF],BDOS_RESULT_REG.bits[L7_DNS_REC_TYPE_SEL_OFF, ~L7_DNS_REC_TYPE_SEL_OFF];

getRes  uqTmpReg1, L7_DNS_TRANSACTION_ID_RES_OFF  (BDOS_ATTACK_RESULTS_L4_2_STR), 4;
getRes  uqTmpReg2, L7_DNS_QUERIES_COUNT_RES_OFF (BDOS_ATTACK_RESULTS_L4_2_STR), 4;
MovBits BDOS_RESULT_REG.bit[L7_DNS_TRANSACTION_ID_SEL_OFF ], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[L7_DNS_QUERIES_COUNT_SEL_OFF], UREG[IND_REG1], 1;

getRes  uqTmpReg1, L7_DNS_ANSWERS_COUNT_RES_OFF  (BDOS_ATTACK_RESULTS_L4_2_STR), 4;
getRes  uqTmpReg2, L7_DNS_FLAGS_RES_OFF (BDOS_ATTACK_RESULTS_L4_2_STR), 4;
MovBits BDOS_RESULT_REG.bit[L7_DNS_ANSWERS_COUNT_SEL_OFF ], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[L7_DNS_FLAGS_SEL_OFF], UREG[IND_REG1], 1;

getRes  uqTmpReg1, L7_DNS_MANUAL_QN_RES_OFF  (BDOS_ATTACK_RESULTS_QN_STR), 4;
getRes  uqTmpReg2,  L7_DNS_BEHAVIOR_QN_RES_OFF(BDOS_ATTACK_RESULTS_QN_STR), 4;
MovBits BDOS_RESULT_REG.bit[L7_DNS_MANUAL_QN_SEL_OFF ], UREG[IND_REG0], 1;
MovBits BDOS_RESULT_REG.bit[L7_DNS_BEHAVIOR_QN_SEL_OFF ], UREG[IND_REG1], 1;

//getRes  uqTmpReg1,  L7_DNS_BEHAVIOR_QN_RES_OFF(BDOS_ATTACK_RESULTS_QN_STR), 4;
//Nop;


getRes  uqTmpReg1,  L7_DNS_BEHAVIOR_DOMAIN_RES_OFF(BDOS_ATTACK_RESULTS_QN_STR), 4;
getRes  uqTmpReg2,  L7_DNS_BEHAVIOR_WL_RES_OFF(BDOS_ATTACK_RESULTS_QN_STR), 4;
MovBits BDOS_RESULT_REG.bit[L7_DNS_BEHAVIOR_DOMAIN_SEL_OFF ], UREG[IND_REG0], 1;

#endif
//never update WL to BDOS result ,  it need to be special treatment
//MovBits BDOS_RESULT_REG.bit[L7_DNS_BEHAVIOR_WL_SEL_OFF  ], UREG[IND_REG1], 1;



BDOS_RESULT_CALCULATED:

mov PC_STACK, END_OF_MACRO, 2; // in case action is to continue
//Sub ALU , BDOS_RESULT_REG.byte[3] , 1 , 1 , MASK_00000003 , MASK_SRC1; 
//check Qname WL result 
  


//special treatment for couple L7_DNS_BEHAVIOR_WL_SEL_OFF , L7_DNS_BEHAVIOR_DOMAIN_SEL_OFF bits ( see dns white list alg ) 
/*
  00 - continue
  01 - go to action 
  10 - don't care , still continue
  11 -continue 
*/

//-------------------------------------------
if (!FLAGS.bit[F_SR]) jmp $ ;
  //And ALU , BDOS_RESULT_REG.byte[3] , 0x40 , 1;
  //MovBits BDOS_RESULT_REG.bit[L7_DNS_BEHAVIOR_DOMAIN_SEL_OFF] , 0 , 2;
  Mov CNT , 0 , 1;
  MovBits byTempCondByte.bit[0], UREG[IND_REG1], 1; 
  
//if white list match exist let's add also Beheviour Q Domain field requerement to control 
//If (!FLAGS.BIT[ F_ZR ])   MovBits STAT_RESULT_H.bit[L7_DNS_BEHAVIOR_DOMAIN_SEL_OFF] , 1 , 2;

//check if nothing matched
Sub ALU  , BDOS_RESULT_REG, 0 , 4;

//check if signa is negative
AND ALU,STAT_RESULT_L.byte[3], (1<<BDOS_SIGNA_CONFIG_BYTE3_NEGATIVE_BIT),1;
//signature config + group 0 bitmask were previously read in "preliminary read policy bdos first signature "
//save signature configuration 
Mov BDOS_SIGNA_CONF , STAT_RESULT_L, 4; 

JNZ NEGETIVE_SIG;
    Sub ALU  , BDOS_RESULT_REG, 0 , 4;
    //read number of groups in signature 
    MovBits CNT , STAT_RESULT_L.bit[BDOS_SIGNA_CONFIG_NUM_GROUPS] , 2 ;


//signa is positive
jz END_OF_MACRO; // If all signature result bits are '0', no need to test expressions.
   //get rid white list from configuration and check rest bits to zero , note that wl never expected to set alone 
   Mov ALU , {~(1<<L7_DNS_BEHAVIOR_WL_SEL_OFF)} , 4;
   And   STAT_RESULT_H , STAT_RESULT_H ,ALU , 4; 

//if whitelist match reset also twisted bit behaviour domain to enforce signature no match 
If (byTempCondByte.bit[0]) MovBits BDOS_RESULT_REG.bit[L7_DNS_BEHAVIOR_DOMAIN_SEL_OFF] , 0 , 1;
Nop;
//nothing to check
//JZ END_OF_MACRO;
//check group 0
    and ALU, STAT_RESULT_H , BDOS_RESULT_REG, 4;
    xor ALU, ALU, STAT_RESULT_H , 4;

//mov byTempCondByte, STAT_RESULT_H.byte[3], 1;
//MovBits byTempCondByte.bit[0] , BDOS_RESULT_REG.bit[L7_DNS_BEHAVIOR_WL_SEL_OFF],1;
//MovBits byTempCondByte.bit[1] , STAT_RESULT_H.[L7_DNS_BEHAVIOR_WL_SEL_OFF],1;
Nop;

jz SIGNA_ACTION, NO_NOP;   // In case expression matches
    Add BDOS_SIGNA_WORD_SEL, BDOS_SIGNA_WORD_SEL, 1, 4;
    Sub CNT , CNT , 1 , 1;
       
Nop;
js END_OF_MACRO , NOP_2;
//Read groups 1,2
EZstatSendCmdIndexReg BDOS_SIGNA_WORD_SEL, STS_READ_CMD;
Mov ALU , {~(1<<L7_DNS_BEHAVIOR_WL_SEL_OFF)} , 4;
Nop;

if (!FLAGS.bit[F_SR]) jmp $;
    Nop;    
    Nop;

    And  STAT_RESULT_L , STAT_RESULT_L , ALU , 4;
    Nop;
//check group 1
   and ALU, STAT_RESULT_L, BDOS_RESULT_REG, 4;
   xor ALU, ALU, STAT_RESULT_L, 4;

//mov byTempCondByte, STAT_RESULT_L.byte[3], 1 ;
MovBits  STAT_RESULT_H.bit[L7_DNS_BEHAVIOR_WL_SEL_OFF] , 0 , 1;

jz SIGNA_ACTION;   // In case expression matches
   Sub CNT , CNT , 1 , 1;
   Nop;


js END_OF_MACRO;
//check group 2
    and ALU, STAT_RESULT_H, BDOS_RESULT_REG, 4;
    xor ALU, ALU, STAT_RESULT_H, 4;


Nop;

jz SIGNA_ACTION;   // In case expression matches
   Add BDOS_SIGNA_WORD_SEL, BDOS_SIGNA_WORD_SEL, 1, 4;
   // Check if more groups:
   Sub CNT , CNT , 1 , 1;

Nop;
js END_OF_MACRO , NOP_2;

//Read group 3
EZstatSendCmdIndexReg BDOS_SIGNA_WORD_SEL, STS_READ_CMD;
nop;
nop;

if (!FLAGS.bit[F_SR]) jmp $;
    Nop;
    Nop;

MovBits  STAT_RESULT_L.bit[L7_DNS_BEHAVIOR_WL_SEL_OFF] , 0 , 1;    
Nop;
//check group 3
and ALU, STAT_RESULT_L,  BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_L, 4;

MovBits  STAT_RESULT_H.bit[L7_DNS_BEHAVIOR_WL_SEL_OFF] , 0 , 1;

jz SIGNA_ACTION;   // In case expression matches
    Sub CNT , CNT , 1 , 1;
    Nop;

//if (!byTempCondByte.bit[BDOS_SIGNA_CONFIG_MORE_GROUPS_EXIST]) jmp END_OF_MACRO, NOP_2; // Check if more groups:   
js END_OF_MACRO;
    and ALU, STAT_RESULT_H,  BDOS_RESULT_REG, 4;
    xor ALU, ALU, STAT_RESULT_H, 4;

Nop;

jnz END_OF_MACRO, NOP_2;   // In case expression matches

//negetive signature: only traffic filter - no BDOS actions
NEGETIVE_SIG:
jz SIGNA_ACTION; // If all signature result bits are '0', negetive signa "match", jmp to action      
   Add BDOS_SIGNA_WORD_SEL, BDOS_SIGNA_WORD_SEL, 1, 4;//prepare BDOS_SIGNA_WORD_SEL for SIGNA_ACTION
   and ALU, STAT_RESULT_H , BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_H , 4;
Nop;

jz END_OF_MACRO, NO_NOP;   // Negetive signa - In case expression doesn't matches - do sinature action
    //prepare to read next signa word
    Add BDOS_SIGNA_WORD_SEL, BDOS_SIGNA_WORD_SEL, 1, 4;
    Sub CNT , CNT , 1 , 1;

nop;
js SIGNA_ACTION , NOP_2;
//Read groups 1,2
EZstatSendCmdIndexReg BDOS_SIGNA_WORD_SEL, STS_READ_CMD;
Nop;

if (!FLAGS.bit[F_SR]) jmp $;
    Nop;    
    Nop;
//check group 1
and ALU, STAT_RESULT_L, BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_L, 4;
Nop;

jz END_OF_MACRO;   // In case expression matches
   Sub CNT , CNT , 1 , 1;
   Nop;

//check group 2
js SIGNA_ACTION,NOP_2;
   and ALU, STAT_RESULT_H, BDOS_RESULT_REG, 4;
   xor ALU, ALU, STAT_RESULT_H, 4;
Nop;

jz END_OF_MACRO;   // In case expression matches
   Add BDOS_SIGNA_WORD_SEL, BDOS_SIGNA_WORD_SEL, 1, 4;
   Sub CNT , CNT , 1 , 1;
Nop;

js SIGNA_ACTION , NOP_2;

//Read group 3
EZstatSendCmdIndexReg BDOS_SIGNA_WORD_SEL, STS_READ_CMD;
nop;
nop;

if (!FLAGS.bit[F_SR]) jmp $;
    Nop;
    Nop;

//check group 3
and ALU, STAT_RESULT_L,  BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_L, 4;
Nop;

jz END_OF_MACRO,NOP_2;
// In case expression matches - perform action
jmp SIGNA_ACTION,NOP_2;

NEG_SIGNA_IMMEDIATE_ACTION:
if (!FLAGS.bit[F_SR]) jmp $;
    Nop;    
    Nop;
//signature config + group 0 bitmask were previously read in "preliminary read policy bdos first signature "
//save signature configuration 
Mov BDOS_SIGNA_CONF , STAT_RESULT_L, 4; 


SIGNA_ACTION:

//start get color of TB ASAP
Mov ALU, BDOS_SAMP_TB, 4;

//signuture global id
//Add ALU , ALU , BDOS_SIGNA_CONF , 4 , MASK_00003FFF, MASK_SRC2 ; 
MovBits byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ALST_EMPTY_BIT] , BDOS_SIGNA_CONF.bit[28] , 1;

//signuture global id
Add /*uqTmpReg5*/ CTX_REG[3] , ALU , BDOS_SIGNA_CONF , 4 , MASK_00003FFF, MASK_SRC2 ; 

GetRes  ALU  ,  MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR) , 2 , RESET;
//without sw vlan
If (!byGlobalStatusBitsReg.bit[SRC_100G_BIT]) Sub ALU , ALU , 4 , 2 ;
If ( !byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ALST_EMPTY_BIT] ) Mov ALU , BDOS_SAMP_SIZE_CONST , 2;


       
// Sampling can be implemented in two methods:
// 1. Using TM - send all sampled frames to dedicated queue in TM
//    and configure TB on this queue according to feature.
// 2. Using Statistics TB.
EZstatPutDataSendCmdIndexReg /* uqTmpReg5 */ CTX_REG[3], ALU, STS_GET_COLOR_CMD;

//signuture global id
//MovBits  uqTmpReg2.bit[3] , BDOS_SIGNA_CONF , 14 , RESET; 
MovBits ALU.bit[3] , BDOS_SIGNA_CONF , 14 , RESET;
nop;
Mov uqTmpReg2 , ALU , 4;
//current counter base = ( polid *4*32) 
//SHL uqTmpReg4 , ALU  , 7 , 4 ;
// First - prepare signature action  
//Mov ALU, SigNum, 4;
Mov ALU, BC_CNT_BASE, 4;

Add uqTmpReg2 , uqTmpReg2 , ALU , 4;


  
xor ALU, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH;    // getRes MREG Value
Movbits ALU, BDOS_SIGNA_CONF.bit[BDOS_SIGNA_CONFIG_ACTION], 2;             // set signature action
Movbits byTempCondByte.bit[2], ALU.bit[GC_CNTRL_1_BDOS_SAMPLING_ENABLE], 1; // Set sampling status
decode  uqTmpReg4, ALU, 1, MASK_00000003, MASK_SRC1;
Movbits byTempCondByte.bit[3], BDOS_SIGNA_CONF.bit[BDOS_SIGNA_CONFIG_TB_GREEN_IS_YELLOW], 3; //BDOS_SIGNA_CONFIG_TB_GREEN_IS_YELLOW,BDOS_SIGNA_CONFIG_TB_GREEN_IS_RED,BDOS_SIGNA_CONFIG_PACKET_TRACE
Nop;


// This Macro performs the action with the data prepared:
// uqTmpReg2 - counter Base
// uqTmpReg4 - Decoded signature action bits 
// byTempCondByte.bit[2] - GC_CNTRL_1_BDOS_SAMPLING_ENABLE
// byTempCondByte.bit[3] - BDOS_SIGNA_CONFIG_TB_GREEN_IS_YELLOW
// byTempCondByte.bit[4] - BDOS_SIGNA_CONFIG_TB_GREEN_IS_RED
// byTempCondByte.bit[5] - BDOS_SIGNA_CONFIG_PACKET_TRACE
// GetColor of Token bucket was previously called


//ENC_PRI gets BDOS_SIGNA_CONFIG_TB_GREEN_IS_RED,BDOS_SIGNA_CONFIG_TB_GREEN_IS_YELLOW,1 (default is green)
Mov3Bits ENC_PRI.bits[13,12,11],byTempCondByte.bits[4,3,TRUE];

//get TB color
//EZwaitFlag F_SR;

   if       ( !FLAGS.BIT [ F_SR ] )
      jmp   $ ;
      
          GetRes uqTmpReg6, { POLICY_UID_OFF }(POLICY_RES_CONF_STR), 2;  // Save policy id in message to be used for Host metadata addition in TOPmodify
          //MovBits uqTmpReg6.bit[10], BDOS_SIGNA_CONF.bit[BDOS_SIGNA_UID] , 4;
          //set defaul value 
          MovBits uqTmpReg6.bit[9], 0xf , 4;

MovBits ENC_PRI.bit[14],STAT_RESULT_L.bit[YELLOW_FLAG_OFF],2;
Nop;
// Green - continue
// Yellow - sample
// RED - perform action

Jmul  BDOS_TB_COLOR_RED,
      BDOS_TB_COLOR_YELLOW,
      BDOS_TB_COLOR_RED,
      BDOS_TB_COLOR_YELLOW,
      BDOS_TB_COLOR_GREEN,
      BDOS_TB_COLOR_GREEN, 
      BDOS_TB_COLOR_GREEN; 

BDOS_TB_COLOR_GREEN:

//if under threshold for all signature types jump to next signature 
jmp  END_OF_MACRO;
    If (RTPC_IS_ENABLED_BIT) mov uxEthTypeMetaData, RTPC_TF_GREEN, 2;
    nop;


#ifdef DEBUG_STAT_MODE;
nop;
nop;
#endif;
          
BDOS_TB_COLOR_RED:
   movBits ENC_PRI.bit[13], uqTmpReg4.bit[0], 3;
   MovBits ALU , BDOS_SIGNA_CONF.bit[BDOS_SIGNA_CONFIG_TYPE] , 2 , RESET;
   Jmul BYPASS_HANDLER, 
      CONT_HANDLER, 
      DROP_HANDLER, 
      NO_NOP;
         getRes uqTmpReg3, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2;  // getRes packet length
         Decode byTempCondByte1 , ALU , 1;

//if no action taken (shoud't be occured) or send CPU action detected 
SEND_CPU_HANDLER:


If (!RTPC_IS_ENABLED_BIT) jmp  SEND_CPU_HANDLER_CONT, NO_NOP;    
   
   //RTPC is set, and it is TF, should mark the frame                         
   If (byTempCondByte1.bit[MANUAL_TYPE_OFF]) mov uxEthTypeMetaData, RTPC_TF_PROCESS , 2; 
   Nop; //If (byTempCondByte1.bit[MANUAL_TYPE_OFF]) movBits byRTPCPolicyFlags.bit[RTPC_IS_RTPC_MARKED], 1, 1;


SEND_CPU_HANDLER_CONT:
   BDOS_Update_Counters BC_CPU_OFFSET, BC_BT_CPU_OFFSET;
   jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
      Mov PC_STACK, SEND_PACKET_LAB_CPU, 2;
      MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

DROP_HANDLER:

   BDOS_Update_Counters BC_DRP_OFFSET, BC_BT_DRP_OFFSET;

//RTPC - update BDOS drop
//check  byTempCondByte.bit[MANUAL_TYPE_OFF] if it is BDOS or TF

   //check if RTPC is enabled and matched.
   If (!RTPC_IS_ENABLED_BIT)  jmp DROP_HANDLER_CONT, NO_NOP;

      If ( byTempCondByte1.bit[MANUAL_TYPE_OFF]) mov ALU, RTPC_TF_DROP,   2;
      If (!byTempCondByte1.bit[MANUAL_TYPE_OFF]) mov ALU, RTPC_BDOS_DROP, 2;

   
   //RTPC is set, should mark the frame 
   Nop;                        
   mov uxEthTypeMetaData, ALU , 2; 
   

DROP_HANDLER_CONT:

   jmp BDOS_DISCARD_LAB , NOP_2; //not trace, drop
      

CONT_HANDLER:
   //if singnuture is manual type do this action
   //Mov3Bits ENC_PRI.bits[14] , BDOS_SIGNA_CONF.bits[BDOS_SIGNA_CONFIG_TYPE,{BDOS_SIGNA_CONFIG_TYPE+1},FALSE], 3; 
#ifdef _netam__
   MovBits ALU , BDOS_SIGNA_CONF.bit[BDOS_SIGNA_CONFIG_TYPE] , 2 , RESET;
   Decode byTempCondByte , ALU , 1;
   MovBits ALU , uqGlobalStatusBitsReg.bit[POLICY_CNG_MANRULE_ACT_BIT] , 2, RESET ;
   Decode ALU , ALU , 1; 
   If (!byTempCondByte.bit[MANUAL_TYPE_OFF]) Jmp CONT_CONT_ACT;       
       MovBits ENC_PRI.bit[9] , ALU.bit[0] , 7;
       Nop;
   
     
   jmul  CONT_CONT_ACT, CONT_CONT_ACT , CONT_CONT_ACT, SEND_CPU_HANDLER , BYPASS_HANDLER , CONT_CONT_ACT , DROP_HANDLER;      

CONT_CONT_ACT:
#endif 

   BDOS_Update_Counters BC_CNT_OFFSET, BC_BT_CNT_OFFSET;
   jmp BDOS_TB_COLOR_GREEN, NOP_2;

BYPASS_HANDLER:

//RTPC - update BDOS BYPASS
//  check byTempCondByte.bit[MANUAL_TYPE_OFF] if the feature is BDOS or TF


 //check if RTPC is enabled and matched.
If (!RTPC_IS_ENABLED_BIT) jmp BYPASS_HANDLER_CONT, NO_NOP;  

   If ( byTempCondByte1.bit[MANUAL_TYPE_OFF]) mov ALU, RTPC_TF_BYPASS,    2;
   If (!byTempCondByte1.bit[MANUAL_TYPE_OFF]) mov ALU, RTPC_BDOS_BYPASS , 2;

Nop;                      
mov uxEthTypeMetaData, ALU, 2;
   

BYPASS_HANDLER_CONT:


jmp YYYYYYY,NOP_2;

FFT_TABLE_TXCOPY_END3_LAB:

YYYYYYY:

   BDOS_Update_Counters BC_PAS_OFFSET, BC_BT_PAS_OFFSET;
   if (!byTempCondByte.bit[5]) jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;//not trace, skip forensic action
       Mov PC_STACK, FRAME_BYPASS_NETWORK_LAB, 2;
       MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;
   jmp BYPASS_HANDLER, NOP_1;
      MovBits byTempCondByte.bit[0], 0x3, 2;//Packet Bypass with trace

BDOS_DISCARD_LAB:

Mov PC_STACK, FRAME_DROP_LAB, 2;
//if marked, handle RTM accordingly

//jump to rtm before discard
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    If (RTPC_IS_ENABLED_BIT)   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;
    If (!RTPC_IS_ENABLED_BIT)  MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;


BDOS_TB_COLOR_YELLOW:
   //skip sample if GC_CNTRL_1_BDOS_SAMPLING_ENABLE == False
   //if (!byTempCondByte.bit[2]) jmp BDOS_TB_COLOR_RED, NOP_2;
   //skip sample if packet jumbo type detected
   if(byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT]) jmp BDOS_TB_COLOR_RED;
       MovBits ALU , BDOS_SIGNA_CONF.bit[BDOS_SIGNA_CONFIG_TYPE] , 2 , RESET;
       Decode byTempCondByte1 , ALU , 1;

    nop;    
    If (byTempCondByte1.bit[MANUAL_TYPE_OFF]) MovBits uqTmpReg6.bit[9], BDOS_SIGNA_CONF.bit[BDOS_SIGNA_UID] , 4;

   //MovBits  uqTmpReg2 , BDOS_SIGNA_CONF , 14 , RESET;
   Mov ALU, BS_SAMP_CPU, 4;

   PutKey  MSG_POLICY_ID_OFF(HW_OBS)  , uqTmpReg6 ,  2;    

   //Add ALU , ALU , BDOS_SIGNA_CONF , 4 ;
   Add ALU , ALU , BDOS_SIGNA_CONF , 4 , MASK_00003FFF, MASK_SRC2 ; 
   

   //color is yellow - sample.
   EZstatIncrIndexReg ALU , 1;
   

//RTPC BDOS sampling 
//check if it is BDOS or TF?  If (byTempCondByte1.bit[MANUAL_TYPE_OFF])

If (!RTPC_IS_ENABLED_BIT)  jmp SAMPLE_CONT, NO_NOP;

   If (byTempCondByte1.bit[MANUAL_TYPE_OFF])  mov ALU,  RTPC_TF_SAMPLE,   2;
   If (!byTempCondByte1.bit[MANUAL_TYPE_OFF]) mov ALU,  RTPC_BDOS_SAMPLE, 2;

Nop;
Mov uxEthTypeMetaData, ALU , 2;
   

SAMPLE_CONT:
    
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, SEND_TO_CPU, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;


/*
#undef   Cont_Counter;
#undef   Pass_Counter;
#undef   CPU_Counter;
#undef   Drop_Counter;
#undef   Cont_Byte_Counter;
#undef   Pass_Byte_Counter;
#undef   CPU_Byte_Counter;
#undef   Drop_Byte_Counter;
*/



END_OF_MACRO:



#undef BDOS_RESULT_REG;
#undef BDOS_SIGNA_WORD_SEL;

ENDMACRO; // AnalyzeBdosResult



MACRO BDOS_Update_Counters BC_FRAME_COUNTER, BC_FRAME_BYTES_COUNTER;
   Add uqTmpReg1, uqTmpReg2, BC_FRAME_COUNTER,    4;//frame counter
   Add uqTmpReg4, uqTmpReg2, BC_FRAME_BYTES_COUNTER, 4;//bytes counter
   EZstatIncrIndexReg uqTmpReg1,1;
   Mov ALU , uqTmpReg3 , 2 , RESET;
   EZstatIncrIndexReg uqTmpReg4,ALU;
ENDMACRO; // BDOS_Update_Counters




/*
MACRO semtake;

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
   EZwaitFlag F_SR;

   if( FLAGS.bit[F_SO]  ) jmp wait_sem11 , NOP_2;

ENDMACRO;
       
MACRO semgive;

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
   nop;
   //EZwaitFlag F_ST;

ENDMACRO;
*/                                  
