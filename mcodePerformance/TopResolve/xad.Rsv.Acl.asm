/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Rsv.Acl.asm
*
*  Usage:         Access List macro file that handles TOPresolve processing of ACL lookup result
*
*******************************************************************************/

 
MACRO xadAccessListResolve BYPASS_HOST_LAB,     //FRAME_BYPASS_HOST_LAB
                           BYPASS_NETW_LAB,     //FRAME_BYPASS_NETWORK_LAB
                           CONT_LAB,            //BDOS_OOS_PERFORM_LAB
                           ERR_LAB,             //FRAME_DROP_LAB
                           TP_BYPASS,           //FRAME_TP_BYPASS_2NETW_LAB
                           DROP_NETW_LAB;       //FRAME_DROP_LAB

// 1. Check if AccessList is empty or not matched (in both cases continue to next feature):
if (!byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_ALST_EMPTY_BIT]) jmp CONT_LAB; // If AccessList is empty continue to next feature, meaning ACL functionality is not enabled.
    mov byTempCondByte1, byFrameActionReg, 1;
    Nop;

GetRes uqTmpReg2, 0(ALST_RES_STR), 4;
Mov ENC_PRI, 0, 2;
Sub ALU, uqTmpReg2.byte[0], 0x11, 1;   // Check for Match + Valid in AccessList result structure
MovBits ENC_PRI.bit[13], 1, 3;         // Set default action to drop
js CONT_LAB, NOP_2;  // If no Match or Valid in AccessList result structure (i.e. no rule should be applied on the current packet) continue to next feature
//TODO: change js to something better - AND with MREG or Mask (or 2 if's in 2 clocks - check valid then match)

// 2. Check if entry is whitelist and if so act accordingly (bypass):
GetRes uqTmpReg5, ALST_RES_ENTRY_ID_OFF(ALST_RES_STR), 4;   // Get AccessList entry ID
Mov ALU, ALIST_BASE, 4;    // Init AccessList counters base
Add uqTmpReg5, ALU, uqTmpReg5, 4; 
xor byTempCondByte, ALU, !ALU, 1, GC_CNTRL_1_MREG, MASK_BOTH;    // Get GC_CNTRL_1 MREG Value                                                        
Sub ALU, uqTmpReg2.byte[ALST_RES_ENTRY_TYPE_OFF], 0, 1;     // Get AccessList entry type: 0x00 - blacklist (drop), 0x80 - whitelist (bypass)
    GetRes uqTmpReg4, MSG_CONTROL_HW_MSG_FR_LEN_OFF(MSG_STR), 2, RESET;

// Check action type, if result is not zero (i.e. whitelist) - change action to bypass (from 'drop' set before)
if (!FLAGS.bit[F_ZR]) jmp ALIST_BYPASS_DISCARD_LAB, NO_NOP;
   if (!FLAGS.bit[F_ZR]) MovBits ENC_PRI.bit[13], 2, 3;
   MovBits uqTmpReg4.byte[2].bit[0], 0x1, 1; //set 1 in uqTmpReg4[16:31] to indicate 1 frame received

// 3. Blacklist handling - check for sampling and handle accordingly, otherwise drop:
if (!byTempCondByte.bit[GC_CNTRL_1_ALIST_SAMPLENABLED_BIT]) jmp ALIST_BYPASS_DISCARD_LAB, NOP_2;    // If sampling not enabled continue to drop packet

// 4. Handle sampling (only for blacklisted packets):
EZstatPutDataSendCmdIndexImm  ALIST_SAM_TB, IMM_SAMP_SIZE_CONST, STS_GET_COLOR_CMD;  // Check if we below sampling rate

nop;
nop;
EZwaitFlag F_SR;

and ALU, STAT_RESULT_L, RED_COLOR_MASK_VAL, 1;
nop;

// If we have exceeded sampling rate for current packet - drop it (since this is a blacklisted packet)
jnz ALIST_BYPASS_DISCARD_LAB, NOP_2;

