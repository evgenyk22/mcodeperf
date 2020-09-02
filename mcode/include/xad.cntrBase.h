/*******************************************************************************
*
*  Company:       Radware Ltd.
*  Platform:      DefensePro ODS-HT
*  Project:       NP-4 XAD Driver
*  Component:     Microcode
*
*  File:          xad.cntrBase.h
*
*  Usage:         Counters offsets definition file
*
*******************************************************************************/

#ifndef _XAD_CNTRBASE_H_
#define _XAD_CNTRBASE_H_

/////////////////////////////////////////////////
// Internal Group 0: Long counters [0..5119]
/////////////////////////////////////////////////

#define GLOB_CFG_BASE  0
#define GLOB_CFG_SIZE  10

//#define uqGcCtrlReg0     (GLOB_CFG_BASE+0)
#define GC_STATS_0      (GLOB_CFG_BASE+1)
#define GC_ERROR_0      (GLOB_CFG_BASE+2)
#define GC_FEATURE      (GLOB_CFG_BASE+3)
#define GC_INB_REPRT1   (GLOB_CFG_BASE+4)
#define GC_INB_ERROR1   (GLOB_CFG_BASE+5)


#define GLOB_STAT_BASE  (GLOB_CFG_BASE + GLOB_CFG_SIZE) // 0 + 10 = 10
#define GLOB_STAT_SIZE  33

//Number of external packets received on TOP Parse
#define GS_TPR_EX_RCV  (GLOB_STAT_BASE+0)

//Number of external packets dropped on TOP Parse by Global traffic processing mode
#define GS_TPR_EX_DRP (GLOB_STAT_BASE+1)

//Number of external packets by-passed on TOP Parse by Global traffic processing mode
#define GS_TPR_EX_PAS (GLOB_STAT_BASE+2)

//Number of external packets sent to CPU on TOP Parse by Global traffic processing mode
#define GS_TPR_EX_CPU (GLOB_STAT_BASE+3)

//Number of internal packets received on TOP Parse
#define GS_TPR_IN_RCV (GLOB_STAT_BASE+4)

//Number of internal packets dropped on TOP Parse
#define GS_TPR_IN_DRP (GLOB_STAT_BASE+5)

//Number of simple searches on TOP Search I
#define GS_TSI_SM_SRH (GLOB_STAT_BASE+6)

//Number of compound searches on TOP Search I
#define GS_TSI_CM_SRH (GLOB_STAT_BASE+7)

//Number of external packets arrived to TOP Resolve
#define GS_TRL_EX_RCV (GLOB_STAT_BASE+8)

//Number of external packets dropped on TOP Resolve
#define GS_TRL_EX_DRP (GLOB_STAT_BASE+9)

//Number of external packets bypassed on TOP Resolve
#define GS_TRL_EX_PAS (GLOB_STAT_BASE+10)

//Number of internal packets arrived to TOP Resolve
#define GS_TRL_IN_RCV (GLOB_STAT_BASE+11)

//Number of internal packets dropped on TOP Resolve
#define GS_TRL_IN_DRP (GLOB_STAT_BASE+12)

//Number of external packets arrived to TOP Modify
#define GS_TMD_EX_RCV (GLOB_STAT_BASE+13)

//Number of external packets dropped on TOP Modify
#define GS_TMD_EX_DRP (GLOB_STAT_BASE+14)

//Number of external packets transmitted by TOP Modify
#define GS_TMD_EX_TRN (GLOB_STAT_BASE+15)

//Number of internal packets arrived to TOP Modify
#define GS_TMD_IN_RCV (GLOB_STAT_BASE+16)

// Number of internal packets dropped on TOP Modify
#define GS_TMD_IN_DRP (GLOB_STAT_BASE+17)

//Number of internal packets transmitted by TOP Modify
#define GS_TMD_IN_TRN (GLOB_STAT_BASE+18)

