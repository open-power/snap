#ifndef __ACTION_HASHJOIN_H__
#define __ACTION_HASHJOIN_H__

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
#include <libdonut.h>

#define HASHJOIN_ACTION_TYPE 0x0022

#define TABLE1_SIZE 32
#define TABLE2_SIZE 32
#define TABLE3_SIZE (TABLE1_SIZE * TABLE2_SIZE)
#define HT_SIZE (TABLE1_SIZE * 16) /* size of hashtable */
#define HT_MULTI TABLE1_SIZE /* multihash entries depends on table1 */

typedef char hashkey_t[64];
typedef char hashdata_t[256];

/* FIXME Make tables entry size a multiple of 64 bytes */
#define HASHJOIN_ALIGN 128

typedef struct table1_s {
	hashkey_t name;         /* 64 bytes */
	uint32_t age;           /*  4 bytes */
	uint8_t reserved[60];   /* 60 bytes */
} table1_t;

typedef struct table2_s {
	hashkey_t name;         /* 64 bytes */
	hashkey_t animal;       /* 64 bytes */
} table2_t;

typedef struct table3_s {
	hashkey_t animal;       /* 64 bytes */
	hashkey_t name;         /* 64 bytes */
	uint32_t age;           /*  4 bytes */
	uint8_t reserved[60];   /* 60 bytes */
} table3_t;

typedef struct entry_s {
	hashkey_t key;		/* key */
	unsigned int used;	/* list entries used */
	table1_t multi[HT_MULTI];/* fixed size */
} entry_t;

typedef struct hashtable_s {
	entry_t table[HT_SIZE];	/* fixed size */
} hashtable_t;

struct hashjoin_job {
	struct dnut_addr t1; /* IN: input table1 for multihash */
	struct dnut_addr t2; /* IN: 2nd table2 to do join with */
	struct dnut_addr t3; /* OUT: resulting table3 */
	struct dnut_addr hashtable; /* CACHE: multihash table */

	uint64_t t1_processed; /* #entries cached, repeat if not all */
	uint64_t t2_processed; /* #entries processed, repeat if not all */
	uint64_t t3_produced;  /* #entries produced store them away */
	uint64_t checkpoint;
	uint64_t rc;
	uint64_t action_version;
};

static inline void print_hex(void *buf, size_t len)
{
	unsigned int x;
	char *d = buf;

	printf("{ ");
	for (x = 0; x < len; x++)
		printf("%02x, ", d[x]);
	printf("}");
}

static inline void ht_dump(hashtable_t *ht)
{
	unsigned int i, j;

	printf("hashtable = {\n");
	for (i = 0; i < HT_SIZE; i++) {
		entry_t *entry = &ht->table[i];

		if (!entry->used)
			continue;

		printf("  { .ht[%d].key = \"%s\", .used = %d, .multi = {\n",
		       i, entry->key, entry->used);
		for (j = 0; j < entry->used; j++) {
			table1_t *multi = &entry->multi[j];

			printf("      { .val = ");
			print_hex(multi, sizeof(*multi));
			printf(" },\n");
		}
		printf("    },\n"
		       "  },\n");
	}
	printf("};\n");
}

static inline void table3_dump(table3_t *table3, unsigned int table3_idx)
{
	unsigned int i;
	table3_t *t3;

	printf("table3_t table3[] = {\n");
	for (i = 0; i < table3_idx; i++) {
		t3 = &table3[i];
		printf("  { .name = \"%s\", .animal = \"%s\", .age=%d }\n",
		       t3->name, t3->animal, t3->age);
	}
	printf("};\n");
}

static inline void set_checkpoint(struct hashjoin_job *hj, uint64_t cp)
{
	hj->checkpoint = cp;
}

#endif	/* __ACTION_HASHJOIN_H__ */
