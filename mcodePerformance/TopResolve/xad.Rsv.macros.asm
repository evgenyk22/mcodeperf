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

   xor uqTmpReg6 , uqTmpReg6,uqTmpReg6,4;

   if (!byGlobalStatusBitsReg.bit[ALIST_SAMPL_BIT]) jmp SKIP_ALIST_SAMPL_MARK_LAB, NO_NOP;
      GetRes ALU.byte[0], ALST_RES_ENTRY_ID_OFF(ALST_RES_STR), 2;
      Mov bytmp1, 0, 2; // Clears bytmp1 and bytmp2

   //prepare whole value for TopModify
   Mov ALU.byte[2], METADATA_RDWR_STAMP_LOW16, 2;

   PutKey MSG_ALIST_SAMPL_INFO_TOP_MODIFY(HW_OBS), METADATA_RDWR_STAMP_HIGH16, 2;
   PutKey MSG_ALIST_STAMP_INFO_TOP_MODIFY(HW_OBS), ALU.byte[0], 4;

SKIP_ALIST_SAMPL_MARK_LAB:

   xor uqTmpReg7, ALU, !ALU, 4, TRAFFIC_ENGINE_NUMBER, MASK_BOTH; // using MREG[12]
   GetRes  uqTmpReg6, MSG_HASH_CORE_OFF(MSG_STR), 1; // Note: frames that are not IP (i.e. L2 control frames e.g. ARP, etc) will probably always have 0 hash function result. this does not give distribution.
   PutKey  MSG_ACTION_ENC_OFF(HW_OBS), byFrameActionReg, 1;
   //Modulo  ALU, bytmp0, uqTmpReg6.byte[0] , 1;
   LongDiv uqTmpReg6 , uqTmpReg6 , uqTmpReg7 , 2;
   MovBits ENC_PRI.bit[13], byFrameActionReg.bit[0], 3;
   //traffic engine number should start from 1


/************************************** New for NP5 *************************************/
/************** MAC selection based  on input port number *************************/

   MovBits ENC_PRI.bit[9] , byFrameActionReg.bit[0] , 7;
   GetRes uqTmpReg1.byte[3] , MSG_NP5_INTERFACE_PORT_NUM_OFF(MSG_STR) , 1;

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
   MovMul  1 , 0 , 0 , 0 ,255 ,255 ,0; /*-1 , -1 , 1;*/
   Xor uqTmpReg1.byte[0] ,uqTmpReg1.byte[0]  , uqTmpReg1.byte[0] , 2;
   Add ALU.byte[0] ,uqTmpReg1.byte[3] , ENC_PRO , 1 ;
   copy    56(HW_OBS),  56(MSG_STR), 8;
   MovBits uqTmpReg1.byte[0].bit[6] , ALU.byte[0].bit[0] , 8;
   PutKey  MSG_NP5_PPORT_NUM_OFF(HW_OBS),ALU.byte[0] , 1;
   PutKey  MSG_NP5_INTERFACE_PORT_NUM_OFF(HW_OBS), uqTmpReg1.byte[0], 2;

UPDATE_MSG_CTRL_TOPRSV_0_1_LAB:

vardef regtype uqRSV_INDIRECT_CTX_LOAD    INDIRECT_CTX_LOAD.byte[0:1];  // INDIRECT_CTX_LOAD register (UREG[12]): bits 8:15 (ignore_rdy_bits) part of this register should always be zero in order to assure that TOPmodify will start ONLY when the relevant context lines marked in bits 7:0 (load_context_bitmap) part of the register are valid.

   //Wait for the end of LongDiv Instruction -- bit 22   F_CTX_LA_RDY_1 the same as F_ITR
   //EZwaitFlag F_CTX_LA_RDY_1;

   if       ( !FLAGS.BIT [ F_CTX_LA_RDY_1 ] )  jmp   $;
       Mov2Bits byTempCondByte1.bits[0, 0], byFrameActionReg.bits[FRAME_BYPASS_HOST_BIT, FRAME_CONT_ACTION_BIT];
       PutKey MSG_CTRL_TOPRSV_0_OFF(HW_OBS), byCtrlMsgRsv0, 2;  // Writing 2 ctrl bytes (byCtrlMsgRsv0 and byCtrlMsgRsv1) in 1 operation



    If (!byTempCondByte1.bit[0]) Jmp SKIP_CORE_DISTRIBUTION;
       PutKey  MSG_CORE_NUM_OFF(HW_OBS),  uqTmpReg6, 1;
       Nop;

    PutHdr HREG[ COM_HBS ], ((LKP_VALID  | ( CORE_DISTR_LAB << HREG_FIRST_LINE_ADDR_BIT) | (((RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE - 1) >> 4) << HREG_KEY_SIZE_BIT) | (KEY_TYPE_1 << HREG_KEY_TYPE_BIT))) ;
    MovBits byTemp3Byte0.bit[CTX_LINE_CORE2IP_DISTRIBUTION], 1, 1;
    Add COM_HBS  , COM_HBS ,  1 , 1;
    xor ALU, ALU, !ALU, 4, TRAFFIC_ENGINE_NUMBER, MASK_BOTH; // using MREG[12]
    GetRes uqTmpReg6.byte[0] , MSG_HASH_CORE_OFF(MSG_STR), 1;
    //Copy { KMEM_RSV2SRH2_FFT_KEY_OFF+RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN + 2} ( HW_OBS ),  MSG_HASH_CORE_OFF(MSG_STR), 1;
    Mov uqTmpReg6.byte[2] , ALU , 1;
    Nop;
    PutKey KMEM_OFFSET( HW_OBS ),  uqTmpReg6 , 4;
    Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_TX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;

