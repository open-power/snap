/*
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
 * Example to use the FPGA to do a hash join operation on two input
 * tables table1_t and table2_t resuling in a new combined table3_t.
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <endian.h>
#include <asm/byteorder.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <libsnap.h>
#include <snap_tools.h>
#include <snap_s_regs.h>
#include <snap_hashjoin.h>

int verbose_flag = 0;
static const char *version = GIT_VERSION;

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
static table1_t t1[TABLE1_SIZE] __attribute__((aligned(HASHJOIN_ALIGN)));

/*
 * Decouple the entries to maintain the multihash table from the data
 * in table1, since we do not want to transfer empty entries over the
 * PCIe bus to the card.
 */
static table2_t t2[TABLE2_SIZE] __attribute__((aligned(HASHJOIN_ALIGN)));
static table3_t t3[TABLE3_SIZE] __attribute__((aligned(64))); /* large++ */
static hashtable_t hashtable __attribute__((aligned(64)));

static const char *get_name(void)
{
	const char *names[] = { "Jonah", "Alan", "Allen", "Glory", "Frank", "Bruno",
				"Dieter", "Thomas", "Lisa", "Andrea", "Anders",
				"Reiner", "Rainer", "Eberhard", "Joerg-Stephan",
				"Klaus-Dieter", "Melanie", "Susanne", "Maik", "Mike",
				"Andreas", "Dirk", "Georg", "George W.", "Willhelm",
				"Uwe", "Ruediger", "Horst", "Klaus", "Klaus-Dieter",
				"Alexander", "Julius", "Markus", "Titus", "Primus",
				"Secundus", "Tercitus", "Quintus", "Sextus", "Septus",
				"Prima", "Secunda", "Tercia", "Septa", "Octa" };
	return names[rand() % ARRAY_SIZE(names)];
}

static const char *get_animal(void)
{
	const char *names[] = { "Gorilla", "Cat", "Fish", "Trout", "Bird", "Elephant",
				"Dog", "Eagle", "Panther", "Gepard", "Ghost", "Goose",
				"Austrich", "Greyling", "Pike", "Cow", "Antilope" };
	return names[rand() % ARRAY_SIZE(names)];
}

static unsigned int get_age(unsigned int max_age)
{
	return rand() % max_age;
}

static void table1_fill(table1_t *t1, unsigned int t1_entries)
{
	unsigned int i;

	for (i = 0; i < t1_entries; i++) {
		sprintf(t1[i].name, "%s", get_name());
		t1[i].age = get_age(100);
	}
}

static void table2_fill(table2_t *t2, unsigned int t2_entries)
{
	unsigned int i;

	for (i = 0; i < t2_entries; i++) {
		sprintf(t2[i].name, "%s", get_name());
		sprintf(t2[i].animal, "%s", get_animal());
	}
}

static inline
ssize_t file_size(const char *fname)
{
	int rc;
	struct stat s;

	rc = lstat(fname, &s);
	if (rc != 0) {
		fprintf(stderr, "err: Cannot find %s!\n", fname);
		return rc;
	}
	return s.st_size;
}

static inline ssize_t
file_read(const char *fname, uint8_t *buff, size_t len)
{
	int rc;
	FILE *fp;

	if ((fname == NULL) || (buff == NULL) || (len == 0))
		return -EINVAL;

	fp = fopen(fname, "r");
	if (!fp) {
		fprintf(stderr, "err: Cannot open file %s: %s\n",
			fname, strerror(errno));
		return -ENODEV;
	}
	rc = fread(buff, len, 1, fp);
	if (rc == -1) {
		fprintf(stderr, "err: Cannot read from %s: %s\n",
			fname, strerror(errno));
		fclose(fp);
		return -EIO;
	}

	fclose(fp);
	return rc;
}

static void snap_prepare_hashjoin(struct snap_job *cjob,
				  struct hashjoin_job *jin,
				  struct hashjoin_job *jout,
				  const table1_t *t1, ssize_t t1_size,
				  const table2_t *t2, size_t t2_size,
				  table3_t *t3, size_t t3_size,
				  hashtable_t *h, size_t h_size)
{
	snap_addr_set(&jin->t1, t1, t1_size,
		      SNAP_ADDRTYPE_HOST_DRAM,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	snap_addr_set(&jin->t2, t2, t2_size,
		      SNAP_ADDRTYPE_HOST_DRAM,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_SRC);
	snap_addr_set(&jin->t3, t3, t3_size,
		      SNAP_ADDRTYPE_HOST_DRAM,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST);

	/* FIXME Assumptions where there is free DRAM on the card ... */
	snap_addr_set(&jin->hashtable, h, h_size,
		      SNAP_ADDRTYPE_CARD_DRAM,
		      SNAP_ADDRFLAG_ADDR | SNAP_ADDRFLAG_DST |
		      SNAP_ADDRFLAG_END);

	jin->t1_processed = 0;
	jin->t2_processed = 0;
	jin->t3_produced = 0;

	snap_job_set(cjob, jin, sizeof(*jin), jout, sizeof(*jout));
}

/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -t, --timeout <timeout>  Timefor for job completion. (default 10 sec)\n"
	       "  -Q, --t1-entries <items> Entries in table1.\n"
	       "  -T, --t2-entries <items> Entries in table2.\n"
	       "  -s, --seed <seed>        Random seed to enable recreation.\n"
	       "  -N, --no irq             Disable Interrupts (polling)\n"
	       "\n"
	       "Example:\n"
	       "echo Random generation of 2 tables with default table size (T1 = 25 entries / T2 = 23 entries)\n"
	       "SNAP_CONFIG=CPU ./snap_hashjoin -C1 -vv -t2500\n"
	       "echo Random generation of 2 tables with 30 entries for T1 and 60 for T2 => action will call 2 times the action\n"
	       "SNAP_CONFIG=CPU ./snap_hashjoin -C1 -vv -t2500 -Q 30 -T 60\n"
	       "\n",
	       prog);
}

