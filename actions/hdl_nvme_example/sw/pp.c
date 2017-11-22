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
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <sys/types.h>

#include "pp.h"
#include "snap_internal.h"	/* ARRAY_SIZE, ... */

#define PP_HISTORY		10000

static int _pp_strategy = PP_STRATEGY_UPDOWN;
static int _pp_history = PP_HISTORY;

struct __lba {
	off_t lba;
	unsigned int nblocks;
	unsigned long usecs;
};

struct __pp {
	pthread_mutex_t lock;
	struct pp_funcs *f;
	int pp_prefetch;
	struct __lba *lba_list;	/* lba request history */
	unsigned int lba_max;	/* maximum # of lba history */
	unsigned int lba_ridx;	/* read index */
	unsigned int lba_widx;	/* write index */
	unsigned int lba_num;	/* valid entries */
	pthread_t tid;

	void *put_data;
	size_t put_nblocks;
	int (* pp_put_offslist)(void *put_data, int *offslist, unsigned int n, size_t nblocks);
};

#define PP_FLAG_ALLOC_LBA_LIST	0x0001
#define PP_FLAG_START_THREAD	0x0002

struct pp_funcs {
	unsigned int flags;
	int (* pp_add_lba)(off_t lba, size_t nblocks, unsigned long usecs, int _read);
	int (* pp_get_offslist)(int *offslist, unsigned int n, size_t nblocks);
	void * (* pp_thread)(struct __pp *pp);
};

static struct __pp pp;

/*
 * Every time a new LBA is requested, we need to be called to update
 * our list of the last lba_max LBAs. This is required to calculate
 * the optimal priolist every once in a while, e.g. every 1 sec.
 *
 * @p:         priority detector
 * @lba:       requested LBA
 * @nblocks:   how many blocks per LBA
 */
static int __pp_add_lba(off_t lba  __attribute__((unused)),
		size_t nblocks  __attribute__((unused)),
		unsigned long usecs  __attribute__((unused)),
		int _read __attribute__((unused)))
{
	if ((pp.f->flags & PP_FLAG_ALLOC_LBA_LIST) != PP_FLAG_ALLOC_LBA_LIST)
		return -1;

	pthread_mutex_lock(&pp.lock);

	pp.lba_list[pp.lba_widx].lba = lba;
	pp.lba_list[pp.lba_widx].nblocks = nblocks;
	pp.lba_list[pp.lba_widx].usecs = usecs;

	if (pp.lba_num < pp.lba_max) {
		pp.lba_num++;
		pp.lba_widx = (pp.lba_widx + 1) % pp.lba_max;
	} else {
		pp.lba_ridx = (pp.lba_ridx + 1) % pp.lba_max;
		pp.lba_widx = (pp.lba_widx + 1) % pp.lba_max;
	}

	pthread_mutex_unlock(&pp.lock);
	return 0;
}

static inline void __print_offslist(int *offslist, unsigned int n)
{
	unsigned int i;
	char s[128], num[32];

	strcpy(s, " ");
	for (i = 0; i < n; i++) {
		sprintf(num, "%d ", offslist[i]);
		strcat(s, num);
	}
	pp_trace("[%s] pp_offslist: [%s]\n", __func__, s); 
}

/*
 * The user is asked to update the priolist in a regular fashion such
 * that the optimal prefetch sequence can be used.
 *
 * @p:         priority detector
 * @offslist:  array of lba offsets e.g. -4, -2, 2, 4
 * @n:         size of priorization list
 */
static int __pp_updown_offslist(int *offslist, unsigned int n, size_t nblocks)
{
	unsigned int i;
	int offs;

	pthread_mutex_lock(&pp.lock);

	for (i = 0, offs = nblocks; i < n/2; i++, offs += nblocks)
		offslist[i] = offs;

	for (i = n/2, offs = -nblocks; i < n; i++, offs -= nblocks)
		offslist[i] = offs;

	pthread_mutex_unlock(&pp.lock);
	__print_offslist(offslist, n);
	return 0;
}

static int __pp_up_offslist(int *offslist, unsigned int n, size_t nblocks)
{
	unsigned int i;
	int offs;

	pthread_mutex_lock(&pp.lock);

	for (i = 0, offs = nblocks; i < n; i++, offs += nblocks)
		offslist[i] = offs;

	pthread_mutex_unlock(&pp.lock);
	__print_offslist(offslist, n);
	return 0;
}

static int __pp_down_offslist(int *offslist, unsigned int n, size_t nblocks)
{
	unsigned int i;
	int offs;

	pthread_mutex_lock(&pp.lock);

	for (i = 0, offs = -nblocks; i < n; i++, offs -= nblocks)
		offslist[i] = offs;

	pthread_mutex_unlock(&pp.lock);
	__print_offslist(offslist, n);
	return 0;
}

static void *__pp_thread(struct __pp *pp)
{
	pp_trace("[%s] pp.lba_num=%d pp.lba_widx=%d pp.lba_ridx=%d\n",
		__func__, pp->lba_num, pp->lba_widx, pp->lba_ridx);

	return NULL;
}

