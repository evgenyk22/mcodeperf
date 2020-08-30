/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Srh.Macros.asm
*
*  Usage:         xad.Srh.asm macro file
*
*******************************************************************************/

#include "EZsearch.h"
#include "xad.common.h"
Export   "src_labels.h";


Macro Policy_Treat;

L_POLICY_SIP_LKP_IN_TCAM:

   // Lookup with Policy full key in External TCAM
   LookupTCAM TREG[TREG_TCAM_RESULT_OFF], EXT_TCAM_STR, 
              TREG[CMP_POLICY_SIP_OFF    ], 32,
              TREG[CMP_POLICY_VLAN_OFF   ], 8,
              PROFILE 1, NO_WR_LAST;

   WriteCond COND_REG, TREG[TREG_TCAM_RESULT_OFF].bit[4], SET_MATCH_BIT;
   JCond;
   JNoMatch L_POLICY_SIP_NO_MATCH_IN_TCAM;

   // If match in TCAM use result index as key for lookup in Policy result table (contains Policy Id) 
   Lookup OREG, POLICY_RES_STR,
			 TREG[TREG_TCAM_IDX_OFF], POLICY_RES_KEY_SIZE,
          TREG[TREG_TCAM_IDX_OFF], 0,
          WR_LAST;

   Halt;
   
      
L_POLICY_SIP_NO_MATCH_IN_TCAM:

   // If there is no match Policy for full key - set valid + no match bit
   MovImm TREG[TREG_TCAM_RESULT_OFF], 0x1, 4; 

   // Write no match result
   Write OREG, POLICY_RES_STR, 
         TREG[TREG_TCAM_RESULT_OFF], POLICY_RES_RES_SIZE,
         WR_LAST; 

   Halt;

endmacro;


// Macro: Attack_IPV4_Treat
// Lookups in the L3 attack structures
Macro Attack_IPV4_Treat STRUCT_OFFSET;

#define tmp_L3_LENGTH_STR    (STRUCT_OFFSET + L3_LENGTH_STR   ) // STR 14
#define tmp_SIP_STR          (STRUCT_OFFSET + SIP_STR         ) // STR 14
#define tmp_DIP_STR          (STRUCT_OFFSET + DIP_STR         ) // STR 14
#define tmp_L4PROT_STR       (STRUCT_OFFSET + L4PROT_STR      ) // STR 14
#define tmp_TOS_STR          (STRUCT_OFFSET + TOS_STR         ) // STR 14
#define tmp_TTL_STR          (STRUCT_OFFSET + TTL_STR         ) // STR 14
#define tmp_IPID_STR         (STRUCT_OFFSET + IPID_STR        ) // STR 14
#define tmp_FRGFLG_STR       (STRUCT_OFFSET + FRGFLG_STR      ) // STR 14
#define tmp_FRGOFF_STR       (STRUCT_OFFSET + FRGOFF_STR      ) // STR 14
#define tmp_SIGNA_CNTRL_STR  (STRUCT_OFFSET + SIGNA_CNTRL_STR ) // STR 14

#if 0 // close BDOS code

// Init BDOS result structure
xor TREG[ TREG_TEMP_BDOS_KEY_TYP_OFF      ], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 4 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 8 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 12}], TREG[0], TREG[0], 4; 

// Sets Valid+Match bits (0,4) in result to '1'
//CMP TREG[TREG_BDOS_RES_OFF], TREG[0], TREG[0], 1;
MovImm TREG[TREG_BDOS_RES_OFF], (1 << MATCH_BIT) | (1 << VALID_BIT), 1;


LookupAttackField tmp_SIP_STR, CMP_BDOS_L23_SIP_OFF,
                  CMP_BDOS_L23_SIP_SIZE, SIP_RES_POS, SIP_RES_OFF, SIP_VALIDATION_BIT, SIP_FLD_TYP;

LookupAttackField tmp_DIP_STR, CMP_BDOS_L23_DIP_OFF,
                  CMP_BDOS_L23_DIP_SIZE, DIP_RES_POS, DIP_RES_OFF, DIP_VALIDATION_BIT, DIP_FLD_TYP;

LookupAttackField tmp_TOS_STR, CMP_BDOS_L23_TOS_OFF,
                  CMP_BDOS_L23_TOS_SIZE, TOS_RES_POS, TOS_RES_OFF, TOS_VALIDATION_BIT, TOS_FLD_TYP;