// discard counters
#define CNT_PRS_DISC               (GLOB_STAT_BASE+19)
#define CNT_PRS_WRONG_TYPE         (GLOB_STAT_BASE+20)
#define CNT_RSV_DISC               (GLOB_STAT_BASE+21)
#define CNT_MDF_DISC               (GLOB_STAT_BASE+22)
#define CNT_MDF_SEND               (GLOB_STAT_BASE+23) // not used at this stage.
#define CNT_EXPR_DISC_BASE         (GLOB_STAT_BASE+24)
#define CNT_PRS_HOST_LAB_DRP       (GLOB_STAT_BASE+25)
#define CNT_PRS_NET_LAB_DRP        (GLOB_STAT_BASE+26)
#define CNT_PRS_ICFDQ_ERR_HOST_DRP (GLOB_STAT_BASE+27)
#define CNT_PRS_ICFDQ_ERR_NET_DRP  (GLOB_STAT_BASE+28)
#define CNT_PRS_ICFDQ_ERR_CTRL_DRP (GLOB_STAT_BASE+29)
#define CNT_PRS_UNS_TO_CPU         (GLOB_STAT_BASE+30) // for performance: L4 types GRE, IPSEC, L2TP, IPinIP sent straight to cpu w/o security

//Number of external packets dropped on TOP Modify caused by simultaneously RX , TX
// table no match . Should be never incremented

#define GS_TMD_EX_TX_RX_DRP (GLOB_STAT_BASE+31)

// Immediate check counters group
#define IMM_CHK_BASE   (GLOB_STAT_BASE + GLOB_STAT_SIZE) // 10 + 33 = 43
#define IMM_CHK_SIZE    100

