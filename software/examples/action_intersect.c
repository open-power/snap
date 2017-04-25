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
 * Example to use the FPGA to do an intersec on two data sets.
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
#include <libdonut.h>
#include <linux/types.h>	/* __be64 */

#include <donut_internal.h>
#include <donut_tools.h>
#include <action_intersect.h>


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
//////////////////////////////////////////////////////////////////
//   Intersect functions
//////////////////////////////////////////////////////////////////

void copyvalue(value_t dst, value_t src)
{
    size_t i;
    for(i = 0 ; i < sizeof(value_t); i++)
    {
        *dst = *src;
        dst++;
        src++;
    }
}

/*
 * The cmpvalue() function compares the two strings s1 and s2. It
 * returns an integer less than, equal to, or greater than zero if s1
 * is found, respectively, to be less than, to match, or be greater
 * than s2.
 */

int cmpvalue(const value_t s1, const value_t s2)
{
    size_t i;
	for (i = 0; i < sizeof(value_t); i++) {
		if (*s1 == 0 || *s2 == 0)
			break;

		if (*s1 != *s2)
			return *s1 - *s2;

		s1 += 1;
		s2 += 1;
	}
	return *s1 - *s2;
}
static int qs_cmp(const void *a, const void *b)
{
    return cmpvalue((char*) a, (char*) b);
}
        

static uint32_t intersect_direct(value_t table1[], uint32_t n1, 
                              value_t table2[], uint32_t n2,
                              value_t result_array[] )
{
    // a straight forward way to do intersection.
    // we can compare the speed with following intersect() function.
    uint32_t i,j;
    uint32_t n3;

    n3 = 0; //number of result_array entries

    for ( i = 0; i < n1; i++)
    {
        for (j = 0; j < n2; j++)
        {
            if(cmpvalue(table1[i], table2[j]) == 0)
            {
                copyvalue(result_array[n3], table2[j]);
                n3++;
                break;
            }
        }
    }
    return n3;
}

static uint32_t ht_hash(value_t key)
{
    uint64_t hashval = 0;
    uint32_t i = 0;
    int k = HT_ENTRY_NUM_EXP/8; //For example, 24/8 = 3. 

    while (i < sizeof(value_t))
    {
        hashval = hashval + (key[i]<<((k-1-(i%k))*8));
        i++;
        // accumluate every k chars.
    }

    return (hashval % HT_ENTRY_NUM);
}
static uint32_t intersect_hash(value_t table1[], uint32_t n1, 
                              value_t table2[], uint32_t n2,
                              value_t result_array[] )
{

    
    uint32_t i, index;
    struct entry_t * *hash_table;
    struct entry_t * ptr;
    struct entry_t * entry;

    uint32_t n3 = 0;
    hash_table = malloc( HT_ENTRY_NUM * 8);
    if(!hash_table)
    {
        fprintf(stderr, "ERROR: hash table malloc failed.\n");
        return 0;
    }


    for ( i = 0; i < HT_ENTRY_NUM; i++)
        hash_table[i] = NULL;

    for ( i = 0; i < n1; i++)
    {
        index = ht_hash(table1[i]);

    //    printf("build hash: %s, index = %d,",table1[i], index);
        entry = malloc(sizeof(entry_t));
        copyvalue(entry->data, table1[i]);
        entry->next = hash_table[index];
        hash_table[index] = entry; //hook in the front.
    }

    for (i = 0; i < n2; i++)
    {
        index = ht_hash(table2[i]);
        ptr = hash_table[index];
        entry = ptr;
        
       // printf("index = %d, ptr = %p\n", index, ptr);

        while (ptr != NULL)
        {
       //     printf("   cmp: %s . %s \n", table2[i], ptr->data);
            if(cmpvalue(table2[i], ptr->data) == 0)
            {
    //            printf("match %d, %s\n", i, table2[i]);
                copyvalue(result_array[n3], table2[i]);
                n3++;
                entry->next = ptr->next; //delete a node.
                break;
            }
            else
                entry = ptr;
            ptr = ptr -> next;
        }
    }
    __free(hash_table);  
    return n3;
}

static uint32_t intersect_sort( value_t table1[], uint32_t n1, 
                                value_t table2[], uint32_t n2,
                                value_t result_array[] )
{

    uint32_t n3 = 0;
    uint32_t i, j;

    i = 0;
    j = 0;
    //Quicksort 
    qsort(table1, n1, sizeof(value_t), qs_cmp);
    qsort(table2, n2, sizeof(value_t), qs_cmp);

    while (i < n1 && j < n2)
    {
        if(cmpvalue(table1[i], table2[j]) == 0)
        {
            copyvalue(result_array[n3], table2[j]);
            n3++;
            i++;
            j++;
        }
        else if (cmpvalue(table1[i], table2[j]) < 0)
            i++;
        else
            j++;
    }
    return n3;
}


uint32_t run_sw_intersection(int method, value_t *table1, uint32_t n1, value_t * table2, uint32_t n2, value_t *result_array)
{
    printf("SW intersection, method = %d, table1 (%p) num is %d, table2 (%p) num is %d, out (%p) \n",
                                    method, table1, n1, table2, n2, result_array);
    if(method == 0)
        return intersect_direct(table1, n1, table2, n2, result_array);
    else if (method == 1)
    {
        if (n1 <= n2)
            return intersect_hash (table1, n1, table2, n2, result_array);
        else
            return intersect_hash (table2, n2, table1, n1, result_array);
    }
    else if (method == 2)
        return intersect_sort (table1, n1, table2, n2, result_array);
    else
        return 0;
}

static int action_main(struct dnut_action *action,
		       void *job, uint32_t job_len)
{
        
	struct intersect_job *js = (struct intersect_job *)job;
    act_trace("%s(%p, %p, %d) table1_size = %d, table2_size = %d\n", 
            __func__, action, job, job_len, js->src_tables_host[0].size,  js->src_tables_host[1].size);
    //Do Nothing.

// out_ok:
	action->job.retc = DNUT_RETC_SUCCESS;
	return 0;

}

//////////////////////////////////////////////
//     Intersect function end.
//////////////////////////////////////////////

static struct dnut_action action = {
	.vendor_id = DNUT_VENDOR_ID_ANY,
	.device_id = DNUT_DEVICE_ID_ANY,
	.action_type = (HLS_INTERSECT_ID&0xFFFF),

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
