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

#include <donut_tools.h>
#include <libdonut.h>
#include <action_hashjoin.h>
#include <snap_s_regs.h>

#define ACTION_REDAY_IRQ        4
#define	HLS_HASH_JOIN_ID	0x10141003

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

static void dnut_prepare_hashjoin(struct dnut_job *cjob,
				  struct hashjoin_job *jin,
				  struct hashjoin_job *jout,
				  const table1_t *t1, ssize_t t1_size,
				  const table2_t *t2, size_t t2_size,
				  table3_t *t3, size_t t3_size,
				  hashtable_t *h, size_t h_size)
{
	dnut_addr_set(&jin->t1, t1, t1_size,
		      DNUT_TARGET_TYPE_HOST_DRAM,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
	dnut_addr_set(&jin->t2, t2, t2_size,
		      DNUT_TARGET_TYPE_HOST_DRAM,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
	dnut_addr_set(&jin->t3, t3, t3_size,
		      DNUT_TARGET_TYPE_HOST_DRAM,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);

	/* FIXME Assumptions where there is free DRAM on the card ... */
	dnut_addr_set(&jin->hashtable, h, h_size,
		      DNUT_TARGET_TYPE_CARD_DRAM,
		      DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST |
		      DNUT_TARGET_FLAGS_END);

	jin->t1_processed = 0;
	jin->t2_processed = 0;
	jin->t3_produced = 0;
	jin->checkpoint = 0xABCD;
	jin->rc = 0;
	jin->action_version = 0;

	dnut_job_set(cjob, HASHJOIN_ACTION_TYPE,
		     jin, sizeof(*jin), jout, sizeof(*jout));
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
	       "  -I, --irq                Enable Interrupts\n"
	       "\n"
	       "Example:\n"
	       "  demo_hashjoin ...\n"
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
	struct dnut_kernel *kernel = NULL;
	char device[128];
	struct dnut_job cjob;
	struct hashjoin_job jin;
	struct hashjoin_job jout;
	unsigned int timeout = 10;
	struct timeval etime, stime;
	int exit_code = EXIT_SUCCESS;
	unsigned int t1_entries = 25;
	unsigned int t2_entries = 23;
	unsigned int t2_tocopy = 0;
	unsigned int seed = 1974;
	int attach_flags = SNAP_CCR_DIRECT_MODE;
	int action_irq = 0;

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
			{ "irq",	 no_argument,	    NULL, 'I' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "s:Q:T:C:t:VvhI",
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
			attach_flags |= SNAP_CCR_IRQ_ATTACH;
			action_irq = ACTION_REDAY_IRQ;
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	srand(seed);

	/*
	 * Apply for exclusive kernel access for kernel type 0xC0FE.
	 * Once granted, MMIO to that kernel will work.
	 */
	pr_info("Opening device ...\n");
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);
	kernel = dnut_kernel_attach_dev(device,
					0x1014,
					0xcafe,
					HASHJOIN_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
		goto out_error;
	}

	if (t1_entries > ARRAY_SIZE(t1)) {
		fprintf(stderr, "err: t1 too large %d\n", t1_entries);
		goto out_error;
	}

	rc = dnut_attach_action((void*)kernel, HLS_HASH_JOIN_ID, attach_flags, 5*timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job Attach %d: %s!\n", rc,
			strerror(errno));
		dnut_kernel_free(kernel);
		goto out_error;
	}
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to define memory base address\n");
	dnut_kernel_mmio_write32(kernel, 0x10, 0);
	dnut_kernel_mmio_write32(kernel, 0x14, 0);
	dnut_kernel_mmio_write32(kernel, 0x1c, 0);
	dnut_kernel_mmio_write32(kernel, 0x20, 0);
#endif
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to enable DDR on the card\n");
	dnut_kernel_mmio_write32(kernel, 0x28, 0);
	dnut_kernel_mmio_write32(kernel, 0x2c, 0);
#endif

	table1_fill(t1, t1_entries);
	if (verbose_flag)
		table1_dump(t1, t1_entries);

	gettimeofday(&stime, NULL);
	while (t2_entries != 0) {
		t2_tocopy = MIN(ARRAY_SIZE(t2), t2_entries);

		table2_fill(t2, t2_tocopy);
		dnut_prepare_hashjoin(&cjob, &jin, &jout,
				      t1, t1_entries * sizeof(table1_t),
				      t2, t2_tocopy * sizeof(table2_t),
				      t3, sizeof(t3),
				      &hashtable, sizeof(hashtable));
		if (verbose_flag) {
			pr_info("Job Input:\n");
			__hexdump(stderr, &jin, sizeof(jin));
			table2_dump(t2, t2_tocopy);
		}

		if (action_irq) {
			dnut_kernel_mmio_write32(kernel, 0x8, 1);
			dnut_kernel_mmio_write32(kernel, 0x4, 1);
		}
		rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout, action_irq);
		if (action_irq) {
			dnut_kernel_mmio_write32(kernel, 0xc, 1);
			dnut_kernel_mmio_write32(kernel, 0x4, 0);
		}
		if (rc != 0) {
			fprintf(stderr, "err: job execution %d: %s!\n", rc,
				strerror(errno));
			goto out_error2;
		}
		if (cjob.retc != DNUT_RETC_SUCCESS)  {
			fprintf(stderr, "err: job retc %x!\n", cjob.retc);
			goto out_error2;
		}

		if (verbose_flag || (jout.rc == 0))
			table3_dump(t3, jout.t3_produced);

		t1_entries = 0; /* no need to process this twice,
				   ht stores the values */
		t2_entries -= t2_tocopy;
	}
	gettimeofday(&etime, NULL);

	fprintf(stderr, "Action version: %llx\n"
		"Checkpoint: %016llx\n"
		"ReturnCode: %lld\n"
		"HashJoin took %lld usec\n",
		(long long)jout.action_version,
		(long long)jout.checkpoint,
		(long long)jout.rc,
		(long long)timediff_usec(&etime, &stime));

	dnut_kernel_free(kernel);
	exit(exit_code);

 out_error2:
	dnut_kernel_free(kernel);
 out_error:
	exit(EXIT_FAILURE);
}
