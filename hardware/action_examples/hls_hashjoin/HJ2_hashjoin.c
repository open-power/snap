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

/* #define NO_SYNTH  */

#if defined(NO_SYNTH)

#include <stdlib.h> /* malloc, free, atoi */
#include <stdio.h>  /* printf */
#include <limits.h> /* ULONG_MAX = 0xFFFFFFFFUL */

#define __unused __attribute__((unused))

#else

#define __unused

/*
 * Hardware implementation is lacking some libc functions. So let us
 * replace those.
 */
#ifndef ULONG_MAX
#  define ULONG_MAX 0xFFFFFFFFUL /* gcc compiler but not HLS compiler */
#endif
#ifndef NULL
#  define NULL 0		 /* gcc compiler but not HLS compiler */
#endif

typedef unsigned long size_t;

#define printf(fmt, args...)

#endif	/* NO_SYNTH */

#define MIN(x, y) ((x) < (y) ? (x) : (y))
#define ARRAY_SIZE(a) (sizeof((a))/sizeof((a)[0]))

typedef char hashkey_t[64];
typedef char hashdata_t[256];

typedef struct table1_s {
        hashkey_t name;         /* 64 bytes */
        unsigned int age;       /*  4 bytes */
        unsigned int reserved[60];   /* 60 bytes */
} table1_t;

typedef struct table2_s {
        hashkey_t name;         /* 64 bytes */
        hashkey_t animal;       /* 64 bytes */
} table2_t;

typedef struct table3_s {
        hashkey_t animal;       /* 64 bytes */
        hashkey_t name;         /* 64 bytes */
        unsigned int age;       /*  4 bytes */
        unsigned int reserved[60];   /* 60 bytes */
} table3_t;

/*
 * table1 = [(27, "Jonah"),
 *           (18, "Alan"),
 *           (28, "Glory"),
 *           (18, "Popeye"),
 *           (28, "Alan")]
 * table2 = [("Jonah", "Whales"),
 *           ("Jonah", "Spiders"),
 *           ("Alan", "Ghosts"),
 *           ("Alan", "Zombies"),
 *           ("Glory", "Buffy")]
 */

//#if defined(NO_SYNTH)
       // table1 is initialized as constant for software
  static table1_t table1[] = {
        { /* .name = */ "ronah",  /* .age = */ 27, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */ 18, { 0x0, } },
        { /* .name = */ "rlory",  /* .age = */ 28, { 0x0, } },
        { /* .name = */ "ropeye", /* .age = */ 18, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */ 28, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */ 38, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */ 48, { 0x0, } },
        { /* .name = */ "rlan",   /* .age = */ 58, { 0x0, } },
        { /* .name = */ "rdam",   /* .age = */ 68, { 0x0, } },
        { /* .name = */ "rnton",  /* .age = */ 23, { 0x0, } },
        { /* .name = */ "rnton",  /* .age = */ 24, { 0x0, } },
        { /* .name = */ "rieter", /* .age = */ 25, { 0x0, } },
        { /* .name = */ "roerg",  /* .age = */ 26, { 0x0, } },
        { /* .name = */ "rhomas", /* .age = */ 22, { 0x0, } },
        { /* .name = */ "rrank",  /* .age = */ 20, { 0x0, } },
        { /* .name = */ "Bruno" , /* .age = */ 12, { 0x0, } },
        { /* .name = */ "rlumi" , /* .age = */ 15, { 0x0, } },
        { /* .name = */ "rikey",  /* .age = */ 15, { 0x0, } },
        { /* .name = */ "rlong",  /* .age = */ 14, { 0x0, } },
        { /* .name = */ "riffy",  /* .age = */ 13, { 0x0, } },
        { /* .name = */ "riffy",  /* .age = */ 12, { 0x0, } },
};
//#else
//       // table1 is read from host mem for hardware
  #define TABLE1_SIZE 256
  static table1_t table1_rd[TABLE1_SIZE] ;
//#endif

