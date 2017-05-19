/*
 * Copyright 2017, International Business Machines
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
 * Example for HashJoin Algorithm
 *
 * Copyright (C) 2017 Rosetta.org
 *
 * Permission is granted to copy, distribute and/or modify this document
 * under the terms of the GNU Free Documentation License, Version 1.3
 * or any later version published by the Free Software Foundation;
 * with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
 * A copy of the license is included in the section entitled "GNU
 * Free Documentation License".
 */

/*
 * HLS Adoptations and other additions
 *
 * Copyright 2017, International Business Machines
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
 * Example to use the FPGA to do a hash join operation on two input
 * tables table1_t and table2_t resuling in a new combined table3_t.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <limits.h>
#include <libsnap.h>
#include <snap_internal.h>
#include <snap_hashjoin.h>

static int mmio_read32(struct snap_card *card,
		       uint64_t offs, uint32_t *data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, *data);
	return 0;
}

/*
 * The strcmp() function compares the two strings s1 and s2. It
 * returns an integer less than, equal to, or greater than zero if s1
 * is found, respectively, to be less than, to match, or be greater
 * than s2.
 */
static int hashkey_cmp(const hashkey_t s1, const hashkey_t s2)
{
	size_t i;

	for (i = 0; i < sizeof(hashkey_t); i++) {
		if (*s1 == 0 || *s2 == 0)
			break;

		if (*s1 != *s2)
			return *s1 - *s2;

		s1 += 1;
		s2 += 1;
	}
	return *s1 - *s2;
}

static void hashkey_cpy(hashkey_t dst, hashkey_t src)
{
	size_t i;

	for (i = 0; i < sizeof(hashkey_t); i++) {
		*dst = *src;
		src++;
		dst++;
	}
}

static size_t hashkey_len(hashkey_t str)
{
	size_t len;

	for (len = 0; len < sizeof(hashkey_t); len++) {
		if (*str == 0)
			break;
		str++;
	}
	return len;
}

/* FIXME We need to use the HLS built in version instead of this */
static void table1_cpy(table1_t *dest, table1_t *src)
{
	*dest = *src;
}

/* Create a new hashtable. */
static void ht_init(hashtable_t *ht)
{
	unsigned int i;

	for (i = 0; i < HT_SIZE; i++) {
		entry_t *entry = &ht->table[i];

		entry->used = 0;
	}
}

/* Hash a string for a particular hash table. */
static int ht_hash(hashkey_t key)
{
	unsigned long int hashval = 0;
	unsigned int i;
	unsigned len = hashkey_len(key);

	/* Convert our string to an integer */
	for (i = 0; hashval < ULONG_MAX && i < len; i++) {
		hashval = hashval << 8;
		hashval += key[i];
	}
	return hashval % HT_SIZE;
}

/**
 * Insert a key-value pair into a hash table.
 *
 * FIXME Review void *value and try to replace with hashdata_t ...
 *       failed on 1st try.
 *
 */
static int ht_set(hashtable_t *ht, hashkey_t key,
	   table1_t *value)
{
	int rc;
	unsigned int i;
	unsigned int bin = 0;

	bin = ht_hash(key);

	/* search if entry exists already */
	for (i = 0; i < HT_SIZE; i++) {
		table1_t *multi;
		entry_t *entry = &ht->table[bin];

		if (entry->used == 0) {	/* hey unused, we can have it */
			hashkey_cpy(entry->key, key);
			multi = &entry->multi[entry->used];
			table1_cpy(multi, value);
			entry->used++;
			return 0;
		}

		rc = hashkey_cmp(key, entry->key);
		if (rc == 0) {		/* insert new multi */
			if (entry->used == HT_MULTI)
				return -1;	/* does not fit */

			multi = &entry->multi[entry->used];
			table1_cpy(multi, value);
			entry->used++;
			return 0;
		}

		/* double hash because of collision */
		if (rc != 0)		/* try next one - not smart */
			bin = (bin + 1) % HT_SIZE;
	}

	return 0;
}

/**
 * Retrieve an array of values matching the key from a hash table.
 * Return the index and not the pointer to entry_t, since HLS does
 * not like that.
 *
 * Non-optimal double hash implementation: pick the next free entry.
 */
static int ht_get(hashtable_t *ht, char *key)
{
	int rc;
	unsigned int i;
	unsigned int bin = 0;
	entry_t *entry = NULL;

	bin = ht_hash(key);

	/* search if entry exists already */
	for (i = 0; i < HT_SIZE; i++) {
		entry = &ht->table[bin];

		if (entry->used == 0) 	/* key not there */
			return -1;

		rc = hashkey_cmp(key, entry->key);
		if (rc == 0)		/* good key was found */
			return bin;

		/* double hash */
		if (rc != 0)		/* try next one - not smart */
			bin = (bin + 1) % HT_SIZE;
	}

	return -1;
}

static void table3_init(unsigned int *table3_idx)
{
	*table3_idx = 0;
}

static int table3_append(table3_t *table3, unsigned int *table3_idx,
			 hashkey_t name, hashkey_t animal,
			 unsigned int age)
{
	table3_t *t3;

	t3 = &table3[*table3_idx];
	hashkey_cpy(t3->name, name);
	hashkey_cpy(t3->animal, animal);
	t3->age = age;
	*table3_idx = *table3_idx + 1;

	return *table3_idx;
}

