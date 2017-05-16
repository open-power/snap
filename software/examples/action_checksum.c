/*
 * Copyright 2016, 2017, International Business Machines
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
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Markku-Juhani O. Saarinen
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * Example to use the FPGA to calculate a CRC32 checksum.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>

#include <libsnap.h>
#include <snap_internal.h>
#include <action_checksum.h>
#include <sha3.h>

static int mmio_write32(struct snap_card *card,
			uint64_t offs, uint32_t data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, data);
	return 0;
}

static int mmio_read32(struct snap_card *card,
		       uint64_t offs, uint32_t *data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, card,
		  (long long)offs, *data);
	return 0;
}

/* Table of CRCs of all 8-bit messages. */
#if defined(CONFIG_BUILD_CRC_TABLE)

static unsigned long crc_table[256];

/* Flag: has the table been computed? Initially false. */
static int crc_table_computed = 0;

/* Make the table for a fast CRC. */
static void make_crc_table(void)
{
	unsigned long c;
	int n, k;

	for (n = 0; n < 256; n++) {
		c = (unsigned long) n;
		for (k = 0; k < 8; k++) {
			if (c & 1) {
				c = 0xedb88320L ^ (c >> 1);
			} else {
				c = c >> 1;
			}
		}
		crc_table[n] = c;
	}
	crc_table_computed = 1;
}

static void dump_crc_table(void)
{
	int i;

	printf("static unsigned long crc_table[] = {\n");
	for (i = 0; i < 256; i++) {
		printf(" 0x%08lx,", (long)crc_table[i]);
		if ((i & 3) == 3)
			printf("\n");
	}
	printf("};\n");
}

#else

static unsigned long crc_table[] = {
	0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
	0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
	0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
	0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
	0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
	0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
	0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
	0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
	0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
	0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
	0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
	0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
	0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
	0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
	0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
	0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
	0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
	0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
	0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
	0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
	0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
	0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
	0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
	0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
	0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
	0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
	0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
	0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
	0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
	0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
	0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
	0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
	0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
	0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
	0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
	0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
	0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
	0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
	0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
	0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
	0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
	0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
	0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
	0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
	0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
	0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
	0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
	0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
	0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
	0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
};
#endif

/*
  Update a running crc with the bytes buf[0..len-1] and return
  the updated crc. The crc should be initialized to zero. Pre- and
  post-conditioning (one's complement) is performed within this
  function so it shouldn't be done by the caller. Usage example:

  unsigned long crc = 0L;

  while (read_buffer(buffer, length) != EOF) {
      crc = update_crc(crc, buffer, length);
  }
  if (crc != original_crc) error();
*/

/* Return the CRC of the bytes buf[0..len-1]. */
static unsigned long do_crc(unsigned long crc, unsigned char *buf, int len)
{
	unsigned long c = crc ^ 0xffffffffL;
	int n;

#if defined(CONFIG_BUILD_CRC_TABLE)
	if (!crc_table_computed) {
		make_crc_table();
		dump_crc_table();
	}
#endif

	for (n = 0; n < len; n++) {
		c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
	}
	return c ^ 0xffffffffL;
}

#undef TEST /* get faster turn-around time */
#ifdef NO_SYNTH /* TEST */
#  define NB_SLICES   (4)
#  define NB_ROUND    (1 << 10)
#else
#  ifndef NB_SLICES
#    define NB_SLICES (65536)   /* 65536 */ /* for real benchmark */
#  endif
#  ifndef NB_ROUND
#    define NB_ROUND  (1 << 16) /* (1 << 24) */ /* for real benchmark */
#  endif
#endif

/* Number of parallelization channels at hls_action level*/
#if NB_SLICES == 4
#  define CHANNELS 4
#else
#  define CHANNELS 16
#endif

#define RESULT_SIZE 8
#define HASH_SIZE 64
/*
 * Casting from uint8_t to uint64_t => 89 FF - 83 LUT - II=34 - Latency=33
 */
static void cast_uint8_to_uint64_W8(uint8_t st_in[64], uint64_t st[8])
{
	uint64_t mem;
	int i, j;
	const int VECTOR_SIZE = 8;

	for (i = 0; i < VECTOR_SIZE; i++ ) {
		/* #pragma HLS PIPELINE */
		mem = 0;
		for (j = 8; j >= 0; j--) {
			mem = (mem << 8);
			mem = (mem & 0xFFFFFFFFFFFFFF00 ) | st_in[j+i*8];
		}
		st[i] = mem;
	}
}