// Can be seen in the CLI with "p eDbgPrint(1,1,0,0,0,0,0,0,0)"
/*
#define IS_UN_L2_DRP        IMM_CHK_BASE       //XAD_L2_SUPPORTED_CHECK
#define IS_L2_BRD_DRP      (IMM_CHK_BASE+4)    //XAD_L2_BROADCAST_CHECK
#define IS_UN_L3_DRP       (IMM_CHK_BASE+8)    //XAD_L3_SUPPORTED_CHECK
#define IS_IP4_CK_DRP      (IMM_CHK_BASE+12)   //XAD_IPV4_CHECKSUM_CHECK
#define IS_IP4_HE_DRP      (IMM_CHK_BASE+16)   //XAD_IP_INV_PCKT_OR_HDR_LEN_CHECK
#define IS_IP4_TTL_DRP     (IMM_CHK_BASE+20)   //XAD_IPV4_TTL_CHECK
#define IS_IP4_FRG_DRP     (IMM_CHK_BASE+24)   //XAD_IPV4_IP_FRAG_CHECK
#define IS_IP6_HE_DRP      (IMM_CHK_BASE+28)   //XAD_IPV6_INCONSIST_HDR_CHECK
#define IS_IP6_HOP_DRP     (IMM_CHK_BASE+32)   //XAD_IPV6_HOP_LIMIT_CHECK
#define IS_IP6_FRG_DRP     (IMM_CHK_BASE+36)   //XAD_IPV6_IP_FRAG_CHECK
#define IS_UN_L4_DRP       (IMM_CHK_BASE+40)   //XAD_L4_SUPPORTED_CHECK
#define IS_L3_LAND_DRP IS_L4PRTZ_CK_DRP   (IMM_CHK_BASE+44)   //XAD_TCP_CHECSUM_CHECK
#define IS_TCP_HE_DRP      (IMM_CHK_BASE+48)   //XAD_TCP_INV_HDR_LEN_CHECK
#define IS_TCP_FL_DRP      (IMM_CHK_BASE+52)   //XAD_TCP_FLAG_VALID_CHECK
#define IS_L3_LOCAL_DRP    (IMM_CHK_BASE+56)   //XAD_UDP_CHECKSUM_CHECK
#define IS_UDP_CZ_DRP      (IMM_CHK_BASE+60)   //XAD_UDP_ZERO_CHECKSUM_CHECK
#define IS_UDP_HE_DRP      (IMM_CHK_BASE+64)   //XAD_UDP_INV_HDR_LEN_CHECK
#define IS_L3_LAND_DRP     (IMM_CHK_BASE+68)   //XAD_ICMP_CHECKSUM_CHECK
#define IS_SCTP_HLEN_DRP   (IMM_CHK_BASE+72)   //XAD_SCTP_HLEN_CHECK
#define IS_GRE_VER_DRP     (IMM_CHK_BASE+76)   //XAD_GRE_VERSION_CHECK
#define IS_GRE_ROUT_DRP    (IMM_CHK_BASE+80)   //XAD_GRE_ROUTING_HDR_NUM_CHECK
#define IS_GRE_HDR_DRP     (IMM_CHK_BASE+84)   //XAD_GRE_INV_HDR_LEN_CHECK
#define IS_GTP_INC_VER_DRP (IMM_CHK_BASE+88)   //XAD_GTP_VERSION_CHECK
#define IS_GTP_HLEN_DRP    (IMM_CHK_BASE+92)   //XAD_GTP_INV_HDR_LEN_CHECK
*/
// Can be seen in the CLI with "p eDbgPrint(1,1,0,0,0,0,0,0,0)"
#define IS_UN_L2_DRP        IMM_CHK_BASE       //XAD_L2_SUPPORTED_CHECK
#define IS_L2_BRD_DRP      (IMM_CHK_BASE+4)    //XAD_L2_BROADCAST_CHECK
#define IS_UN_L3_DRP       (IMM_CHK_BASE+8)    //XAD_L3_SUPPORTED_CHECK
#define IS_IP4_CK_DRP      (IMM_CHK_BASE+12)   //XAD_IPV4_CHECKSUM_CHECK
#define IS_IP4_HE_DRP      (IMM_CHK_BASE+16)   //XAD_IP_INV_PCKT_OR_HDR_LEN_CHECK
#define IS_IP4_TTL_DRP     (IMM_CHK_BASE+20)   //XAD_IPV4_TTL_CHECK
#define IS_IP4_FRG_DRP     (IMM_CHK_BASE+24)   //XAD_IPV4_IP_FRAG_CHECK
#define IS_IP6_HE_DRP      (IMM_CHK_BASE+28)   //XAD_IPV6_INCONSIST_HDR_CHECK
#define IS_IP6_HOP_DRP     (IMM_CHK_BASE+32)   //XAD_IPV6_HOP_LIMIT_CHECK
#define IS_IP6_FRG_DRP     (IMM_CHK_BASE+36)   //XAD_IPV6_IP_FRAG_CHECK
#define IS_UN_L4_DRP       (IMM_CHK_BASE+40)   //XAD_L4_SUPPORTED_CHECK
#define IS_L3_LAND_DRP     (IMM_CHK_BASE+44)   //XAD_TCP_CHECSUM_CHECK
#define IS_TCP_HE_DRP      (IMM_CHK_BASE+48)   //XAD_TCP_INV_HDR_LEN_CHECK
#define IS_TCP_FL_DRP      (IMM_CHK_BASE+52)   //XAD_TCP_FLAG_VALID_CHECK
#define IS_L4PRTZ_CK_DRP   (IMM_CHK_BASE+56)   //XAD_UDP_CHECKSUM_CHECK
#define IS_UDP_CZ_DRP      (IMM_CHK_BASE+60)   //XAD_UDP_ZERO_CHECKSUM_CHECK
#define IS_UDP_HE_DRP      (IMM_CHK_BASE+64)   //XAD_UDP_INV_HDR_LEN_CHECK
#define IS_L3_LOCAL_DRP    (IMM_CHK_BASE+68)   //XAD_ICMP_CHECKSUM_CHECK
#define IS_SCTP_HLEN_DRP   (IMM_CHK_BASE+72)   //XAD_SCTP_HLEN_CHECK
#define IS_GRE_VER_DRP     (IMM_CHK_BASE+76)   //XAD_GRE_VERSION_CHECK
#define IS_GRE_ROUT_DRP    (IMM_CHK_BASE+80)   //XAD_GRE_ROUTING_HDR_NUM_CHECK
#define IS_GRE_HDR_DRP     (IMM_CHK_BASE+84)   //XAD_GRE_INV_HDR_LEN_CHECK
#define IS_GTP_INC_VER_DRP (IMM_CHK_BASE+88)   //XAD_GTP_VERSION_CHECK
#define IS_GTP_HLEN_DRP    (IMM_CHK_BASE+92)   //XAD_GTP_INV_HDR_LEN_CHECK



#define IS_SAMP_CPU        (IMM_CHK_BASE+96)

#define POLICY_CNTR_NUMBER       (404)


