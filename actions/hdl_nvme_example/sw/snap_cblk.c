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
#include <pthread.h>
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

#undef CONFIG_SINGLE_THREADED

int verbose_flag = 0;
static const char *version = GIT_VERSION;

static int err_detected = 0;
static int random_seed = 0;

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
	       "  -R, --random <seed>	    random seek ordering"
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
	fprintf(stderr, "\nCntl+C (%d)\n", sig);
	cblk_close(cid, 0);
	cblk_term(NULL, 0);

	/* signal(sig, SIG_IGN); */
	/* signal(SIGINT, INT_handler); *//* Try again */
	exit(EXIT_FAILURE);
}

struct rqueue {
	pthread_mutex_t read_lock;
	void *buf;
	unsigned long start_lba;	/* starting lba */
	unsigned long lba_size;		/* size of lba e.g. 4KiB */
	unsigned long *lba;		/* current lba */
	unsigned int lba_idx;
	unsigned long num_lba;		/* maximum number to read */
	unsigned int nblocks;		/* how many blocks to read each time */
};

struct thread_data {
	pthread_t thread_id;
	int thread_rc;			/* ret: rc of thread */
	unsigned int num;
	struct rqueue *rq;
};

#define THREAD_MAX	160		/* max number of possible threads */

static struct rqueue rq;
static struct thread_data thread_data[THREAD_MAX];

static inline void __swap(unsigned long *a, unsigned long *b)
{
	unsigned long t;

	t = *a;
	*a = *b;
	*b = t;
}

static inline void randperm(unsigned long *P, unsigned int n)
{
	int i;

	for (i = n - 1; i > 0; i--) {
		unsigned int z = rand() % i;
		__swap(&P[i], &P[z]);
	}
}

static int rqueue_init(struct rqueue *rq, void *buf,
			unsigned long start_lba,
			unsigned long lba_size,
			unsigned long num_lba,
			unsigned int nblocks)
{
	unsigned int i;

	pthread_mutex_init(&rq->read_lock, NULL);
	rq->buf = buf;
	rq->start_lba = start_lba;
	rq->lba_size = lba_size;
	rq->lba_idx = 0;
	rq->num_lba = num_lba;
	rq->nblocks = nblocks;

	rq->lba= malloc(num_lba/nblocks * sizeof(unsigned long));
	if (rq->lba == NULL)
		return -1;
	
	for (i = 0; i < num_lba/nblocks; i++)
		rq->lba[i] = start_lba + i * nblocks;

	if (random_seed)
		randperm(rq->buf, num_lba/nblocks);

	return 0;
}

static void rqueue_free(struct rqueue *rq)
{
	__free(rq->lba);
	rq->lba = NULL;
}

/**
 * Get block from the queue, trigger read and collect results.
 */
static void *read_thread(void *data)
{
	int rc;
	void *buf;
	unsigned long lba;
	unsigned long nblocks;
	struct thread_data *d = (struct thread_data *)data;
	struct rqueue *rq = d->rq;

	block_trace("[%s] NEW THREAD ALIVE %u\n", __func__, d->num);
	while (!err_detected) {
		pthread_mutex_lock(&rq->read_lock);

		/* Exit loop if there is no more work to be done */
		if (rq->lba_idx == rq->num_lba/rq->nblocks) {
			pthread_mutex_unlock(&rq->read_lock);
			break;
		}

		/* Calculate current positions parameters */
		lba = rq->lba[rq->lba_idx];
		buf = rq->buf + (lba - rq->start_lba) * rq->lba_size;
		nblocks = rq->nblocks;

		/* Select next lba for follow up thread */
		rq->lba_idx++;
		pthread_mutex_unlock(&rq->read_lock);

		/* Perform read operation */
		block_trace("[%s] reading lba %lu ...\n", __func__, lba);
		rc = cblk_read(cid, buf, lba, nblocks, 0);
		if (rc != (int)nblocks) {
			fprintf(stderr, "err: cblk_read unhappy rc=%d! %s\n",
				rc, strerror(errno));
			goto err_out;
		}
		pthread_testcancel();
	}
	block_trace("[%s] THREAD %u STOPPED\n", __func__, d->num);
	d->thread_rc = 0;
	pthread_exit(&d->thread_rc);

err_out:
	err_detected = 1;		/* inform others to stop */
	d->thread_rc = -2;
	pthread_exit(&d->thread_rc);
}

static int run_threads(struct thread_data *d, unsigned int threads,
			struct rqueue *rq)
{
	int rc;
	unsigned int i;

	if (threads > THREAD_MAX) {
		fprintf(stderr, "err: too many threads %u!\n", threads);
		return -1;
	}
	
	for (i = 0; i < threads; i++) {
		d[i].thread_rc = -1;
		d[i].rq = rq;
		d[i].num = i;
	}

	for (i = 0; i < threads; i++) {
		rc = pthread_create(&d[i].thread_id, NULL,
				&read_thread, &d[i]);
		if (rc != 0) {
			fprintf(stderr, "err: starting %d. read_thread failed!\n", i);
			return -1;
		}
	}

	for (i = 0; i < threads; i++) {
		rc = pthread_join(d[i].thread_id, NULL);
		if (rc != 0) {
			fprintf(stderr, "err: joining threads failed!\n");
			return -2;
		}
	}

	return 0;
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
	unsigned int threads = 1;
	int random_seed = 0;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* options */
			{ "card",	required_argument, NULL, 'C' },
			{ "cpu",	required_argument, NULL, 'X' },