/*
 * Decouple the entries to maintain the multihash table from the data
 * in table1, since we do not want to transfer empty entries over the
 * PCIe bus to the card.
 */
//#if defined(NO_SYNTH)
       // table2 is initialized as constant for software
static table2_t table2[] = {
	{ /* .name = */ "ronah", /* .animal = */ "Whales"   },
	{ /* .name = */ "ronah", /* .animal = */ "Spiders"  },
	{ /* .name = */ "rlan",  /* .animal = */ "Ghosts"   },
	{ /* .name = */ "rlan",  /* .animal = */ "Zombies"  },
	{ /* .name = */ "rlory", /* .animal = */ "Buffy"    },
	{ /* .name = */ "rrobi", /* .animal = */ "Giraffe"  },
	{ /* .name = */ "roofy", /* .animal = */ "Lion"     },
	{ /* .name = */ "rumie", /* .animal = */ "Gepard"   },
	{ /* .name = */ "rlumi", /* .animal = */ "Cow"      },
	{ /* .name = */ "roofy", /* .animal = */ "Ape"      },
	{ /* .name = */ "roofy", /* .animal = */ "Fish"     },
	{ /* .name = */ "rikey", /* .animal = */ "Trout"    },
	{ /* .name = */ "rikey", /* .animal = */ "Greyling" },
	{ /* .name = */ "rnton", /* .animal = */ "Eagle"    },
	{ /* .name = */ "rhomy", /* .animal = */ "Austrich" },
	{ /* .name = */ "rlomy", /* .animal = */ "Sharks"   },
	{ /* .name = */ "rroof", /* .animal = */ "Fly"      },
	{ /* .name = */ "rlimb", /* .animal = */ "Birds"    },
	{ /* .name = */ "rlong", /* .animal = */ "Buffy"    },
	{ /* .name = */ "rrank", /* .animal = */ "Turtles"  },
	{ /* .name = */ "rrank", /* .animal = */ "Gorillas" },
	{ /* .name = */ "roffy", /* .animal = */ "Buffy"    },
	{ /* .name = */ "ruffy", /* .animal = */ "Buffy"    },
	{ /* .name = */ "rrank", /* .animal = */ "Buffy"    },
	{ /* .name = */ "Bruno", /* .animal = */ "Buffy"    },
};
//#else
//       // table2 is read from host mem for hardware
//  #define TABLE2_SIZE 512
//  //#define TABLE2_SIZE 25
//  static table2_t table2[TABLE2_SIZE] ;
//#endif

#define HT_SIZE 128		/* size of hashtable */
#define HT_MULTI ARRAY_SIZE(table1) /* multihash entries = ARRAY_SIZE(table1) */

typedef struct entry_s {
	hashkey_t key;		/* key */
	unsigned int used;	/* list entries used */
	table1_t multi[HT_MULTI];/* fixed size */
} entry_t;

typedef struct hashtable_s {
	entry_t table[HT_SIZE];	/* fixed size */
} hashtable_t;

static int quiet = 0;
static int check = 1;
static unsigned int iterations = 1;

