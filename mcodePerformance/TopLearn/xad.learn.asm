/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Lrn.asm
*
*  Usage:         TOPlearn main file
*
*******************************************************************************/

EZTop Learn ;


#include "EZlearn.h"
#include "EZstat.h"

#include "xad.common.h"
Export   "lrn_labels.h";


#define OOS_FRAME_CNT_OFF           4;  // 4 bytes - don't change, used in learn
#define BW_CMD_SIZE_1               0;
#define OOS_CNTR_NEG_VAL            0xFFFF;
#define OOS_DATA_CNTR_INST0         ((1 << VALID_BIT) | (1 << MATCH_BIT) | (1 <<TCP_OOS_CTRL_INST_0_BIT));
#define OOS_DATA_CNTR_INST1         ((1 << VALID_BIT) | (1 << MATCH_BIT) | (1 <<TCP_OOS_CTRL_INST_1_BIT));

// Bitwise Stat Operations Data Register Bit Offsets
#define BW_OP_DATA_VALUE_BIT        0;  // 16 bits
#define BW_OP_DATA_SIZE_BIT         16; // 3 bits
#define BW_OP_DATA_OFFSET_BIT       19; // 6 bits
#define BW_OP_DATA_RESERVED_BIT     25; // 7 bits


/******************************************************************************
                           Statistics Memory Management
*******************************************************************************/
// 0-1023:          Group 0 - Long counters

// 1024-1279 (256): Group 1 - Bitwise counters
#define CNT_SEMAPHORE_BASE          1024;

/******************************************************************************
   Global VarDefs and Variables Defines
*******************************************************************************/
vardef volatile regtype byTempCondByte UDB;
vardef volatile regtype LEARN_RESULT   CTX_LOW[0:7];
vardef volatile regtype LOOKUP_RESULT  CTX_LOW[8:15];

#define uqCntrData0    UREG[0];
#define uqCntrData1    UREG[1];


/******************************************************************************
   Mask Registers definition and loading
*******************************************************************************/
#define M_0x00000003                MREG[ 0 ];
#define M_0x00000060                MREG[ 1 ];
LdReg MREG[ 0 ], 0x00000003;
LdReg MREG[ 1 ], 0x00000060;

/*******************************************************************************/

        
L_LRN_START:
   jstack;
      nop;
      nop;

/******************************************************************************/

public L_LRN_CREATE_OR_UPDATE_OOS_ENTRY:

   // Add a new entry or update an existing entry in OOS table according to given key & result from TOPresolve

   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_CREATE_OR_UPDATE_OOS_ENTRY_AFTER_LKP, 2;
      mov IF_HEADER, LRN_CMD_LOOKUP_CONT,                        2;  // Lookup and put result in LKP_RESULT0-7 (IF_HEADER bits[0..3] = 0000)


L_LRN_CREATE_OR_UPDATE_OOS_ENTRY_AFTER_LKP:

   // If entry already exists go to "update" case, else go to "create"
   if (FLAGS.bit[ F_LKP_M_LRN ]) jmp L_LRN_UPDATE_OOS_ENTRY_AFTER_LKP, NOP_2;
              
   // "Create" case:
   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_RELEASE_SEMAPHORE, 2; // After learning, release semaphore
      mov IF_HEADER, LRN_CMD_ADD_PUSH_END,    2; // Add entry (learn data is taken from LRN_RESULT0-7) + push result to LRN_RESULT0-7 + finish (IF_HEADER bits[0..3] = 0001, bits[10..13] = 1100)


L_LRN_UPDATE_OOS_ENTRY_AFTER_LKP:

   // "Update" case:
   Mov $byTempCondByte.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ], $LEARN_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ], 1;

   Or  $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ], $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ], $LEARN_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ], 1;

   // Add existing entry counter per instance to learned value (0 or 1, according to instance)
   Add $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ], $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ], $LEARN_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ], 2;
   Add $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ], $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ], $LEARN_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ], 2;

