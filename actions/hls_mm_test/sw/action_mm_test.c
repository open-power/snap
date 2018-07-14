/*
 * Copyright 2018 International Business Machines
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
 * Simple Software implementation of a Matrix Multiply.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <endian.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <libsnap.h>
#include <linux/types.h>	/* __be64 */
#include <asm/byteorder.h>

#include <snap_internal.h>
#include <snap_tools.h>
#include <action_mm_test.h>

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

/* Main program of the software action */
static int action_main(struct snap_sim_action *action,
		       void *job __unused, unsigned int job_len __unused)
{
/*
	struct mm_test_job *js = (struct mm_test_job *)job;
	int32_t i, j, k;
	int32_t temp;
	// get the parameters from the structure
	int32_t *W_buff = (int32_t *)(unsigned long long) js->WED_addr.W_addr;
	int32_t *X_buff = (int32_t *)(unsigned long long) js->WED_addr.X_addr;
	int32_t *Q_buff = (int32_t *)(unsigned long long) js->WED_addr.Q_addr;
//	volatile uint8_t *status_array = (uint8_t *)(unsigned long long) js->STATUS_addr;
	// Uncomment to dump the action params
	//__hexdump(stderr, js, sizeof(*js));



//             DIM2                        DIM2       
//       +---------------+           +---------------+
//     | |               |         | |               |
//     | |               |         | |               |
//     | |      k        |         | |               |
//     | |-------------->|         | |               |
//     | |AAAAAAAAAAAAAAA|         | |               |
//DIM1 | |               |     DIM3| |               |
//     | |               |         | |      k        |
//    i| |               |         | |-------------->|
//     | |               |         | |BBBBBBBBBBBBBBB|
//     | |    W_buff     |        j| |               |
//     | |               |         | |               |
//     v |               |         | |               |
//       +---------------+         | |    X_buff     |
//                                 | |               |
//                                 v |               |
//                                   +---------------+	
//                                   
// software action processing : Matrix multiplication
// X_buff holds the transposition matrix
// "AAA..AA" will do dot-multiply with "BBB..BB" to set Q(i, j)

	for (i = 0; i < DIM1; i++) {
		for (j = 0; j < DIM3; j++ ) {
			temp = 0;
			for (k = 0; k < DIM2; k++) {
				temp += W_buff[i * DIM2 + k] * X_buff[j * DIM2 + k];
			}

			Q_buff[i * DIM3 + j] = temp;
		}
	}
//	status_array[0] = STATUS_CALC_DONE;
//
//	sleep(1);
//	status_array[0] = STATUS_OUTPUT_DONE;
*/
	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;

}

/* This is the switch call when software action is called */
/* NO CHANGE TO BE APPLIED BELOW OTHER THAN ADAPTING THE ACTION_TYPE NAME */
static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = MM_TEST_ACTION_TYPE, // Adapt with your ACTION NAME

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