LookupAttackField tmp_IPID_STR, CMP_BDOS_L23_ID_NUM_OFF, 
                  CMP_BDOS_L23_ID_NUM_SIZE, IPID_RES_POS, IPID_RES_OFF, IPID_VALIDATION_BIT, IPID_FLD_TYP;

LookupAttackField tmp_TTL_STR, CMP_BDOS_L23_TTL_OFF,
                  CMP_BDOS_L23_TTL_SIZE, TTL_RES_POS, TTL_RES_OFF, 7, TTL_FLD_TYP;

LookupAttackField tmp_FRGFLG_STR, CMP_BDOS_L23_FRGMNT_FLG_OFF, 
                  CMP_BDOS_L23_FRGMNT_FLG_SIZE, FRGFLG_RES_POS, FRGFLG_RES_OFF, 7, FRGFLG_FLD_TYP;

// Write first part L23 results
Write OREG, BDOS_ATTACK_RESULTS_L23_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE;

LookupAttackField tmp_FRGOFF_STR, CMP_BDOS_L23_FRGMNT_OFF, 
                  CMP_BDOS_L23_FRGMNT_SIZE, FRGOFF_RES_POS, FRGOFF_RES_OFF, FRGOFF_VALIDATION_BIT, FRGOFF_FLD_TYP;

LookupAttackField tmp_L4PROT_STR, CMP_BDOS_L23_L4_PROT_OFF, 
                  CMP_BDOS_L23_L4_PROT_SIZE, L4PROT_RES_POS, L4_PROT_RES_OFF, L4PROT_VALIDATION_BIT, L4PROT_FLD_TYP;

LookupAttackField tmp_L3_LENGTH_STR, CMP_BDOS_L23_L3_SIZE_OFF, 
                  CMP_BDOS_L23_L3_SIZE_SIZE, L3_LENGTH_RES_POS, IPV4_L3_LENGTH_RES_OFF, L3_LENGTH_VALIDATION_BIT, L3_LENGTH_FLD_TYP;

// lookup for signature controller
LookupAttackField tmp_SIGNA_CNTRL_STR, CMP_BDOS_L23_SIGNA_CNTRL_OFF,
                  CMP_BDOS_L23_SIGNA_CNTRL_SIZE, SIGNA_CNTRL_RES_POS, SIGNA_CNTRL_RES_OFF, 7, SIGNA_CNTRL_FLD_TYP;

#endif

#undef tmp_L4PROT_STR;
#undef tmp_SIP_STR;
#undef tmp_DIP_STR;
#undef tmp_TOS_STR;
#undef tmp_IPID_STR;
#undef tmp_TTL_STR;
#undef tmp_FRGFLG_STR;
#undef tmp_FRGOFF_STR;
#undef tmp_L3_LENGTH_STR;
#undef tmp_SIGNA_CNTRL_STR;

endmacro;


Macro Attack_IPV6_Treat STRUCT_OFFSET;

#define tmp_L3_LENGTH_STR          (STRUCT_OFFSET + L3_LENGTH_STR          ) // STR 14
#define tmp_IPV6_SIP_STR           (STRUCT_OFFSET + IPV6_SIP_STR           ) // STR 14
#define tmp_IPV6_DIP_STR           (STRUCT_OFFSET + IPV6_DIP_STR           ) // STR 14
#define tmp_IPV6_HOP_LIMIT_STR     (STRUCT_OFFSET + IPV6_HOP_LIMIT_STR     ) // STR 14
#define tmp_IPV6_TRAFFIC_CLASS_STR (STRUCT_OFFSET + IPV6_TRAFFIC_CLASS_STR ) // STR 14
#define tmp_IPV6_FLOW_LABEL_STR    (STRUCT_OFFSET + IPV6_FLOW_LABEL_STR    ) // STR 14
#define tmp_IPV6_FRGID_STR         (STRUCT_OFFSET + IPV6_FRGID_STR         ) // STR 14
#define tmp_IPV6_FRGFLG_STR        (STRUCT_OFFSET + IPV6_FRGFLG_STR        ) // STR 14
#define tmp_IPV6_FRGOFF_STR        (STRUCT_OFFSET + IPV6_FRGOFF_STR        ) // STR 14
#define tmp_SIGNA_CNTRL_STR        (STRUCT_OFFSET + SIGNA_CNTRL_STR        ) // STR 14

