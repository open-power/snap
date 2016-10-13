# CAPI Donut Framework Software

Set of tools and library to drive the CAPI streaming framework hardware. The tools are intended to support bringup and debugging of the solution.

Libdonut is intended to provide helper functions for own applications.

Libdonut is planed to provide 3 different modes of operation:

1. Job-queue mode: In this mode jobs can be send to the hardware which are put onto a queue. After completion the caller is notified. The framework offers the possiblity to generate a queue per AFU context, respectively per process using it. Within a process the queue can be exploited by multiple threads at the same time. The hardware job-manager is responsible to connect the job-request to a free FPGA-action. This is done dynamically in round-robin fashion. There is a request and a completion queue. The jobs can finish asyncronously depending on how long they take.
2. *FIXME Not fully in plan yet* Action-assignment mode: A process requests the connection between an AFU-context to an FPGA-action. This connection is managed by the job-manager and supports as many assignments as FPGA-actions are available. Once connected the process can use FPGA-action MMIOs to do further work e.g. implement door-bells, or data-send/receive queues. Interrupts can be used for error or completion notification.
3. Direct access cards AFU-master/slave contexts. This mode is for debugging and global configuration tasks.

Here a simple example for the action-assignment mode.

    #include <libdonut.h>
    
    struct search_job {
      struct dnut_addr input;
      struct dnut_addr output;
      struct dnut_addr pattern;
      uint64_t nb_of_occurrences;
      uint64_t next_input_addr;
    };
   
    static void dnut_prepare_search(struct dnut_job *cjob, 
             struct search_job *sjob,
             const uint8_t *dbuff, ssize_t dsize,
             uint64_t *offs, unsigned int items,
             const uint8_t *pbuff, unsigned int psize)
    {
      dnut_addr_set(&sjob->input, dbuff, dsize,
             DNUT_TARGET_TYPE_HOST_DRAM,
             DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC);
      dnut_addr_set(&sjob->output, offs, items * sizeof(*offs),
             DNUT_TARGET_TYPE_HOST_DRAM,
             DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_DST);
      dnut_addr_set(&sjob->pattern, pbuff, psize,
             DNUT_TARGET_TYPE_HOST_DRAM,
             DNUT_TARGET_FLAGS_ADDR | DNUT_TARGET_FLAGS_SRC |
             DNUT_TARGET_FLAGS_END);
   
      sjob->nb_of_occurrences = 0;
      sjob->next_input_addr = 0;
      dnut_job_set(cjob, SEARCH_ACTION_TYPE, sjob, sizeof(*sjob));
    }
   
    int main(int argc, char *argv[])
    {
      struct dnut_job cjob;
      struct search_job sjob;
      const char *pattern_str = "Donut";
      dsize = file_size(fname);
      dbuff = memalign(page_size, dsize);
      psize = strlen(pattern_str);
      pbuff = memalign(page_size, psize);
      memcpy(pbuff, pattern_str, psize);
   
      offs = memalign(page_size, items * sizeof(*offs));
      file_read(fname, dbuff, dsize);
    
      dnut_prepare_search(&cjob, &sjob, dbuff, dsize,
             offs, items, pbuff, psize);
   
      snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
      kernel = dnut_kernel_attach_dev(device,  DNUT_VENDOR_ID_ANY,
             DNUT_DEVICE_ID_ANY,
             SEARCH_ACTION_TYPE);
      run = 0;
      do {
        dnut_kernel_sync_execute_job(kernel, &cjob, timeout);
        if (cjob.retc != 0x0)
          exit(EXIT_FAILURE);
     
        dnut_print_search_results(&cjob, run);
   
        /* trigger repeat if search was not complete */
        if (sjob.next_input_addr != 0x0) {
          sjob.input.size -= (sjob.next_input_addr -
                 sjob.input.addr);
          sjob.input.addr = sjob.next_input_addr;
        }
        run++;
      } while (sjob.next_input_addr != 0x0);
   
      dnut_kernel_free(kernel);
      exit(EXIT_SUCCESS);
    }