/**
 * Read accelerator specific registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	struct snap_card *card = NULL;
	struct snap_action *action = NULL;
	char device[128];
	struct snap_job cjob;
	struct hashjoin_job jin;
	struct hashjoin_job jout;
	unsigned int timeout = 10;
	struct timeval etime, stime;
	int exit_code = EXIT_SUCCESS;
	unsigned int t1_entries = 25;
	unsigned int t2_entries = 23;
	unsigned int t2_tocopy = 0;
	unsigned int seed = 1974;
	snap_action_flag_t action_irq = (SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ);

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "t1-entries",	 required_argument, NULL, 'Q' },
			{ "t2-entries",	 required_argument, NULL, 'T' },
			{ "seed",	 required_argument, NULL, 's' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ "noirq",	 no_argument,	    NULL, 'N' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "s:Q:T:C:t:VvhN",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
		/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 't':
			timeout = strtol(optarg, (char **)NULL, 0);
			break;
		case 'Q':
			t1_entries = strtol(optarg, (char **)NULL, 0);
			break;
		case 'T':
			t2_entries = strtol(optarg, (char **)NULL, 0);
			break;
		case 's':
			seed = strtol(optarg, (char **)NULL, 0);
			break;
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			verbose_flag++;
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'I':
			action_irq = 0;
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

        if (argc == 1) {               // to provide help when program is called without argument
          usage(argv[0]);
          exit(EXIT_FAILURE);
        }
        
	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	srand(seed);

	/*
	 * Apply for exclusive action access for action type 0xC0FE.
	 * Once granted, MMIO to that action will work.
	 */
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	card = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
				   SNAP_DEVICE_ID_SNAP);
	if (card == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
                fprintf(stderr, "Default mode is FPGA mode.\n");
                fprintf(stderr, "Did you want to run CPU mode ? => add SNAP_CONFIG=CPU before your command.\n");
                fprintf(stderr, "Otherwise make sure you ran snap_find_card and snap_maint for your selected card.\n");
		goto out_error;
	}

	action = snap_attach_action(card, HASHJOIN_ACTION_TYPE, action_irq, 60);
	if (action == NULL) {
		fprintf(stderr, "err: failed to attach action %u: %s\n",
			card_no, strerror(errno));
		goto out_error1;
	}

	if (t1_entries > ARRAY_SIZE(t1)) {
		fprintf(stderr, "err: t1 too large %d\n", t1_entries);
		goto out_error;
	}

	table1_fill(t1, t1_entries);
	if (verbose_flag)
		table1_dump(t1, t1_entries);

	gettimeofday(&stime, NULL);
	while (t2_entries != 0) {
		t2_tocopy = MIN(ARRAY_SIZE(t2), t2_entries);

		table2_fill(t2, t2_tocopy);
		snap_prepare_hashjoin(&cjob, &jin, &jout,
				      t1, t1_entries * sizeof(table1_t),
				      t2, t2_tocopy * sizeof(table2_t),
				      t3, sizeof(t3),
				      &hashtable, sizeof(hashtable));
		if (verbose_flag) {
			pr_info("Job Input:\n");
			__hexdump(stderr, &jin, sizeof(jin));
			table2_dump(t2, t2_tocopy);
		}

		rc = snap_action_sync_execute_job(action, &cjob, timeout);
		if (rc != 0) {
			fprintf(stderr, "err: job execution %d: %s!\n", rc,
				strerror(errno));
			goto out_error2;
		}
		if (cjob.retc != SNAP_RETC_SUCCESS)  {
			fprintf(stderr, "err: job retc %x!\n", cjob.retc);
			goto out_error2;
		}

		if (verbose_flag)
			table3_dump(t3, jout.t3_produced);

		t1_entries = 0; /* no need to process this twice,
				   ht stores the values */
		t2_entries -= t2_tocopy;
	}
	snap_detach_action((void*)action);
	gettimeofday(&etime, NULL);

	fprintf(stderr, "ReturnCode: %x\n"
		"HashJoin took %lld usec\n", cjob.retc,
		(long long)timediff_usec(&etime, &stime));

	snap_detach_action(action);
	snap_card_free(card);
	exit(exit_code);

 out_error2:
	snap_detach_action(action);
 out_error1:
	snap_card_free(card);
 out_error:
	exit(EXIT_FAILURE);
}
