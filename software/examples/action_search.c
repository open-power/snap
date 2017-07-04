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
#include <sys/time.h>
#include <snap_tools.h>

#include <libsnap.h>
#include <snap_internal.h>
#include <snap_search.h>

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
void preprocess_KMP_table(char *Pattern, int PatternSize, int KMP_table[])
{
   int i, j;

   i = 0;
   j = -1;
   KMP_table[0] = -1;
   while (i < PatternSize) {
      while (j > -1 && Pattern[i] != Pattern[j])
         j = KMP_table[j];
      i++;
      j++;
      if (Pattern[i] == Pattern[j])
          KMP_table[i] = KMP_table[j];
      else
          KMP_table[i] = j;
   }
}
int KMP_search(char *Pattern, int PatternSize, char *Text, int TextSize)
{
   int i, j;
   /*FIXME Pattern is currently hardware limited to 64 Bytes */
   int KMP_table[64];
   int count;

   preprocess_KMP_table(Pattern, PatternSize, KMP_table);

   i = j = 0;
   count = 0;
   while (j < TextSize) {
      while (i > -1 && Pattern[i] != Text[j])
         i = KMP_table[i];
      i++;
      j++;
      if (i >= PatternSize)
      {
         i = KMP_table[i];
         //printf("Found pattern at index %d\n", j-i-PatternSize);
         count++;
      }
   }
   return count;
}
// Naive / Brute Force Searching algorithm
// based on D. E. Knuth, J. H. Morris, Jr., and V. R. Pratt, i
// Fast pattern matching in strings", SIAM J. Computing 6 (1977), 323--350
//
int Naive_search(char *Pattern, int PatternSize, char *Text, int TextSize)
{
   int i, j;
   int count=0;

   for (j = 0; j <= TextSize - PatternSize; ++j) {
      for (i = 0; i < PatternSize && Pattern[i] == Text[i + j]; ++i);
      if (i >= PatternSize)
      {
           count++;
           //printf("Pattern found at index %d \n", j);
      }
   }
   return count;
}
unsigned int run_sw_search(unsigned int Method,
           char *Pattern, unsigned int PatternSize,
           char *Text, unsigned int TextSize)
{
        int count;

        struct timeval etime, stime;

        count = 0;
 	gettimeofday(&stime, NULL);

        switch (Method) {
        case(1):
		printf("======== SW Naive method ========\n");
                count = Naive_search (Pattern, PatternSize, Text, TextSize);
                break;
        case(2):
	        printf("========= SW KMP method =========\n");
                count = KMP_search(Pattern, PatternSize, Text, TextSize);
                break;
        default:
	        printf("=== SW Default Naive method ===\n");;
                count = Naive_search(Pattern, PatternSize, Text, TextSize);
                break;
        }

        gettimeofday(&etime, NULL);
        fprintf(stdout, "SW run step took %lld usec\n",
                 (long long)timediff_usec(&etime, &stime));

        printf("pattern size %d - text size %d - rc = %d \n", PatternSize, TextSize, count);


        return (unsigned int) count;
}

static void __trace_addr(const char *name, struct snap_addr *a)
{
	act_trace("  %-12s: %012llx %08x %04x %04x\n",
		  name, (long long)a->addr, a->size, a->type, a->flags);
}

static int action_main(struct snap_sim_action *action,
		       void *job, unsigned int job_len)
{
	struct search_job *js = (struct search_job *)job;
	char *needle, *haystack;
	unsigned int needle_len, haystack_len, method;

	act_trace("%s(%p, %p, %d) SEARCH\n", __func__, action, job, job_len);
	__trace_addr("src_text1",   &js->src_text1);
	__trace_addr("src_pattern", &js->src_pattern);
	__trace_addr("ddr_text1",   &js->ddr_text1);
	__trace_addr("src_result",  &js->src_result);
	__trace_addr("ddr_result",  &js->ddr_result);

	if (js->src_result.addr != 0 && js->src_result.type == SNAP_ADDRTYPE_HOST_DRAM)
		memset((uint8_t *)js->src_result.addr, 0, js->src_result.size);

	haystack = (char *)(unsigned long)js->src_text1.addr;
	haystack_len = js->src_text1.size;

	needle = (char *)(unsigned long)js->src_pattern.addr;
	needle_len = js->src_pattern.size;

	method =  js->method;

        if (js->step == 3) 
		js->nb_of_occurrences = run_sw_search(method, (char *)needle, needle_len,
                                        (char *)haystack, haystack_len);

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