SKIP_CORE_DISTRIBUTION:

    movbits $uqRSV_INDIRECT_CTX_LOAD , byTemp3Byte0 , 4;
    nop;
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
EZstatIncrIndexReg uqTmpReg1, 1;
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
MACRO AnalyzeBdosResult SigNum,
                        SIG_OFFSET;    //SIG_OFFSET

#define BDOS_RESULT_REG uqTmpReg4;
#define BDOS_SIGNA_SEL  uqTmpReg3;

Mov ALU, SigNum, 1;
Mov BDOS_SIGNA_SEL, SIG_OFFSET, 4;
SHL ALU, ALU, 2, 4;
Add BDOS_SIGNA_SEL, ALU, BDOS_SIGNA_SEL, 4;

// getRes the first group of the signature
EZstatSendCmdIndexReg BDOS_SIGNA_SEL, STS_READ_CMD;

// Prepare indirect registers for access to special signature result
Mov 	IND_REG0, &uqTmpReg1, 2;      // Prepare indirect register pointer for uqTmpReg1
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

mov PC_STACK, END_OF_MACRO, 2; // in case action is to continue
add ALU, BDOS_RESULT_REG, 0, 4;
nop;
jz END_OF_MACRO, NOP_2; // If all signature result bits are '0', no need to test expressions.

if (!FLAGS.bit[F_SR]) jmp $ | NOP_2;

and ALU, STAT_RESULT_L, BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_L, 4, MASK_0FFFFFFF, MASK_SRC2;
mov byTempCondByte, STAT_RESULT_L.byte[3], 1;

jz SIGNA_ACTION, NO_NOP;   // In case expression matches
   Add BDOS_SIGNA_SEL, BDOS_SIGNA_SEL, 1, 4;
   Mov uqTmpReg1.byte[0], byTempCondByte, 1;          // store signature configuration (action and PT status) for the next groups

if (!byTempCondByte.bit[7]) jmp END_OF_MACRO | NOP_2; // Check if more groups

EZstatSendCmdIndexReg BDOS_SIGNA_SEL, STS_READ_CMD;
Nop;
nop;

if (!FLAGS.bit[F_SR]) jmp $ | NOP_2;

and ALU, STAT_RESULT_L, BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_L, 4, MASK_0FFFFFFF, MASK_SRC2;
mov byTempCondByte, STAT_RESULT_L.byte[3],1;

jz SIGNA_ACTION, NOP_1;   // In case expression matches
   Add BDOS_SIGNA_SEL, BDOS_SIGNA_SEL, 1, 4;

if (!byTempCondByte.bit[7]) jmp END_OF_MACRO, NOP_2; // Check if more groups:

EZstatSendCmdIndexReg BDOS_SIGNA_SEL, STS_READ_CMD;
nop;
nop;

if (!FLAGS.bit[F_SR]) jmp $ | NOP_2;

and ALU, STAT_RESULT_L, BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_L, 4, MASK_0FFFFFFF, MASK_SRC2;
mov byTempCondByte, STAT_RESULT_L.byte[3], 1;

jz SIGNA_ACTION, NOP_1;   // In case expression matches
   Add BDOS_SIGNA_SEL, BDOS_SIGNA_SEL, 1, 4;

if (!byTempCondByte.bit[7]) jmp END_OF_MACRO, NOP_2; // Check if more groups:

EZstatSendCmdIndexReg BDOS_SIGNA_SEL, STS_READ_CMD;
nop;
nop;

if (!FLAGS.bit[F_SR]) jmp $ | NOP_2;

and ALU, STAT_RESULT_L,  BDOS_RESULT_REG, 4;
xor ALU, ALU, STAT_RESULT_L, 4, MASK_0FFFFFFF, MASK_SRC2;
mov byTempCondByte, STAT_RESULT_L.byte[3],1;

jnz END_OF_MACRO, NOP_2;   // In case expression matches

// if (byTempCondByte.bit[7]) jmp END_OF_MACRO | NOP_2; // Check if more groups:

SIGNA_ACTION:

// First - prepare signature action
Mov ALU, SigNum, 4;
Mov uqTmpReg2, BC_CNT_BASE, 4;
SHL ALU, ALU, 3, 4;
Add uqTmpReg2, ALU, uqTmpReg2, 4; // Set signature counter