#if 0 // close BDOS code

// Init BDOS result structure
xor TREG[ TREG_TEMP_BDOS_KEY_TYP_OFF      ], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 4 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 8 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 12}], TREG[0], TREG[0], 4; 

// Sets Valid+Match bits (0,4) in result to '1'
//CMP TREG[TREG_BDOS_RES_OFF], TREG[0], TREG[0], 1;
MovImm TREG[TREG_BDOS_RES_OFF], (1 << MATCH_BIT) | (1 << VALID_BIT), 1;


LookupAttackField tmp_IPV6_DIP_STR, CMP_BDOS_L23_IPV6_DIP_OFF,
                  CMP_BDOS_L23_IPV6_DIP_SIZE, IPV6_DIP_RES_POS, IPV6_DIP_RES_OFF, IPV6_DIP_VALIDATION_BIT, IPV6_DIP_FLD_TYP;

LookupAttackField tmp_IPV6_SIP_STR, CMP_BDOS_L23_IPV6_SIP_OFF,
                  CMP_BDOS_L23_IPV6_SIP_SIZE, IPV6_SIP_RES_POS, IPV6_SIP_RES_OFF, IPV6_SIP_VALIDATION_BIT, IPV6_SIP_FLD_TYP;

LookupAttackField tmp_IPV6_TRAFFIC_CLASS_STR, CMP_BDOS_L23_IPV6_TRAFFIC_CLASS_OFF, 
                  CMP_BDOS_L23_IPV6_TRAFFIC_CLASS_SIZE, IPV6_TRAFFIC_CLASS_RES_POS, IPV6_TRAFFIC_CLASS_RES_OFF, IPV6_TRAFFIC_CLASS_VALIDATION_BIT, IPV6_TRAFFIC_CLASS_FLD_TYP;

LookupAttackField tmp_IPV6_FLOW_LABEL_STR, CMP_BDOS_L23_IPV6_FLOW_LABEL_OFF,
                  CMP_BDOS_L23_IPV6_FLOW_LABEL_SIZE, IPV6_FLOW_LABEL_RES_POS, IPV6_FLOW_LABEL_RES_OFF, IPV6_FLOW_LABEL_VALIDATION_BIT, IPV6_FLOW_LABEL_FLD_TYP;

LookupAttackField tmp_IPV6_HOP_LIMIT_STR, CMP_BDOS_L23_IPV6_HOP_LIMIT_OFF,
                  CMP_BDOS_L23_IPV6_HOP_LIMIT_SIZE, IPV6_HOP_LIMIT_RES_POS, IPV6_HOP_LIMIT_RES_OFF, IPV6_HOP_LIMIT_VALIDATION_BIT, IPV6_HOP_LIMIT_FLD_TYP;

LookupAttackField tmp_IPV6_FRGFLG_STR, CMP_BDOS_L23_IPV6_FRGMNT_FLG_OFF, 
                  CMP_BDOS_L23_IPV6_FRGMNT_FLG_SIZE, IPV6_FRGFLG_RES_POS, IPV6_FRGFLG_RES_OFF, IPV6_FRGFLG_VALIDATION_BIT, IPV6_FRGFLG_FLD_TYP;

// Write first part L23 results
Write OREG, BDOS_ATTACK_RESULTS_L23_STR, TREG[TREG_BDOS_RES_OFF], BDOS_ATTACK_RESULT_SIZE;


LookupAttackField tmp_IPV6_FRGOFF_STR, CMP_BDOS_L23_IPV6_FRGMNT_OFF,
                  CMP_BDOS_L23_IPV6_FRGMNT_SIZE, IPV6_FRGOFF_RES_POS, IPV6_FRGOFF_RES_OFF, IPV6_FRGOFF_VALIDATION_BIT, IPV6_FRGOFF_FLD_TYP;

LookupAttackField tmp_IPV6_FRGID_STR, CMP_BDOS_L23_IPV6_FRGMNT_ID_OFF,
                  CMP_BDOS_L23_IPV6_FRGMNT_ID_SIZE, IPV6_FRGID_RES_POS, IPV6_FRGID_RES_OFF, IPV6_FRGID_VALIDATION_BIT, IPV6_FRGID_FLD_TYP;


