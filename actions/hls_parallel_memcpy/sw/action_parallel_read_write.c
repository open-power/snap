/*
 * Copyright 2019 International Business Machines
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
 * Example to read(write) data from(to) HOST in FPGA in parallel.
 * Buffers are storded in a buffer for reading(writing) and swap between 
 * each iteration.
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
#include <action_parallel_read_write.h>

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


static void read_addr(uint8_t *flag, uint32_t **addr){
	unsigned long address = 0x0ull;
	for(int i = 0; i<(int)sizeof(uint64_t); i++){
		address += (unsigned long)(flag[i+1] << 8*i);
	}
	
	*addr = (uint32_t *)address;
}

static int action_main(struct snap_sim_action *action,
		void *job, unsigned int job_len)
{
	printf("...");
	struct parallel_memcpy_job *args = (struct parallel_memcpy_job *)job;
	uint8_t *read_flag, *write_flag;
	uint32_t *addr_read, *addr_write;
	int max_iteration, vector_size;
	
	// get the parameters from the structure
	addr_read = (uint32_t *)(unsigned long)args->read.addr;
    	addr_write = (uint32_t *)(unsigned long)args->write.addr;
    	vector_size = args->vector_size;
    	read_flag = (uint8_t *)(unsigned long)args->read_flag.addr;
    	write_flag = (uint8_t *)(unsigned long)args->write_flag.addr;
	max_iteration = args->max_iteration;

	(void)job_len;
	int i = 0;
	size_t size = vector_size*sizeof(uint32_t);
	uint32_t *buffer1 = malloc(size);
	uint32_t *buffer2 = malloc(size);

	buffer1[0] = 1;
	buffer2[0] = 1;

	printf("FPGA SW Action starts");
	while (i<max_iteration) {
		sleep(0.000001);
		if ((read_flag[0] == 1) && (write_flag[0] == 1)){

			//pointer switch
			switch (i%2){
				case 0:
					memcpy(buffer1,addr_read,size);
					memcpy(addr_write,buffer2,size);
					break;
				case 1:
					memcpy(buffer2,addr_read,size);
					memcpy(addr_write,buffer1,size);
					break;
			}

			read_addr(read_flag,&addr_read);
			read_addr(write_flag,&addr_write);
			read_flag[0] = 0;
			write_flag[0] = 0;
			
			i++;
		}
	}



	// update the return code to the SNAP job manager
	action->job.retc = SNAP_RETC_SUCCESS;
	return 0;

}

/* This is the switch call when software action is called */
/* NO CHANGE TO BE APPLIED BELOW OTHER THAN ADAPTING THE ACTION_TYPE NAME */
static struct snap_sim_action action = {
	.vendor_id = SNAP_VENDOR_ID_ANY,
	.device_id = SNAP_DEVICE_ID_ANY,
	.action_type = PARALLEL_MEMCPY_ACTION_TYPE, // Adapt with your ACTION NAME

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