xor ALU, ALU, !ALU, 4, GC_CNTRL_1_MREG, MASK_BOTH;    // getRes MREG Value
Movbits ALU, uqTmpReg1.byte[0].bit[5], 2;             // set signature action
Movbits byTempCondByte.bit[2], ALU.bit[GC_CNTRL_1_BDOS_SAMPLING_ENABLE], 1; // Set sampling status
decode  uqTmpReg4, ALU, 1, MASK_00000003, MASK_SRC1;
Movbits byTempCondByte.bit[3], uqTmpReg1.byte[0].bit[4], 1; // Set sigature PT status

// Second - perform action
SignaturePerformAction SigNum, FRAME_TP_BYPASS_2NETW_LAB;

indirect END_OF_MACRO:

#undef BDOS_RESULT_REG;
#undef BDOS_SIGNA_SEL;

ENDMACRO; // AnalyzeBdosResult


// This Macro performs the action with the data prepared:
// uqTmpReg2 - counter Base
// uqTmpReg4 - Bits for ENC_PRI
// byTempCondByte - Sampling bit
MACRO SignaturePerformAction SigNum, TP_NETWORK_BYPASS;

movBits ENC_PRI.bit[13], uqTmpReg4.bit[0], 3;

//Mov ENC_PRI.byte[1] , 0 , 1;
//nop;
getRes uqTmpReg3, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2;  // getRes packet length

Jmul BYPASS_LOCAL,
     CONTINUE_LAB,
     DROP,
     NOP_2;


//if no action taken (shoud't be occured) or send CPU action detected
SEND_CPU:
Add uqTmpReg1, uqTmpReg2, BC_CPU_OFFSET, 4;
EZstatIncrByOneIndexReg uqTmpReg1;
Add uqTmpReg1, uqTmpReg2, BC_BT_CPU_OFFSET, 4;
//STAT_OPERATION uqTmpReg1, uqTmpReg3, EZ_INCR_CMD_STS;
EZstatIncrIndexReg uqTmpReg1, uqTmpReg3;

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, SEND_PACKET_LAB_CPU, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;


CONTINUE_LAB:
Add uqTmpReg1, uqTmpReg2, BC_CNT_OFFSET, 4;
EZstatIncrByOneIndexReg uqTmpReg1;

Add uqTmpReg1, uqTmpReg2, BC_BT_CNT_OFFSET, 4;
// Two bytes of Data are taken, 3 bytes of index are taken
//STAT_OPERATION uqTmpReg1, uqTmpReg3, EZ_INCR_CMD_STS;
EZstatIncrIndexReg uqTmpReg1, uqTmpReg3;


//save stack
Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
   Mov PC_STACK, BDOS_CONT_RTM_DONE_LAB, 2;
   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

indirect BDOS_CONT_RTM_DONE_LAB:
Mov PC_STACK, uqTmpReg1, 2;
nop;
Jstack NOP_2;

#ifdef DEBUG_STAT_MODE;
nop;
nop;
#endif;


DROP:
//jmp to DROP
jmp SET_CNTR_LAB, NO_NOP;
   Add uqTmpReg1, uqTmpReg2, BC_DRP_OFFSET,    4;
   Add uqTmpReg4, uqTmpReg2, BC_BT_DRP_OFFSET, 4;


BYPASS_LOCAL:
//jmp to Net bypass
Add uqTmpReg1, uqTmpReg2, BC_PAS_OFFSET,    4;
Add uqTmpReg4, uqTmpReg2, BC_BT_PAS_OFFSET, 4;


SET_CNTR_LAB:
//check sampling status
if (byTempCondByte.bit[2]) jmp SAMPLING, NOP_1;
   MovBits UREG[1].bit[0], ENC_PRI.bit[13], 3;


DROP_BYPASS_ACT_LAB:

EZstatIncrByOneIndexReg uqTmpReg1;
nop;
EZstatIncrIndexReg uqTmpReg4,uqTmpReg3;

if (!byTempCondByte.bit[3]) jmp FORENZIK_SKIP_ACT_LAB, NOP_2;

jmp TP_NETWORK_BYPASS, NO_NOP;
   MovBits byTempCondByte.bit[1], UREG[1].bit[2], 1;
   MovBits byTempCondByte.bit[0], byTempCondByte.bit[3], 1;


FORENZIK_SKIP_ACT_LAB:
if (!UREG[1].bit[2]) jmp BDOS_DISCARD_LAB, NOP_2;

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, FRAME_BYPASS_NETWORK_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;


BDOS_DISCARD_LAB:
//jump to rtm before discard
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, FRAME_DROP_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;


SAMPLING:
//skip sample if packet jumbo type detected
if(byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT]) jmp DROP_BYPASS_ACT_LAB, NOP_2;

Mov ALU, BDOS_SAMP_TB, 4;
Add ALU, ALU, SigNum, 4;