LookupAttackField tmp_L3_LENGTH_STR, CMP_BDOS_L23_L3_SIZE_OFF, 
                  CMP_BDOS_L23_L3_SIZE_SIZE, L3_LENGTH_RES_POS, IPV6_L3_LENGTH_RES_OFF, L3_LENGTH_VALIDATION_BIT, IPV6_L3_LENGTH_FLD_TYP;

// lookup for signature controller
LookupAttackField tmp_SIGNA_CNTRL_STR, CMP_BDOS_L23_SIGNA_CNTRL_OFF,
                  CMP_BDOS_L23_SIGNA_CNTRL_SIZE, SIGNA_CNTRL_RES_POS, SIGNA_CNTRL_RES_OFF, 7, SIGNA_CNTRL_FLD_TYP;

#endif

#undef tmp_SIP_STR;
#undef tmp_DIP_STR;
#undef tmp_HOP_LIMIT_STR;
#undef tmp_IPV6_TRAFFIC_CLASS_STR;
#undef tmp_IPV6_FRGFLG_STR;
#undef tmp_IPV6_FRGOFF_STR;
#undef tmp_IPV6_FLOW_LABEL_STR;
#undef tmp_IPV6_FRGID_STR;
#undef tmp_L3_LENGTH_STR;
#undef tmp_SIGNA_CNTRL_STR;

endmacro;


Macro Attack_TCP_Treat STRUCT_OFFSET;

#define tmp_TCPFLGS_STR   (STRUCT_OFFSET + TCPFLGS_STR   ) // STR 14
#define tmp_TCPCHKSUM_STR (STRUCT_OFFSET + TCPCHKSUM_STR ) // STR 14
#define tmp_TCPSEQNUM_STR (STRUCT_OFFSET + TCPSEQNUM_STR ) // STR 14
#define tmp_TCPSPORT_STR  (STRUCT_OFFSET + TCPSPORT_STR  ) // STR 14
#define tmp_TCPDPORT_STR  (STRUCT_OFFSET + TCPDPORT_STR  ) // STR 14
#define tmp_L2_VLAN_STR      (STRUCT_OFFSET + L2_VLAN_STR     ) // STR 14
#define tmp_PACKET_SIZE_STR  (STRUCT_OFFSET + PACKET_SIZE_STR ) // STR 14

#if 0 // close BDOS code

// Init BDOS result structure
xor TREG[ TREG_TEMP_BDOS_KEY_TYP_OFF      ], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 4 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 8 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 12}], TREG[0], TREG[0], 4; 

LookupAttackField tmp_TCPSPORT_STR, CMP_BDOS_L4_SRC_PORT_OFF, 
                  CMP_BDOS_L4_SRC_PORT_SIZE, TCPSPORT_RES_POS, TCP_SPORT_RES_OFF, TCPSPORT_VALIDATION_BIT, TCPSPORT_FLD_TYP;

LookupAttackField tmp_TCPDPORT_STR, CMP_BDOS_L4_DST_PORT_OFF,
                  CMP_BDOS_L4_DST_PORT_SIZE, TCPDPORT_RES_POS, TCP_DPORT_RES_OFF, TCPDPORT_VALIDATION_BIT, TCPDPORT_FLD_TYP;

LookupAttackField tmp_TCPCHKSUM_STR, CMP_BDOS_L4_CHECKSUM_OFF, 
                  CMP_BDOS_L4_CHECKSUM_SIZE, TCPCHKSUM_RES_POS, TCP_CHKSUM_RES_OFF, TCPCHKSUM_VALIDATION_BIT, TCPCHKSUM_FLD_TYP;

LookupAttackField tmp_TCPSEQNUM_STR, CMP_BDOS_L4_TCP_SEQ_NUM_OFF, 
                  CMP_BDOS_L4_TCP_SEQ_NUM_SIZE, TCPSEQNUM_RES_POS, TCP_SEQNUM_RES_OFF, TCPSEQNUM_VALIDATION_BIT, TCPSEQNUM_FLD_TYP;
 
LookupAttackField tmp_TCPFLGS_STR, CMP_BDOS_L4_TCP_FLAGS_OFF, 
                  CMP_BDOS_L4_TCP_FLAGS_SIZE, TCPFLGS_RES_POS, TCP_FLAGS_RES_OFF, 0x7, TCPFLGS_FLD_TYP;

LookupAttackField tmp_PACKET_SIZE_STR, CMP_BDOS_L23_PACKET_SIZE_OFF, 
                  CMP_BDOS_L23_PACKET_SIZE_SIZE, PACKET_SIZE_RES_POS, PACKET_SIZE_RES_OFF, PACKET_SIZE_VALIDATION_BIT, PACKET_SIZE_FLD_TYP;

