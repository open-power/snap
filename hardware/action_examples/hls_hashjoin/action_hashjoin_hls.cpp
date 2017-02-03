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

#if !defined(NO_SYNTH)

#define MAX_NB_OF_BYTES_READ    (128 * 128)             // Value should be X*BPERDW
ap_uint<MEMDW> buffer_mem[MAX_NB_OF_BYTES_READ/BPERDW]; // if MEMDW=512 : 128*128=>256 words

#endif  /* NO_SYNTH */

static hashtable_t __hashtable;

/*
 * The strcmp() function compares the two strings s1 and s2. It
 * returns an integer less than, equal to, or greater than zero if s1
 * is found, respectively, to be less than, to match, or be greater
 * than s2.
 */
int hashkey_cmp(hashkey_t s1, hashkey_t s2)
{
        size_t i;

        for (i = 0; i < sizeof(hashkey_t); i++) {
		// FIXME TIMING #pragma HLS UNROLL
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
        size_t i;

        for (i = 0; i < sizeof(hashkey_t); i++) {
		//#pragma HLS UNROLL
                *dst = *src;
                src++;
                dst++;
        }
}

size_t hashkey_len(hashkey_t str)
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
void table1_cpy(table1_t *dest, table1_t *src)
{
        *dest = *src;
}

#if defined(NO_SYNTH)
static inline void print_hex(table1_t *buf, size_t len)
{
        unsigned int x;
        char *d = (char *)buf;

        printf("{ ");
        for (x = 0; x < len; x++)
                printf("%02x, ", d[x]);
        printf("}");
}
void ht_dump(hashtable_t *ht)
{
        unsigned int i, j;

        printf("hashtable = {\n");
        for (i = 0; i < HT_SIZE; i++) {
                entry_t *entry = &ht->table[i];

                if (!entry->used)
                        continue;

                printf("  .ht[%d].key = \"%s\" = {\n", i, entry->key);
                for (j = 0; j < entry->used; j++) {
                        table1_t *multi = &entry->multi[j];

                        printf("    { .val = { ");
                        print_hex(multi, sizeof(*multi));
                        printf(" },\n");
                }
                printf("  },\n");
        }
        printf("};\n");
}
#else
#  define ht_dump(ht)
#endif

unsigned int ht_count(hashtable_t *ht)
{
        unsigned int i, j;
        unsigned int count = 0;

        for (i = 0; i < HT_SIZE; i++) {
		//#pragma HLS UNROLL
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
		//#pragma HLS UNROLL
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
		//#pragma HLS UNROLL // Cannot unroll loop completely: variable loop bound.
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
		//#pragma HLS UNROLL
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
		//#pragma HLS UNROLL
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

void table3_init(unsigned int *table3_idx)
{
        *table3_idx = 0;
}

int table3_append(table3_t *table3, unsigned int *table3_idx,
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

#if defined(NO_SYNTH)
void table3_dump(table3_t *table3, unsigned int table3_idx)
{
        unsigned int i;
        table3_t *t3;

        printf("table3_t table3[] = { \n");
        for (i = 0; i < table3_idx; i++) {
                t3 = &table3[i];
                printf("  { .name = \"%s\", .animal = \"%s\", .age=%d }\n",
                       t3->name, t3->animal, t3->age);
        }
        printf("}; /* %d lines */\n", table3_idx);
}
#endif

int action_hashjoin_hls(table1_t __table1[TABLE1_SIZE], unsigned int table1_used,
			table2_t __table2[TABLE2_SIZE],	unsigned int table2_used,
			table3_t __table3[TABLE3_SIZE],	unsigned int *table3_used,
			int check)
{
        unsigned int i, j;
	table1_t *t1;
        hashtable_t *h = &__hashtable;
	unsigned int __table3_idx = 0;

        ht_init(h);

        /* hash phase */
        for (i = 0; i < table1_used; i++) {
		// FIXME TIMING #pragma HLS UNROLL
                t1 = &__table1[i];
                printf("Inserting %s ...\n", t1->name);
                ht_set(h, t1->name, t1);
        }
        ht_dump(h);

        table3_init(&__table3_idx);
        for (i = 0; i < table2_used; i++) {
		// FIXME TIMING  #pragma HLS UNROLL
                int bin;
                entry_t *entry;
                table2_t *t2 = &__table2[i];

                bin = ht_get(h, t2->name);
                if (bin == -1)
                        continue;       /* nothing found */

                entry = &h->table[bin];
                for (j = 0; j < entry->used; j++) {
			//#pragma HLS UNROLL
                        table1_t *m = &entry->multi[j];

                        table3_append(__table3, &__table3_idx,
                                      t2->name, t2->animal, m->age);
                }
        }

#if defined(NO_SYNTH)
	table3_dump(__table3, __table3_idx);
#endif

	*table3_used = __table3_idx;

        /*
         * Sanity check, elements in multihash table must match
         * elements in table1.
         */
	if (check)
		return ht_count(h) != table1_used;

	return 0;
}