// If this packet is jumbo frame - drop it (even if sampling is required)
if (byCtrlMsgPrs0.bit[MSG_CTRL_TOPPRS_0_JUMBO_STATUS_BIT]) jmp ALIST_BYPASS_DISCARD_LAB, NOP_2;

// Increment sampling counter
EZstatIncrIndexReg ALIST_SAMP_CPU, 1;


//no change in the flow for RTPC
If (RTPC_IS_ENABLED_BIT) 
   Mov uxEthTypeMetaData, RTPC_BLACK_LIST_LEGIT , 2;

                                                                                 
// Forward packet to host
jmp BYPASS_HOST_LAB, NO_NOP;                        
   Movbits byGlobalStatusBitsReg.bit[ALIST_SAMPL_BIT], 1, 1;
   MovBits byCtrlMsgRsv0.bit[MSG_CTRL_TOPRSV_0_ALIST_SAMPL_BIT], 1, 1;

// 5. Bypass or drop according to decision in previous steps:       
ALIST_BYPASS_DISCARD_LAB:

EZstatPutDataSendCmdIndexReg uqTmpReg5, uqTmpReg4, STS_INCR_TWO_VAL_CMD, 0, 0, 1;

Jmul ERR_LAB,
     BYPASS_NETW_LOC_LAB, 
     ALIST_DISCARD_LAB,
     NOP_2;


BYPASS_NETW_LOC_LAB:
       

//check RTPC enable
If (RTPC_IS_ENABLED_BIT) 
   
   //don't change the flow                     
   mov uxEthTypeMetaData, RTPC_WHITE_BYPASS, 2;  


if (!bitRSV_isRoutingMode) jmp FFT_TABLE_TXCOPY_END_LAB;
    PutHdr HREG[ COM_HBS ], RSV_FFT_ALST_LKP_HDR;
    Copy KMEM_OFFSET ( HW_OBS ),  MSG_VIF_OFF(MSG_STR), 1;

GetRes uqTmpReg6 , 0(INT_TCAM_STR), 3 ;
PutHdr HREG[ COM_HBS ], RSV_ROUTE_ALST_LKP_HDR;
and ALU, uqTmpReg6.byte[1], uqTmpReg6.byte[1] , 2, MASK_000007FF, MASK_BOTH;    
Nop;
PutKey KMEM_OFFSET ( HW_OBS ),  ALU, 2;

FFT_TABLE_TXCOPY_END_LAB:
Add COM_HBS  , COM_HBS ,  1 , 1;

jmp BYPASS_NETW_LAB; // Continue to bypass action
    MovBits byTemp3Byte0.bit[CTX_LINE_OUT_IF]  , 1 , 1;
    Add KMEM_OFFSET , KMEM_OFFSET , RSV_FFT_RX_COPY_PORT_LKP_KEY_SIZE_KMEM_ALIGN , 1;
    


ALIST_DISCARD_LAB:


//check if RTPC is enabled and matched.
If (RTPC_IS_ENABLED_BIT)  mov uxEthTypeMetaData, RTPC_BLACK_LIST_DROP , 2;//set RTPC without changing the flow
If (RTPC_IS_ENABLED_BIT)  movBits RTPC_IS_DOUBLE_COUNT_BIT, 0, 1;
   xor byTempCondByte, ALU, !ALU, 1, GC_CNTRL_2_MREG, MASK_BOTH; // Get GC_CNTRL_2_MREG Value

 

// If GC_CNTRL_2_ALST_TP_ACTION_OFFSET bit enabled (Packet Trace) continue to TP handling, otherwise drop packet
jmp DROP_NETW_LAB, NOP_1;
   if (byTempCondByte.bit[GC_CNTRL_2_ALST_TP_ACTION_OFFSET]) jmp TP_BYPASS, NOP_2;   


ENDMACRO;