#define ROUTING_CNTR_BASE                                       (IMM_CHK_BASE + IMM_CHK_SIZE) //143
#define ROUTING_CNTR_SIZE                               20
#define ROUTING__L_CNTR__DMAC_NO_MATCH                          (ROUTING_CNTR_BASE + 0)  // Frames with DMAC no match, i.e. not MY_MAC, not MAC_BC, not MAC_MC and not L2 control frames.    Action: IC_CNTRL_1_DMAC_NO_MATCH_OFF
#define ROUTING__L_CNTR__NOT_IPVX_FRAME_DISC                    (ROUTING_CNTR_BASE + 1)  // Num of frames discarded as not IP frames.                                                        Action: Discard.
#define ROUTING__L_CNTR__FROM_HOST_CANT_ROUTE_NOT_IP_FRAME_DISC (ROUTING_CNTR_BASE + 2)  // In routing mode, a frame that arrived from the host can't be routed as it it not an IP frame.    Action: Discard
#define ROUTING__L_CNTR__MORE_THEN_3_VLANS_IN_FRAME             (ROUTING_CNTR_BASE + 3)  // Frames with more then 3 VLANs (1 SW and more then 2 user VLANS) - unsupported.                   Action: Act accord to configuration for L2_UNS_PROT.
#define ROUTING__L_CNTR__SUBIF                                  (ROUTING_CNTR_BASE + 4)  // Frames with subinterface no match
#define ROUTING__L_CNTR__TTL_OR_HOP_EXP_DISC                    (ROUTING_CNTR_BASE + 5)  // Num of frames discarded due to TTL or HOP count expired.                                         Action: Discard
#define ROUTING__L_CNTR__ROUTING_TABLE_INDEX_NO_MATCH           (ROUTING_CNTR_BASE + 6)  // Frame.DIP does not exist in the TCAM routing table.                                              Action: Discard
#define ROUTING__L_CNTR__ROUTING_TABLE_NO_MATCH                 (ROUTING_CNTR_BASE + 7)  // Frame.DIP does not exist in the routing table.                                                   Action: Discard
#define ROUTING__L_CNTR__ROUTING_TABLE_MATCH                    (ROUTING_CNTR_BASE + 8)  // Match in both routing table index (TCAM) and in the routing table.                               Action: No special action attached. Just used to allow visability
#define ROUTING__L_CNTR__IS_MY_IP_SEND_TO_CPU                   (ROUTING_CNTR_BASE + 9)  // Num of MY_IP packets that where sampled to the CPU (as TB did not return RED color for them)     Action: No special action attached. Just used to allow visability
#define ROUTING__L_CNTR__IS_MY_IP_TB_DISC                       (ROUTING_CNTR_BASE + 10) // Num of MY_IP packets that where discarded, due to passing the sampling rate defined by the TB. (TB returned RED color). Action: Discard
#define ROUTING__L_CNTR__GRE_KEEPALIVE_REQUEST                  (ROUTING_CNTR_BASE + 11) // Num of GRE KeepAlive request frames.                                                             Action: Send frame as is to the host without perfomring on it security features.
#define ROUTING__L_CNTR__GRE_KEEPALIVE_REPLY                    (ROUTING_CNTR_BASE + 12) // Num of GRE KeepAlive reply frames.                                                               Action: Send frame as is to the host without perfomring on it security features.
#define ROUTING__L_CNTR__RADWARE_GRE_TUNNEL                     (ROUTING_CNTR_BASE + 13) // Num of frames that are RadwareGRETunnel (IP_TO_ME).                                              Action: Decapsulate the RadwareTunnelGRE, perform security on 1 level inner of the L3 (just after the first IPv4.GRE that will be removed). route frame.
#define ROUTING__L_CNTR__GRE_UNEXPECTED_TUNNEL_TO_ME            (ROUTING_CNTR_BASE + 14) // Num of IPV4_TO_ME GRE frames do not match any known scenario.                                    Action: Route frame based on outer IPv4. as this is MY_IP it will be punted to the host.
// Counters numbers ROUTING_CNTR_BASE +15..19 - Free for future use for routing mechanism

#define LACP_CNT_BASE           (ROUTING_CNTR_BASE + ROUTING_CNTR_SIZE) /* (=163) */
#define LACP_CNT_SIZE           ( 4 /*send per port */+ 4 /* recived network */ /* recived CPU */ )

#define LACP_PORT_SEND            LACP_CNT_BASE /* 0 - caui0 , 1 - caui1 , 2 - caui2 , 3 - caui3 */
#define LACP_NET_RECIVED         (LACP_CNT_BASE + 4)

