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
 * Example to use the FPGA to find patterns in a byte-stream.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>

#include <libdonut.h>
#include <donut_internal.h>
#include <action_search.h>

static int mmio_write32(void *_card, uint64_t offs, uint32_t data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, _card,
		  (long long)offs, data);
	return 0;
}

static int mmio_read32(void *_card, uint64_t offs, uint32_t *data)
{
	act_trace("  %s(%p, %llx, %x)\n", __func__, _card,
		  (long long)offs, *data);
	return 0;
}
//
// C++ program for Knuth Morris Pratt Pattern Searching algorithm
//
// Origin:
//   based on D. E. Knuth, J. H. Morris, Jr., and V. R. Pratt, i
//   Fast pattern matching in strings", SIAM J. Computing 6 (1977), 323--350
//
int Naive_search(char *pat, int M, char *txt, int N)
{
   int i, j;
   int count=0;


   for (j = 0; j <= N - M; ++j) {
      for (i = 0; i < M && pat[i] == txt[i + j]; ++i);
      if (i >= M)
      {
           count++; 
           printf("Pattern found at index %d \n", j);
      }
   }
   return count;
}


uint32_t run_sw_search (char *dbuff, ssize_t dsize, char *pbuff, int psize, int method)
{
        int count = 0;
        //int q = 101; // a prime number

    printf("SW search, method = %d, Text size is %d, pattern is %s, pattern size is %d \n",
                                    method, (unsigned int) dsize, pbuff, psize);

        switch (method) {
        case(NAIVE):    printf("======== Naive method ========\n");
                        count = Naive_search  ((char *) pbuff, psize, (char *)dbuff, dsize);
                        break;
/*
        case(KMP):      printf("========= KMP method =========\n");
                        count = KMPsearch(Pattern, PatternSize, Text, TextSize);
                        break;
        case(FA):       printf("========= FA method =========\n");
                        count = FAsearch (Pattern, PatternSize, Text, TextSize);
                        break;
        case(FAE):      printf("========= FAE method =========\n");
                        count = FAEsearch(Pattern, PatternSize, Text, TextSize);
                        break;
        case(BM):       printf("========= BM method =========\n");
                        count = BMsearch (Pattern, PatternSize, Text, TextSize);
                        break;
        case(RK):       printf("========= RK method =========\n");
                        count = RKsearch (Pattern, PatternSize, Text, TextSize, q);
                        break;
*/
        default:        printf("=== Default Naive method ===\n");;
                        count = Naive_search  (pbuff, psize, dbuff, dsize);
        }
        printf("pattern size %d - text size %d - rc = %d \n", psize, (unsigned int)dsize, count);

        return count;

}

static int action_main(struct dnut_action *action,
		       void *job, unsigned int job_len)
{
//	struct search_job *js = (struct search_job *)job;
	act_trace("%s(%p, %p, %d) SEARCH\n", __func__, action, job, job_len);
/*
    char *needle, *haystack;
	unsigned int needle_len, haystack_len, offs_used, offs_max;
	uint64_t *offs;

	memset((uint8_t *)js->res_text.addr, 0, js->res_text.size);

	offs = (uint64_t *)(unsigned long)js->res_text.addr;
	offs_max = js->res_text.size / sizeof(uint64_t);
	offs_used = 0;

	haystack = (char *)(unsigned long)js->src_text1.addr;
	haystack_len = js->src_text1.size;

	needle = (char *)(unsigned long)js->src_text2.addr;
	needle_len = js->src_text2.size;

	js->next_input_addr = 0;
	while (haystack_len != 0) {
		if (needle_len > haystack_len) {
			js->next_input_addr = 0;
			break;	// cannot find more
		}
		if (strncmp(haystack, needle, needle_len) == 0) {
			if (offs_used == offs_max) {
				js->next_input_addr = (unsigned long)haystack;
				break;	// cannot put more in result array 
			}
			// write down result
			offs[offs_used] = (unsigned long)haystack;
			offs_used++;
		}
		haystack++;	// uuh, is that performing badly ;-)
		haystack_len--;
	}

	js->nb_of_occurrences = offs_used;
	//js->action_version = 0xC0FEBABEBABEBABEull;
    */
	action->job.retc = DNUT_RETC_SUCCESS;

	//act_trace("%s SEARCH DONE retc=%x\n", __func__, action->job.retc);
	return 0;
}

static struct dnut_action action = {
	.vendor_id = DNUT_VENDOR_ID_ANY,
	.device_id = DNUT_DEVICE_ID_ANY,
	.action_type = SEARCH_ACTION_TYPE,

	.job = { .retc = DNUT_RETC_FAILURE, },
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
	dnut_action_register(&action);
}
