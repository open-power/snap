/**
 * Simple hash-join algorithm in C.
 *
 * Example code in Python from:
 *    http://rosettacode.org/wiki/Hash_join
 *
 * Example for hashtable from:
 *    https://gist.github.com/tonious/1377667
 *
 * Bruno and Frank 2016, 2017
 *
 * Comments:
 *   - Avoid void *
 *   - Put parameter arrays on stack instead of pointer passing
 *     such that HSL can use them to generate proper interfaces
 *   - No pointer chasing - use multidimensional tables (memory ...) instead
 */

#include "action_hashjoin_hls.H"

/*
 * The strcmp() function compares the two strings s1 and s2. It
 * returns an integer less than, equal to, or greater than zero if s1
 * is found, respectively, to be less than, to match, or be greater
 * than s2.
 */
static int hashkey_cmp(hashkey_t s1, hashkey_t s2)
{
        unsigned char i;

        for (i = 0; i < sizeof(hashkey_t); i++) {
#pragma HLS UNROLL factor=2
                if (*s1 == 0 || *s2 == 0)
                        break;

                if (*s1 != *s2)
                        return *s1 - *s2;

                s1 += 1;
                s2 += 1;
        }
        return *s1 - *s2;
}

void hashkey_cpy(hashkey_t dst, hashkey_t src)
{
        unsigned char i;

        for (i = 0; i < sizeof(hashkey_t); i++) {
#pragma HLS UNROLL factor=2
                *dst = *src;
                src++;
                dst++;
        }
}

static size_t hashkey_len(hashkey_t str)
{
        unsigned char len;

        for (len = 0; len < sizeof(hashkey_t); len++) {
#pragma HLS UNROLL factor=2
                if (*str == 0)
                        break;
                str++;
        }
        return len;
}

/* FIXME We need to use the HLS built in version instead of this */
static void table1_cpy(table1_t *dst, table1_t *src)
{
	/* FIXME memcpy(dst, src, sizeof(*dest)); did not work! */
	hashkey_cpy(dst->name, src->name);
	dst->age = src->age;
}

#if defined(NO_SYNTH)
static inline void print_hex(table1_t *buf, size_t len)
{
        unsigned char x;
        char *d = (char *)buf;

        fprintf(stderr, "{ ");
        for (x = 0; x < len; x++)
                fprintf(stderr, "%02x, ", d[x]);
        fprintf(stderr, "}");
}

void ht_dump(hashtable_t *ht)
{
        unsigned short i, j;
	static int printed = 0;

	if (printed++)
		return;

        fprintf(stderr, "hashtable = {\n");
        for (i = 0; i < HT_SIZE; i++) {
                entry_t *entry = &ht->table[i];

                if (!entry->used)
                        continue;

                fprintf(stderr, "  .ht[%d].key = \"%s\" = {\n", i, entry->key);
                for (j = 0; j < entry->used; j++) {
                        table1_t *multi = &entry->multi[j];

                        fprintf(stderr, "    { .val = { ");
                        print_hex(multi, sizeof(*multi));
                        fprintf(stderr, " },\n");
                }
		fprintf(stderr, "  },\n");
        }
        fprintf(stderr, "};\n");
}
#else
#  define ht_dump(ht)
#endif

unsigned int ht_count(hashtable_t *ht)
{
        unsigned int i, j;
        unsigned int count = 0;

        for (i = 0; i < HT_SIZE; i++) {
                entry_t *entry = &ht->table[i];

                if (!entry->used)
                        continue;

                for (j = 0; j < entry->used; j++)
                        count++;
        }
        return count;
}
/* Create a new hashtable. */
void ht_init(hashtable_t *ht)
{
        unsigned int i;

        for (i = 0; i < HT_SIZE; i++) {
/* #pragma HLS UNROLL*/
                entry_t *entry = &ht->table[i];
                entry->used = 0;
        }
}