#define TRUNK_PORT0_DBG          (LACP_CNT_BASE + LACP_CNT_SIZE) /* (=171) */
#define TRUNK_PORT0_DBG_SIZE     16
/*
#define TRUNK_PORT1_DBG          (LACP_CNT_BASE + LACP_CNT_SIZE + 1)
#define TRUNK_PORT2_DBG          (LACP_CNT_BASE + LACP_CNT_SIZE + 2)
#define TRUNK_PORT3_DBG          (LACP_CNT_BASE + LACP_CNT_SIZE + 3)
*/

#define TRAFFIC_LIMIT_CNTR_BASE                        (TRUNK_PORT0_DBG + TRUNK_PORT0_DBG_SIZE)//(=187)
#define TRAFFIC_LIMIT_CNTR_SIZE                        4

#define TRAFFIC_LIMIT_DROP_CNTR_BASE                   (TRAFFIC_LIMIT_CNTR_BASE + TRAFFIC_LIMIT_CNTR_SIZE)
#define TRAFFIC_LIMIT_DROP_CNTR_SIZE                   4

#define TRAFFIC_LIMIT_BYTE_DROP_CNTR_BASE              (TRAFFIC_LIMIT_DROP_CNTR_BASE + TRAFFIC_LIMIT_DROP_CNTR_SIZE)
#define TRAFFIC_LIMIT_BYTE_DROP_CNTR_SIZE              4



#define TRAFFIC_LIMIT_INB_DROP_CNTR_BASE               (TRAFFIC_LIMIT_BYTE_DROP_CNTR_BASE + TRAFFIC_LIMIT_BYTE_DROP_CNTR_SIZE)

#define TRAFFIC_LIMIT_INB_BYTE_DROP_CNTR_BASE          (TRAFFIC_LIMIT_INB_DROP_CNTR_BASE  + 1)

#define TRAFFIC_LIMIT_INB_REC_BYTE_CNTR_BASE          (TRAFFIC_LIMIT_INB_BYTE_DROP_CNTR_BASE  + 1)

//199
#define RTPC_FILTER_CNTR_BASE              (TRAFFIC_LIMIT_INB_REC_BYTE_CNTR_BASE + 1)    //199
#define RTPC_FILTER_CNTR_SIZE              5

#define TRAFFIC_LIMIT_INB_PPS_CNTR_BASE              (RTPC_FILTER_CNTR_BASE + RTPC_FILTER_CNTR_SIZE) //204
#define TRAFFIC_LIMIT_INB_PPS_DROP_CNTR_BASE          (TRAFFIC_LIMIT_INB_PPS_CNTR_BASE)
#define TRAFFIC_LIMIT_INB_PPS_BYTE_CNTR_BASE          (TRAFFIC_LIMIT_INB_PPS_DROP_CNTR_BASE  + 1)
#define TRAFFIC_LIMIT_PPS_CNTR_SIZE              2

//#define LACP_HOST_RECIVED       (LACP_NET_RECIVED + 1)


/* 163 - 0x600 empty ,could be used */
#define TB_CNTR_BASE      (0x100 /*0x14f00*/ /*BC_BASE + BC_CONFIG_SIZE*/)  // in Imem, follows BDOS configurations
// bug 0x500 - unnesesary 0x500 counters , free it and put FFT instead
#define IMM_CHK_SAM_TB   (TB_CNTR_BASE + 0)
#define ALIST_SAM_TB     (TB_CNTR_BASE + 1)
#define TP_ACT_TB     (TB_CNTR_BASE + 2)

#define BDOS_SAMP_TB TB_CNTR_BASE + 3
#define BDOS_SAMP_TB_SIZE 256

#define BDOS_THR_TB (BDOS_SAMP_TB+BDOS_SAMP_TB_SIZE)
#define BDOS_SAMP_THR_SIZE 256

#define BDOS_SAMP_TB_S0_OFF   1
#define BDOS_SAMP_TB_S1_OFF   2
#define BDOS_SAMP_TB_S2_OFF   3
#define BDOS_SAMP_TB_S3_OFF   4

#define TRAFFIC_LIMIT_INB_PPS_TB   (BDOS_THR_TB+ BDOS_SAMP_THR_SIZE)
#define TRAFFIC_LIMIT_INB_PPS_TB_SIZE   1
#define ROUTING_MY_IP_TB  		 0xfff
#define ROUTING_MY_IP_TB_SIZE  	1

#define TB_CNTR_SIZE     (3 + BDOS_SAMP_TB_SIZE + BDOS_SAMP_THR_SIZE + 2)



