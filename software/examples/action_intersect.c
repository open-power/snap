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
	struct dnut_action *action = (struct dnut_action *)_card;

	if (offs == ACTION_RETC)
		*data = action->retc;

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



/* DataSet: 
 * char[16] value;
 *
 * It emulates a list with next pointer. 
 * And it never changes the order of the list nodes.
 */

static void search_minmax(value_t table[], uint32_t plist[], uint32_t header, 
        value_t *minvalue, value_t * maxvalue,
        value_t *min2rd, value_t *max2rd)
{
    uint32_t i; 
    //uint32_t steps=0;

    //printf("header = %d: ", header);
    copyvalue(*minvalue, table[header]);
    copyvalue(*min2rd,   table[header]);

    copyvalue(*maxvalue, table[header]);
    copyvalue(*max2rd,   table[header]);

    i = plist[header];
    while ( i != END_SIGN)
    {
        access_bytes += sizeof(value_t);

        if(cmpvalue(table[i], *minvalue) < 0)
        {
            copyvalue(*min2rd, *minvalue);
            copyvalue(*minvalue,table[i]);
         //   printf("cur = %s, min is %s, minsec is %s\n", table[i], *minvalue, *min2rd);
        }
        else if (cmpvalue(table[i], *min2rd) < 0 && cmpvalue(table[i], *minvalue) != 0)
        {
            copyvalue(*min2rd, table[i]);
         //   printf("cur = %s, min (nochange) %s, minsec is %s\n", table[i], *minvalue, *min2rd);
        }
                

        if(cmpvalue(table[i], *maxvalue) > 0)
        {
            copyvalue(*max2rd, *maxvalue);
            copyvalue(*maxvalue,table[i]);
        }
        else if(cmpvalue(table[i], *max2rd) > 0 && cmpvalue(table[i], *maxvalue) != 0)
        {
            copyvalue(*max2rd, table[i]);
        }

        i = plist[i];
       // steps ++;
    }
    //printf("min = %s, min second = %s, max second= %s, max = %s\n", *minvalue, *min2rd, *max2rd, *maxvalue);
    //printf("search steps = %d\n", steps);

}
/*
static void dump_table_list(value_t table[], uint32_t plist[], uint32_t header)
{
    uint32_t i;
    i = header;
    while(i != END_SIGN)
    {
        printf("dump: table[%d] = %s\n", i, table[i]);
        i = plist[i];
    }
}
*/
static uint32_t check_and_remove(value_t table[],uint32_t plist[], uint32_t header,
        value_t equ_val1, value_t equ_val2, value_t lt_val, value_t gt_val, uint32_t pattern, uint32_t* append)
{


    //printf("pattern = %x, eq1 = %s, eq2 = %s, lt = %s, gt = %s\n", pattern, equ_val1, equ_val2, lt_val, gt_val);
    //pattern = 0xC (1100): remove equ_val1, and equ_val2
    //pattern = 0x8 (1000): remove equ_val1
    //pattern = 0x3 (0011): remove < lt_val, and > gt_val

    uint32_t cur, pre;
    uint32_t newheader;
   // uint32_t steps = 0; 
   // uint32_t remove_num = 0;
    uint32_t bit_equ1, bit_equ2, bit_lt, bit_gt;
    bit_equ1 = (pattern & 0x8) >>3;
    bit_equ2 = (pattern & 0x4) >>2;
    bit_lt   = (pattern & 0x2) >>1;
    bit_gt   = (pattern & 0x1);

    //we do nothing for empty list.
    if(header == END_SIGN) 
        return END_SIGN;
   

    cur = header;
    pre = header;
    newheader = header;
    *append = 0;

    do {
      //  steps++;

        access_bytes +=  sizeof(value_t);
        //check
        if((cmpvalue(table[cur], equ_val1) == 0 ) && bit_equ1 == 0)
            *append |= 2;
        if((cmpvalue(table[cur], equ_val2) == 0 ) && bit_equ2 == 0)
            *append |= 1;


        //remove
        if( ((cmpvalue(table[cur], equ_val1) == 0 ) && bit_equ1) ||
            ((cmpvalue(table[cur], equ_val2) == 0 ) && bit_equ2) ||
            ((cmpvalue(table[cur], lt_val) < 0) && bit_lt) ||
            ((cmpvalue(table[cur], gt_val) > 0) && bit_gt))
        {
            //remove_num ++;
            //Remove it.
            if(cur == newheader) //first node
            {
                newheader = plist[cur]; //Update new header
            }
            else
            {
                plist[pre] = plist[cur];
            }
        }
        else
            pre = cur;
        cur = plist[cur];
    } while (cur != END_SIGN); //exit

   // printf("append = %d\n", *append);
    //printf("remove_num = %d\n",  remove_num);
    //newheader == END_SIGN means that the list is emtpy after removing.
    //dump_table_list(table, plist, newheader);
    return newheader;
}

