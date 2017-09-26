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

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <endian.h>
#include <signal.h>
#include <asm/byteorder.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <getopt.h>
#include <snap_tools.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "snap_internal.h"
#include "force_cpu.h"
#include <capiblock.h> /* FIXME fake fake */

int verbose_flag = 0;
static const char *version = GIT_VERSION;

typedef enum {
	OP_READ = 0,
	OP_WRITE = 1,
	OP_FORMAT = 2,
} cblk_operation_t;

static chunk_id_t cid = (chunk_id_t)-1; /* global to close device via sig_INT */

/**
 * @brief Prints valid command line options
 *
 * @param prog	current program name
 */
static void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v,--verbose]\n"
	       "  -C,--card <cardno> can be (0...3)\n"
	       "  -V, --version		    print version.\n"
	       "  -X, --cpu <id>	    only run on this CPU.\n"
	       "  -f, --format		    write entire device with pattern.\n"
	       "  -w, --write		    write entire device.\n"
	       "  -r, --read		    read entire device.\n"
	       "  -s, --start_lba <start_lba> start offset\n"
	       "  -n, --num_lba <num_lba>   number of lbas to read or write\n"
	       "  -b, --lba_blocks <lba_blocks> number of lbas to read"
	       " or write in one operation.\n"
	       "  -p, --pattern <pattern>   pattern for formatting/INC\n"
	       "  <file.bin>\n"
	       "\n"
	       "Example:\n"
	       "  snap_cblk -C0 --read cblk_read.bin\n"
	       "\n",
	       prog);
}