#pragma EZ_Warnings_Off;
   // validate if counter is zero
   If ( !$byTempCondByte.bit[TCP_OOS_CTRL_INST_0_BIT] ) jmp L_LRN_UPDATE_OOS_ENTRY_AFTER_LKP_INST_1, NO_NOP; 
      Sub ALU, $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ], 0, 2;
      Nop;
   // This is an instance 0, check counter
   JNZ L_LRN_UPDATE_OOS_ENTRY_AFTER_LKP_CONT, NOP_2;

   Jmp L_LRN_DELETE_EXISTING_OOS_ENTRY, NO_NOP;
      MovBits $byTempCondByte.bit[TCP_OOS_CTRL_INST_0_BIT], 0, 1;
      MovBits $LOOKUP_RESULT.bit [TCP_OOS_CTRL_INST_0_BIT], 0, 1;

L_LRN_UPDATE_OOS_ENTRY_AFTER_LKP_INST_1:
   // This is an instance 1, check counter
   Sub ALU, $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ], 0, 2;
   Nop;

   JNZ L_LRN_UPDATE_OOS_ENTRY_AFTER_LKP_CONT, NOP_2;

   Jmp L_LRN_DELETE_EXISTING_OOS_ENTRY, NO_NOP;
      MovBits $byTempCondByte.bit[TCP_OOS_CTRL_INST_1_BIT], 0, 1;
      MovBits $LOOKUP_RESULT.bit [TCP_OOS_CTRL_INST_1_BIT], 0, 1;
  
L_LRN_UPDATE_OOS_ENTRY_AFTER_LKP_CONT: 
#pragma EZ_Warnings_On;

   // already incremented counter in TOPresolve and put it into Learn Result
   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_RELEASE_SEMAPHORE, 2; // After learning, release semaphore
      mov IF_HEADER, LRN_CMD_OVRW_PUSH_END,   2; // Update entry (OVERWRITE, learn data is taken from LKP_RESULT0-7) + push result to LKP_RESULT0-7 + finish (IF_HEADER bits[0..3] = 0011, bits[10..13] = 1000)

                               

/******************************************************************************/

public L_LRN_DELETE_OOS_ENTRY_INST_0:


   // Delete or update counter in an existing entry in OOS table according to given key from TOPresolve

   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_DELETE_OOS_ENTRY_AFTER_LKP_INST_0, 2;
      mov IF_HEADER, LRN_CMD_LOOKUP_CONT, 2;   // Lookup and put result in LKP_RESULT0-7 (IF_HEADER bits[0..3] = 0000)


L_LRN_DELETE_OOS_ENTRY_AFTER_LKP_INST_0:

   // If entry exists decrement 1 from instance counter
   if (FLAGS.bit[ F_LKP_M_LRN ]) Sub $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ], $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ] , 1, 2;
   if (FLAGS.bit[ F_LKP_M_LRN ]) Mov $byTempCondByte.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ], $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF  ] , 1;

   // If entry exist but instance 0 bit is off set to on. Counter should be -1;
   if (FLAGS.bit[ F_LKP_M_LRN ]) MovBits $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ].bit[TCP_OOS_CTRL_INST_0_BIT], 1, 1;

   // If entry exists go to "delete" case, else go to "continue"
   if (FLAGS.bit[ F_LKP_M_LRN ]) jmp L_LRN_DELETE_EXISTING_OOS_ENTRY, NO_NOP;
      If (FLAGS.bit[F_ZR]) MovBits $byTempCondByte.bit[TCP_OOS_CTRL_INST_0_BIT], 0, 1;           // If instance counter == 0 -> mark that instance bit is 0
      If (FLAGS.bit[F_ZR]) MovBits $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ].bit[TCP_OOS_CTRL_INST_0_BIT], 0, 1;  // If instance counter == 0 -> turn instance bit off