static struct pp_funcs pp_funcs[] = {
	/* 0: PP_STRATEGY_UP */
	{ .flags = 0x0,
	  .pp_add_lba = NULL,
	  .pp_get_offslist = __pp_up_offslist,
	  .pp_thread = __pp_thread },
	/* 1: PP_STRATEGY_DOWN */
	{ .flags = 0x0,
	  .pp_add_lba = NULL,
	  .pp_get_offslist = __pp_down_offslist,
	  .pp_thread = __pp_thread },
	/* 2: PP_STRATEGY_UPDOWN */
	{ .flags = 0x0,
	  .pp_add_lba = NULL,
	  .pp_get_offslist = __pp_updown_offslist,
	  .pp_thread = __pp_thread },
	/* 3: PP_STRATEGY_SMART */
	{ .flags = (PP_FLAG_ALLOC_LBA_LIST | PP_FLAG_START_THREAD),
	  .pp_add_lba = __pp_add_lba,
	  .pp_get_offslist = __pp_updown_offslist,
	  .pp_thread = __pp_thread },
};

int pp_add_lba(off_t lba, size_t nblocks, unsigned long usecs, int _read)
{
	pp_trace("  [%s] %s[%4u] LBA=%ld nblocks=%i %ld usecs\n",
		__func__, _read ? "lba_read" : "lba_write",
		pp.lba_widx, lba, (int)nblocks, usecs);

	if (pp.f->pp_add_lba)
		return pp.f->pp_add_lba(lba, nblocks, usecs, _read);
	return 0;
}

int pp_get_offslist(int *offslist, unsigned int n, size_t nblocks)
{
	/* pp_trace("[%s]\n", __func__); */

	if (pp.f->pp_get_offslist)
		return pp.f->pp_get_offslist(offslist, n, nblocks);
	return 0;
}

static void *pp_thread(void *arg __attribute__((unused)))
{
	struct __pp *pp = (struct __pp *)arg;

	while (1) {
		/* Do something useful */
		if (pp->f->pp_thread) {
			pthread_mutex_lock(&pp->lock);
			pp->f->pp_thread(pp);
			pthread_mutex_unlock(&pp->lock);
		}
		if (pp->pp_put_offslist)
			pp->pp_put_offslist(pp->put_data, NULL,
				pp->pp_prefetch, pp->put_nblocks);

		sleep(1);
		pthread_testcancel();	/* go home if requested */
	}

	return NULL;
}

/*
 * @strategy:     Devines how the next LBAs should be prefetched
 * @pp_prefetch:  How many entries should be prefetched
 * @pp_history:   How many LBAs should be kept for the calculation
 */
int pp_init(int pp_prefetch, pp_put_offslist_t put,  size_t put_nblocks,
	void *put_data)
{
	int rc;

	pthread_mutex_init(&pp.lock, NULL);

	pp.f = &pp_funcs[_pp_strategy];
	pp.lba_list = NULL;

	if (pp.f->flags & PP_FLAG_ALLOC_LBA_LIST) {
		pp.lba_list = calloc(1, _pp_history * sizeof(struct __lba));
		if (!pp.lba_list)
			return -1;
		pp.lba_ridx = 0;
		pp.lba_widx = 0;
		pp.lba_max = _pp_history;
	}

	pp.pp_prefetch = pp_prefetch;
	pp.pp_put_offslist = put;
	pp.put_nblocks = put_nblocks;
	pp.put_data = put_data;
	pp.tid = 0;

	if (pp.f->flags & PP_FLAG_START_THREAD) {
		rc = pthread_create(&pp.tid, NULL, &pp_thread, &pp);
		if (rc != 0)
			goto err_out;
	}
	return 0;
 err_out:
	free(pp.lba_list);
	return -1;
}
void pp_done(void)
{
	if (pp.lba_list) {
		free(pp.lba_list);
		pp.lba_list = NULL;
	}

	if (pp.tid != 0) {
		pthread_cancel(pp.tid);
		pthread_join(pp.tid, NULL);
		pp.tid = 0;
	}
}

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	const char *env;

	env = getenv("CBLK_HISTORY");
	if (env != NULL)
		_pp_history = strtol(env, (char **)NULL, 0);
	if (_pp_history <= 0)
		_pp_history = PP_HISTORY;

	env = getenv("CBLK_STRATEGY");
	if (env != NULL) {
		if (strcmp(env, "UP") == 0)
			_pp_strategy = PP_STRATEGY_UP;
		else if (strcmp(env, "DOWN") == 0)
			_pp_strategy = PP_STRATEGY_DOWN;
		else if (strcmp(env, "UPDOWN") == 0)
			_pp_strategy = PP_STRATEGY_UPDOWN;
		else if  (strcmp(env, "SMART") == 0)
			_pp_strategy = PP_STRATEGY_SMART;
		else if (env != NULL) {
			_pp_strategy = strtol(env, (char **)NULL, 0);
			if (_pp_strategy < 0 || _pp_strategy >= PP_STRATEGY_MAX)
				_pp_strategy = PP_STRATEGY_UPDOWN;
		}
	}

	pp_trace("[%s] CBLK_HISTORY=%d CBLK_STRATEGY=%s\n", __func__, _pp_history,
		getenv("CBLK_STRATEGY")); 
}

static void _done(void) __attribute__((destructor));

static void _done(void)
{
	pp_done();
}
