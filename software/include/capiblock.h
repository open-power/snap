/* IBM_PROLOG_BEGIN_TAG                                                   */
/* This is an automatically generated prolog.                             */
/*                                                                        */
/* $Source: src/include/capiblock.h $                                     */
/*                                                                        */
/* IBM Data Engine for NoSQL - Power Systems Edition User Library Project */
/*                                                                        */
/* Contributors Listed Below - COPYRIGHT 2014,2015                        */
/* [+] International Business Machines Corp.                              */
/*                                                                        */
/*                                                                        */
/* Licensed under the Apache License, Version 2.0 (the "License");        */
/* you may not use this file except in compliance with the License.       */
/* You may obtain a copy of the License at                                */
/*                                                                        */
/*     http://www.apache.org/licenses/LICENSE-2.0                         */
/*                                                                        */
/* Unless required by applicable law or agreed to in writing, software    */
/* distributed under the License is distributed on an "AS IS" BASIS,      */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        */
/* implied. See the License for the specific language governing           */
/* permissions and limitations under the License.                         */
/*                                                                        */
/* IBM_PROLOG_END_TAG                                                     */
#ifndef _H_CFLASH_BLOCK
#define _H_CFLASH_BLOCK

#include <sys/types.h>
#include <inttypes.h>
#include <stdint.h>
#if !defined(_AIX) && !defined(_MACOSX)
#include <linux/types.h>
#endif /* !_AIX && !_NACOSX */

/*
 * This header file specifies the API for the CAPI flash
 * user space block layer.
 */