static uint32_t add_result(value_t result_array[], uint32_t result_cnt, value_t val)
{
   // printf("add result %s\n", val);
    copyvalue(result_array[result_cnt], val);
    return (result_cnt+1);
}

static uint32_t intersect_direct(value_t table1[], uint32_t n1, 
                              value_t table2[], uint32_t n2,
                              value_t result_array[] )
{
    // a straight forward way to do intersection.
    // we can compare the speed with following intersect() function.
    uint32_t i,j;
    uint32_t k, n3;

    int found = 0;
    k = 0;
    n3 = 0; //number of result_array entries
    for ( i = 0; i < n1; i++)
    {
        for (j = 0; j < n2; j++)
        {
            access_bytes += 2* sizeof(value_t);
            if(cmpvalue(table1[i], table2[j]) == 0)
            {
                found = 0;
                for (k = 0; k < n3; k++)
                {
                    access_bytes += sizeof(value_t);
                    if(cmpvalue(result_array[k], table2[j]) == 0)
                        found = 1;
                }
                if(found == 0)
                {
                    copyvalue(result_array[n3], table2[j]);
                    n3++;
                }
                break;
            }
        }
    }
    return n3;
}


static uint32_t intersect(value_t table1[], uint32_t plist1[], 
                          value_t table2[], uint32_t plist2[],
                          value_t result_array[] )
{
    uint32_t h1, h2;
    value_t min1, min2, max1, max2;
    value_t min_com, max_com; //intersection range
    value_t min1sec, min2sec, max1sec, max2sec;

    int cmp_min1min2;
    int cmp_max1max2;
    int cmp_min1max1;
    int cmp_min2max2;
    uint32_t res_cnt = 0;
    uint32_t append = 0;
    uint32_t steps = 0;
    h1 = 0;
    h2 = 0;
    //printf("Step2\n");

    while (h1 != END_SIGN && h2 != END_SIGN) //Only if both list are not empty
    {
        steps ++;
     //   printf("table1 addr = %p, table2 addr = %p\n", table1, table2); 
     //   printf("plist1 addr = %p, plist2 addr = %p\n", plist1, plist2);
     //   printf("-------------------\n");
        search_minmax (table1, plist1, h1, &min1, &max1, &min1sec, &max1sec);
        search_minmax (table2, plist2, h2, &min2, &max2, &min2sec, &max2sec);

     //   printf("min1 = %s, max1 = %s, min1sec = %s, max1sec = %s\n", min1, max1, min1sec, max1sec);
     //   printf("min2 = %s, max2 = %s, min2sec = %s, max2sec = %s\n", min2, max2, min2sec, max2sec);

        /*   min1    max1
         *       \   /  
         *        \ /
         *         X
         *        / \
         *       /   \ 
         *   min2    max2
         */
        if(cmpvalue(min1, max2) > 0 || cmpvalue(min2, max1) > 0)
        {
            printf("@@ steps = %d\n", steps);
            return res_cnt; //Exit!
        }


        /*   min1 ------- max1
         *     |            |
         *     |            | 
         *   min2 ------- max2
         */
        cmp_min1min2 = cmpvalue(min1, min2);
        cmp_max1max2 = cmpvalue(max1, max2);
        cmp_min1max1 = cmpvalue(min1, max1);
        cmp_min2max2 = cmpvalue(min2, max2);

        if(cmp_min1min2 == 0 && cmp_min1max1 == 0 && cmp_max1max2 == 0)
        {
            // All four items are equal
            // Add only one result.

            //h1 = check_and_remove(table1, plist1, h1, min1);
            //h2 = check_and_remove(table2, plist2, h2, min2);
            res_cnt = add_result(result_array, res_cnt, min1);
            //printf("Exit: res_cnt = %d", res_cnt);

            printf("@@ steps = %d\n", steps);
            return res_cnt; // Exit!
        }
        else
        {
            if(cmpvalue(min1sec, min2sec) > 0)
                copyvalue(min_com, min1sec);
            else
                copyvalue(min_com, min2sec);

            if(cmpvalue(max1sec, max2sec) < 0)
                copyvalue(max_com, max1sec);
            else
                copyvalue(max_com, max2sec);

            if(cmp_min1min2 == 0 && cmp_max1max2 != 0)
            {
                res_cnt = add_result(result_array, res_cnt, min1);
                h1 = check_and_remove(table1, plist1, h1, min1, max2, min_com, max_com, 11, &append);
                if(append)
                    res_cnt = add_result(result_array, res_cnt, max2);
                h2 = check_and_remove(table2, plist2, h2, min1, max1, min_com, max_com, 11, &append);
                if(append)
                    res_cnt = add_result(result_array, res_cnt, max1);
                //pattern = 1011
            }
            else if(cmp_max1max2 == 0 && cmp_min1min2 != 0)
            {
                res_cnt = add_result(result_array, res_cnt, max1);
                h1 = check_and_remove(table1, plist1, h1, min2, max1, min_com, max_com, 7, &append);
                if(append)
                    res_cnt = add_result(result_array, res_cnt, min2);
                h2 = check_and_remove(table2, plist2, h2, min1, max1, min_com, max_com, 7, &append);
                if(append)
                    res_cnt = add_result(result_array, res_cnt, min1);
            }
            else if(cmp_min1min2 == 0 && cmp_max1max2 == 0)
            {
                res_cnt = add_result(result_array, res_cnt, min1);
                res_cnt = add_result(result_array, res_cnt, max1);
                h1 = check_and_remove(table1, plist1, h1, min1, max1, min_com, max_com, 15, &append);
                h2 = check_and_remove(table2, plist2, h2, min1, max1, min_com, max_com, 15, &append);
            }
            else
            {
                h1 = check_and_remove(table1, plist1, h1, min2, max2, min_com, max_com, 3, &append);
                if((append&2) == 2)
                    res_cnt = add_result(result_array, res_cnt, min2);
                if((append&1) == 1)
                    res_cnt = add_result(result_array, res_cnt, max2);


                h2 = check_and_remove(table2, plist2, h2, min1, max1, min_com, max_com, 3, &append);
                if((append&2) == 2)
                    res_cnt = add_result(result_array, res_cnt, min1);
                if((append&1) == 1)
                    res_cnt = add_result(result_array, res_cnt, max1);
            }





       /*     if(cmp_min1min2 == 0 && cmp_max1max2 != 0)
            {
                //There is a common node at the left bound, but different at right. 
               
                //pattern = 1001 (9)
                if(cmp_max1max2 > 0)
                    copyvalue(max_com, max2);
                else
                    copyvalue(max_com, max1);


                h1 = check_and_remove(table1, plist1, h1, min1, min1, min1, max_com, 9);
                h2 = check_and_remove(table2, plist2, h2, min1, min1, min1, max_com, 9);
                                                           //N/A, N/A

                res_cnt = add_result(result_array, res_cnt , min1);
         
            }
            else if(cmp_max1max2 == 0 && cmp_min1min2 !=0)
            {
                //There is a common node at the right bound, but different at let
                //pattern = 0110 (6)

                if (cmp_min1min2 > 0)
                    copyvalue(min_com, min1);
                else
                    copyvalue(min_com, min2);


                h1 = check_and_remove(table1, plist1, h1, max1, max1, min_com, max1, 6);
                h2 = check_and_remove(table2, plist2, h2, max1, max1, min_com, max1, 6);
                                                    //N/A                   N/A
                res_cnt = add_result(result_array, res_cnt, max1);
            }
            else if(cmp_min1min2 == 0 && cmp_max1max2 == 0)
            {
                //Remove both
                //pattern = 1100 (12)
                //
                //
                h1 = check_and_remove(table1, plist1, h1, min1, max1, min1, max1, 12);
                h2 = check_and_remove(table2, plist2, h2, min1, max1, min1, max1, 12);
                                                                 //N/A  N/A
                res_cnt = add_result(result_array, res_cnt, min1);
                res_cnt = add_result(result_array, res_cnt, max1);
            }
            else
            {
                //pattern = 0011 (3)
                if (cmp_min1min2 > 0)
                    copyvalue(min_com, min1);
                else
                    copyvalue(min_com, min2);

                if(cmp_max1max2 < 0)
                    copyvalue(max_com, max1);
                else
                    copyvalue(max_com, max2);
                
                h1 = check_and_remove(table1, plist1, h1, min1, max1, min_com, max_com, 3);
                h2 = check_and_remove(table2, plist2, h2, min1, max1, min_com, max_com, 3);
                                                    //N/A   N/A
            
            }

          */


        }

    }

    //Exit ! One data list is empty./afs/bb/proj/fpga/xilinx/Vivado/2016.4/bin/vivado
    printf("@@ steps = %d\n", steps);
    return res_cnt;
}