#pragma EZ_Warnings_Off;
   // "Continue" case: delete none existing entry may be happen since out of order problem
   Mov uqCntrData0, OOS_CNTR_NEG_VAL, 4;
   Mov uqCntrData1, 0, 4;
   Mov $LEARN_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF  ], OOS_DATA_CNTR_INST0, 1;  // set valid match bit and instance 0

   jmp L_LRN_CREATE_OR_UPDATE_OOS_ENTRY_AFTER_LKP, NO_NOP;
      Mov $LEARN_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ], uqCntrData0, 2;       // set counter instance 0 to -1
      Mov $LEARN_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ], uqCntrData1, 2;       // set counter instance 1 to  0
#pragma EZ_Warnings_On;

   // Will be never work
   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_RELEASE_SEMAPHORE, 2; // After learning, release semaphore
      mov IF_HEADER, LRN_CMD_CONT,            2; // Continue - end the current context but return to it later (IF_HEADER bits[0..3] = 1000)



public L_LRN_DELETE_OOS_ENTRY_INST_1:

   // Delete or update counter in an existing entry in OOS table according to given key from TOPresolve

   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_DELETE_OOS_ENTRY_AFTER_LKP_INST_1, 2;
      mov IF_HEADER, LRN_CMD_LOOKUP_CONT, 2;   // Lookup and put result in LKP_RESULT0-7 (IF_HEADER bits[0..3] = 0000)


L_LRN_DELETE_OOS_ENTRY_AFTER_LKP_INST_1:

   // If entry exists decrement 1 from instance counter
   if (FLAGS.bit[ F_LKP_M_LRN ]) Sub $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ], $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ] , 1, 2;
   if (FLAGS.bit[ F_LKP_M_LRN ]) Mov $byTempCondByte.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ], $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF  ] , 1;

   // If entry exist but instance 1 bit is off set to on. Counter should be -1;
   if (FLAGS.bit[ F_LKP_M_LRN ]) MovBits $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ].bit[TCP_OOS_CTRL_INST_1_BIT], 1, 1;

   // If entry exists go to "delete" case, else go to "continue"
   if (FLAGS.bit[ F_LKP_M_LRN ]) jmp L_LRN_DELETE_EXISTING_OOS_ENTRY, NO_NOP;
      If (FLAGS.bit[F_ZR]) MovBits $byTempCondByte.bit[TCP_OOS_CTRL_INST_1_BIT], 0, 1;           // If instance counter == 0 -> mark that instance bit is 0
      If (FLAGS.bit[F_ZR]) MovBits $LOOKUP_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF ].bit[TCP_OOS_CTRL_INST_1_BIT], 0, 1;  // If instance counter == 0 -> turn instance bit off

   // "Continue" case: delete none existing entry may be happen since out of order problem
#pragma EZ_Warnings_Off;
   Mov uqCntrData0, OOS_CNTR_NEG_VAL, 4;
   Mov uqCntrData1, 0, 4;
   Mov $LEARN_RESULT.BYTE[ TCP_OOS_RES_CTRL_BITS_OFF  ], OOS_DATA_CNTR_INST1, 1;  // set valid match bit and instance 0

   jmp L_LRN_CREATE_OR_UPDATE_OOS_ENTRY_AFTER_LKP, NO_NOP;
      Mov $LEARN_RESULT.BYTE[ TCP_OOS_RES_INST_0_CNT_OFF ], uqCntrData1, 2;       // set counter instance 0 to -1
      Mov $LEARN_RESULT.BYTE[ TCP_OOS_RES_INST_1_CNT_OFF ], uqCntrData0, 2;       // set counter instance 1 to  0
#pragma EZ_Warnings_On;

   // Will be never work
   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_RELEASE_SEMAPHORE, 2; // After learning, release semaphore
      mov IF_HEADER, LRN_CMD_CONT,            2; // Continue - end the current context but return to it later (IF_HEADER bits[0..3] = 1000)