// Sampling can be implemented in two methods:
// 1. Using TM - send all sampled frames to dedicated queue in TM
//    and configure TB on this queue according to feature.
// 2. Using Statistics TB.
EZstatPutDataSendCmdIndexReg ALU, BDOS_SAMP_SIZE_CONST, STS_GET_COLOR_CMD;

Mov ALU, BS_SAMP_CPU, 4;
Add ALU, ALU, SigNum, 4;

EZwaitFlag F_SR;

// And ALU, STAT_RESULT_L, RED_IN_RESULT, 1;
// Color is also returned to UDB.bits 16,17.
MovBits UDB.bit[17], STAT_RESULT_L.bit[RED_FLAG_OFF], 1;
   nop;
if (UDB.bit[17]) jmp DROP_BYPASS_ACT_LAB, NOP_2;

EZstatIncrByOneIndexReg ALU;

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
ENDMACRO; // SignaturePerformAction



MACRO OOS_Preparse_Action  ACTION_OFFSET, Act_Counter;

#if 0 /* disable OOS */

#define uxPacketLen       uxTmpReg1;
#define byPolicyValByte1  byTempCondByte1;
#define byPolicyValByte2  byTempCondByte2;

Mov uqTmpReg2, 0, 4;

//save byte 1,2 from policy result
Mov byPolicyValByte1, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE0], 1;
Mov byPolicyValByte2, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE1], 1;

getRes uxPacketLen, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2;  // Get packet length

//mov 2 bits of threshold action to  bytmp0
MovBits bytmp0, uqGlobalStatusBitsReg.bit[POLICY_CNG_OOS_ACTIV_ACT_BIT], 2;

//calculate counters block position
MovBits uqTmpReg2.bit[2], uxGlobalPolIdx.bit[0], 16;
Mov ALU, OS_BASE, 4;
Add uqTmpReg2, uqTmpReg2, ALU, 4;

//decode threshold action
decode bytmp1, bytmp0, 1, MASK_00000003, MASK_SRC1;

if (!byPolicyValByte2.bit[POLICY_ID_BYTE2ACTIVATE_THR_STAT_BIT]) jmp SKIP_THR_ACTION, NOP_2;

MovBits ENC_PRI.bit[9], bytmp1.bit[0], 7;

//calculate action token bucket
Mov ALU, OOS_ACT_TB, 2;
Add ALU, uxGlobalPolIdx, ALU, 2, MASK_0000FFFF, MASK_SRC1;

EZstatPutDataSendCmdIndexReg ALU, OOS_ACT_SIZE_CONST, STS_GET_COLOR_CMD;
nop;
nop;
EZwaitFlag F_SR;


MovBits byTempCondByte.bit[0], STAT_RESULT_L.bit[RED_FLAG_OFF], 1;
Mov ALU, OS_ACT_THRESH,  4;
Add ALU, uqTmpReg2, ALU, 4;
if (byTempCondByte.bit[0]) jmp SKIP_THR_ACTION, NOP_2;

EZstatPostedLongIncrIndex ALU, 1;

Jmul ERROR_LAB,
     ERROR_LAB,
     ERROR_LAB,
     2CPU_OOS_ACT_THRESH,
     BYPASS_ACT_THRESH,
     CONT_OOS_ACT_THRESH,
     DROP_ACT_THRESH;
     nop;
     nop;


BYPASS_ACT_THRESH:
DROP_ACT_THRESH:
nop;

//second jmul for  bypass and  drop logic only
Jmul ERROR_LAB,
     ERROR_LAB,
     ERROR_LAB,
     ERROR_LAB,
     BYPASS_OOS_ACT_THRESH,
     ERROR_LAB,
     DROP_OOS_ACT_THRESH;
     nop;
     nop;


SKIP_THR_ACTION:
if (byPolicyValByte2.bit[POLICY_ID_BYTE2SAMPL_STAT_BIT]) jmp SAMPLING, NOP_2;


BYPASS_DROP_SAMPLING:

MovBits ALU, uqGlobalStatusBitsReg.bit[ACTION_OFFSET], 2; //get threshold action (byPolicyValByte1 == uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE0])
decode  ALU, ALU, 1, MASK_00000003, MASK_SRC1;
nop;
movBits ENC_PRI.bit[9], ALU.bit[0], 7;
Nop;

ACT_SELECT_LAB:

Jmul ERROR_LAB,
     ERROR_LAB,
     ERROR_LAB,
     2CPU,
     BYPASS,
     CONT,
     DROP;
     nop;
     nop;


CONT:

EZstatPostedLongIncrIndex uqTmpReg2, 1;
Add ALU, uqTmpReg2, OS_OTHR_BYTE_CNT, 4;
EZstatPostedLongIncrIndex ALU, uxPacketLen;


CONT_OOS_ACT_THRESH:
//indicate rtm recive

Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, OOS_CONT_RTM_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

