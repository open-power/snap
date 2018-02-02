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

int verbose_flag = 0;
static const char *version = GIT_VERSION;

#define __CBLK_BLOCK_SIZE 4096	/* hardcoded this for simplicity */

static int err_detected = 0;
static int random_seed = 0;

typedef enum {
	OP_READ = 0,
	OP_WRITE = 1,
	OP_FORMAT = 2,
	OP_RW = 3,
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
	       "  -C, --card <cardno> can be (0...3)\n"
	       "  -V, --version             print version.\n"
	       "  -X, --cpu <id>            only run on this CPU.\n"
	       "  -f, --format              write entire device with pattern.\n"
	       "  -w, --write               write entire device.\n"
	       "  -r, --read                read entire device.\n"
	       "  -x, --rw                  read write testcase.\n"
	       "  -R, --random <seed>       random seek ordering\n"
	       "  -s, --start_lba <start_lba> start offset.\n"
	       "  -n, --num_lba <num_lba>   number of lbas to read or write\n"
	       "                            0x40000 for 1 GiB.\n"
	       "                            The size of a logical block is 4KiB.\n"
	       "  -b, --lba_blocks <lba_blocks> number of lbas to read\n"
	       "                            or write in one operation.\n"
	       "  -p, --pattern <pattern>   pattern for formatting or INC\n"
	       "                            INC is filling the blocks with\n"
	       "                            and increasing number.\n"
	       "  -M, --use-mmap            create output file using mmap.\n"
	       "  <file.bin>\n"
	       "\n"
	       "Known limitation:\n"
	       "  We create an in-memory copy of the data. That restricts\n"
	       "  the max possible -n <N> to whatever maximum possible memory\n"
	       "  allocation size. The code will warn appropriately if you\n"
	       "  exceed the maximum possible size.\n"
	       "\n"
	       "Examples:\n"
	       "  Format the device with a pattern of 0xab:\n"
	       "    snap_cblk -C0 --format -p 0xab -n 0x40000\n"
	       "\n"
	       "  Read back the data:\n"
	       "    snap_cblk -C0 --read -n 0x40000 cblk_read.bin\n"
	       "\n"
	       "  Write file content into the NVMe device:\n"
	       "    snap_cblk -C0 --write cblk_read.bin\n"
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

static inline int
file_map(const char *fname, uint8_t **buf, size_t len)
{
	int fd;
	off64_t rc;

	if ((fname == NULL) || (buf == NULL) || (len == 0)) {
		errno = EINVAL;
		return -1;
	}

	fd = open(fname, O_CREAT | O_TRUNC | O_RDWR, 0644);
	if (fd < 0) {
		fprintf(stderr, "err: Cannot open file %s: %s\n",
			fname, strerror(errno));
		return fd;
	}

	rc = lseek64(fd, len, SEEK_SET);	/* Empty file */
	if (rc == (off_t) -1)
		fprintf(stderr, "err: rc=%ld %s\n", rc, strerror(errno));

	rc = write(fd, "", 1);
	if (rc == -1)
		fprintf(stderr, "err: rc=%ld %s\n", rc, strerror(errno));

	rc = lseek64(fd, 0, SEEK_SET);		/* Go to start */
	if (rc == (off_t) -1)
		fprintf(stderr, "err: rc=%ld %s\n", rc, strerror(errno));

	*buf = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (*buf == MAP_FAILED) {
		*buf = NULL;
		close(fd);
		return -1;
	}

	return fd;
}

static inline void
file_unmap(int fd, uint8_t **buf, size_t len)
{
	if (buf) {
		munmap(*buf, len);
		*buf = NULL;
	}
	if (fd >= 0)
		close(fd);
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

	unsigned long total_bytes;
	unsigned long total_usecs;	/* total usecs in read */
	unsigned long max_read_usecs;
	unsigned long min_read_usecs;
	unsigned long avg_read_usecs;
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
	rq->total_usecs = 0;
	rq->total_bytes = 0;
	rq->min_read_usecs = 0xffffffff;
	rq->max_read_usecs = 0;
	rq->avg_read_usecs = 0;

	rq->lba = malloc(num_lba/nblocks * sizeof(unsigned long));
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

typedef void * (* worker_thread_t)(void *data);
typedef int (* cblk_read_write_f)(chunk_id_t id, void *buf, off_t lba,
		size_t nblocks, int flags);
/**
 * Get block from the queue, trigger read and collect results.
 */
static void *__read_write_thread(void *data, cblk_read_write_f func)
{
	int rc;
	void *buf;
	unsigned long lba;
	unsigned long nblocks;
	struct thread_data *d = (struct thread_data *)data;
	struct rqueue *rq = d->rq;
	struct timeval stime, etime;

	block_trace("[%s] NEW THREAD ALIVE %u\n", __func__, d->num);
	while (!err_detected) {
		unsigned long diff_usec;

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

		gettimeofday(&stime, NULL);

		rc = func(cid, buf, lba, nblocks, 0);

		gettimeofday(&etime, NULL);
		diff_usec = timediff_usec(&etime, &stime);

		if (rc != (int)nblocks) {
			fprintf(stderr, "err: cblk_read unhappy rc=%d! %s\n",
				rc, strerror(errno));
			goto err_out;
		}

		/* Update statistics under lock to make it consistent */
		pthread_mutex_lock(&rq->read_lock);
		if (diff_usec < rq->min_read_usecs)
			rq->min_read_usecs = diff_usec;
		if (diff_usec > rq->max_read_usecs)
			rq->max_read_usecs = diff_usec;
		rq->total_usecs += diff_usec;
		rq->total_bytes += nblocks * rq->lba_size;
		pthread_mutex_unlock(&rq->read_lock);
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

static void *read_thread(void *data)
{
	return __read_write_thread(data, cblk_read);
}

static void *write_thread(void *data)
{
	return __read_write_thread(data, cblk_write);
}

/**
 * Testcase to excersise read and write in parallel.
 */
static void *rw_thread(void *data)
{
	int rc;
	void *buf;
	unsigned long lba;
	unsigned long nblocks;
	struct thread_data *d = (struct thread_data *)data;
	struct rqueue *rq = d->rq;
	int do_read = 0;
	uint8_t _buf[__CBLK_BLOCK_SIZE * 32];

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

		do_read = (((lba/nblocks) % 2) == 0);

		/* Perform operation */
		if (do_read) {
			block_trace("[%s] READING LBA=%lu ...\n", __func__, lba);
			rc = cblk_read(cid, _buf, lba, nblocks, 0);
			if (rc != (int)nblocks) {
				fprintf(stderr, "err: cblk_READ unhappy rc=%d! %s\n",
					rc, strerror(errno));
				goto err_out;
			}
			rc = memcmp(buf, _buf, rq->lba_size * nblocks);
			if (rc != 0) {
				fprintf(stderr, "err: verification for LBA=%ld failed\n",
					lba);

				fprintf(stderr, "ORIGINAL:\n");
				__hexdump(stderr, buf, rq->lba_size * nblocks);

				fprintf(stderr, "READOUT:\n");
				__hexdump(stderr, _buf, rq->lba_size * nblocks);
				goto err_out;
			}
		} else {
			block_trace("[%s] WRITING LBA=%lu ...\n", __func__, lba);
			rc = cblk_write(cid, buf, lba, nblocks, 0);
			if (rc != (int)nblocks) {
				fprintf(stderr, "err: cblk_WRITE unhappy rc=%d! %s\n",
					rc, strerror(errno));
				goto err_out;
			}
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
			worker_thread_t func,
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
				func, &d[i]);
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
	double mib_sec = 0.0;
	int pattern = 0xff;
	int incremental_pattern = 0;
	unsigned int threads = 1;
	int random_seed = 0;
	int use_mmap = 0;

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
			{ "use-mmap",	no_argument,	   NULL, 'M' },

			{ "format",	no_argument,	   NULL, 'f' },
			{ "write",	no_argument,	   NULL, 'w' },
			{ "read",	no_argument,	   NULL, 'r' },
			{ "rw",		no_argument,	   NULL, 'x' },

			/* misc/support */
			{ "version",	no_argument,	   NULL, 'V' },
			{ "quiet",	no_argument,	   NULL, 'q' },
			{ "verbose",	no_argument,	   NULL, 'v' },
			{ "help",	no_argument,	   NULL, 'h' },

			{ 0,		no_argument,	   NULL, 0   },
		};

		ch = getopt_long(argc, argv, "MR:p:C:X:xfwrs:t:n:b:p:Vqrvh",
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
		case 'M':
			use_mmap = 1;
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
		case 'x':
			_op = OP_RW;
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
	fprintf(stdout, "NVMe device has %zu blocks of each %zu bytes; "
		"%zu MiB (MAX 0x%lx blocks) @ %u threads\n",
		lun_size, lba_size, lun_size * lba_size / (1024 * 1024),
		lun_size,
		threads);

	/*
	 * NOTE: Using lun_size will fail, since we create an in memory
	 *       copy of the device and the NVMe device is likely to be
	 *       larger than the memory our process can allocate with
	 *       posix_memalign().
	 */
	/* if (num_lba == 0)
		num_lba = lun_size; */

	switch (_op) {
	case OP_READ: {
		int fd = -1;

		if ((num_lba == 0) || (num_lba > lun_size)) {
			fprintf(stderr, "warn: -n <num_lba> is %u but "
				"should be >= %zu and <= %zu\n",
				num_lba, lba_blocks, lun_size);
			goto err_out;
		}

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

		if (use_mmap) {
			fd = file_map(fname, &buf, num_lba * lba_size);
			if (fd < 0) {
				fprintf(stderr, "[%s] err: Cannot map output file! %s\n",
					__func__, strerror(errno));
				goto err_out;
			}
		} else {
			rc = posix_memalign((void **)&buf, 64, num_lba * lba_size);
			if (rc != 0) {
				fprintf(stderr, "[%s] err: Cannot allocate enough memory! %s\n",
					__func__, strerror(errno));
				goto err_out;
			}
			memset(buf, 0xff, num_lba * lba_size);
		}

		fprintf(stdout, "About to read %zu times %zu bytes: %zu KiB NVMe into %s\n",
			num_lba/lba_blocks, lba_blocks * lba_size,
			num_lba * lba_size / 1024,
			fname);

		rqueue_init(&rq, buf, start_lba, lba_size, num_lba, lba_blocks);
		gettimeofday(&stime, NULL);

		rc = run_threads(thread_data, threads, &read_thread, &rq);
		if (rc != 0) {
			fprintf(stderr, "err: run_threads unhappy rc=%d! %s\n", rc,
				strerror(errno));
			goto err_out;
		}

		gettimeofday(&etime, NULL);
		diff_usec = timediff_usec(&etime, &stime);

		rq.avg_read_usecs = rq.total_usecs / (num_lba/lba_blocks);
		fprintf(stdout, "MIN: %ld usecs, MAX: %ld usecs, AVG: %ld usecs\n",
			rq.min_read_usecs, rq.max_read_usecs, rq.avg_read_usecs);

		rqueue_free(&rq);

		if (use_mmap)
			file_unmap(fd, &buf, num_lba * lba_size);
		else {
			rc = file_write(fname, buf, num_lba * lba_size);
			if (rc <= 0) {
				fprintf(stderr, "err: Could not write %s, rc=%d\n",
					fname, rc);
				goto err_out;
			}
		}

		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stdout, "Reading of %lld bytes with %d threads "
			"took %lld usec @ %.3f MiB/sec %s\n",
			(long long)num_lba * lba_size, threads,
			(long long)diff_usec, mib_sec,
			random_seed ? "random ordering" : "linear ordering");
		break;
	}
	case OP_RW: {
		uint8_t *_buf;

		if ((num_lba == 0) || (num_lba > lun_size)) {
			fprintf(stderr, "warn: -n <num_lba> is %u but "
				"should be >= %zu and <= %zu\n",
				num_lba, lba_blocks, lun_size);
			goto err_out;
		}

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
			fprintf(stderr, "[%s] err: Cannot allocate "
				"enough memory! %s\n", __func__,
				strerror(errno));
			goto err_out;
		}
		memset(buf, 0xff, num_lba * lba_size);

		fprintf(stdout, "About to read/write %zu times %zu bytes: %zu KiB NVMe into %s\n",
			num_lba/lba_blocks, lba_blocks * lba_size,
			num_lba * lba_size / 1024,
			fname);

		/* Formatting part */
		gettimeofday(&stime, NULL);
		for (lba = start_lba; lba < (start_lba + num_lba); lba += lba_blocks) {
			block_trace("  formatting lba %d ...\n", lba);

			if (verbose_flag == 1) {
				__hexdump(stderr, buf + ((lba - start_lba) * lba_size),
					lba_size * lba_blocks);
			}

			_buf = buf + (lba - start_lba) * lba_size;
			memset(_buf, lba, lba_size * lba_blocks);

			rc = cblk_write(cid, _buf, lba, lba_blocks, 0);
			if (rc != (int)lba_blocks)
				goto err_out;
		}
		gettimeofday(&etime, NULL);

		diff_usec = timediff_usec(&etime, &stime);
		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stdout, "Formatting of %lld bytes took %lld usec @ %.3f MiB/sec\n",
			(long long)num_lba * lba_size, (long long)diff_usec, mib_sec);


		/* Test part */
		rqueue_init(&rq, buf, start_lba, lba_size, num_lba, lba_blocks);
		gettimeofday(&stime, NULL);

		rc = run_threads(thread_data, threads, &rw_thread, &rq);
		if (rc != 0) {
			fprintf(stderr, "err: run_threads unhappy rc=%d! %s\n", rc,
				strerror(errno));
			goto err_out;
		}

		gettimeofday(&etime, NULL);
		diff_usec = timediff_usec(&etime, &stime);

		rq.avg_read_usecs = rq.total_usecs / (num_lba/lba_blocks);
		fprintf(stdout, "MIN: %ld usecs, MAX: %ld usecs, AVG: %ld usecs\n",
			rq.min_read_usecs, rq.max_read_usecs, rq.avg_read_usecs);

		rqueue_free(&rq);

		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stdout, "Reading/writing of %lld bytes with %d threads "
			"took %lld usec @ %.3f MiB/sec %s\n",
			(long long)num_lba * lba_size, threads,
			(long long)diff_usec, mib_sec,
			random_seed ? "random ordering" : "linear ordering");
		break;
	}
	case OP_WRITE: {
		ssize_t len;

		fprintf(stdout, "Reading data from %s\n", fname);
		len = file_size(fname);
		if (len <= 0) {
			fprintf(stderr, "err: Unexpected size of file %s %zu\n",
				fname, len);
			goto err_out;
		}

		if (len % lba_size) {
			fprintf(stderr, "err: size is not a multiple of lba_size=%zu bytes\n",
				lba_size);
			goto err_out;
		}
		num_lba = len / lba_size;

		if ((num_lba == 0) || (num_lba > lun_size)) {
			fprintf(stderr, "warn: -n <num_lba> is %u but "
				"should be >= %zu and <= %zu\n",
				num_lba, lba_blocks, lun_size);
			goto err_out;
		}

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
			fprintf(stderr, "[%s] err: Cannot allocate enough "
			"	memory!\n", __func__);
			goto err_out;
		}

		rc = file_read(fname, buf, num_lba * lba_size);
		if (rc < 0) {
			fprintf(stderr, "err: Reading file did not work rc=%d!\n", rc);
			goto err_out;
		}

		rqueue_init(&rq, buf, start_lba, lba_size, num_lba, lba_blocks);
		gettimeofday(&stime, NULL);

		rc = run_threads(thread_data, threads, &write_thread, &rq);
		if (rc != 0) {
			fprintf(stderr, "err: run_threads unhappy rc=%d! %s\n", rc,
				strerror(errno));
			goto err_out;
		}

		gettimeofday(&etime, NULL);

		diff_usec = timediff_usec(&etime, &stime);
		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stdout, "Writing of %lld bytes took %lld usec @ %.3f MiB/sec\n",
			(long long)num_lba * lba_size, (long long)diff_usec, mib_sec);
		break;
	}
	case OP_FORMAT: {

		if ((num_lba == 0) || (num_lba > lun_size)) {
			fprintf(stderr, "warn: -n <num_lba> is %u but "
				"should be >= %zu and <= %zu\n",
				num_lba, lba_blocks, lun_size);
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

		/* Allocate memory for entire device (simplicity first) */
		rc = posix_memalign((void **)&buf, 64, num_lba * lba_size);
		if (rc != 0) {
			fprintf(stderr, "err: Cannot allocate enough memory "
				"to keep copy of the device!\n");
			goto err_out;
		}

		if (incremental_pattern) {
			uint64_t p;
			for (p = 0; p < (num_lba * lba_size)/sizeof(uint64_t); p++)
				((uint64_t *)buf)[p] = __cpu_to_be64(p);
		} else
			memset(buf, pattern, num_lba * lba_size);

		if (verbose_flag == 2) {
			__hexdump(stderr, buf, num_lba * lba_size);
		}

		fprintf(stdout, "About to format NVMe drive %zu KiB with pattern %02x ...\n",
			(num_lba * lba_size) / 1024, pattern);

		rqueue_init(&rq, buf, start_lba, lba_size, num_lba, lba_blocks);
		gettimeofday(&stime, NULL);

		rc = run_threads(thread_data, threads, &write_thread, &rq);
		if (rc != 0) {
			fprintf(stderr, "err: run_threads unhappy rc=%d! %s\n", rc,
				strerror(errno));
			goto err_out;
		}

		gettimeofday(&etime, NULL);

		diff_usec = timediff_usec(&etime, &stime);
		mib_sec = (diff_usec == 0) ? 0.0 :
			(double)(num_lba * lba_size) / diff_usec;

		fprintf(stdout, "Formatting of %lld bytes took %lld usec @ %.3f MiB/sec\n",
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