/*
 * Casting from uint64_t to uint8_t => 89 FF - 99 LUT - II=36 - Latency=35
 */
static void cast_uint64_to_uint8_W8(uint64_t st_in[8], uint8_t st_out[64])
{
	uint64_t tmp = 0;
	int i, j;
	const int VECTOR_SIZE = 8;

	for (i = 0; i < VECTOR_SIZE; i++ ) {
		/* #pragma HLS PIPELINE */
		tmp = st_in[i];
		for (j = 0; j < 8; j++ ) {
			st_out[i*8+j] = (uint8_t)tmp;
			tmp = (tmp >> 8);
		}
	}
}

static uint64_t sponge(const uint64_t rank)
{
	uint64_t magic[8] = { 0x0123456789abcdeful, 0x13579bdf02468aceul,
			      0xfdecba9876543210ul, 0xeca86420fdb97531ul,
			      0x571e30cf4b29a86dul, 0xd48f0c376e1b29a5ul,
			      0xc5301e9f6b2ad748ul, 0x3894d02e5ba71c6ful };
	uint64_t odd[8], even[8], result;
	uint8_t odd8b[64], even8b[64];
	int i, j;
	int rnd_nb;

	for (i = 0; i < RESULT_SIZE; i++) {
		/* #pragma HLS UNROLL */
		even[i] = magic[i] + rank;
	}

	// FIXME - this double conversion need to be optimized
	cast_uint64_to_uint8_W8(even, even8b);
	sha3((uint8_t*)even8b, HASH_SIZE, (uint8_t*)odd8b, HASH_SIZE);
	cast_uint8_to_uint64_W8(odd8b, odd);
	
	for (rnd_nb = 0; rnd_nb < NB_ROUND; rnd_nb++) {
		/* #pragma HLS UNROLL factor=4 */

		for (j = 0; j < 4; j++) {
			/* #pragma HLS UNROLL */
			odd[2*j] ^= ROTL64( even[2*j] , 4*j+1);
			odd[2*j+1] = ROTL64( even[2*j+1] + odd[2*j+1], 4*j+3);
		}

		// FIXME - this double conversion need to be optimized
		cast_uint64_to_uint8_W8(odd, odd8b);
		sha3((uint8_t*)odd8b,HASH_SIZE,(uint8_t*)even8b,HASH_SIZE);
		cast_uint8_to_uint64_W8(even8b, even);

		for (j = 0; j < 4; j++) {
			/* #pragma HLS UNROLL */
			even[2*j] += ROTL64( odd[2*j] , 4*j+5);
			even[2*j+1] = ROTL64( even[2*j+1] ^ odd[2*j+1], 4*j+7);
		}
		
		cast_uint64_to_uint8_W8(even, even8b);
		sha3((uint8_t*)even8b,HASH_SIZE,(uint8_t*)odd8b,HASH_SIZE);
		cast_uint8_to_uint64_W8(odd8b, odd);
	}
	result = 0;
  
	for (i = 0; i < RESULT_SIZE; i++) {
		/* #pragma HLS UNROLL */
		result += (even[i] ^ odd[i]);
	}
	return result;
}

#if !defined(CONFIG_USE_PTHREADS)

/**
 * nb_pe must be != 0, since we divide by it.
 */
static uint64_t sponge_main(uint32_t pe, uint32_t nb_pe,
			    uint32_t threads __attribute__((unused)))
{
	uint32_t slice;
	uint64_t checksum=0;

	act_trace("%s(%d, %d)\n", __func__, pe, nb_pe);
	act_trace("  sw: NB_SLICES=%d NB_ROUND=%d\n", NB_SLICES, NB_ROUND);

	for (slice = 0; slice < NB_SLICES; slice++) {
		if (pe == (slice % nb_pe)) {
			uint64_t checksum_tmp;

			act_trace("  slice=%d\n", slice);
			checksum_tmp = sponge(slice);
			checksum ^= checksum_tmp;
			act_trace("    %016llx %016llx\n",
				  (long long)checksum_tmp,
				  (long long)checksum);
		}
	}

	act_trace("checksum=%016llx\n", (unsigned long long)checksum);
	return checksum;
}

#else

#include <pthread.h>