static hashtable_t hashtable;
static unsigned int table3_idx = 0;
static table3_t table3[ARRAY_SIZE(table1) * ARRAY_SIZE(table2)];

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
	#pragma HLS UNROLL
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
static inline void print_hex(void *buf, size_t len)
{
	unsigned int x;
	char *d = buf;

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
	printf("}; (%d lines)\n", table3_idx);
}
#else
short table3_dump(table3_t *table3, unsigned int table3_idx, ap_uint<64> output_address,
	ap_uint<memDW> *dout_gmem, ap_uint<memDW> *d_ddrmem,
       	action_input_reg *Action_Input, ap_uint<memDW> *buf_gmem)
{
	unsigned int i;
	table3_t *t3;
  	short rc = 0;
        ap_uint<64> current_address;
        ap_uint<16> BperDW = memDW/8;

	// 64 Bytes => 4 words of DW with memDW=128bits or 1 word of DW with memDW=512bits
	int nb_of_words = 64/BperDW;

        current_address = output_address;

	for (i = 0; i < table3_idx; i++) {
       //#pragma HLS UNROLL    //cannot completely unroll a loop with a variable trip count
		t3 = &table3[i];
       
		// Following writes are done sequentially for debug purpose
		// A filter will reduce number of data sent back to host
		
		convert_64charTable_to_DWTable(buf_gmem, t3->animal);
        	rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.table3.type,
               		current_address, buf_gmem, 64);
                current_address += nb_of_words;

		convert_64charTable_to_DWTable(buf_gmem, t3->name); 
        	rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.table3.type,
               		current_address, buf_gmem, 64);
                current_address += nb_of_words;

                // write memDW bits words to avoid unaligned address issue (bug#39/#45)
                buf_gmem[0]( 31, 0) = t3->age;
                buf_gmem[0](memDW-1,32) = 0;

        	rc |= write_burst_of_data_to_mem(dout_gmem, d_ddrmem, Action_Input->Data.table3.type,
               		current_address, buf_gmem, BperDW); 
                current_address += 1;

	}
        return rc;
}

short read_table1(ap_uint<64> input_address, 
	ap_uint<memDW> *din_gmem, ap_uint<memDW> *d_ddrmem, 
       	action_input_reg *Action_Input, ap_uint<memDW> *buffer, 
	table1_t *t1_read)
{
	unsigned int i;
  	short rc = 0;
	hashkey_t word_read;
	ap_uint<16> BperDW = memDW/8;
 
	// 64 Bytes => 4 words of DW with memDW=128bits or 1 word of DW with memDW=512bits
	int nb_of_words = 64/BperDW;

       	rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.table1.type,
       		input_address, buffer, Action_Input->Data.table1.size);

	for (i = 0; i < ARRAY_SIZE(t1_read); i++) {
       	#pragma HLS UNROLL
		// limitation : consider that all fields are aligned on 64 Bytes
		convert_DWTable_to_64charTable( &buffer[ i*2*nb_of_words ],
			 t1_read[i].name );

		t1_read[i].age  = (unsigned int) buffer[ (i*2*nb_of_words) + nb_of_words ](31, 0);

	}
        return rc;
}

short read_table2(ap_uint<64> input_address, 
	ap_uint<memDW> *din_gmem, ap_uint<memDW> *d_ddrmem, 
       	action_input_reg *Action_Input, ap_uint<memDW> *buf_gmem,
	table2_t *t2_read)
{
	unsigned int i;
  	short rc = 0;
	ap_uint<16> BperDW = memDW/8;
        
	// 64 Bytes => 4 words of DW with memDW=128bits or 1 word of DW with memDW=512bits
	int nb_of_words = 64/BperDW;

       	rc = read_burst_of_data_from_mem(din_gmem, d_ddrmem, Action_Input->Data.table2.type,
       		input_address, buf_gmem, Action_Input->Data.table2.size);

	for (i = 0; i < ARRAY_SIZE(t2_read); i++) {
       	#pragma HLS UNROLL
		convert_DWTable_to_64charTable( &buf_gmem[ (i*2*nb_of_words)             ],
			 t2_read[i].animal );
		convert_DWTable_to_64charTable( &buf_gmem[ (i*2*nb_of_words)+nb_of_words ],
			 t2_read[i].name );

	}
        return rc;
}

#endif

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
#if defined(NO_SYNTH)
int hash_join(void)
#else
short hash_join_V2(ap_uint<memDW> *din_gmem, ap_uint<memDW> *dout_gmem, ap_uint<memDW> *d_ddrmem,
       	action_input_reg *Action_Input, 
 	ap_uint<64> T1_address, ap_uint<64> T2_address, ap_uint<64> T3_address, 
	ap_uint<memDW> *buf_gmem, ap_uint<64> *T3_produced)
#endif

