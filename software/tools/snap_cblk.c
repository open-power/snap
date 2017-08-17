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

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <endian.h>
#include <asm/byteorder.h>
#include <sys/mman.h>
#include <getopt.h>
#include <snap_tools.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "force_cpu.h"

#include <capiblock.h> /* FIXME fake fake */

int verbose_flag = 0;
static const char *version = GIT_VERSION;

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
	       "  -w, --write		    write entire device.\n"
	       "  -r, --read		    read entire device.\n"
	       "  -s, --start_lba <start_lba> start offset\n"
	       "  -n, --num_lba <num_lba>   number of lbas to read or write\n"
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
	int _read = 1;
	chunk_id_t cid = (chunk_id_t)-1;
	size_t lun_size = 0;
	size_t lba_size = 4 * 1024;
	unsigned int lba;
	unsigned int num_lba = 0;
	unsigned int start_lba = 0;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* options */
			{ "card",	required_argument, NULL, 'C' },
			{ "cpu",	required_argument, NULL, 'X' },

			{ "lba_size",	required_argument, NULL, 'b' },
			{ "start_lba",	required_argument, NULL, 's' },
			{ "num_lba",	required_argument, NULL, 'n' },
			{ "write",	no_argument,	   NULL, 'w' },
			{ "read",	no_argument,	   NULL, 'r' },

			/* misc/support */
			{ "version",	no_argument,	   NULL, 'V' },
			{ "quiet",	no_argument,	   NULL, 'q' },
			{ "verbose",	no_argument,	   NULL, 'v' },
			{ "help",	no_argument,	   NULL, 'h' },

			{ 0,		no_argument,	   NULL, 0   },
		};

		ch = getopt_long(argc, argv, "p:C:X:wrs:n:b:Vqrvh",
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
			lba_size = strtoul(optarg, NULL, 0);
			break;
		case 's':
			start_lba = strtoul(optarg, NULL, 0);
			break;
		case 'n':
			num_lba = strtoul(optarg, NULL, 0);
			break;
		case 'w':
			_read = 0;
			break;
		case 'r':
			_read = 1;
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

	if (optind + 1 != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

	fname = argv[optind++];
	switch_cpu(cpu, verbose_flag);

	cblk_init(NULL, 0);


	if ((card_no < 0) || (card_no > 4)) {
		fprintf(stderr, "err: (%d) is a invalid card number!\n",
			card_no);
		usage(argv[0]);
		goto err_out;
	}

	/* FIXME Fill in function ... */
	snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);

	cid = cblk_open(device, 128, O_RDWR, 0ull, 0);
	if (cid < 0) {
		fprintf(stderr, "err: openging %s failed rc=%d!\n", device, (int)cid);
		goto err_out;
	}

	rc = cblk_get_lun_size(cid, &lun_size, 0);
	if (rc < 0) {
		fprintf(stderr, "err: reading lun_size failed rc=%d!\n", rc);
		goto err_out;
	}
	fprintf(stderr, "lun_size is %zu blocks of %zu bytes\n", lun_size, lba_size);

	if (num_lba == 0)
		num_lba = lun_size;

	if (_read) {
		fprintf(stderr, "reading from card NVMe ... to %s\n", fname);

		if (start_lba + num_lba > lun_size) {
			fprintf(stderr, "err: device not large enougn %zu lbas\n",
				lun_size);
			goto err_out;
		}

		rc = posix_memalign((void **)&buf, 64, lun_size * lba_size);
		if (rc != 0)
			goto err_out;

		for (lba = start_lba; lba < (start_lba + num_lba); lba++) {
			fprintf(stderr, "  reading lba %d ...\n", lba);
			rc = cblk_read(cid, &buf[lba], lba, 1, 0);
			if (rc != 0)
				goto err_out;
		}

		rc = file_write(fname, buf, lun_size * lba_size);
		if (rc != 0)
			goto err_out;

	} else {
		ssize_t len;

		fprintf(stderr, "writing to card NVMe ... from %s\n", fname);
		len = file_size(fname);
		if (len < 0)
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
		if (rc != 0)
			goto err_out;

		rc = file_read(fname, buf, lun_size * lba_size);
		if (rc != 0)
			goto err_out;

		for (lba = start_lba; lba < (start_lba + num_lba); lba++) {
			fprintf(stderr, "  writing lba %d ...\n", lba);
			rc = cblk_write(cid, &buf[lba], lba, 1, 0);
			if (rc != 0)
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