indirect OOS_CONT_RTM_DONE_LAB:

Mov PC_STACK, uqTmpReg1, 2;
nop;
Jstack NOP_2;


2CPU:

EZstatPostedLongIncrIndex uqTmpReg2,1;
Add ALU, uqTmpReg2, OS_OTHR_BYTE_CNT, 4;
EZstatPostedLongIncrIndex ALU, uxPacketLen;


2CPU_OOS_ACT_THRESH:

Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, OOS_2CPU_RTM_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

indirect OOS_2CPU_RTM_DONE_LAB:

Mov PC_STACK, uqTmpReg1, 2;
Or byPolicyOOSActionReg, byPolicyOOSActionReg, OOS_ACT_2CPU, 1;

Jstack NOP_2;


BYPASS:

EZstatPostedLongIncrIndex uqTmpReg2, 1;
Add ALU, uqTmpReg2, OS_OTHR_BYTE_CNT, 4;
EZstatPostedLongIncrIndex ALU, uxPacketLen;

Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, OOS_BPASS_RTM_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;


indirect OOS_BPASS_RTM_DONE_LAB:

//little optimization, here action could be only 0 or 2, therefore no need to jmul it
MovBits byTempCondByte, uqGlobalStatusBitsReg.bit[ACTION_OFFSET], 2;
Nop;
if (byTempCondByte.bit[1]) Or byPolicyOOSActionReg, byPolicyOOSActionReg, OOS_ACT_BYPASS, 1;

And ALU, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE0], POLICY_OOS_PT_STAT_BIT_MASK, 1;
Mov PC_STACK, uqTmpReg1, 4;
if (!FLAGS.bit[F_ZR]) MovBits byPolicyOOSActionReg.bit[OOS_POLICY_PT_BYPASS_BIT], 1, 1; // store PT status if enable

Jstack NOP_2;


DROP:
ERROR_LAB:
DROP_OOS_ACT_THRESH:

EZstatPostedLongIncrIndex uqTmpReg2, 1;
Add ALU, uqTmpReg2, OS_OTHR_BYTE_CNT, 4;
EZstatPostedLongIncrIndex ALU, uxPacketLen;

Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, OOS_DISCARD_RTM_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 0, 1;

indirect OOS_DISCARD_RTM_DONE_LAB:

Or byPolicyOOSActionReg, byPolicyOOSActionReg, OOS_ACT_DROP, 1;
And ALU, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE0], POLICY_OOS_PT_STAT_BIT_MASK, 1;
Mov PC_STACK, uqTmpReg1, 2;
if (!FLAGS.bit[F_ZR]) MovBits byGlobalStatusBitsReg.bit[OOS_POLICY_PT_BIT], 1, 1; // store PT status if enable

Jstack NOP_2;


BYPASS_OOS_ACT_THRESH:

Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, OOS_NBPASS_RTM_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

indirect OOS_NBPASS_RTM_DONE_LAB:

Mov PC_STACK, uqTmpReg1, 2;
Or byPolicyOOSActionReg, byPolicyOOSActionReg, OOS_ACT_NBYPASS, 1;

Jstack NOP_2;


SAMPLING:
// Sampling can be implemented in two methods:
// 1. Using TM - send all sampled frames to dedicated queue in TM
//    and configure TB on this queue.
// 2. Using Statistics TB.

#ifdef USE_TM_FOR_SAMPLING;
putkey MSG_TM_QUEUE_OFFSET(HW_OBS), OOS_SAMP_QUEUE_OFFSET, 1;

#else;

//set counter
Mov ALU, OOS_SAMP_TB, 2;
Add ALU, uxGlobalPolIdx, ALU, 2, MASK_0000FFFF, MASK_SRC1;

EZstatPutDataSendCmdIndexReg ALU, OOS_SAMP_SIZE_CONST, STS_GET_COLOR_CMD;
nop;
nop;
EZwaitFlag F_SR;

MovBits byTempCondByte.bit[0], STAT_RESULT_L.bit[RED_FLAG_OFF], 1;
nop;
if (byTempCondByte.bit[0]) jmp BYPASS_DROP_SAMPLING, NOP_2;

#endif;

Mov ALU, OS_SAMP_CPU, 3;
Add ALU, uqTmpReg2, ALU, 3;

EZstatPostedLongIncrIndex ALU, 1;

Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, OOS_2CPU1_RTM_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

indirect OOS_2CPU1_RTM_DONE_LAB:

Mov PC_STACK, uqTmpReg1, 2;
Or byPolicyOOSActionReg, byPolicyOOSActionReg, OOS_ACT_2CPU, 1;

Jstack NOP_2;


#undef uxPacketLen;
#undef byPolicyValByte1;
#undef byPolicyValByte2;

#endif

ENDMACRO; // OOS_Preparse_Action



MACRO CheckOOSResult;

// Check if TCP session is open. In case of SYN-ACK, need to verify correctness of SYN-Cockie
// Note that this Macro is duplicated 3 times in the code space