{
	unsigned int i, j;
	table1_t *t1;
	hashtable_t *h = &hashtable;
	short rc = 0;

	ht_init(h);


	/* hash phase */
//#if defined(NO_SYNTH)
       // table1 is defined as constant for software
	for (i = 0; i < ARRAY_SIZE(table1); i++) {
		t1 = &table1[i];

/* Bruno => Trying to debug these following lines
 * table1 and table2 are still using init values and not read values!
#else
       // table1 is read from host mem for hardware
	rc |= read_table1(T1_address, din_gmem, d_ddrmem, Action_Input, buf_gmem, table1_rd);
	for (i = 0; i < ARRAY_SIZE(table1_rd); i++) {
	#pragma HLS UNROLL
		t1 = &table1_rd[i];
#endif
*/

		printf("Inserting %s ...\n", t1->name);
		ht_set(h, t1->name, t1);
	}
	ht_dump(h);

#if defined(NO_SYNTH)
       // table2 is defined as constant for software
#else
       // table2 is read from host mem for hardware
	rc |= read_table2(T2_address, din_gmem, d_ddrmem, Action_Input, buf_gmem, table2);
#endif

	table3_init(&table3_idx);
	for (i = 0; i < ARRAY_SIZE(table2); i++) {
	#pragma HLS UNROLL
		int bin;
		entry_t *entry;
		table2_t *t2 = &table2[i];
		
		bin = ht_get(h, t2->name);
		if (bin == -1)
			continue;	/* nothing found */

		entry = &h->table[bin];
		for (j = 0; j < entry->used; j++) {
		//#pragma HLS UNROLL
			table1_t *m = &entry->multi[j];

			table3_append(table3, &table3_idx,
				      t2->name, t2->animal, m->age);
		}
	}

	if (!quiet) {
		//ht_dump(h); //commented this line since dump already done above
#if defined(NO_SYNTH)
		table3_dump(table3, table3_idx);
#else
		// write table 3 back to the host memory
		rc = table3_dump(table3, table3_idx, T3_address,
			dout_gmem, d_ddrmem, Action_Input, buf_gmem);

		*T3_produced = (ap_uint<32>) table3_idx;
#endif
	}
	/*
	 * Sanity check, elements in multihash table must match
	 * elements in table1.
	 */
	if (check)
		return ht_count(h) != ARRAY_SIZE(table1);

	return rc;
}

#if defined(NO_SYNTH)
#include <getopt.h>

static void usage(char *prog)
{
	printf("Usage: %s [-h] [-q] [-i <iterations>] [-c <check>]\n", prog);
}

int main(int argc, char *argv[])
{
	int rc = 0;
	unsigned int i;

	while (1) {
		int ch;
		int option_index = 0;
		static struct option long_options[] = {
			{ "quiet", no_argument, NULL, 'q' },
			{ "check", required_argument, NULL, 'c' },
			{ "iterations", required_argument, NULL, 'i' },
			{ "help", no_argument, NULL, 'h' },
		};

		ch = getopt_long(argc, argv, "c:qi:h",
				long_options, &option_index);
		if (ch == -1)
			break;
		switch (ch) {
		case 'q':
			quiet = 1;
			break;
		case 'c':
			check = atoi(optarg);
			break;
		case 'i':
			iterations = atoi(optarg);
			break;
		case 'h':
			usage(argv[0]);
			return 0;
		}
	}

	/* Iterations are needed to get the profiler working right
	   ... memory leaks? */
	for (i = 0; i < iterations; i++) {
		/* ht_testcase(); */
		rc = hash_join();
		if (rc != 0)
			return 1;
	}
	return 0;
}
#else
int main(void)
{
	int rc = 0;
	unsigned int i;

	for (i = 0; i < iterations; i++) {
		//rc = hash_join();
                //rc = hash_join_V2(din_gmem, dout_gmem, d_ddrmem, Action_Input,
                //		T1_address, T2_address, T3_address, buf_gmem, T3_produced);
                //
                return rc;
		//if (rc != 0)
		//	return 1;
	}
	return 0;
}
#endif
