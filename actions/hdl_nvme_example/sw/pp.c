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
#include <stdlib.h>
#include <sys/types.h>

#include "pp.h"

struct __lba {
	off_t lba;
	unsigned int nblocks;
};

struct __pp {
	pthread_mutex_t lock;
	int prefetch_count;
	struct __lba *lba_list;	/* lba request history */
	unsigned int lba_max;	/* maximum # of lba histrory */
	unsigned int lba_ridx;	/* read index */
	unsigned int lba_widx;	/* write index */
};

struct __pp pp;

int pp_init(int strategy __attribute__((unused)),
	int prefetch_count,
	unsigned int lba_max)
{
	pp.lba_list = calloc(1, lba_max * sizeof(struct __lba));
	if (!pp.lba_list)
		return -1;
	pp.prefetch_count = prefetch_count;

	return 0;
}
void pp_done(void)
{
	if (pp.lba_list)
		free(pp.lba_list);
	pp.lba_list = NULL;
}

/*
 * Every time a new LBA is requested, we need to be called to update
 * our list of the last lba_max LBAs. This is required to calculate
 * the optimal priolist every once in a while, e.g. every 1 sec.
 *
 * @p:         priority detector
 * @lba:       requested LBA
 * @nblocks:   how many blocks per LBA
 */
int pp_add_lba(off_t lba __attribute__((unused)),
	size_t nblocks __attribute__((unused)))
{
	return 0;
}

/*
 * The user is asked to update the priolist in a regular fashion such
 * that the optimal prefetch sequence can be used.
 *
 * @p:         priority detector
 * @priolist:  array of lba offsets e.g. -4, -2, 2, 4
 * @n:         size of priorization list
 */
int pp_get_offslist(int *offslist, unsigned int n, size_t nblocks)
{
	unsigned int i;
	int offs;

	for (i = 0, offs = nblocks; i < n/2; i++, offs += nblocks)
		offslist[i] = offs;

	for (i = n/2, offs = -nblocks; i < n; i++, offs -= nblocks)
		offslist[i] = offs;

	return 0;
}