// Collect control bits from TCP_OOS_STR result
GetCtrlBits byTempCondByte1, STRNUM[TCP_OOS_STR].bit[MATCH_BIT              ],  // bit 3
                             STRNUM[TCP_OOS_STR].bit[VALID_BIT              ],  // bit 2
                             STRNUM[TCP_OOS_STR].bit[TCP_OOS_CTRL_INST_1_BIT],  // bit 1
                             STRNUM[TCP_OOS_STR].bit[TCP_OOS_CTRL_INST_0_BIT];  // bit 0

Mov PC_STACK, END_OF_MACRO, 2;
MovBits byTempCondByte, uqGlobalStatusBitsReg.bit[POLICY_INSTANCE_0_BIT], 2; // Get instance bits from policy configuration

// Check OOS no search case
if (!byTempCondByte1.bit[2]) jmp END_OF_MACRO, NOP_2;

// Check OOS match case
if (!byTempCondByte1.bit[3]) jmp OOS_NO_MATCH, NOP_2;

// OOS match case - check policy instance:
And byTempCondByte, byTempCondByte, byTempCondByte1, 1, MASK_00000003, MASK_BOTH;
Mov ALU, 0, 4;

JNZ END_OF_MACRO_CNT, NOP_2;

// Get counter
If ( byTempCondByte.bit[0] ) GetRes ALU, TCP_OOS_RES_INST_0_CNT_OFF(TCP_OOS_STR), 2;
If ( byTempCondByte.bit[1] ) GetRes ALU, TCP_OOS_RES_INST_1_CNT_OFF(TCP_OOS_STR), 2;

// Validate counter should be > 0
Sub ALU, ALU, 0, 4;
Nop;

JG END_OF_MACRO_CNT, NOP_2;

OOS_NO_MATCH:

// OOS no match case

//check if syn-ack packet
Mov byTempCondByte1, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE0], 1;
if (!byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT]) jmp OOS_ACTION_LAB, NOP_2;

//skip if syn-ack allow mode is enabled
if (byTempCondByte1.bit[POLICY_OOS_SYNACK_STAT_BIT]) jmp END_OF_MACRO, NOP_2;


OOS_ACTION_LAB:

// Check SYN Cookie that was calculated in TOPparse
GetRes byTempCondByte, MSG_SYN_COOKIE_OFF(MSG_STR), 1;

if (byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_SYN_ACK_BIT]) jmp OOS_SYN_ACK_FR_ACTION, NOP_2;
if (byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_TCP_OOS_FIN_RST_BIT]) jmp OOS_SYN_ACK_FR_ACTION, NOP_2;
if (!byTempCondByte.bit[0]) jmp OOS_ACK_ACTION, NOP_2;


END_OF_MACRO_CNT:

// Temporary increment match counter (for debug only!)
EZstatIncrByOneIndexImm GS_OOS_MATCH;

// Update RTM and Policy match statistics
Mov uqTmpReg1, PC_STACK, 2, RESET;
jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
    Mov PC_STACK, OOS_MATCH_RTM_DONE_LAB, 2;
    MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;

indirect OOS_MATCH_RTM_DONE_LAB:
Mov PC_STACK, uqTmpReg1, 2;

indirect END_OF_MACRO:

ENDMACRO; // CheckOOSResult


// Macro OOS_Perform_Action
MACRO OOS_Perform_Action;

MovBits ENC_PRI.bit[9], byPolicyOOSActionReg.bit[POLICY_ID_BYTE3_OOS_ACT_OFF], 7;
Mov uqTmpReg2, 0, 4;

//mov 2 bits of threshold action to  bytmp0
//Add bytmp0, byTempCondByte2, 0, 1, MASK_00000003, MASK_SRC1;

//calculate counters block position
MovBits uqTmpReg2.bit[2], uxGlobalPolIdx.bit[0], 16;

//Mov byTempCondByte , uqTmpReg1.byte[0] , 1;
Mov uqTmpReg5, 0, 4;
Mov ALU, OS_BASE, 4;
Add uqTmpReg2, uqTmpReg2, ALU, 4;

GetRes byTempCondByte, MSG_SYN_COOKIE_OFF(MSG_STR), 1;

Mov byTempCondByte2, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE1], 1;
Mov byTempCondByte1, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE0], 1;

//perform actions by them priority
Jmul OOS_PERFORM_ERROR_LAB,
     OOS_PERFORM_ERROR_LAB,
     OOS_PERFORM_DROP_LAB,
     OOS_PERFORM_BYPASS_LAB,
     OOS_PERFORM_2CPU_LAB,
     OOS_PERFORM_NBYPASS_LAB,
     OOS_PERFORM_ERROR_LAB;
     Nop;
     Nop;

jmp OOS_PERFORM_CONT_LAB, NOP_2;


OOS_PERFORM_2CPU_LAB:
jmp SEND_TO_CPU, NOP_2;