/* Hash a string for a particular hash table. */
int ht_hash(hashkey_t key)
{
        unsigned long int hashval = 0;
        unsigned int i;
        unsigned len = hashkey_len(key);

        /* Convert our string to an integer */
        for (i = 0; hashval < ULONG_MAX && i < len; i++) {
/* #pragma HLS UNROLL */ // Cannot unroll loop completely: variable loop bound.
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
int ht_set(hashtable_t *ht, hashkey_t key,
           table1_t *value)
{
        int rc;
        unsigned int i;
        unsigned int bin = 0;

        bin = ht_hash(key);

        /* search if entry exists already */
        for (i = 0; i < HT_SIZE; i++) {
/* #pragma HLS UNROLL */
                table1_t *multi;
                entry_t *entry = &ht->table[bin];

                if (entry->used == 0) { /* hey unused, we can have it */
                        hashkey_cpy(entry->key, key);
                        multi = &entry->multi[entry->used];
                        table1_cpy(multi, value);
                        entry->used++;
                        return 0;
                }

                rc = hashkey_cmp(key, entry->key);
                if (rc == 0) {          /* insert new multi */
                        if (entry->used == HT_MULTI)
                                return -1;      /* does not fit */

                        multi = &entry->multi[entry->used];
                        table1_cpy(multi, value);
                        entry->used++;
                        return 0;
                }

                /* double hash because of collision */
                if (rc != 0)            /* try next one - not smart */
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
int ht_get(hashtable_t *ht, char *key)
{
        int rc;
        unsigned int i;
        unsigned int bin = 0;
        entry_t *entry = NULL;

        bin = ht_hash(key);

        /* search if entry exists already */
        for (i = 0; i < HT_SIZE; i++) {
/* #pragma HLS UNROLL */
                entry = &ht->table[bin];

                if (entry->used == 0)   /* key not there */
                        return -1;

                rc = hashkey_cmp(key, entry->key);
                if (rc == 0)            /* good key was found */
                        return bin;

                /* double hash */
                if (rc != 0)            /* try next one - not smart */
                        bin = (bin + 1) % HT_SIZE;
        }

        return -1;
}

#if defined(NO_SYNTH)
void table3_dump(table3_t *table3, unsigned int table3_idx)
{
        unsigned int i;
        table3_t *t3;

        fprintf(stderr, "table3_t table3[] = { \n");
        for (i = 0; i < table3_idx; i++) {
                t3 = &table3[i];
                fprintf(stderr,
			"  { .name = \"%s\", .animal = \"%s\", .age=%d } /* #%d */\n",
			t3->name, t3->animal, t3->age, i);
        }
        fprintf(stderr, "}; /* %d lines */\n", table3_idx);
}
#endif

#if defined(CONFIG_HOSTSTYLE_ALGO)

int action_hashjoin_hls(t1_fifo_t *fifo1, unsigned int table1_used,
			t2_fifo_t *fifo2, unsigned int table2_used,
			t3_fifo_t *fifo3, unsigned int *table3_used)
{
        unsigned int i, j;
	table1_t t1;
	static hashtable_t __hashtable;
        hashtable_t *h = &__hashtable;
	unsigned int table3_idx = 0;

	/* preserve hashtable if table1 is not passed */
	if (table1_used)
		ht_init(h);

        /* hash phase */
        for (i = 0; i < table1_used; i++) {
/* #pragma HLS PIPELINE */
                t1 = fifo1->read();

#if defined(CONFIG_FIFO_DEBUG)
		fprintf(stderr, "fifo1->read(%d, %s)\n", i, t1.name);
#endif
                ht_set(h, t1.name, &t1);
        }

#if defined(CONFIG_HASHTABLE_DEBUG)
        ht_dump(h);
#endif

 table2_inserting:
        for (i = 0; i < table2_used; i++) {
/* #pragma HLS PIPELINE */
                int bin;
                entry_t *entry;
                table2_t t2 = fifo2->read();

#if defined(CONFIG_FIFO_DEBUG)
		fprintf(stderr, "fifo2->read(%d, %s)\n", i, t2.name);
#endif
                bin = ht_get(h, t2.name);
                if (bin == -1)
                        continue;       /* nothing found */

                entry = &h->table[bin];
	multihash_entry_processing:
                for (j = 0; j < entry->used; j++) {
/* #pragma HLS UNROLL factor=8 */
                        table1_t *m = &entry->multi[j];
			table3_t t3;

			hashkey_cpy(t3.name, t2.name);
			hashkey_cpy(t3.animal, t2.animal);
			t3.age = m->age;
			fifo3->write(t3);
#if defined(CONFIG_FIFO_DEBUG)
			fprintf(stderr, "fifo3->write(%d, %d/%d, %s)\n",
				table3_idx, i, j, t3.name);
#endif
			table3_idx++;
                }
        }

	*table3_used = table3_idx;
	return 0;
}

#else

static void hashkey_zero(hashkey_t s)
{
        unsigned char i;

        for (i = 0; i < sizeof(hashkey_t); i++)
#pragma HLS UNROLL factor=2
		s[i] = 0;
}

/*
 * Alternate version of the algorithm not using the multihash table.
 * According to recent discussions, this must not necesarrilly help
 * to get the performance/optimizations better. But it is there as
 * way to try out different things.
 */
int action_hashjoin_hls(t1_fifo_t *fifo1, unsigned int table1_used,
			t2_fifo_t *fifo2, unsigned int table2_used,
			t3_fifo_t *fifo3, unsigned int *table3_used)
{
        unsigned int i, j;
	static table1_t t1[TABLE1_SIZE];
	static unsigned int t1_idx = 0;
	unsigned int table3_idx = 0;

        /* do not use a hash phase */
	if (t1_idx == 0) {
		for (i = 0; i < table1_used; i++)
			t1[i] = fifo1->read();
		for (; i < TABLE1_SIZE; i++) {
			hashkey_zero(t1[i].name);
			t1[i].age = 0;
		}
		t1_idx = table1_used;
	}

	/* Simle O(n2) loop which should be flattened by HLS optimizer */
        for (i = 0; i < table2_used; i++) {
                table2_t t2 = fifo2->read();

#if defined(CONFIG_FIFO_DEBUG)
		fprintf(stderr, "fifo2->read(%d, %s)\n", i, t2.name);
#endif
                for (j = 0; j < TABLE1_SIZE; j++) {
#pragma HLS UNROLL factor=8
			table3_t t3;

			if (hashkey_cmp(t1[j].name, t2.name) == 0) {
				hashkey_cpy(t3.name, t2.name);
				hashkey_cpy(t3.animal, t2.animal);
				t3.age = t1[j].age;
				fifo3->write(t3);
#if defined(CONFIG_FIFO_DEBUG)
				fprintf(stderr, "fifo3->write(%d, %d/%d, %s)\n",
					table3_idx, i, j, t3.name);
#endif
				table3_idx++;
			}
		}
        }

	*table3_used = table3_idx;
	return 0;
}

#endif /* CONFIG_HOSTSTYLE_ALGO */