			{ "threads",	required_argument, NULL, 't' },
			{ "start_lba",	required_argument, NULL, 's' },
			{ "lba_blocks",	required_argument, NULL, 'b' },
			{ "start_lba",	required_argument, NULL, 's' },
			{ "num_lba",	required_argument, NULL, 'n' },
			{ "pattern",	required_argument, NULL, 'p' },
			{ "random",	required_argument, NULL, 'R' },

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

		ch = getopt_long(argc, argv, "R:p:C:X:fwrs:t:n:b:p:Vqrvh",
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
		case 't':
			threads = strtoul(optarg, NULL, 0);
			break;
		case 'b':
			lba_blocks = strtoul(optarg, NULL, 0);
			break;
		case 's':
			start_lba = strtoul(optarg, NULL, 0);
			break;
		case 'R':
			random_seed = strtoul(optarg, NULL, 0);
			break;
		case 'p':
			if (strcmp("INC", optarg) == 0) {
				incremental_pattern = 1;
				break;
			}
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

	if ((lba_blocks <= 0) || (lba_blocks > 32)) {
		fprintf(stderr, "err: %zu blocks not yet supported (1, 2, 4, ..., 32)!\n",
			lba_blocks);
		usage(argv[0]);
		goto err_out;
	}

	srand(random_seed);
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
		fprintf(stderr, "err: opening %s failed rc=%d!\n",
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
	fprintf(stderr, "NVMe device has %zu blocks of each %zu bytes; %zu MiB @ %u threads\n",
		lun_size, lba_size, lun_size * lba_size / (1024 * 1024),
		threads);

	if (num_lba == 0)
		num_lba = lun_size;

	switch (_op) {
	case OP_READ: {
		fprintf(stderr, "Reading %zu times %zu bytes: %zu KiB NVMe into %s\n",
			num_lba/lba_blocks, lba_blocks * lba_size,
			num_lba * lba_size / 1024,
			fname);

		if (start_lba + num_lba > lun_size) {
			fprintf(stderr, "err: device not large enough %zu lbas\n",
				lun_size);
			goto err_out;
		}

		if (num_lba < lba_blocks) {
			fprintf(stderr, "err: num_lba %u smaller than lba_blocks %zu\n",
				num_lba, lba_blocks);
			goto err_out;
		}

		if (num_lba % lba_blocks) {
			fprintf(stderr, "err: num_lba %u not multiple of lba_blocks %zu\n",
				num_lba, lba_blocks);
			goto err_out;
		}

		rc = posix_memalign((void **)&buf, 64, num_lba * lba_size);
		if (rc != 0) {
			fprintf(stderr, "err: Cannot allocate enough memory!\n");
			goto err_out;
		}
		memset(buf, 0xff, num_lba * lba_size);


#ifdef CONFIG_SINGLE_THREADED /* single threaded */
		gettimeofday(&stime, NULL);

		for (lba = start_lba; lba < (start_lba + num_lba); lba += lba_blocks) {
			block_trace("  reading lba %d ...\n", lba);
			rc = cblk_read(cid, buf + ((lba - start_lba) * lba_size),
					lba, lba_blocks, 0);
			if (rc != (int)lba_blocks) {
				fprintf(stderr, "err: cblk_read unhappy rc=%d! %s\n",
					rc, strerror(errno));
				goto err_out;
			}

			if (verbose_flag == 1)
				__hexdump(stderr, buf + ((lba - start_lba) * lba_size),
					lba_size * lba_blocks);

		}
		gettimeofday(&etime, NULL);
#else
		rqueue_init(&rq, buf, start_lba, lba_size, num_lba, lba_blocks);
		gettimeofday(&stime, NULL);

		rc = run_threads(thread_data, threads, &rq);
		if (rc != 0) {
			fprintf(stderr, "err: run_threads unhappy rc=%d! %s\n", rc,
				strerror(errno));
			goto err_out;
		}

		gettimeofday(&etime, NULL);
		rqueue_free(&rq);
#endif
		rc = file_write(fname, buf, num_lba * lba_size);
		if (rc <= 0) {
			fprintf(stderr, "err: Could not write %s, rc=%d\n",
				fname, rc);
			goto err_out;
		}

		diff_usec = timediff_usec(&etime, &stime);
		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stderr, "Reading of %lld bytes with %d threads took %lld usec @ %.3f MiB/sec %s\n",
			(long long)num_lba * lba_size, threads,
			(long long)diff_usec, mib_sec,
			random_seed ? "random ordering" : "linear ordering");
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
			fprintf(stderr, "err: device not large enough %zu lbas\n",
				lun_size);
			goto err_out;
		}

		if (num_lba < lba_blocks) {
			fprintf(stderr, "err: num_lba %u smaller than lba_blocks %zu\n",
				num_lba, lba_blocks);
			goto err_out;
		}

		if (num_lba % lba_blocks) {
			fprintf(stderr, "err: num_lba %u not multiple of lba_blocks %zu\n",
				num_lba, lba_blocks);
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
			block_trace("  writing lba %d max: %d ...\n", lba, start_lba + num_lba - 1);
			rc = cblk_write(cid, buf + ((lba - start_lba) * lba_size),
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

		if (num_lba < lba_blocks) {
			fprintf(stderr, "err: num_lba %u smaller than lba_blocks %zu\n",
				num_lba, lba_blocks);
			goto err_out;
		}

		if (num_lba % lba_blocks) {
			fprintf(stderr, "err: num_lba %u not multiple of lba_blocks %zu\n",
				num_lba, lba_blocks);
			goto err_out;
		}

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
	exit(err_detected ? EXIT_FAILURE : EXIT_SUCCESS);

 err_out:
	__free(buf);
	cblk_close(cid, 0);
	cblk_term(NULL, 0);
	exit(EXIT_FAILURE);
}