LookupAttackField tmp_L2_VLAN_STR, CMP_BDOS_L23_VLAN_OFF, 
                  CMP_BDOS_L23_VLAN_SIZE, L2_VLAN_RES_POS, L2_VLAN_RES_OFF, L2_VLAN_VALIDATION_BIT, L2_VLAN_FLD_TYP;

// Sets Valid+Match bits (0,4) in result to '1'                    
//CMP TREG[TREG_BDOS_RES_OFF], TREG[0], TREG[0], 1;
MovImm TREG[TREG_BDOS_RES_OFF], (1 << MATCH_BIT) | (1 << VALID_BIT), 1;

#endif

#undef tmp_TCPSPORT_STR;
#undef tmp_TCPDPORT_STR;
#undef tmp_TCPCHKSUM_STR;
#undef tmp_TCPSEQNUM_STR;
#undef tmp_TCPFLGS_STR;
#undef tmp_L2_VLAN_STR;
#undef tmp_PACKET_SIZE_STR;

endmacro;



Macro Attack_UDP_Treat STRUCT_OFFSET;

#define tmp_UDPCHKSUM_STR  (STRUCT_OFFSET + UDPCHKSUM_STR ) // STR 14
#define tmp_UDPSPORT_STR   (STRUCT_OFFSET + UDPSPORT_STR  ) // STR 14
#define tmp_UDPDPORT_STR   (STRUCT_OFFSET + UDPDPORT_STR  ) // STR 14
#define tmp_L2_VLAN_STR      (STRUCT_OFFSET + L2_VLAN_STR     ) // STR 14
#define tmp_PACKET_SIZE_STR  (STRUCT_OFFSET + PACKET_SIZE_STR ) // STR 14

#if 0 // close BDOS code

// Init BDOS result structure
xor TREG[ TREG_TEMP_BDOS_KEY_TYP_OFF      ], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 4 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 8 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 12}], TREG[0], TREG[0], 4; 

LookupAttackField tmp_UDPSPORT_STR, CMP_BDOS_L4_SRC_PORT_OFF, 
                  CMP_BDOS_L4_SRC_PORT_SIZE,  UDPSPORT_RES_POS, UDP_SPORT_RES_OFF, UDPSPORT_VALIDATION_BIT, UDPSPORT_FLD_TYP;

LookupAttackField tmp_UDPDPORT_STR, CMP_BDOS_L4_DST_PORT_OFF, 
                  CMP_BDOS_L4_DST_PORT_SIZE, UDPDPORT_RES_POS, UDP_DPORT_RES_OFF, UDPDPORT_VALIDATION_BIT, UDPDPORT_FLD_TYP;

LookupAttackField tmp_UDPCHKSUM_STR, CMP_BDOS_L4_CHECKSUM_OFF, 
                  CMP_BDOS_L4_CHECKSUM_SIZE, UDPCHKSUM_RES_POS, UDP_CHKSUM_RES_OFF, UDPCHKSUM_VALIDATION_BIT, UDPCHKSUM_FLD_TYP;

LookupAttackField tmp_PACKET_SIZE_STR, CMP_BDOS_L23_PACKET_SIZE_OFF, 
                  CMP_BDOS_L23_PACKET_SIZE_SIZE, PACKET_SIZE_RES_POS, PACKET_SIZE_RES_OFF, PACKET_SIZE_VALIDATION_BIT, PACKET_SIZE_FLD_TYP;

LookupAttackField tmp_L2_VLAN_STR, CMP_BDOS_L23_VLAN_OFF, 
                  CMP_BDOS_L23_VLAN_SIZE, L2_VLAN_RES_POS, L2_VLAN_RES_OFF, L2_VLAN_VALIDATION_BIT, L2_VLAN_FLD_TYP;

// Sets Valid+Match bits (0,4) in result to '1'
//CMP TREG[TREG_BDOS_RES_OFF], TREG[0], TREG[0], 1;
MovImm TREG[TREG_BDOS_RES_OFF], (1 << MATCH_BIT) | (1 << VALID_BIT), 1;

#endif

#undef tmp_UDPSPORT_STR;
#undef tmp_UDPDPORT_STR;
#undef tmp_UDPCHKSUM_STR;
#undef tmp_L2_VLAN_STR;
#undef tmp_PACKET_SIZE_STR;

