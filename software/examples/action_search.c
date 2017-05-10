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
/*******************************************************/
// Knuth Morris Pratt Pattern Searching algorithm
// based on D. E. Knuth, J. H. Morris, Jr., and V. R. Pratt, i
// Fast pattern matching in strings", SIAM J. Computing 6 (1977), 323--350
//
void preprocess_KMP_table(char *pat, int M, int KMP_table[])
{
   int i, j;

   i = 0;
   j = -1;
   KMP_table[0] = -1;
   while (i < M) {
      while (j > -1 && pat[i] != pat[j])
         j = KMP_table[j];
      i++;
      j++;
      if (pat[i] == pat[j])
          KMP_table[i] = KMP_table[j];
      else
          KMP_table[i] = j;
   }
}
int KMP_search(char *pat, int M, char *txt, int N)
{
   int i, j;
   int KMP_table[64];
   int count;

   preprocess_KMP_table(pat, M, KMP_table);

   i = j = 0;
   count = 0;
   while (j < N) {
      while (i > -1 && pat[i] != txt[j])
         i = KMP_table[i];
      i++;
      j++;
      if (i >= M)
      {
         i = KMP_table[i];
         printf("Found pattern at index %d\n", j-i-M);
         count++;
      }
   }
   return count;
}
// Naive / Brute Force Searching algorithm
// based on D. E. Knuth, J. H. Morris, Jr., and V. R. Pratt, i
// Fast pattern matching in strings", SIAM J. Computing 6 (1977), 323--350
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
unsigned int run_sw_search(unsigned int Method,
           char *Pattern, unsigned int PatternSize,
           char *Text, unsigned int TextSize)
{
        int count;
        //unsigned int positions[TEXT_SIZE];

        count = 0;
        switch (Method) {
        case(NAIVE_method):    printf("======== Naive method ========\n");
                        count = Naive_search (Pattern, PatternSize, Text, TextSize);
                        break;
        case(KMP_method):      printf("========= KMP method =========\n");
                        count = KMP_search(Pattern, PatternSize, Text, TextSize);
                        break;
        default:        printf("=== Default Naive method ===\n");;
                        count = Naive_search(Pattern, PatternSize, Text, TextSize);
                        break;
        }

        printf("pattern size %d - text size %d - rc = %d \n", PatternSize, TextSize, count);


        return (unsigned int) count;
}

static int action_main(struct snap_sim_action *action,
		       void *job, unsigned int job_len)
{
	struct search_job *js = (struct search_job *)job;
	char *needle, *haystack;
	unsigned int needle_len, haystack_len, offs_used, offs_max;
	uint64_t *offs;

	act_trace("%s(%p, %p, %d) SEARCH\n", __func__, action, job, job_len);
	memset((uint8_t *)js->src_result.addr, 0, js->src_result.size);

	offs = (uint64_t *)(unsigned long)js->src_result.addr;
	offs_max = js->src_result.size / sizeof(uint64_t);
	offs_used = 0;

	haystack = (char *)(unsigned long)js->src_text1.addr;
	haystack_len = js->src_text1.size;

	needle = (char *)(unsigned long)js->src_pattern.addr;
	needle_len = js->src_pattern.size;

	js->next_input_addr = 0;
	while (haystack_len != 0) {
		if (needle_len > haystack_len) {
			js->next_input_addr = 0;
			break;	/* cannot find more */
		}
		if (strncmp(haystack, needle, needle_len) == 0) {
			if (offs_used == offs_max) {
				js->next_input_addr = (unsigned long)haystack;
				break;	/* cannot put more in result array */
			}
			/* write down result */
			offs[offs_used] = (unsigned long)haystack;
			offs_used++;
		}
		haystack++;	/* uuh, is that performing badly ;-) */
		haystack_len--;
	}

	js->nb_of_occurrences = offs_used;
	action->job.retc = SNAP_RETC_SUCCESS;

	act_trace("%s SEARCH DONE retc=%x\n", __func__, action->job.retc);
	return 0;
}

static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = SEARCH_ACTION_TYPE,

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
