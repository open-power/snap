/*
 * Copyright 2016, International Business Machines
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
static table1_t t1[TABLE1_SIZE] = {
	{ /* .age = */ 27, /* .name = */ "Jonah"  },
	{ /* .age = */ 18, /* .name = */ "Alan"   },
	{ /* .age = */ 28, /* .name = */ "Glory"  },
	{ /* .age = */ 18, /* .name = */ "Popeye" },
	{ /* .age = */ 28, /* .name = */ "Alan"   },
	{ /* .age = */ 38, /* .name = */ "Alan"   },
	{ /* .age = */ 48, /* .name = */ "Alan"   },
	{ /* .age = */ 58, /* .name = */ "Alan"   },
	{ /* .age = */ 68, /* .name = */ "Adam"   },
	{ /* .age = */ 23, /* .name = */ "Anton"  },
	{ /* .age = */ 24, /* .name = */ "Anton"  },
	{ /* .age = */ 25, /* .name = */ "Dieter" },
	{ /* .age = */ 26, /* .name = */ "Joerg"  },
	{ /* .age = */ 22, /* .name = */ "Thomas" },
	{ /* .age = */ 20, /* .name = */ "Frank"  },
	{ /* .age = */ 12, /* .name = */ "Bruno"  },
	{ /* .age = */ 15, /* .name = */ "Blumi"  },
	{ /* .age = */ 15, /* .name = */ "Mikey"  },
	{ /* .age = */ 14, /* .name = */ "Blong"  },
	{ /* .age = */ 13, /* .name = */ "Tiffy"  },
	{ /* .age = */ 12, /* .name = */ "Tiffy"  },
};

/*
 * Decouple the entries to maintain the multihash table from the data
 * in table1, since we do not want to transfer empty entries over the
 * PCIe bus to the card.
 */
static table2_t t2[TABLE2_SIZE] = {
	{ /* .name = */ "Jonah", /* .animal = */ "Whales"   },
	{ /* .name = */ "Jonah", /* .animal = */ "Spiders"  },
	{ /* .name = */ "Alan",  /* .animal = */ "Ghosts"   },
	{ /* .name = */ "Alan",  /* .animal = */ "Zombies"  },
	{ /* .name = */ "Glory", /* .animal = */ "Buffy"    },
	{ /* .name = */ "Grobi", /* .animal = */ "Giraffe"  },
	{ /* .name = */ "Doofy", /* .animal = */ "Lion"     },
	{ /* .name = */ "Mumie", /* .animal = */ "Gepard"   },
	{ /* .name = */ "Blumi", /* .animal = */ "Cow"      },
	{ /* .name = */ "Doofy", /* .animal = */ "Ape"      },
	{ /* .name = */ "Goofy", /* .animal = */ "Fish"     },
	{ /* .name = */ "Mikey", /* .animal = */ "Trout"    },
	{ /* .name = */ "Mikey", /* .animal = */ "Greyling" },
	{ /* .name = */ "Anton", /* .animal = */ "Eagle"    },
	{ /* .name = */ "Thomy", /* .animal = */ "Austrich" },
	{ /* .name = */ "Blomy", /* .animal = */ "Sharks"   },
	{ /* .name = */ "Groof", /* .animal = */ "Fly"      },
	{ /* .name = */ "Blimb", /* .animal = */ "Birds"    },
	{ /* .name = */ "Blong", /* .animal = */ "Buffy"    },
	{ /* .name = */ "Frank", /* .animal = */ "Turtles"  },
	{ /* .name = */ "Frank", /* .animal = */ "Gorillas" },
	{ /* .name = */ "Toffy", /* .animal = */ "Buffy"    },
	{ /* .name = */ "Tuffy", /* .animal = */ "Buffy"    },
	{ /* .name = */ "Frank", /* .animal = */ "Buffy"    },
	{ /* .name = */ "Bruno", /* .animal = */ "Buffy"    },
};

static table3_t t3[TABLE3_SIZE];       /* large++ */
static hashtable_t hashtable;

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
	       "  -i, --input <data.bin> Input data.\n"
	       "  -I, --items <items>    Max items to find.\n"
	       "  -p, --pattern <str>    Pattern to search for\n"
	       "  -E, --expected <num>   Expected # of patterns to find, "
	       "for verification\n"
	       "\n"
	       "Example:\n"
	       "  demo_search ...\n"
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

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
				 "C:t:Vvh",
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

		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	dnut_prepare_hashjoin(&cjob, &jin, &jout,
			      t1, sizeof(t1),
			      t2, sizeof(t2),
			      t3, sizeof(t3),
			      &hashtable, sizeof(hashtable));

	/*
	 * Apply for exclusive kernel access for kernel type 0xC0FE.
	 * Once granted, MMIO to that kernel will work.
	 */
	pr_info("Opening device ...\n");
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
	kernel = dnut_kernel_attach_dev(device,
					DNUT_VENDOR_ID_ANY,
					DNUT_DEVICE_ID_ANY,
					HASHJOIN_ACTION_TYPE);
	if (kernel == NULL) {
		fprintf(stderr, "err: failed to open card %u: %s\n",
			card_no, strerror(errno));
		goto out_error;
	}

#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to define memory base address\n");
	dnut_kernel_mmio_write32(kernel, 0x10010, 0);
	dnut_kernel_mmio_write32(kernel, 0x10014, 0);
	dnut_kernel_mmio_write32(kernel, 0x1001c, 0);
	dnut_kernel_mmio_write32(kernel, 0x10020, 0);
#endif
#if 1				/* FIXME Circumvention should go away */
	pr_info("FIXME Temporary setting to enable DDR on the card\n");
	dnut_kernel_mmio_write32(kernel, 0x10028, 0);
	dnut_kernel_mmio_write32(kernel, 0x1002c, 0);
#endif

	gettimeofday(&stime, NULL);

	rc = dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
	if (rc != 0) {
		fprintf(stderr, "err: job execution %d: %s!\n", rc,
			strerror(errno));
		goto out_error2;
	}
	if (cjob.retc != DNUT_RETC_SUCCESS)  {
		fprintf(stderr, "err: job retc %x!\n", cjob.retc);
		goto out_error2;
	}

	gettimeofday(&etime, NULL);

	fprintf(stdout, "Action version: %llx\n"
		"Checkpoint: %016llx\n"
		"ReturnCode: %lld\n"
		"HashJoin took %lld usec\n",
		(long long)jout.action_version,
		(long long)jout.checkpoint,
		(long long)jout.rc,
		(long long)timediff_usec(&etime, &stime));

	if (jout.rc == 0) {
		ht_dump(&hashtable);
		table3_dump(t3, jout.t3_produced);
	}

	dnut_kernel_free(kernel);
	exit(exit_code);

 out_error2:
	dnut_kernel_free(kernel);
 out_error:
	exit(EXIT_FAILURE);
}