/////////////////////////////////////////////////
// Imem Group 0 : 89808 [8192..97999] long counters BDOS + SYN + FFT + others
/////////////////////////////////////////////////

// BDOS configuration
#define BC_BASE                       8192 												  // Imem, first group
#define BC_PER_POLICY_SIGNA           32                            				  // defines number of local signatures for each policy
#define BC_SIGNA_SIZE                 3                             				  // defines number counters for signature selector configuration
#define BC_CONFIG_PER_POLICY_SIZE     (BC_PER_POLICY_SIGNA * BC_SIGNA_SIZE)     // 32 * 3  = 96 counters
#define BC_CONFIG_PER_POLICY_PHASE_SIZE (BC_CONFIG_PER_POLICY_SIZE *  POLICY_CNTR_NUMBER) //96 * 404 = 38784
#define BC_CONFIG_SIZE                BC_CONFIG_PER_POLICY_PHASE_SIZE *2        // BC config per phase * 2 = 77568

#define BC_NUM_GLOBAL_SIGNA 1000                                                // Number of global signatures

#define BC_COUNTER_TYPES   2                                                    // counts bytes and Frames
#define BC_NUMBER_OF_ACTIONS 4                                                  // DROP/CONTINUE/TO_CPU/BYPASS
#define BC_SIGNA_STAT_COUNTRS (BC_NUMBER_OF_ACTIONS * BC_COUNTER_TYPES)         // 8 STAT counters per signature
#define BC_STAT_COUNTRS 	(BC_SIGNA_STAT_COUNTRS * BC_NUM_GLOBAL_SIGNA)        // 8 * 1000 = 8000

// Counter indices for signature definitions
// BC_S<signature number>G<Group within signature>S<Set (phase)>_SEL

#define BC_S0G0S0_SEL      BC_BASE                                 				  // = 8192 = 0x2000 defines Signature 0 selector 0 phase 0 offset
#define BC_S0G0S1_SEL      (BC_BASE + BC_CONFIG_PER_POLICY_PHASE_SIZE)	        // = 46976 = 0xB780 defines Signature 0 selector 0 phase 1 offset


// Protected Destination table counters definition
#define PD_MATCH_GLOBAL_BASE      (BC_BASE + BC_CONFIG_SIZE) // = 85760
#define PD_MATCH_AUTCH_ADD_ERROR  PD_MATCH_GLOBAL_BASE       // Authentication table add entry error
#define PD_MATCH_BASE             (PD_MATCH_GLOBAL_BASE + 1) // = 85761
#define PD_MATCH_NUM_CNTRS        6
#define PD_MATCH_BASE_SIZE        (512*PD_MATCH_NUM_CNTRS+1) // defines 4 counters per entry and one error
#define PD_MATCH_SYN_OFFSET       0                 // SYN packets match / SYN non authenticated match counter
#define PD_MATCH_SYN_AUTH_OFFSET  1                 // SYN authenticated match counter
#define PD_MATCH_CHALLENGE_OFFSET 2                 // RST/ACK packet Challenge response success counter
#define PD_MATCH_SHORT_ACK_OFFSET 3                 // Short ACK - In TCP Reset mode when configured to ACK+Payload and receiving short ACKs we drop the packet and increment this counter
#define PD_MATCH_BAD_SYN_OFFSET   4                 // For timeout SYN packets (timestamp not validated)
#define PD_MATCH_GOOD_SYN_OFFSET  5                 // For SYN packets that added entry to Authentication table

#define TP_CNTRL_BASE     (PD_MATCH_GLOBAL_BASE + PD_MATCH_BASE_SIZE)           // = 88833
#define TP_CNTRL_SIZE     3

/* incremented when frame send to copy port instead drop */
#define TP_CNTRL_CP_PRT   TP_CNTRL_BASE
/* incremented when frame send to copy port and bypassed to network instead drop */
#define TP_CNTRL_PRT_GRP  (TP_CNTRL_BASE+1)
#define TP_CNTRL_PRT_MRK  (TP_CNTRL_BASE+2)


