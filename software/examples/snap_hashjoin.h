#ifndef __SNAP_HASHJOIN_H__
#define __SNAP_HASHJOIN_H__

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

#include <stdint.h>
#include <stdio.h>
#include <libsnap.h>
#include <action_hashjoin.h>

static inline void print_hex(void *buf, size_t len)
{
	unsigned int x;
	char *d = buf;

	fprintf(stderr, "{ ");
	for (x = 0; x < len; x++)
		fprintf(stderr, "%02x, ", d[x]);
	fprintf(stderr, "}");
}

static inline void ht_dump(hashtable_t *ht)
{
	unsigned int i, j;

	fprintf(stderr, "hashtable = {\n");
	for (i = 0; i < HT_SIZE; i++) {
		entry_t *entry = &ht->table[i];

		if (!entry->used)
			continue;

		fprintf(stderr, "  { .ht[%d].key = \"%s\", .used = %d, .multi = {\n",
		       i, entry->key, entry->used);
		for (j = 0; j < entry->used; j++) {
			table1_t *multi = &entry->multi[j];

			fprintf(stderr, "      { .val = ");
			print_hex(multi, sizeof(*multi));
			fprintf(stderr, " },\n");
		}
		fprintf(stderr, "    },\n"
		       "  },\n");
	}
	fprintf(stderr, "};\n");
}

static inline void table1_dump(table1_t *table1, unsigned int table1_idx)
{
	unsigned int i;
	table1_t *t1;

	fprintf(stderr, "table1_t table1[] = {\n");
	for (i = 0; i < table1_idx; i++) {
		t1 = &table1[i];
		fprintf(stderr, "  { .name = \"%s\", .age=%d } /* %d. */\n",
		       t1->name, t1->age, i);
	}
	fprintf(stderr, "}; /* table1_idx=%d\n", table1_idx);
}

static inline void table2_dump(table2_t *table2, unsigned int table2_idx)
{
	unsigned int i;
	table2_t *t2;

	fprintf(stderr, "table2_t table2[] = {\n");
	for (i = 0; i < table2_idx; i++) {
		t2 = &table2[i];
		fprintf(stderr, "  { .name = \"%s\", .animal = \"%s\" } "
		       "/* %d. */\n", t2->name, t2->animal, i);
	}
	fprintf(stderr, "}; /* table2_idx=%d\n", table2_idx);
}

static inline void table3_dump(table3_t *table3, unsigned int table3_idx)
{
	unsigned int i;
	table3_t *t3;

	fprintf(stderr, "table3_t table3[] = {\n");
	for (i = 0; i < table3_idx; i++) {
		t3 = &table3[i];
		fprintf(stderr, "  { .name = \"%s\", .animal = \"%s\", .age=%d } "
		       "/* %d. */\n", t3->name, t3->animal, t3->age, i);
	}
	fprintf(stderr, "}; /* table3_idx=%d\n", table3_idx);
}

#endif	/* __SNAP_HASHJOIN_H__ */