/*
 * #!/usr/bin/python
 * from collections import defaultdict
 *
 * def hashJoin(table1, index1, table2, index2):
 *     h = defaultdict(list)
 *     # hash phase
 *     for s in table1:
 *        h[s[index1]].append(s)
 *     # join phase
 *     return [(s, r) for r in table2 for s in h[r[index2]]]
 *
 * for row in hashJoin(table1, 1, table2, 0):
 *     print(row)
 *
 * Output:
 *   ((27, 'Jonah'), ('Jonah', 'Whales'))
 *   ((27, 'Jonah'), ('Jonah', 'Spiders'))
 *   ((18, 'Alan'), ('Alan', 'Ghosts'))
 *   ((28, 'Alan'), ('Alan', 'Ghosts'))
 *   ((18, 'Alan'), ('Alan', 'Zombies'))
 *   ((28, 'Alan'), ('Alan', 'Zombies'))
 *   ((28, 'Glory'), ('Glory', 'Buffy'))
 */
static int hash_join(table1_t *table1, table2_t *table2, table3_t *table3,
		     hashtable_t *h, unsigned int *table3_idx)
{
	unsigned int i, j;
	table1_t *t1;

	/* hash phase */
	ht_init(h);
	for (i = 0; i < TABLE1_SIZE; i++) {
		t1 = &table1[i];

		if (hashkey_cmp(t1->name, "") == 0)
			continue;

		ht_set(h, t1->name, t1);
	}

	/* ht_dump(h); */

	table3_init(table3_idx);
	for (i = 0; i < TABLE2_SIZE; i++) {
		int bin;
		entry_t *entry;
		table2_t *t2 = &table2[i];

		bin = ht_get(h, t2->name);
		if (bin == -1)
			continue;	/* nothing found */

		entry = &h->table[bin];
		for (j = 0; j < entry->used; j++) {
			table1_t *m = &entry->multi[j];

			table3_append(table3, table3_idx,
				      t2->name, t2->animal, m->age);
		}
	}
	return 0;
}

static void print_job(struct hashjoin_job *j)
{
	printf("HashJoin Job\n");
	printf("  t1: %016llx %d bytes %ld entries\n",
	       (long long)j->t1.addr, j->t1.size,
	       j->t1.size/sizeof(table1_t));
	printf("  t2: %016llx %d bytes %ld entries\n",
	       (long long)j->t2.addr, j->t2.size,
	       j->t2.size/sizeof(table2_t));
	printf("  t3: %016llx %d bytes %ld entries\n",
	       (long long)j->t3.addr, j->t3.size,
	       j->t3.size/sizeof(table3_t));
	printf("  h:  %016llx %d bytes %ld entries\n",
	       (long long)j->hashtable.addr, j->hashtable.size,
	       j->hashtable.size/sizeof(entry_t));

}

static int action_main(struct snap_sim_action *action,
		       void *job, unsigned int job_len __unused)
{
	int rc;
	struct hashjoin_job *hj = (struct hashjoin_job *)job;
	table1_t *t1;
	table2_t *t2;
	table3_t *t3;
	hashtable_t *h;
	unsigned int table3_idx = 0;

	print_job(hj);

	t1 = (table1_t *)hj->t1.addr;
	if (!t1 || hj->t1.size/sizeof(table1_t) > TABLE1_SIZE) {
		printf("  t1.size/sizeof(table1_t) = %ld entries\n",
		       hj->t1.size/sizeof(table1_t));
		goto err_out;
	}

	t2 = (table2_t *)hj->t2.addr;
	if (!t2 || hj->t2.size/sizeof(table2_t) > TABLE2_SIZE) {
		printf("  t2.size/sizeof(table2_t) = %ld entries\n",
		       hj->t2.size/sizeof(table2_t));
		goto err_out;
	}

	t3 = (table3_t *)hj->t3.addr;
	if (!t3 || hj->t3.size/sizeof(table3_t) > TABLE3_SIZE) {
		printf("  t3.size/sizeof(table3_t) = %ld entries\n",
		       hj->t3.size/sizeof(table3_t));
		goto err_out;
	}

	h = (hashtable_t *)hj->hashtable.addr;
	if (hj->hashtable.size/sizeof(entry_t) > HT_SIZE) {
		printf("  hashtable.size/sizeof(entry_t) = %ld entries\n",
		       hj->hashtable.size/sizeof(entry_t));
		goto err_out;
	}

	rc = hash_join(t1, t2, t3, h, &table3_idx);
	hj->t3_produced = table3_idx;

	if (rc == 0) {
		action->job.retc = SNAP_RETC_SUCCESS;
	} else
		action->job.retc = SNAP_RETC_FAILURE;
	return 0;

 err_out:
	action->job.retc = SNAP_RETC_FAILURE;
	return -1;
}

static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = HASHJOIN_ACTION_TYPE,

	.job = { .retc = SNAP_RETC_FAILURE, },
	.state = ACTION_IDLE,
	.main = action_main,
	.priv_data = NULL,	/* this is passed back as void *card */
	.mmio_read32 = mmio_read32,

	.next = NULL,
};

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	snap_action_register(&action);
}