struct thread_data {
        pthread_t thread_id;    /* Thread id assigned by pthread_create() */
        unsigned int slice;
        uint64_t checksum;
        int thread_rc;
};

static struct thread_data *d;

static void *sponge_thread(void *data)
{
        struct thread_data *d = (struct thread_data *)data;

        d->checksum = 0;
        d->thread_rc = 0;
        d->checksum = sponge(d->slice);
        pthread_exit(&d->thread_rc);
}

/**
 * nb_pe must be != 0, since we divide by it.
 */
static uint64_t sponge_main(uint32_t pe, uint32_t nb_pe, uint32_t _threads)
{
        int rc;
        uint32_t slice;
        uint64_t checksum = 0;

	if (_threads == 0) {
		fprintf(stderr, "err: Min threads must be 1\n");
		return 0;
	}

        d = calloc(_threads * sizeof(struct thread_data), 1);
	if (d == NULL) {
		fprintf(stderr, "err: No memory available\n");
		return 0;
	}

        act_trace("%s(%d, %d, %d)\n", __func__, pe, nb_pe, _threads);
        act_trace("  NB_SLICES=%d NB_ROUND=%d\n", NB_SLICES, NB_ROUND);

        for (slice = 0; slice < NB_SLICES; ) {
                unsigned int i;
                unsigned int remaining_slices = NB_SLICES - slice;
                unsigned int threads = MIN(remaining_slices, _threads);

                act_trace("  [X] slice=%d remaining=%d threads=%d\n",
                          slice, remaining_slices, threads);

                for (i = 0; i < threads; i++) {
                        if (pe != ((slice + i) % nb_pe))
                                continue;

                        d[i].slice = slice + i;
                        rc = pthread_create(&d[i].thread_id, NULL,
                                            &sponge_thread, &d[i]);
                        if (rc != 0) {
				free(d);
                                fprintf(stderr, "starting %d failed!\n", i);
                                return EXIT_FAILURE;
                        }
                }
                for (i = 0; i < threads; i++) {
			act_trace("      slice=%d checksum=%016llx\n",
				  slice + i, (long long)d[i].checksum);

                        if (pe != ((slice + i) % nb_pe))
                                continue;

                        rc = pthread_join(d[i].thread_id, NULL);
                        if (rc != 0) {
				free(d);
				fprintf(stderr, "joining threads failed!\n");
                                return EXIT_FAILURE;
                        }
                        checksum ^= d[i].checksum;
                }
                slice += threads;
        }

	free(d);

        act_trace("checksum=%016llx\n", (unsigned long long)checksum);
        return checksum;
}

#endif /* CONFIG_USE_PTHREADS */

static int action_main(struct snap_sim_action *action, void *job,
		       unsigned int job_len)
{
	struct checksum_job *js = (struct checksum_job *)job;
	void *src;

	act_trace("%s(%p, %p, %d) [%d]\n", __func__, action, job, job_len,
		  (int)js->chk_type);

	switch (js->chk_type) {
	case CHECKSUM_SPONGE: {
		unsigned int threads;

		act_trace("pe=%d nb_pe=%d\n", js->pe, js->nb_pe);

		threads = js->nb_slices; /* misused for sw sim */
		js->nb_slices = NB_SLICES;
		js->nb_round = NB_ROUND;
		js->timer_ticks = 0; /* FIXME */

		if (js->nb_pe == 0)
			return 0;

		js->chk_out = sponge_main(js->pe, js->nb_pe, threads);
		break;
	}
	case CHECKSUM_CRC32:
		/* checking parameters ... */
		if (js->in.type != SNAP_ADDRTYPE_HOST_DRAM)
			return 0;

		src = (void *)js->in.addr;
		if (src == NULL)
			return 0;

		/* calculate the results ... */
		js->chk_out = do_crc(js->chk_in, src, js->in.size);
		js->chk_out &= 0xffffffff; /* 32-bit only */
		break;

	default:
		return 0;
	}

	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;
}

static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = CHECKSUM_ACTION_TYPE,

	.job = { .retc = SNAP_RETC_FAILURE, },
	.state = ACTION_IDLE,
	.main = action_main,
	.priv_data = NULL,	/* this is passed back as void *card */
	.mmio_write32 = mmio_write32,
	.mmio_read32 = mmio_read32,

	.next = NULL,
};

static void _init(void) __attribute__((constructor));

static void _init(void)
{
	snap_action_register(&action);
}
