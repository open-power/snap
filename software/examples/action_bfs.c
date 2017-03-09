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
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <endian.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <libdonut.h>
#include <linux/types.h>	/* __be64 */
#include <asm/byteorder.h>

#include <donut_internal.h>
#include <donut_tools.h>
#include <action_bfs.h>


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
//-------------------------------------
//   Queue functions
//-------------------------------------
static Queue * InitQueue()
{
    Queue *q= (Queue*)malloc (sizeof(Queue));
    if (!q)
    {
        printf("ERROR: failed to malloc queue.\n");
        return NULL;
    }
    q -> front = NULL;
    q -> rear  = NULL;
    return q;
}

static void DestoryQueue( Queue *q)
{
    free (q);
}

static int QueueEmpty(Queue * q)
{
    return (q->front == NULL);
}

/*
static void PrintQueue(Queue *q)
{
    printf("Queue is ");
    if (QueueEmpty(q))
    {
        printf ("empty.\n");
        return;
    }
    
    QNode * node = q->front;
    while (node != NULL)
    {
        printf ("%d, ", node->data);
        node = node->next;
    }
    printf("\n");
}
*/
static void EnQueue (Queue *q, ElementType element)
{
    QNode * node_ptr = (QNode*) malloc (sizeof(QNode));
    if (!node_ptr)
    {
        printf("ERROR: failed to malloc a queue node.\n");
        return;
    }

    node_ptr->data = element;
    node_ptr->next = NULL;

    //Append to the tail
    
    if (q->front == NULL)
        q->front = node_ptr;
    
    if (q->rear == NULL)
    {
        q->rear = node_ptr;
    }
    else
    {
        q->rear->next = node_ptr;
        q->rear = node_ptr;
    }


    //PrintQueue(q);
}



static void DeQueue (Queue *q, ElementType *ep)
{
   // printf("Dequeue\n");
    if (QueueEmpty (q)) 
    {
        printf ("ERROR: DeQueue: queue is empty.\n");
        return;
    }

    QNode *temp = q->front;
    if(q->front == q->rear) //only one element
    {
        q->front = NULL;
        q->rear = NULL;
    }
    else
    {
        q->front = q->front->next;
    }

    *ep = temp->data;
    free(temp);
}


//-------------------------------------
//    breadth first search   
//-------------------------------------

void output_vex(unsigned int vex, int is_tail)
{
    if(is_tail == 0)
    {
        *g_out_ptr = vex;
        g_out_ptr ++;
     //   printf("Visit Node %d\n", vex);
    }
    else
    {
        *g_out_ptr = 0xFF000000 + vex; //here vex means cnt
     // printf("End. %x\n", *g_out_ptr);
        g_out_ptr += 16 - (((unsigned long long )g_out_ptr & 0x3C) >> 2); //Make paddings.

    }
}


int bfs_all (VexNode * vex_list, unsigned int vex_num)
{
    unsigned int i;
    for (i = 0; i < vex_num; i++)
    {
        bfs(vex_list, vex_num, i); 
    }
    return 0;
}

//Breadth-first-search from a perticular vertex. 
void bfs (VexNode * vex_list, unsigned int vex_num, unsigned int root)
{
    EdgeNode *p;
    Queue *Q;
    unsigned int current, i;
    int * visited;
    visited = (int *) malloc (vex_num * sizeof(int));
    unsigned int cnt = 0; 
    current = 0;
    
    //initilize to all zero.  
    for (i = 0; i < vex_num; i++)
        visited[i] = 0;

    Q = InitQueue();

    visited[root] = 1;
    output_vex( root,0);
    cnt++;
    
    EnQueue(Q, root);

    while (! QueueEmpty(Q))
    {
        
   /*
        printf("vistied = ");
        for (i = 0; i < vex_num; i++)
        {
            printf("%d", visited[i]);
        }
        printf("\n");
     */   
            
        DeQueue(Q, &current);
        p = vex_list[current].edgelink;

       // printf("current = %d\n", current);
        while(p)
        {
            if(!visited[p->adjvex])
            {
                visited[p->adjvex] = 1;
                output_vex(p->adjvex, 0);
                cnt++;

                EnQueue(Q, p->adjvex);
            }
            p = p->next;
        } //till to NULL of the edge list
    }
    output_vex(cnt, 1); //Indicate a tail

    free(visited);
    DestoryQueue(Q);
}

//------------------------------------
//    action main
//------------------------------------

static int action_main(struct dnut_action *action,
		       void *job, unsigned int job_len __unused)
{
	int rc;
	struct bfs_job *js = (struct bfs_job *)job;
	
    VexNode * vex_list = (VexNode *) js->input_adjtable_address;
    unsigned int vex_num = js->input_vex_num;

    
    g_out_ptr = (unsigned int *)js->output_address;

    rc = bfs_all(vex_list, vex_num);
    js->status_vex = vex_num -1;
    js->status_pos = (unsigned int)((unsigned long long) g_out_ptr & 0xFFFFFFFFull);
    if (rc == 0)
        goto out_ok;
    else
        goto out_err;

 
 out_ok:
	action->retc = DNUT_RETC_SUCCESS;
	return 0;

 out_err:
	action->retc = DNUT_RETC_FAILURE;
	return 0;
}

static struct dnut_action action = {
	.vendor_id = DNUT_VENDOR_ID_ANY,
	.device_id = DNUT_DEVICE_ID_ANY,
	.action_type = BFS_ACTION_TYPE,

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
