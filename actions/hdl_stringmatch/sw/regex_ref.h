// ****************************************************************
// (C) Copyright International Business Machines Corporation 2017
// Author: Gou Peng Fei (shgoupf@cn.ibm.com)
// ****************************************************************

#ifndef F_REGEX_REF
#define F_REGEX_REF

#include <inttypes.h>

typedef struct {
    uint32_t packet_id;
    uint32_t pattern_id;
    uint16_t offset;
} sm_stat;

#ifdef __cplusplus
extern "C" {
#endif
void    regex_ref_push_pattern (const char* in_patt);
void    regex_ref_push_packet (const char* in_pkt, uint32_t in_pkt_id);
sm_stat regex_ref_get_result (uint32_t in_pkt_id);
int     regex_ref_get_num_matched_pkt();
#ifdef __cplusplus
}
#endif

#endif