static inline
ssize_t file_size(const char *fname)
{
	int rc;
	struct stat s;

	rc = lstat(fname, &s);
	if (rc < 0) {
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

static inline ssize_t
file_write(const char *fname, const uint8_t *buff, size_t len)
{
	int rc;
	FILE *fp;

	if ((fname == NULL) || (buff == NULL) || (len == 0))
		return -EINVAL;

	fp = fopen(fname, "w+");
	if (!fp) {
		fprintf(stderr, "err: Cannot open file %s: %s\n",
			fname, strerror(errno));
		return -ENODEV;
	}
	rc = fwrite(buff, len, 1, fp);
	if (rc == -1) {
		fprintf(stderr, "err: Cannot write to %s: %s\n",
			fname, strerror(errno));
		fclose(fp);
		return -EIO;
	}
	fclose(fp);
	return rc;
}

static void INT_handler(int sig);

static void INT_handler(int sig)
{
	signal(sig, SIG_IGN);

	cblk_close(cid, 0);
	cblk_term(NULL, 0);

	/* signal(SIGINT, INT_handler); *//* Try again */
}

/**
 * @brief Tool to write to zEDC registers. Must be called as root!
 */
int main(int argc, char *argv[])
{
	int ch, rc = 0;
	int card_no = 0;
	int cpu = -1;
	const char *fname = "snap_cblk.bin";
	uint8_t *buf = NULL;
	char device[128];
	cblk_operation_t _op = OP_READ;
	size_t lun_size = 0;
	size_t lba_size = 4 * 1024;
	size_t lba_blocks = 1;
	unsigned int lba;
	unsigned int num_lba = 0;
	unsigned int start_lba = 0;
	struct timeval etime, stime;
	long long diff_usec = 0;
	double mib_sec;
	int pattern = 0xff;
	int incremental_pattern = 0;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* options */
			{ "card",	required_argument, NULL, 'C' },
			{ "cpu",	required_argument, NULL, 'X' },

			{ "lba_blocks",	required_argument, NULL, 'b' },
			{ "start_lba",	required_argument, NULL, 's' },
			{ "num_lba",	required_argument, NULL, 'n' },
			{ "pattern",	required_argument, NULL, 'p' },

			{ "format",	no_argument,	   NULL, 'f' },
			{ "write",	no_argument,	   NULL, 'w' },
			{ "read",	no_argument,	   NULL, 'r' },

			/* misc/support */
			{ "version",	no_argument,	   NULL, 'V' },
			{ "quiet",	no_argument,	   NULL, 'q' },
			{ "verbose",	no_argument,	   NULL, 'v' },
			{ "help",	no_argument,	   NULL, 'h' },

			{ 0,		no_argument,	   NULL, 0   },
		};

		ch = getopt_long(argc, argv, "p:C:X:fwrs:n:b:p:Vqrvh",
				 long_options, &option_index);
		if (ch == -1)	/* all params processed ? */
			break;

		switch (ch) {
		/* which card to use */
		case 'C':
			card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'X':
			cpu = strtoul(optarg, NULL, 0);
			break;
		case 'b':
			lba_blocks = strtoul(optarg, NULL, 0);
			break;
		case 's':
			start_lba = strtoul(optarg, NULL, 0);
			break;
		case 'p':
			if (strcmp("INC", optarg) == 0)
				incremental_pattern = 1;
			pattern = strtoul(optarg, NULL, 0);
			break;
		case 'n':
			num_lba = strtoul(optarg, NULL, 0);
			break;
		case 'w':
			_op = OP_WRITE;
			break;
		case 'r':
			_op = OP_READ;
			break;
		case 'f':
			_op = OP_FORMAT;
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

	if (argc >= optind + 1)
		fname = argv[optind++];

	if (lba_blocks > 2) {
		fprintf(stderr, "err: %zu blocks not yet supported (1 or 2)!\n",
			lba_blocks);
		usage(argv[0]);
		goto err_out;
	}

	switch_cpu(cpu, verbose_flag);
	cblk_init(NULL, 0);

	if ((card_no < 0) || (card_no > 4)) {
		fprintf(stderr, "err: (%d) is a invalid card number!\n",
			card_no);
		usage(argv[0]);
		goto err_out;
	}

	/* FIXME Fill in function ... */
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0s", card_no);

	cid = cblk_open(device, 128, O_RDWR, 0ull, 0);
	if (cid < 0) {
		fprintf(stderr, "err: openging %s failed rc=%d!\n",
			device, (int)cid);
		goto err_out;
	}
	
	signal(SIGINT, INT_handler);

	rc = cblk_get_lun_size(cid, &lun_size, 0);
	if (rc < 0) {
		fprintf(stderr, "err: reading lun_size failed rc=%d!\n",
			rc);
		goto err_out;
	}
	fprintf(stderr, "NVMe device has %zu blocks of each %zu bytes; %zu MiB\n",
		lun_size, lba_size, lun_size * lba_size / (1024 * 1024));

	if (num_lba == 0)
		num_lba = lun_size;

	switch (_op) {
	case OP_READ: {
		fprintf(stderr, "Reading %d times %zu bytes: %zu KiB NVMe into %s\n",
			num_lba, lba_blocks * lba_size, num_lba * lba_size / 1024,
			fname);

		if (start_lba + num_lba > lun_size) {
			fprintf(stderr, "err: device not large enougn %zu lbas\n",
				lun_size);
			goto err_out;
		}

		rc = posix_memalign((void **)&buf, 64, num_lba * lba_size);
		if (rc != 0) {
			fprintf(stderr, "err: Cannot allocate enough memory!\n");
			goto err_out;
		}
		memset(buf, 0xff, num_lba * lba_size);

		gettimeofday(&stime, NULL);
		for (lba = start_lba; lba < (start_lba + num_lba); lba += lba_blocks) {
			block_trace("  reading lba %d ...\n", lba);
			rc = cblk_read(cid, buf + ((lba - start_lba) * lba_size),
					lba, lba_blocks, 0);
			if (rc != (int)lba_blocks) {
				fprintf(stderr, "err: cblk_read unhappy rc=%d!\n",
					rc);
				goto err_out;
			}

			if (verbose_flag == 1)
				__hexdump(stderr, buf + ((lba - start_lba) * lba_size),
					lba_size * lba_blocks);

		}
		gettimeofday(&etime, NULL);

		rc = file_write(fname, buf, num_lba * lba_size);
		if (rc <= 0) {
			fprintf(stderr, "err: Could not write %s, rc=%d\n",
				fname, rc);
			goto err_out;
		}

		diff_usec = timediff_usec(&etime, &stime);
		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stderr, "Reading of %lld bytes took %lld usec @ %.3f MiB/sec\n",
			(long long)num_lba * lba_size, (long long)diff_usec, mib_sec);
		break;
	}
	case OP_WRITE: {
		ssize_t len;

		fprintf(stderr, "Writing NVMe from %s\n", fname);
		len = file_size(fname);
		if (len <= 0)
			goto err_out;

		if (len % lba_size) {
			fprintf(stderr, "err: size is not a multiple of lba_size=%zu bytes\n",
				lba_size);
			goto err_out;
		}
		num_lba = len / lba_size;

		if (start_lba + num_lba > lun_size) {
			fprintf(stderr, "err: device not large enougn %zu lbas\n",
				lun_size);
			goto err_out;
		}

		rc = posix_memalign((void **)&buf, 64, num_lba * lba_size);
		if (rc != 0) {
			fprintf(stderr, "err: Cannot allocate enough memory!\n");
			goto err_out;
		}

		rc = file_read(fname, buf, num_lba * lba_size);
		if (rc < 0) {
			fprintf(stderr, "err: Reading file did not work rc=%d!\n", rc);
			goto err_out;
		}

		gettimeofday(&stime, NULL);
		for (lba = start_lba; lba < (start_lba + num_lba); lba += lba_blocks) {
			block_trace("  writing lba %d ...\n", lba);
			rc = cblk_write(cid, buf + ((lba - start_lba) * lba_size * lba_blocks),
					lba, lba_blocks, 0);
			if (rc != (int)lba_blocks)
				goto err_out;
		}
		gettimeofday(&etime, NULL);

		diff_usec = timediff_usec(&etime, &stime);
		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stderr, "Writing of %lld bytes took %lld usec @ %.3f MiB/sec\n",
			(long long)num_lba * lba_size, (long long)diff_usec, mib_sec);
		break;
	}
	case OP_FORMAT: {
		fprintf(stderr, "Formatting NVMe drive %zu KiB with pattern %02x ...\n",
			(num_lba * lba_size) / 1024, pattern);

		/* Allocate memory for entire device (simplicity first) */
		rc = posix_memalign((void **)&buf, 64, num_lba * lba_size);
		if (rc != 0)
			goto err_out;

		if (incremental_pattern) {
			uint64_t p;
			for (p = 0; p < (num_lba * lba_size)/sizeof(uint64_t); p++)
				((uint64_t *)buf)[p] = __cpu_to_be64(p);
		} else
			memset(buf, pattern, num_lba * lba_size);

		if (verbose_flag == 2) {
			__hexdump(stderr, buf, num_lba * lba_size);
		}

		gettimeofday(&stime, NULL);
		for (lba = start_lba; lba < (start_lba + num_lba); lba += lba_blocks) {
			block_trace("  formatting lba %d ...\n", lba);

			if (verbose_flag == 1) {
				__hexdump(stderr, buf + ((lba - start_lba) * lba_size),
					lba_size * lba_blocks);
			}

			rc = cblk_write(cid, buf + ((lba - start_lba) * lba_size),
					lba, lba_blocks, 0);
			if (rc != (int)lba_blocks)
				goto err_out;
		}
		gettimeofday(&etime, NULL);

		diff_usec = timediff_usec(&etime, &stime);
		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stderr, "Formatting of %lld bytes took %lld usec @ %.3f MiB/sec\n",
			(long long)num_lba * lba_size, (long long)diff_usec, mib_sec);
		break;
	default:
		goto err_out;
	}
	}

	__free(buf);
	cblk_close(cid, 0);
	cblk_term(NULL, 0);
	exit(EXIT_SUCCESS);

 err_out:
	__free(buf);
	cblk_close(cid, 0);
	cblk_term(NULL, 0);
	exit(EXIT_FAILURE);
}