L_LRN_DELETE_EXISTING_OOS_ENTRY:
   
   // "Delete" case:

   // If instance bit 0 or 1 are enabled - do not delete this entry, only update. Otherwise (both are 0) delete the entry
   If ($byTempCondByte.bit[TCP_OOS_CTRL_INST_0_BIT]) jmp L_LRN_UPDATE_EXISTING_OOS_ENTRY, NOP_2;
   If ($byTempCondByte.bit[TCP_OOS_CTRL_INST_1_BIT]) jmp L_LRN_UPDATE_EXISTING_OOS_ENTRY, NOP_2;

   // Delete entry: OOS_FRAME_CNT_OFF < 0, so there are no other duplicates on this entry 
   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_RELEASE_SEMAPHORE, 2; // After learning, release semaphore
      mov IF_HEADER, LRN_CMD_DEL_END,         2; // Delete entry from the structure (IF_HEADER bits[0..3] = 0010)

L_LRN_UPDATE_EXISTING_OOS_ENTRY:

   // Update entry (instead of delete)
   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_RELEASE_SEMAPHORE, 2; // After learning, release semaphore
      mov IF_HEADER, LRN_CMD_OVRW_PUSH_END,   2; // Update entry (OVERWRITE, learn data is taken from LKP_RESULT0-7) + push result to LKP_RESULT0-7 + finish (IF_HEADER bits[0..3] = 0011, bits[10..13] = 1000)
   

/******************************************************************************/

L_LRN_RELEASE_SEMAPHORE:
   // Statistics operations from a learn machine:
   //    UREG[0] bits 23:0  – address
   //    UREG[0] bits 29:24 – statistics command opcode
   //    UREG[1] bits 31:0  – write data0
   //    UREG[2] bits 31:0  – write data1
   //    Result written to UREG[0]-[1].

#ifdef __global_implemented_top_resolve__

vardef regtype by3Address     UREG[ 0 ].BYTE[ 0:2 ];
vardef regtype byCommand      UREG[ 0 ].BYTE[ 3 ];
vardef regtype uqStatData     UREG[ 1 ];

mov ALU, CNT_SEMAPHORE_BASE, 4;

#pragma EZ_Warnings_Off;

// "pragma" used here to prevent warning of EZasm - "warning: register boundary exceeded in variable: LEARN_RESULT"

// add $by3Address, ALU, $LEARN_RESULT.BYTE[ MAC_HASH_KEY_OFF ], 3, M_0x00000003, MASK_SRC2;
   Mov $by3Address, ALU , 3;

#pragma EZ_Warnings_On;                      

   mov     $byCommand, STS_BW_CLR_CMD, 1;   
   mov     $uqStatData.bit[ BW_OP_DATA_VALUE_BIT  ], 1, 4;  // put value 1 to bits 0-15, init the rest
   movbits $uqStatData.bit[ BW_OP_DATA_SIZE_BIT   ], BW_CMD_SIZE_1, 3;
   movbits $uqStatData.bit[ BW_OP_DATA_OFFSET_BIT ], 0, 6;
// movbits $uqStatData.bit[ BW_OP_DATA_OFFSET_BIT ], $LEARN_RESULT.BYTE[ OOS_HASH_KEY_OFF ].bit[ 2 ], 6;

varundef by3Address;
varundef byCommand;
varundef uqStatData;




   jmp L_LRN_START, NO_NOP;
      mov NEXT_PC,   L_LRN_END,               2;
      mov IF_HEADER, LRN_CMD_STATISTICS_CONT, 2;

#endif

L_LRN_END:
   jmp L_LRN_START, NO_NOP;
      mov IF_HEADER, LRN_CMD_END, 2;
      nop;

varundef LEARN_RESULT ;
varundef LOOKUP_RESULT ;
   
/******************************************************************************/