OOS_PERFORM_NBYPASS_LAB:
// for bypass action for activation thresh not PT
jmp OOS_PERFORM_TP_DISABLE_LOCAL_LAB, NOP_2;

OOS_PERFORM_BYPASS_LAB:
// for bypass action PT is support
jmp OOS_PERFORM_TP_BPASS_DET_LAB;
    MovBits byTempCondByte.bit[0], 3, 2;
    // update for drop action since no more use
    MovBits byGlobalStatusBitsReg.bit[OOS_POLICY_PT_BIT], byPolicyOOSActionReg.bit[OOS_POLICY_PT_BYPASS_BIT], 1;

OOS_PERFORM_DROP_LAB:
MovBits byTempCondByte.bit[0], 1, 2;

OOS_PERFORM_TP_BPASS_DET_LAB:
Mov byTempCondByte2, uqGlobalStatusBitsReg.byte[POLICY_ID_BYTE1], 1;
nop;

OOS_PERFORM_BYPASS_DROP_SAMPLING:
if (!byGlobalStatusBitsReg.bit[OOS_POLICY_PT_BIT]) jmp OOS_PERFORM_TP_DISABLE_LOCAL_LAB, NOP_2;
jmp FRAME_TP_BYPASS_2NETW_LAB, NOP_2;


OOS_PERFORM_TP_DISABLE_LOCAL_LAB:
//Since toCPU support before stay drop with bypass and nbypass and drop will high priority
And ALU, byPolicyOOSActionReg, OOS_ACT_DROP, 1;
nop;

jz FRAME_BYPASS_NETWORK_LAB, NOP_2;
//temporary solution

OOS_PERFORM_ERROR_LAB:
Jmp FRAME_DROP_LAB, NOP_2;

OOS_PERFORM_CONT_LAB:

ENDMACRO; // OOS_Perform_Action



MACRO HighLearnTCPSessions;

vardef volatile regtype LEARN_KEY         UREG[ 0 ];
vardef volatile regtype INST_ID           byTempCondByte;

GetRes ALU, MSG_CONTROL_HW_MSG_SRC_PORT_OFF(MSG_STR), 1;
Sub ALU, ALU, PRT_CFG1, 1;  // Check whether control message arrived from Host instance (interface) 0 or 1
Mov $INST_ID, 0x0, 1;
Mov RMEM_OFFSET, 4, 1;

jz OOS_HL_CONT, NO_NOP;
   GetRes CNT, MSG_CONTROL_NUM_OF_COMMANDS(MSG_STR), 1;
   Nop;

Mov $INST_ID, 0x1, 1;

OOS_HL_CONT:

sub CNT, CNT, 1, 1;

READ_LOOP:
GetRes $LEARN_KEY, RMEM_OFFSET(CTRL_MSG_STR)+, 4;  // Read key (4 bytes) from control message
nop;
// for debug jmp CONT, NOP_2;
if ($LEARN_KEY.bit[31]) jmp DEL_ENTRY, NOP_2;      // If delete indication enabled (bit 31) go to delete label
PerformHighLearnADD $LEARN_KEY, $INST_ID;          // Add entry (perform learning through TOPlearn)
jmp CONT, NOP_2;

DEL_ENTRY:
Movbits $LEARN_KEY.bit[31], 0, 1;                  // Clear delete bit
PerformHighLearnDelete $LEARN_KEY, $INST_ID;       // Delete entry (perform learning through TOPlearn)

CONT:
Loop READ_LOOP, NOP_2;


FINISH_LEARN:


END_OF_MACRO:

varundef LEARN_KEY;
varundef INST_ID;

ENDMACRO; // HighLearnTCPSessions



// HighLearn add OOS entry using TOPlearn

MACRO PerformHighLearnAdd Key, instance;

#define VALID_MATCH_BITS_INIT_INST0  (1 << VALID_BIT) | (1 << MATCH_BIT) | (1 << TCP_OOS_CTRL_INST_0_BIT) | (1 << 16);
#define VALID_MATCH_BITS_INIT_INST1  (1 << VALID_BIT) | (1 << MATCH_BIT) | (1 << TCP_OOS_CTRL_INST_1_BIT);

    If (instance) jmp OOS_HL_ADD_INST_1, NOP_1;
         Mov ALIAS_LRN_REG,  OOS_ADD_HEADER,     4;     // OOS learn header

    // Prepare result in case message received from instance 0
    OOS_HL_ADD_INST_0:
    jmp OOS_HL_ADD_CONT, NO_NOP;
         Mov uqTmpReg4, VALID_MATCH_BITS_INIT_INST0,  4;
         Mov uqTmpReg5, 0x0,  4;

    // Prepare result in case message received from instance 1
    OOS_HL_ADD_INST_1:
    Mov uqTmpReg4, VALID_MATCH_BITS_INIT_INST1,  4;
    Mov uqTmpReg5, 0x1,  4;

    // Write key & result to TOPlearn registers
    OOS_HL_ADD_CONT:
    EZwaitFlag  F_LN_RSV;
    Mov ALIAS_LRN_REG, uqTmpReg4, 4;  // Result bytes [0..3]
    Mov ALIAS_LRN_REG, uqTmpReg5, 4;  // Result bytes [4..7]
    Mov ALIAS_LRN_REG, Key,       4;  // Key    bytes [0..3]

