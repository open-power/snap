// ****************************************************************
// (C) Copyright International Business Machines Corporation 2017
// Author: Gou Peng Fei (shgoupf@cn.ibm.com)
// ****************************************************************

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include "regex_ref.h"
#include "constants.h"
#include "utils/re_match.h"

using namespace std;

class RegexRef
{
public:
    RegexRef()
    {
        patterns.clear();
        stats.clear();
        num_matched_packets = 0;
    }
    ~RegexRef() {}

    void push_pattern (string & in_patt)
    {
        patterns.push_back (in_patt);
    }

    void push_packet (string & in_pkt, uint32_t in_pkt_id)
    {
        if (patterns.size() == 0) {
            cout << "WARNING! No patterns in regex_ref" << endl;
        }

        for (uint32_t i = 0; i < patterns.size(); i++) {
            // PATTERN ID starts from 1
            if (gen_result (in_pkt, in_pkt_id, patterns[i], i+1)) {
                break;
            }
        }
    }

    sm_stat get_result(uint32_t in_pkt_id)
    {
        return stats[in_pkt_id];
    }

    int get_num_matched_pkt()
    {
        return num_matched_packets;
    }

private:
    vector<string> patterns;

    // <key = PKT ID, value = sm_stat>
    map<uint32_t, sm_stat> stats;

    int num_matched_packets;

    int gen_result (string & in_pkt, uint32_t in_pkt_id,
                    string & in_patt, uint32_t in_patt_id)
    {
        int offset = re_match (in_patt.c_str(), in_pkt.c_str());

        if (offset == -2) {
            cout << "WARNING! Pattern[ " << dec << in_patt_id << "] "
                 << in_patt << " compiled error" << endl;
            return 1;
        }

        if (offset == -1) {
            cout << "WARNING! Pattern[ "
                 << dec << in_patt_id << "] " << in_patt
                 << " match error on packet["
                 << dec << in_pkt_id << "] " << in_pkt
                 << endl;
            return 1;
        }

        if ((offset != 0) && (in_pkt != "")) {
            if (stats.find(in_pkt_id) == stats.end()) {
                stats[in_pkt_id].pattern_id = 0;
                stats[in_pkt_id].packet_id = 0;
                stats[in_pkt_id].offset = 0;
            }

            if (stats[in_pkt_id].pattern_id <= 0) {
                num_matched_packets++;
            }

            if ((stats[in_pkt_id].pattern_id <= 0) ||
                ((stats[in_pkt_id].pattern_id > 0) && (stats[in_pkt_id].offset > offset))) {
                stats[in_pkt_id].pattern_id = in_patt_id;
                stats[in_pkt_id].offset = offset;
                stats[in_pkt_id].packet_id = in_pkt_id;
            }

            if ((stats[in_pkt_id].pattern_id > 0) && ((stats[in_pkt_id].pattern_id % NUM_OF_PU) == 0)) {
                return 1;
            }
        }

        return 0;
    }
};

RegexRef regex_ref;

void regex_ref_push_pattern(const char* in_patt)
{
    string patt(in_patt);
    // Need to push in the patt id order
    regex_ref.push_pattern(patt);
}

void regex_ref_push_packet(const char* in_pkt, uint32_t in_pkt_id)
{
    string pkt(in_pkt);
    regex_ref.push_packet(pkt, in_pkt_id);
}

sm_stat regex_ref_get_result(uint32_t in_pkt_id)
{
    return regex_ref.get_result(in_pkt_id);
}

int regex_ref_get_num_matched_pkt()
{
    return regex_ref.get_num_matched_pkt();
}