//BDOS counters
#define BC_CNT_BASE        ( TP_CNTRL_BASE + TP_CNTRL_SIZE ) // = 88836
#define BC_CNT_OFFSET      0
#define BC_DRP_OFFSET      1
#define BC_PAS_OFFSET      2
#define BC_CPU_OFFSET      3
#define BC_BT_CNT_OFFSET   4
#define BC_BT_DRP_OFFSET   5
#define BC_BT_PAS_OFFSET   6
#define BC_BT_CPU_OFFSET   7

#define BS_SAMP_CPU        (BC_CNT_BASE + BC_STAT_COUNTRS)   // = 96836
#define BS_SAMP_CPU_SIZE   BC_NUM_GLOBAL_SIGNA


// FFT counters defininiton
#define FFT_BASE                    (BS_SAMP_CPU + BS_SAMP_CPU_SIZE)  // = 97836
#define FFT_TABLE_SIZE              (FFT_GLOBAL_SIZE + FFT_VIF_ENTRY_NUM * FFT_CNTR_PER_ENTRY) //67
#define FFT_GLOBAL_SIZE             (3)
#define FFT_CNTR_PER_ENTRY          (2)
#define FFT_VIF_ENTRY_NUM           (40)
#define FFT_VIF_NOT_FOUND_CNT       (FFT_BASE + 0)
#define FFT_DMAC_NO_MATCH_CNT       (FFT_BASE + 1)
#define FFT_FFT_NOT_FOUND_CNT       (FFT_BASE + 2)
#define FFT_VIF_BASE                (FFT_BASE + FFT_GLOBAL_SIZE)      // = 97839
#define FFT_VIF_RCV_OFF             (0)   // entry receive counter offset
#define FFT_VIF_TRN_OFF             (1)   // entry transmit counter offset

#define PERVIF_IN_BASE              (FFT_VIF_BASE + FFT_VIF_RCV_OFF)
#define PERVIF_OUT_BASE             (FFT_VIF_BASE + FFT_VIF_TRN_OFF)  // next free counter = 97903 (98000)

//Number of packets passed Access List with no match result
#define AS_NOT_CNT                  (FFT_BASE + FFT_TABLE_SIZE)       // = 97903

//Number of sampling packets sent to CPU direction
#define ALIST_SAMP_CPU              (AS_NOT_CNT + 1)                  // = 97904

// Default policy stats
#define POLICY_CNTR_DEF_POL_BASE    (ALIST_SAMP_CPU + 1)              // = 97905
#define POLICY_CNTR_DEF_POL_SIZE    4
#define POLICY_CNTR_DEF_POL_DRP     (POLICY_CNTR_DEF_POL_BASE)
#define POLICY_CNTR_DEF_POL_CNT     (POLICY_CNTR_DEF_POL_BASE + 1)
#define POLICY_CNTR_DEF_POL_PAS     (POLICY_CNTR_DEF_POL_BASE + 2)
#define POLICY_CNTR_DEF_POL_CPU     (POLICY_CNTR_DEF_POL_BASE + 3)

#define PORTS_STATS                                    MAX_PHYS_PORT_NUM
#define LACP_BYPASS_BASE                               (POLICY_CNTR_DEF_POL_BASE+POLICY_CNTR_DEF_POL_SIZE)
#define LACP_BYPASS_SIZE                               0
#define ARP_BYPASS_BASE                                LACP_BYPASS_BASE + LACP_BYPASS_SIZE


#define ARP_BYPASS_SIZE                                PORTS_STATS //temporary ack could be recived from 32 ports

#define IP2ME_OFF                                      PORTS_STATS*2
#define IPv6_LOC                                       PORTS_STATS*3
#define OTH_OFF                                        PORTS_STATS*4

//sends
#define SENDS_CTRL                                     (LACP_BYPASS_BASE +  PORTS_STATS*4)
#define SENDS_CTRL_SIZE                                 4




//#define POLICY_CNTR_MATCH_BASE      (POLICY_CNTR_DEF_POL_BASE + POLICY_CNTR_DEF_POL_SIZE)

/////////////////////////////////////////////////
// Imem Group 0 : 24880 [98000..122879] double counters  ALIST and RTM
/////////////////////////////////////////////////

#define ALIST_BASE                  0x18000
#define ALIST_SIZE                  (ALIST_CNTR_SIZE)

//Access List feature configuration
#define AC_CNTRL_0                  ALIST_BASE
#define ALIST_CNTR_SIZE             10240  //1024 * 10 entries * 1 counter per entry