endmacro;



Macro Attack_ICMP_Treat STRUCT_OFFSET;

#define tmp_ICMP_TYPE_STR     (STRUCT_OFFSET + ICMP_TYPE_STR   ) // STR 14
#define tmp_ICMP_CHKSUM_STR   (STRUCT_OFFSET + ICMP_CHKSUM_STR ) // STR 14
#define tmp_L2_VLAN_STR       (STRUCT_OFFSET + L2_VLAN_STR     ) // STR 14
#define tmp_PACKET_SIZE_STR   (STRUCT_OFFSET + PACKET_SIZE_STR ) // STR 14

#if 0 // close BDOS code

// Init BDOS result structure
xor TREG[ TREG_TEMP_BDOS_KEY_TYP_OFF      ], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 4 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 8 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 12}], TREG[0], TREG[0], 4; 

LookupAttackField tmp_ICMP_TYPE_STR, CMP_BDOS_L4_ICMP_TYPE_OFF, 
                  CMP_BDOS_L4_ICMP_TYPE_SIZE,  ICMP_TYPE_RES_POS, ICMP_TYPE_RES_OFF, ICMP_TYPE_VALIDATION_BIT, ICMP_TYPE_FLD_TYP;

LookupAttackField tmp_ICMP_CHKSUM_STR, CMP_BDOS_L4_CHECKSUM_OFF, 
                  CMP_BDOS_L4_CHECKSUM_SIZE, ICMP_CHKSUM_RES_POS, ICMP_CHKSUM_RES_OFF, ICMP_CHKSUM_VALIDATION_BIT, ICMP_CHKSUM_FLD_TYP;

LookupAttackField tmp_PACKET_SIZE_STR, CMP_BDOS_L23_PACKET_SIZE_OFF, 
                  CMP_BDOS_L23_PACKET_SIZE_SIZE, PACKET_SIZE_RES_POS, PACKET_SIZE_RES_OFF, PACKET_SIZE_VALIDATION_BIT, PACKET_SIZE_FLD_TYP;

LookupAttackField tmp_L2_VLAN_STR, CMP_BDOS_L23_VLAN_OFF, 
                  CMP_BDOS_L23_VLAN_SIZE, L2_VLAN_RES_POS, L2_VLAN_RES_OFF, L2_VLAN_VALIDATION_BIT, L2_VLAN_FLD_TYP;

//CMP TREG[TREG_BDOS_RES_OFF], TREG[0], TREG[0], 1;
MovImm TREG[TREG_BDOS_RES_OFF], (1 << MATCH_BIT) | (1 << VALID_BIT), 1;

#endif

#undef tmp_ICMP_TYPE_STR;
#undef tmp_ICMP_CHKSUM_STR;
#undef tmp_L2_VLAN_STR;
#undef tmp_PACKET_SIZE_STR;

endmacro;



Macro Attack_IGMP_Treat STRUCT_OFFSET;

#define tmp_IGMP_TYPE_STR    (STRUCT_OFFSET + IGMP_TYPE_STR   ) // STR 14
#define tmp_IGMP_CHKSUM_STR  (STRUCT_OFFSET + IGMP_CHKSUM_STR ) // STR 14
#define tmp_L2_VLAN_STR      (STRUCT_OFFSET + L2_VLAN_STR     ) // STR 14
#define tmp_PACKET_SIZE_STR  (STRUCT_OFFSET + PACKET_SIZE_STR ) // STR 14

#if 0 // close BDOS code

// Init BDOS result structure
xor TREG[ TREG_TEMP_BDOS_KEY_TYP_OFF      ], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 4 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 8 }], TREG[0], TREG[0], 4; 
xor TREG[{TREG_TEMP_BDOS_KEY_TYP_OFF + 12}], TREG[0], TREG[0], 4; 

LookupAttackField tmp_IGMP_TYPE_STR, CMP_BDOS_L4_IGMP_TYPE_OFF, 
                  CMP_BDOS_L4_IGMP_TYPE_SIZE, IGMP_TYPE_RES_POS, IGMP_TYPE_RES_OFF, IGMP_TYPE_VALIDATION_BIT, IGMP_TYPE_FLD_TYP;

