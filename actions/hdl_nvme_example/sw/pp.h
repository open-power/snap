#ifndef __PP_H__
#define __PP_H__

/**
 * Copyright 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Prefetch Predictor
 *
 * From a given sequence of LBAs (logical block addresses), we like
 * to predict an optimal order of LBAs to be prefetched. That should
 * help to reduce the latency needed to load the next LBA from an
 * NVMe device.
 *
 * We tried positive and negative sequences, but we wondered if a
 * sequence based on the history of requested LBAs can be of advantage.
 */

#include <stdint.h>

enum pp_strategy {
	PP_STRATEGY_UP = 0,
	PP_STRATEGY_DOWN,
	PP_STRATEGY_UPDOWN, /* default */
	PP_STRATEGY_SMART,
	PP_STRATEGY_MAX,
};

typedef int (* pp_put_offslist_t)(void *put_data, int *offslist, unsigned int n, size_t nblocks);

int pp_init(int pp_prefetch, pp_put_offslist_t put,  size_t put_nblocks, void *put_data);
void pp_done(void);

/*
 * Every time a new LBA is requested, we need to be called to update
 * our list of the last lba_max LBAs. This is required to calculate
 * the optimal priolist every once in a while, e.g. every 1 sec.
 *
 * @lba:       requested LBA
 * @nblocks:   how many blocks per LBA
 */
int pp_add_lba(off_t lba, size_t nblocks, unsigned long usecs, int _read);

/*
 * The user is asked to update the priolist in a regular fashion such
 * that the optimal prefetch sequence can be used.
 *
 * @priolist:  array of lba offsets e.g. -4, -2, 2, 4
 * @n:         size of priorization list
 */
int pp_get_offslist(int *offslist, unsigned int n, size_t nblocks);

#endif /* __PP_H__ */
