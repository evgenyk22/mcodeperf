/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.Prs.PacketAnomalies.h
*
*  Usage:         xad.Prs.PacketAnomalies.asm include file
*
*******************************************************************************/

#ifndef _XAD_PRS_PACKETANOMALIES_H_;
#define _XAD_PRS_PACKETANOMALIES_H_;

                           
#define actReg0                        UREG[ 12 ];
#define actRegMask0                    UREG[ 9 ]; 
#define icCtrlType                     bytmp2;

#define IC_CNTRL_POLICY_GROUP_MASK_0   ( (1<<IC_CNTRL_0_INC_TTL_OFF) | (1<<IC_CNTRL_0_FRAG_OFF) | (1<<IC_CNTRL_0_IPv6_HLIM_OFF) | (1<<IC_CNTRL_0_IPv6_FRAG_OFF) );
#define IC_CNTRL_POLICY_GROUP_MASK_1   ( (1<<IC_CNTRL_1_UNK_L4_OFF) | (1<<IC_CNTRL_1_TCP_HLEN_OFF) | (1<<IC_CNTRL_1_TCP_FLAG_OFF) | (1<<IC_CNTRL_1_UDP_ZCHKSUM_OFF) | (1<<IC_CNTRL_1_UDP_INC_HLEN_OFF) | (1<<IC_CNTRL_1_SCTP_HLEN_OFF) );
#define IC_CNTRL_TUNNEL_GROUP_MASK_1   ( (1<<IC_CNTRL_1_GRE_VERSION_OFF) | (1<<IC_CNTRL_1_GRE_ROUTING_HDR_NUM_OFF) | (1<<IC_CNTRL_1_GRE_INV_HDR_LEN_OFF) | (1<<IC_CNTRL_1_INC_VER_GTP_OFF) | (1<<IC_CNTRL_1_INC_HLEN_GTP_OFF) );
                                       
#define IC_CNTRL_MASK_0                (IC_CNTRL_POLICY_GROUP_MASK_0);
#define IC_CNTRL_MASK_1                (IC_CNTRL_POLICY_GROUP_MASK_1 | IC_CNTRL_TUNNEL_GROUP_MASK_1);


/******************************************************************************
// UDP DEFINITIONS
******************************************************************************/
#define UDP_HLEN_OFF          4;
#define UDP_CHKSUM_OFF        6;

#endif; // of #ifndef _XAD_PRS_PACKETANOMALIES_H_