LookupAttackField tmp_IGMP_CHKSUM_STR, CMP_BDOS_L4_CHECKSUM_OFF, 
                  CMP_BDOS_L4_CHECKSUM_SIZE, IGMP_CHKSUM_RES_POS, IGMP_CHKSUM_RES_OFF, IGMP_CHKSUM_VALIDATION_BIT, IGMP_CHKSUM_FLD_TYP;

LookupAttackField tmp_PACKET_SIZE_STR, CMP_BDOS_L23_PACKET_SIZE_OFF, 
                  CMP_BDOS_L23_PACKET_SIZE_SIZE, PACKET_SIZE_RES_POS, PACKET_SIZE_RES_OFF, PACKET_SIZE_VALIDATION_BIT, PACKET_SIZE_FLD_TYP;

LookupAttackField tmp_L2_VLAN_STR, CMP_BDOS_L23_VLAN_OFF, 
                  CMP_BDOS_L23_VLAN_SIZE, L2_VLAN_RES_POS, L2_VLAN_RES_OFF, L2_VLAN_VALIDATION_BIT, L2_VLAN_FLD_TYP;

// Sets Valid+Match bits (0,4) in result to '1'
//CMP TREG[TREG_BDOS_RES_OFF], TREG[0], TREG[0], 1;
MovImm TREG[TREG_BDOS_RES_OFF], (1 << MATCH_BIT) | (1 << VALID_BIT), 1;

#endif

#undef tmp_ICMP_TYPE_STR;
#undef tmp_ICMP_CHKSUM_STR;
#undef tmp_L2_VLAN_STR;
#undef tmp_PACKET_SIZE_STR;

endmacro;



// Macro: LookupAttackField
// Lookup in attack field structure. If there is a match - copy it over the default value

Macro LookupAttackField F_STR,         // One of the BDOS attack structures 14-23 (also includes STRUCT_OFFSET)
                        COMP_KEY_OFF,  // Compound key offset in KREG
                        COMP_KEY_SIZE, // Compound key size
                        TEMP_RES_OFF,  // Offset of the desired field in F_STR result (which will be copied to FINAL_RES_OFF)
                        FINAL_RES_OFF, // Offset where the lookup result will be written in structure BDOS_ATTACK_RESULTS_L23_STR or BDOS_ATTACK_RESULTS_L4_STR
                        VALID_BIT,     // Validation bits mask
                        FLD_TYP;       // Field type

// Prepare first part of the key - field type
MovImm TREG[TREG_TEMP_BDOS_KEY_TYP_OFF], FLD_TYP, 1;
Xor TREG[{TREG_BDOS_RES_OFF + FINAL_RES_OFF}], TREG[0], TREG[0], 4;

Lookup TREG[TREG_TEMP_BDOS_LKP_RES_OFF], F_STR, 
       TREG[TREG_TEMP_BDOS_KEY_TYP_OFF], {17 - COMP_KEY_SIZE}, // First part of key - field type
       TREG[COMP_KEY_OFF], COMP_KEY_SIZE,                      // Second part of key - field value
       LKPS_MASK VALID_BIT;

// Do not write if lookup fails                    
JNoMatch SKIP_WRITE;

// Copy temporary lookup result to BDOS result (that goes to OREG)
Write TREG[{TREG_BDOS_RES_OFF + FINAL_RES_OFF}], 1, TREG[{TREG_TEMP_BDOS_LKP_RES_OFF + TEMP_RES_OFF}], 4;

SKIP_WRITE:

endmacro;


Macro Attack_ALST_Treat STRUCT_OFFSET;

#define tmp_ALST_PRT_TYPE_STR   (ALIST_L4_PRT_STR  + STRUCT_OFFSET);
#define tmp_ALST_TREE_STR       (ALIST_SRC_STR  + STRUCT_OFFSET);
#define CALC_RESRV_2BYTE_POS1  11; //4 byte size result of shift + kreg vlan 
#define CALC_RESRV_1BYTE_POS1  15; //2byte
#define REZ_ZERO_BYTE_POS      17; //must be zero
#define PRT_SRC_RES_LOW8   3;
#define PRT_DST_RES_HIGH8  6;
#define VLAN_LOW_KREG_POS  0x21;
#define VLAN_HIGH_KREG_POS 0x22;
#define CALC_TEMP0_WORD_POS 10;
#define CALC_TEMP0_BYTE_POS 12;
#define CALC_SRC_PRT_10_2_IDX 0x23;
#define CALC_SRC_PRT_1_0_IDX  0x24;
#define CALC_DST_PRT_14_8_IDX  0x25;
#define PROT_PHYS_PORT_POS    0x23;
#define DST_PRT_RES_POS_HIGH      6;
#define DST_PRT_RES_POS_LOW       5;
#define VLAN_LOW_TREG_POS         0x22; 
#define PROT_PHYS_PORT_TREG_POS   0x20;
#define VLAN_HIGH_TREG_POS        0x21;
#define DST_PRT_RES_POS   DST_PRT_RES_POS_LOW;
#define DST_PRT_POS_TREG          36;
#define DST_PRT_POS_KREG          38;