//global rtm counters block
//Counters format is per port and per protocol and includes Receive and Drop as regular.
#define RT_MONITOR_BASE_CNTR        (ALIST_BASE + ALIST_SIZE)           // = 108240
#define MAX_PHYS_PORT_NUM           32
#define MAX_PROT_NUM                8
#define RT_MONITOR_SIZE             (MAX_PHYS_PORT_NUM * MAX_PROT_NUM * 2)  //(=512)
                                    // 512 = 32 physical ports * 8 protocol types * 2 (not packet cnt, bytes cnt as it's dual counters, so why?)

//The Excluded RTM block represents counters for Policy exclude feature if it enable.
//Counter format is per port and protocol and includes Receive counters only
#define RT_MONITOR_EXLUD_BASE_CNTR  (RT_MONITOR_BASE_CNTR + RT_MONITOR_SIZE)//= 108752
#define RT_MONITOR_EXLUD_SIZE       RT_MONITOR_SIZE //(=512)
                                    // 512 = 32 physical ports * 8 protocol types * 2 (not packet cnt, bytes cnt as it's dual counters, so why?)

//The Per Policy RTM block represents counters per policy.
//Counter format is per protocol and includes Receive and Drop as regular.
//RT_MONITOR_POLICY is not clear
#define RT_MONITOR_POLICY_BASE_CNTR (RT_MONITOR_EXLUD_BASE_CNTR + RT_MONITOR_EXLUD_SIZE + 1) // = 109152
#define RT_MONITOR_POLICY_SIZE      (POLICY_CNTR_NUMBER * MAX_PROT_NUM * 2) //(=6464)404 * 8 * 2
                                    // 6464 = 8(protocol) * 2(receive/drop) * 404(policies)
                                    // Next free counter 115616


//posted counters
#define RTPC_POSTED_DEBUG_CNTR_BASE 0

//just for driver stay in the posted
#define OOS_ACT_TB                  0
#define OOS_ACT_TB_SIZE             100
#define OOS_SAMP_TB                 0
#define OOS_SAMP_TB_SIZE            100
#define GC_INB_REPRT                0
#define OS_MSG_CNTR_INST_SIZE       64
#define OS_MSG_CNTR_SIZE            128
#define OS_BASE                     0
#define GS_OOS_MATCH                0
#define GS_POL_00_BASE              0

/*
//Special Counters ( group 1 )
#define SP_CNTR_BASE        4096
#define SP_CNTR_SISE        128

#define SP_EBDMA_CNTR       SP_CNTR_BASE  // should be aligned to 64
#define SP_EBDMA_CNTR_SIZE  34
#define SP_IBDMA_CNTR       4144          // should be aligned to 16 SP_EBDMA_CNTR + 48
#define SP_IBDMA_CNTR_SIZE  1
#define SP_IFDMA_CNTR       4160          // should be aligned to 64 SP_EBDMA_CNTR + 64
#define SP_IFDMA_CNTR_SIZE  33
#define SP_EFDMA_CNTR       4208          // should be aligned to 16 SP_IFDMA_CNTR + 48
#define SP_EFDMA_CNTR_SIZE  16
#define SP_MODIFY_0_CNTR    4205          // single SP_EFDMA_CNTR - 3; send a frame to a full ETFD queue
#define SP_MODIFY_1_CNTR    4206          // single SP_EFDMA_CNTR - 2; send a frame to a full HTFD queue
#define SP_MODIFY_2_CNTR    4207          // single SP_EFDMA_CNTR - 1; send a frame to a full Output queue
#define SP_H_LEARN_0_CNTR   4200          // single SP_EFDMA_CNTR - 8
#define SP_H_LEARN_1_CNTR   4201          // single SP_EFDMA_CNTR - 7
#define SP_RT_CNTR          4202          // single SP_EFDMA_CNTR - 6
*/


#define OOS_SAMP_SIZE_CONST            0x2000 //100
#define BDOS_SAMP_SIZE_CONST           0x10 //100
#define IMM_SAMP_SIZE_CONST            0x2000 //100
#define ALIST_SIZE_CONST               0x2000 //100
#define OOS_ACT_SIZE_CONST             0x2000 //100
#define TP_SIZE_CONST                  0x2000 //100
#define ROUTING_IS_MY_IP_SIZE_CONST    0x2000 //100
#define PPS_TIN_LIN_SIZE_CONST         0x28



#endif // _XAD_CNTRBASE_H_
