# CAPI Snap Framework Software

Set of tools and library to drive the CAPI streaming framework hardware. The tools are intended to support bringup and debugging of the solution.

Libsnap is intended to provide helper functions for own applications.

Libsnap is planed to provide 3 different modes of operation:

1. Job-queue mode: In this mode jobs can be send to the hardware which are put onto a queue. After completion the caller is notified. The framework offers the possiblity to generate a queue per AFU context, respectively per process using it. Within a process the queue can be exploited by multiple threads at the same time. The hardware job-manager is responsible to connect the job-request to a free FPGA-action. This is done dynamically in round-robin fashion. There is a request and a completion queue. The jobs can finish asyncronously depending on how long they take.
2. *FIXME Not fully in plan yet* Action-assignment mode: A process requests the connection between an AFU-context to an FPGA-action. This connection is managed by the job-manager and supports as many assignments as FPGA-actions are available. Once connected the process can use FPGA-action MMIOs to do further work e.g. implement door-bells, or data-send/receive queues. Interrupts can be used for error or completion notification.
3. Direct access cards AFU-master/slave contexts. This mode is for debugging and global configuration tasks.

## Environment Variables

To debug libsnap functionality or associated actions, there are currently some environment variables available:
- ***SNAP_CONFIG***: 0x1 Enable software action emulation for those actions which we use for trying out.
- ***SNAP_TRACE***: 0x1 General libsnap trace, 0x2 Enable register read/write trace, 0x4 Enable simulation specific trace, 0x8 Enable action traces.

Here a simple example for the action-assignment mode.

    #include <libsnap.h>

    struct search_job {
      struct snap_addr input;
      struct snap_addr output;
      struct snap_addr pattern;
      uint64_t nb_of_occurrences;
      uint64_t next_input_addr;
    };

    static void snap_prepare_search(struct snap_job *cjob,
             struct search_job *sjob,
             const uint8_t *dbuff, ssize_t dsize,
             uint64_t *offs, unsigned int items,
             const uint8_t *pbuff, unsigned int psize)
    {
      snap_addr_set(&sjob->input, dbuff, dsize,
             SNAP_TARGET_TYPE_HOST_DRAM,
             SNAP_TARGET_FLAGS_ADDR | DSNAPTARGET_FLAGS_SRC);
      snap_addr_set(&sjob->output, offs, items * sizeof(*offs),
             SNAP_TARGET_TYPE_HOST_DRAM,
             SNAP_TARGET_FLAGS_ADDR | SNAP_TARGET_FLAGS_DST);
      snap_addr_set(&sjob->pattern, pbuff, psize,
             SNAP_TARGET_TYPE_HOST_DRAM,
             SNAP_TARGET_FLAGS_ADDR | SNAP_TARGET_FLAGS_SRC |
             SNAP_TARGET_FLAGS_END);

      sjob->nb_of_occurrences = 0;
      sjob->next_input_addr = 0;
      snap_job_set(cjob, SEARCH_ACTION_TYPE, sjob, sizeof(*sjob));
    }

    int main(int argc, char *argv[])
    {
      struct snap_job cjob;
      struct search_job sjob;
      const char *pattern_str = "Snap";
      dsize = file_size(fname);
      dbuff = memalign(page_size, dsize);
      psize = strlen(pattern_str);
      pbuff = memalign(page_size, psize);
      memcpy(pbuff, pattern_str, psize);

      offs = memalign(page_size, items * sizeof(*offs));
      file_read(fname, dbuff, dsize);

      snap_prepare_search(&cjob, &sjob, dbuff, dsize,
             offs, items, pbuff, psize);

      snprintf(device, sizeof(device)-1, "/dev/cxl/afu%d.0m", card_no);
      kernel = snap_kernel_attach_dev(device,  SNAP_VENDOR_ID_ANY,
             SNAP_DEVICE_ID_ANY,
             SEARCH_ACTION_TYPE);
      run = 0;
      do {
        snap_kernel_sync_execute_job(kernel, &cjob, timeout);
        if (cjob.retc != 0x0)
          exit(EXIT_FAILURE);

        snap_print_search_results(&cjob, run);

        /* trigger repeat if search was not complete */
        if (sjob.next_input_addr != 0x0) {
          sjob.input.size -= (sjob.next_input_addr -
                 sjob.input.addr);
          sjob.input.addr = sjob.next_input_addr;
        }
        run++;
      } while (sjob.next_input_addr != 0x0);

      snap_kernel_free(kernel);
      exit(EXIT_SUCCESS);
    }