#define SRC_PRT_IDX_HIGH          4;
#define VLAN_LOW_KREG7_0_POS      0x21;
#define SRC_PRT_IDX_LOW_DEST      0x23;
#define SRC_PRT_IDX_LOW_SRC       3;

lookup TREG, tmp_ALST_PRT_TYPE_STR, KREG.BYTE[CMP_ALST_L4SRC_PRT_PHASE], 2, NULL, 0,
                    _NO__MSK, 0xF, _WR_NLST;

//jMatch CALC_SPRT_IDX;
//write  TREG.byte[VLAN_LOW_TREG_POS], 2 , KREG.byte[VLAN_LOW_KREG_POS] , 2, NULL, 0,  _WR_NLST;
jNoMatch  SKIP_SPRT_IDX;

//SHR  TREG.byte[CALC_RESRV_2BYTE_POS1] ,TREG.byte[PRT_SRC_RES_LOW8] , KREG.byte[VLAN_LOW_KREG_POS],1,3;
//SHL  TREG.byte[CALC_RESRV_1BYTE_POS1],TREG.byte[PRT_SRC_RES_LOW8] , TREG.byte[REZ_ZERO_BYTE_POS] , 0 ,4;
//SHL  TREG.byte[CALC_RESRV_1BYTE_POS1],TREG.byte[CALC_RESRV_1BYTE_POS1] , TREG.byte[REZ_ZERO_BYTE_POS] , 0 ,2;
OR     TREG.byte[VLAN_LOW_TREG_POS]   ,TREG.byte[SRC_PRT_IDX_HIGH] , KREG.byte[VLAN_LOW_KREG7_0_POS];
write  TREG.byte[SRC_PRT_IDX_LOW_DEST] ,1, TREG.byte[SRC_PRT_IDX_LOW_SRC], 1, NULL, 0,  _WR_NLST;    
SKIP_SPRT_IDX:
//lookup TREG, tmp_ALST_PRT_TYPE_STR, KREG.BYTE[CMP_ALST_L4DST_PRT_PHASE], 2, NULL, 0,
//                    _NO__MSK, 0xF, _WR_NLST;
//jNoMatch CALC_DPRT_IDX;
//OR    TREG.byte[CALC_SRC_PRT_1_0_IDX] , TREG.byte[CALC_SRC_PRT_1_0_IDX] , TREG.byte[DST_PRT_RES_POS_HIGH];
//write TREG.byte[CALC_DST_PRT_14_8_IDX], 1, TREG.byte[DST_PRT_RES_POS_LOW], 1, NULL, 0,  _WR_NLST;
//CALC_DPRT_IDX:
write TREG.byte[DST_PRT_POS_TREG],2 ,KREG.byte[DST_PRT_POS_KREG] , 2, NULL , 0,  _WR_NLST;;
write TREG.byte[0], 32, KREG.byte[0], 32, NULL , 0,  _WR_NLST;
write TREG.byte[PROT_PHYS_PORT_TREG_POS], 1, KREG.byte[PROT_PHYS_PORT_POS], 1, NULL , 0,  _WR_NLST;
lookup TREG, tmp_ALST_TREE_STR, TREG, 38, NULL, 0, _NO__MSK, 0xF, _WR_NLST;
jmatch ALST_ATTACK_DET;
write OREG.byte[0],  ALIST_IPv4_STR, KREG.byte[ALST_WHITE_SPACE], 1, NULL, 0,  _WR_LAST;
halt;
ALST_ATTACK_DET:

//always put result in IPv4 structure
write OREG, ALIST_IPv4_STR, TREG.byte[1], 3, NULL, 0,  _WR_LAST;



#undef tmp_ALST_PRT_TYPE_STR;
#undef tmp_ALST_TREE_STR;

halt;
endmacro;