#ifdef __cplusplus
extern "C" {
#endif

#define NULL_CHUNK_ID  -1
#define NULL_CHUNK_CG_ID NULL_CHUNK_ID

typedef int chunk_id_t;
typedef int chunk_cg_id_t;
typedef int chunk_r0_id_t;

typedef uint64_t chunk_ext_arg_t;

/************************************************************************/
/* Chunk statistics                                                     */
/************************************************************************/

typedef struct chunk_stats_s {
    uint32_t block_size;            /* Block size of this chunk.       */
    uint32_t num_paths;             /* Number of paths of this chunk.  */
    uint64_t max_transfer_size;     /* Maximum transfer size in        */
                                    /* blocks of this chunk.           */
    uint64_t num_reads;             /* Total number of reads issued    */
                                    /* via cblk_read interface         */
    uint64_t num_writes;            /* Total number of writes issued   */
                                    /* via cblk_write interface        */
    uint64_t num_areads;            /* Total number of async reads     */
                                    /* issued via cblk_aread interface */
    uint64_t num_awrites;           /* Total number of async writes    */
                                    /* issued via cblk_awrite interface*/
    uint32_t num_act_reads;         /* Current number of reads active  */
                                    /* via cblk_read interface         */
    uint32_t num_act_writes;        /* Current number of writes active */
                                    /* via cblk_write interface        */
    uint32_t num_act_areads;        /* Current number of async reads   */
                                    /* active via cblk_aread interface */
    uint32_t num_act_awrites;       /* Current number of async writes  */
                                    /* active via cblk_awrite interface*/
    uint32_t max_num_act_writes;    /* High water mark on the maximum  */
                                    /* number of writes active at once */
    uint32_t max_num_act_reads;     /* High water mark on the maximum  */
                                    /* number of reads active at once  */
    uint32_t max_num_act_awrites;   /* High water mark on the maximum  */
                                    /* number of asyync writes active  */
                                    /* at once.                        */
    uint32_t max_num_act_areads;    /* High water mark on the maximum  */
                                    /* number of asyync reads active   */
                                    /* at once.                        */
    uint64_t num_blocks_read;       /* Total number of blocks read     */
    uint64_t num_blocks_written;    /* Total number of blocks written  */
    uint64_t num_errors;            /* Total number of all error       */
                                    /* responses seen                  */
    uint64_t num_aresult_no_cmplt;  /* Number of times cblk_aresult    */
                                    /* returned with no command        */
                                    /* completion                      */
    uint64_t num_retries;           /* Total number of all commmand    */
                                    /* retries.                        */
    uint64_t num_timeouts;          /* Total number of all commmand    */
                                    /* time-outs.                      */
    uint64_t num_fail_timeouts;     /* Total number of all commmand    */
                                    /* time-outs that led to a command */
                                    /* failure.                        */
    uint64_t num_no_cmds_free;      /* Total number of times we didm't */
                                    /* have free command available     */
    uint64_t num_no_cmd_room ;      /* Total number of times we didm't */
                                    /* have room to issue a command to */
                                    /* the AFU.                        */
    uint64_t num_no_cmds_free_fail; /* Total number of times we didn't */
                                    /* have free command available and */
                                    /* failed a request because of this*/
    uint64_t num_fc_errors;         /* Total number of all FC          */
                                    /* error responses seen            */
    uint64_t num_port0_linkdowns;   /* Total number of all link downs  */
                                    /* seen on port 0.                 */
    uint64_t num_port1_linkdowns;   /* Total number of all link downs  */
                                    /* seen on port 1.                 */
    uint64_t num_port0_no_logins;   /* Total number of all no logins   */
                                    /* seen on port 0.                 */
    uint64_t num_port1_no_logins;   /* Total number of all no logins   */
                                    /* seen on port 1.                 */
    uint64_t num_port0_fc_errors;   /* Total number of all general FC  */
                                    /* errors seen on port 0.          */
    uint64_t num_port1_fc_errors;   /* Total number of all general FC  */
                                    /* errors seen on port 1.          */
    uint64_t num_cc_errors;         /* Total number of all check       */
                                    /* condition responses seen        */
    uint64_t num_afu_errors;        /* Total number of all AFU error   */
                                    /* responses seen                  */
    uint64_t num_capi_false_reads;  /* Total number of all times       */
                                    /* poll indicated a read was ready */
                                    /* but there was nothing to read.  */
    uint64_t num_capi_read_fails;   /* Total number of all             */
                                    /* CXL_EVENT_READ_FAIL responses   */
                                    /* seen.                           */
    uint64_t num_capi_adap_resets;  /* Total number of all adapter     */
                                    /* reset errors.                   */
    uint64_t num_capi_adap_chck_err;/* Total number of all check       */
                                    /* adapter errors.                 */
    uint64_t num_capi_reserved_errs;/* Total number of all             */
                                    /* CXL_EVENT_RESERVED responses    */
                                    /* seen.                           */
    uint64_t num_capi_data_st_errs; /* Total number of all             */
                                    /* CAPI data storage event         */
                                    /* responses seen.                 */
    uint64_t num_capi_afu_errors;   /* Total number of all             */
                                    /* CAPI error responses seen       */
    uint64_t num_capi_afu_intrpts;  /* Total number of all             */
                                    /* CAPI AFU interrupts for command */
                                    /* responses seen.                 */
    uint64_t num_capi_unexp_afu_intrpts; /* Total number of all of     */
                                    /* unexpected AFU interrupts       */
    uint64_t num_success_threads;   /* Total number of pthread_creates */
                                    /* that succeed.                   */
    uint64_t num_failed_threads;    /* Total number of pthread_creates */
                                    /* that failed.                    */
    uint64_t num_canc_threads;      /* Number of threads we had to     */
                                    /* cancel, which succeeded.        */
    uint64_t num_fail_canc_threads; /* Number of threads we had to     */
                                    /* cancel, but the cancel failed   */
    uint64_t num_fail_detach_threads;/* Number of threads we detached  */
                                    /* but the detach failed           */
    uint64_t num_active_threads;    /* Current number of threads       */
                                    /* running.                        */
    uint64_t max_num_act_threads;   /* Maximum number of threads       */
                                    /* running simultaneously.         */
    uint64_t num_cache_hits;        /* Total number of cache hits      */
                                    /* seen on all reads               */
    uint64_t num_reset_contexts;    /* Total number of reset contexts  */
                                    /* done                            */
    uint64_t num_reset_contxt_fails;/* Total number of reset context   */
                                    /* failures                        */
    uint32_t primary_path_id;       /* Primary path id                 */
    uint64_t num_path_fail_overs;   /* Total number of times a request */
                                    /* has failed over to another path.*/
} chunk_stats_t;


/************************************************************************/
/* General flags                                                        */
/************************************************************************/

#define CBLK_SCRUB_DATA_FLG  1      /* Scrub virtual lun data blocks,   */
                                    /* when they are no longer in use.  */


#ifdef _AIX
typedef offset_t cflash_offset_t;
#else
typedef off_t cflash_offset_t;
#endif 
/************************************************************************/
/* Open flags                                                            */
/************************************************************************/

#define CBLK_OPN_SCRUB_DATA  CBLK_SCRUB_DATA_FLG

#define CBLK_OPN_VIRT_LUN         2   /* Use a virtual lun              */
    
#define CBLK_OPN_NO_INTRP_THREADS 4   /* Do not use back threads for    */
                                      /* handling interrupts processing */

#define CBLK_OPN_SHARE_CTXT       8   /* Share context in same process  */

#ifdef _AIX
#define CBLK_OPN_RESERVE        0x10  /* Tell master context to use     */
                                      /* reservations on this lun.      */
#define CBLK_OPN_FORCED_RESERVE 0x20  /* Tell master context to break   */
                                      /* reservations for this lun and  */
                                      /* establish a new reservation    */
#endif /* _AIX */
#define CBLK_OPN_MPIO_FO        0x40  /* Use multi-path I/O fail over   */
                                      /* this lun.                      */

#define CBLK_OPN_GROUP         0x100  /* Use cblk_group_open            */

/************************************************************************/
/* Common flag for non-open APIs                                        */
/************************************************************************/
#define CBLK_GROUP_ID           0x100 /* id passed is a chunk group id  */
#define CBLK_GROUP_RAID0        0x200  /* Use cblk_group_open           */


/************************************************************************/
/* cblk_aread and cblk_awrite flags                                     */
/************************************************************************/


#define CBLK_ARW_WAIT_CMD_FLAGS 1 /* Wait for commmand for cblk_aread   */
                                  /* or cblk_awrite.                    */
#define CBLK_ARW_USER_TAG_FLAG 2 /* The caller is specifying a user     */
                                  /* defined tag for this request.      */
#define CBLK_ARW_USER_STATUS_FLAG 4 /* The caller has set the status    */
                                  /* parameter to the address which it  */
                                  /* expects command completion status  */
                                  /* to be posted.                      */
typedef enum {

    CBLK_ARW_STATUS_PENDING = 0, /* Command has not completed           */
    CBLK_ARW_STATUS_SUCCESS = 1, /* Command completed successfully      */
    CBLK_ARW_STATUS_INVALID = 2, /* Caller's request was invalid        */
    CBLK_ARW_STATUS_FAIL    = 3, /* Command completed with error        */
} cblk_status_type_t;

    
typedef struct cblk_arw_status_s {
    cblk_status_type_t status;   /* Status of command                   */
                                 /* See errno field for additional      */
                                 /* details on failure.                 */
    size_t blocks_transferred;   /* Number of blocks transferred for    */
                                 /* this request.                       */
    int    fail_errno;           /* Errno when status indicates         */
                                 /* CBLK_ARW_STAT_FAIL.                 */
} cblk_arw_status_t;

/************************************************************************/
/* cblk_aresult flags                                                   */
/************************************************************************/

#define CBLK_ARESULT_NEXT_TAG 1   /* cblk_aresult will return the tag   */
                                  /* of the next async I/O to complete  */
                                  /* for this chunk. If this flag is not*/
                                  /* set then caller should have passed */
                                  /* the address of the tag for which   */
                                  /* they are waiting to complete.      */

#define CBLK_ARESULT_BLOCKING 2   /* If set then cblk_aresult will block*/
                                  /* until the specified tag completes. */
                                  /* Otherwise cblk_aresult will return */
                                  /* immediately with a value of 1 if   */
                                  /* the specified tag has not yet      */
                                  /* completed                          */

#define CBLK_ARESULT_USER_TAG 4   /* If set then the tag parameter      */
                                  /* specifies a user defined tag that  */
                                  /* was provided  when the cblk_aread  */
                                  /* or cblk_awrite call was issued.    */

#define CBLK_ARESULT_NO_HARVEST 8 /* If set then cblk_aresult will      */
                                  /* not pull newly completed cmds from */
                                  /* the AFU, but will instead check    */
                                  /* the completed queue.               */

/************************************************************************/
/* cblk_listio flags and structure                                      */
/************************************************************************/

#define CBLK_LISTIO_WAIT_ISSUE_CMD 1 /* Wait for commmand for all commands   */
                                  /* in issue_io_list.                    */

typedef struct cblk_io {
    uint8_t version;              /* Version of structure               */
    int   flags;                  /* Flags for the request              */
#define CBLK_IO_USER_TAG   0x0001 /* Caller is specifying a user defined*/
                                  /* tag.                               */
#define CBLK_IO_USER_STATUS 0x0002/* Caller is specifying a status      */
                                  /* location to be updated.            */
#define CBLK_IO_PRIORITY_REQ 0x0004/* This is a (high) priority request */
                                  /* that should be expedited vs non-   */
                                  /* priority requests.                 */
    uint8_t request_type;         /* Type of request                    */
#define CBLK_IO_TYPE_READ  0x01   /* Read data request                  */
#define CBLK_IO_TYPE_WRITE 0x02   /* Write data request                 */
    void *buf;                    /* Data buffer for request.           */
    cflash_offset_t lba;          /* Starting logical block address for */
                                  /* request.                           */
    size_t nblocks;               /* Size of request based on number of */
                                  /* blocks.                            */
    int tag;                      /* Tag for request                    */
    cblk_arw_status_t stat;       /* Status of request.                 */
} cblk_io_t;


int cblk_init(void *arg,uint64_t flags);
int cblk_term(void *arg,uint64_t flags);

chunk_id_t cblk_open(const char *path, int max_num_requests, int mode, chunk_ext_arg_t ext, int flags);
int cblk_close(chunk_id_t chunk_id,int flags);

/* Determine number blocks on CAPI flash device (lun) */
int cblk_get_lun_size(chunk_id_t chunk_id, size_t *nblocks, int flags);

/* Determine number blocks on CAPI flash chunk */
int cblk_get_size(chunk_id_t chunk_id, size_t *nblocks, int flags);

/* Allocate/deallocate blocks on CAPI flash chunk */
int cblk_set_size(chunk_id_t chunk_id, size_t nblocks, int flags);

/* Get statistics for a CAPI flash chunk */
int cblk_get_stats(chunk_id_t chunk_id, chunk_stats_t *stats, int flags);

/* Blocking CAPI flash read */
int cblk_read(chunk_id_t chunk_id,void *buf,cflash_offset_t lba, size_t nblocks, int flags);

/* Blocking CAPI flash write */
int cblk_write(chunk_id_t chunk_id,void *buf,cflash_offset_t lba, size_t nblocks, int flags);

/* Asynchronous CAPI flash read */
int cblk_aread(chunk_id_t chunk_id,void *buf,cflash_offset_t lba, size_t nblocks, int *tag, cblk_arw_status_t *status, int flags);

/* Asynchronous CAPI flash write */
int cblk_awrite(chunk_id_t chunk_id,void *buf,cflash_offset_t lba, size_t nblocks, int *tag, cblk_arw_status_t *status, int flags);

/* Wait for completion and results of asynchronous read/write */
int cblk_aresult(chunk_id_t chunk_id,int *tag, uint64_t *status, int flags);

/* CAPI flash I/O request interface */
int cblk_listio(chunk_id_t chunk_id,
                cblk_io_t *issue_io_list[],int issue_items,
                cblk_io_t *pending_io_list[], int pending_items,
                cblk_io_t *wait_io_list[],int wait_items,
                cblk_io_t *completion_io_list[],int *completion_items,
                uint64_t timeout,int flags);

/* Clone a chunk (such as a parent and chilld process' chunk */
int cblk_clone_after_fork(chunk_id_t chunk_id, int mode, int flags);


typedef struct cflsh_cg_tag_s
{
    chunk_id_t id;
    int        tag;
} cflsh_cg_tag_t;

chunk_cg_id_t cblk_cg_open(const char           *path,
                                 int             max_num_requests,
                                 int             mode,
                                 int             num_chunks,
                                 chunk_ext_arg_t ext,
                                 int             flags);
int cblk_cg_close(chunk_cg_id_t cgid,
                  int           flags);
int cblk_cg_get_stats(chunk_cg_id_t  cgid,
                      chunk_stats_t *stats,
                      int            flags);
int cblk_cg_get_lun_size(chunk_cg_id_t cgid,
                         size_t       *nblocks,
                         int           flags);
int cblk_cg_get_size(chunk_cg_id_t cgid,
                     size_t       *nblocks,
                     int           flags);
int cblk_cg_set_size(chunk_cg_id_t cgid,
                     size_t        nblocks,
                     int           flags);
int cblk_cg_read(chunk_cg_id_t   cgid,
                 void           *pbuf,
                 cflash_offset_t lba,
                 size_t          nblocks,
                 int             flags);
int cblk_cg_write(chunk_cg_id_t   cgid,
                  void           *pbuf,
                  cflash_offset_t lba,
                  size_t          nblocks,
                  int             flags);
int cblk_cg_aread(chunk_cg_id_t      cgid,
                  void              *pbuf,
                  cflash_offset_t    lba,
                  size_t             nblocks,
                  cflsh_cg_tag_t    *ptag,
                  cblk_arw_status_t *p_arwstatus,
                  int               flags);
int cblk_cg_awrite(chunk_cg_id_t     cgid,
                   void             *pbuf,
                   cflash_offset_t   lba,
                   size_t            nblocks,
                   cflsh_cg_tag_t    *ptag,
                   cblk_arw_status_t *p_arwstatus,
                   int                flags);
int cblk_cg_aresult(chunk_cg_id_t   cgid,
                    cflsh_cg_tag_t *ptag,
                    uint64_t       *p_arwstatus,
                    int             flags);
int cblk_cg_clone_after_fork(chunk_cg_id_t cgid,
                             int           mode,
                             int           flags);
int cblk_cg_get_num_chunks(chunk_cg_id_t cgid,
                           int           flags);

#ifdef __cplusplus
}
#endif

#endif /* _H_CFLASH_BLOCK */