#undef VALID_MATCH_BITS_INIT_INST0;
#undef VALID_MATCH_BITS_INIT_INST1;

ENDMACRO; // PerformHighLearnAdd



// HighLearn delete OOS entry using TOPlearn

MACRO PerformHighLearnDelete Key, instance;

    If (instance) jmp OOS_HL_DELETE_INST_1, NOP_2;

    // Prepare learn header in case message received from instance 0
    OOS_HL_DELETE_INST_0:
    jmp OOS_HL_DELETE_CONT, NO_NOP;
      	Mov ALIAS_LRN_REG, OOS_DEL_INST_0_HEADER, 4;
      	Nop;

    // Prepare learn header in case message received from instance 1
    OOS_HL_DELETE_INST_1:
    Mov ALIAS_LRN_REG, OOS_DEL_INST_1_HEADER, 4;
    Nop;

    // Write key to TOPlearn registers
    OOS_HL_DELETE_CONT:
    EZwaitFlag  F_LN_RSV;
    Mov ALIAS_LRN_REG, Key, 4;  // Key    bytes [0..3]

ENDMACRO; // PerformHighLearnDelete




/*******************************************************************************
*
* Inputs - Priority encoder with precalculated action
*/
MACRO policyPerformActionLab SIG_OFFSET;

POLICY_PERFORM_ACTION_LOCAL_LAB:

#define bySigNum  bytmp0; //1 byte, defines signature num

Jmul SKIP_LONG_LAB,
     POLICY_BDOS_LAB,
     POLICY_OOS_LAB,
     RESET;
     nop;
     nop;

//nop;
//Mov uqTmpReg5.byte[0],ENC_PRI,1;

SKIP_LONG_LAB:

// Don't increment rtm per policy for default policy case
if ( byGlobalStatusBitsReg.bit[POLICY_CONT_ACT_BIT] ) jmp SEND_PACKET_LAB_CPU, NOP_2;

jmp rtmCountersPerPolicyUpdate_LAB, NO_NOP;
   Mov PC_STACK, AFTER_POLICY, 2;
   MovBits byGlobalStatusBitsReg.bit[RTM_RECIVE_DROP_IND_BIT], 1, 1;


//10 bytes per policy mask
POLICY_OOS_LAB:

MovBits byFcfgTmpStorage , ENC_PRI.bit[13] , 3;

CheckOOSResult;

Sub ALU, byFcfgTmpStorage, 0, 1;
MovBits ENC_PRI.bit[6], 0, 2;

jnz BDOS_CONT_LAB, NOP_2;

//OOS beheviour different from BDOS. Even DROP action doesn't destroyed loop
//need special treatment here

// Finish policy evaluation
Jmp AFTER_POLICY, NOP_2;


BDOS_CONT_LAB:
   jmp  POLICY_PERFORM_ACTION_LOCAL_LAB, NO_NOP;
      //restore main priority encoder
      //Mov ENC_PRI,uqTmpReg5.byte[0],1;
      MovBits ENC_PRI.bit[13], byFcfgTmpStorage.bit[0], 3;
      MovBits byGlobalStatusBitsReg.bit[POLICY_LOOP_IND_BIT], 1, 1;


POLICY_BDOS_LAB:
   // Perform and between sinagnature config and controller signature bitmasks
   And uqBdosL4ValidBitsReg, uqGlobalSignaBitsReg, uqBdosL4ValidBitsReg, 4;
   Nop;
   JZ POLICY_PERFORM_ACTION_LOCAL_LAB, NOP_2;

   Encode bySigNum, uqBdosL4ValidBitsReg, 4;
   MovBits byFcfgTmpStorage, ENC_PRI.bit[13], 3;

POLICY_BDOS_LOOP:

//   AnalyzeBdosResult bySigNum, SIG_OFFSET;

   // clear evaluated signature num in the bitmask
   Decode ALU, bySigNum, 4;
   Xor uqBdosL4ValidBitsReg, uqBdosL4ValidBitsReg, ALU, 4;
   //restore main priority encoder
   MovBits ENC_PRI.bit[13], byFcfgTmpStorage.bit[0], 3;

   JNZ POLICY_BDOS_LOOP, NO_NOP;
      Encode bySigNum, uqBdosL4ValidBitsReg, 4;
      MovBits byFcfgTmpStorage, ENC_PRI.bit[13], 3;

   jmp  POLICY_PERFORM_ACTION_LOCAL_LAB, NOP_2;


#undef bySigNum;

ENDMACRO; // policyPerformActionLab

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