static int action_main(struct dnut_action *action,
		       void *job, uint32_t job_len)
{
	//int rc;
	struct intersect_job *js = (struct intersect_job *)job;
    uint32_t n[NUM_TABLES];
    uint32_t i, j;
    uint32_t result_num;

    act_trace("%s(%p, %p, %d) table1_size = %d, table2_size = %d\n", 
            __func__, action, job, job_len, js->src_tables[0].size,  js->src_tables[1].size);



    for (i = 0; i < NUM_TABLES; i++)
    {
        n[i] = js->src_tables[i].size / sizeof(value_t);
        
        //check input parameters
        if(n[i] <= 0)
        {
            goto out_err;
        }
    }

    // Action! 
    //  In this software implemented version , we ignore type=DNUT_TARGET_TYPE_CARD_DRAM
    if (js->step == 1) 
    {
        // For hardware kernel, it copies from Host memory to DDR. 
        //  And DDR adress starts from 0. 
        //
        // For software, just construct initial plist.
        for (i = 0; i < NUM_TABLES; i++)
        {
         //   printf("plist: ");
            
            for (j = 0; j < n[i]-1; j++)
            {
                plists[i][j] = j+1;
          //      printf("%d:%d| ",j, plists[i][j]);

            }
            plists[i][n[i]-1] = END_SIGN;
          //  printf("%d:END \n",n[i]-1);
        }
                
    }
    
    if (js-> step == 2) 
    {
        //Do intersection!

        if (intersect_method == 0)
        {
            result_num = intersect_direct((value_t *)js->src_tables[0].addr, n[0], 
                             (value_t *)js->src_tables[1].addr, n[1], 
                             (value_t *)js->result_table.addr);
        }
        else
        {
            result_num = intersect ((value_t *)js->src_tables[0].addr, plists[0], 
                       (value_t *)js->src_tables[1].addr, plists[1], 
                       (value_t *)js->result_table.addr);
        }


        printf("result_num = %d\n", result_num);
        js-> result_table.size = result_num * sizeof(value_t);
    

    }
    //Do nothing for step3. 
        

// out_ok:
	action->retc = DNUT_RETC_SUCCESS;
	return 0;

 out_err:
	action->retc = DNUT_RETC_FAILURE;
	return 0;
}

//////////////////////////////////////////////
//     Intersect function end.
//////////////////////////////////////////////

static struct dnut_action action = {
	.vendor_id = DNUT_VENDOR_ID_ANY,
	.device_id = DNUT_DEVICE_ID_ANY,
	.action_type = (HLS_INTERSECT_ID&0xFFFF),

	.retc = DNUT_RETC_FAILURE, /* preset value, should be 0 on success */
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
