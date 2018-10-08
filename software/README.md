# CAPI Snap Framework Software

Set of tools and library to drive the CAPI streaming framework hardware. The tools are intended to support bringup and debugging of the solution.

Libsnap is intended to provide helper functions for own applications.

Libsnap is planed to provide 3 different modes of operation:

1. Job-queue mode: In this mode jobs can be send to the hardware which are put onto a queue. After completion the caller is notified. The framework offers the possiblity to generate a queue per AFU context, respectively per process using it. Within a process the queue can be exploited by multiple threads at the same time. The hardware job-manager is responsible to connect the job-request to a free FPGA-action. This is done dynamically in round-robin fashion. There is a request and a completion queue. The jobs can finish asyncronously depending on how long they take.

2. *FIXME Not fully in plan yet* Action-assignment mode: A process requests the connection between an AFU-context to an FPGA-action. This connection is managed by the job-manager and supports as many assignments as FPGA-actions are available. Once connected the process can use FPGA-action MMIOs to do further work e.g. implement door-bells, or data-send/receive queues. Interrupts can be used for error or completion notification.

3. Direct access cards AFU-master/slave contexts. This mode is for debugging and global configuration tasks.

## Environment Variables

To debug libsnap functionality or associated actions, there are currently some environment variables available:
- ***SNAP_CONFIG***: 0x1 Enable software action emulation for those actions which we use for trying out. Instead of 0x0 or 0x1 one can also use FPGA or CPU.
- ***SNAP_TRACE***: 0x1 General libsnap trace, 0x2 Enable register read/write trace, 0x4 Enable simulation specific trace, 0x8 Enable action traces. Applications might use more bits above those defined here.

## Directory Structure

    .
    |-- include        libsnap.h and auxiliary C-headers
    |                  snap_types.h contains shared data types and definitions between the host-code
    |                  and SNAP actions
    |-- lib            libsnap.so/.a
    |-- scripts        Testcases
    `-- tools          Generic tools for SNAP users. E.g.:
                       snap_maint setup tool which needs to be called before using the card.
                                             It sets up the SNAP action assignment hardware.
                       snap_peek/poke debug tools to read/write SNAP MMIO registers.

### API description

| Simple API name         | Description                                  | Declaration location (in snap/software)
|:------------------------|:---------------------------------------------|:----------------------------------
| **snap_addr_set**       | helper function to setup snap_addr structire | include/snap_types.h
| **snap_job_set**        | helper function to setup the job request     | include/libsnap.h
|:------------------------|:---------------------------------------------|:----------------------------------
| **snap_mmio_write32**   | MMIO 32b write access functions for card     | lib/snap.c 
| **snap_mmio_read32**    MMIO 32b read access functions for card      | lib/snap.c 
| snap_mmio_write64       | MMIO 64b write access functions for card     | lib/snap.c 
| snap_mmio_read64        | MMIO 64b read access functions for card      | lib/snap.c 
| snap_action_write32     | MMIO 32b write access functions for actions  | lib/snap.c 
| snap_action_read32      | MMIO 32b read access functions for actions   | lib/snap.c 
|:------------------------|:---------------------------------------------|:----------------------------------
| **snap_card_alloc_dev** | opens the device given by the path           | lib/snap.c
| **snap_card_free**      | free the device given by the path            | lib/snap.c
| **snap_attach_action**  | attach the action given by the path          | lib/snap.c
| **snap_detach_action**  | detach the action given by the path          | lib/snap.c
|:------------------------|:---------------------------------------------|:----------------------------------
| snap_action_start       | starts the action                            | lib/snap.c
| snap_action_stop        | stops the action                             | lib/snap.c
| snap_action_is_idle     | test if the action is idle                   | lib/snap.c
| snap_action_completed   | test if the action is completed - **blocks until job is done** | lib/snap.c
|:------------------------|:---------------------------------------------|:----------------------------------
| snap_queue_alloc        | allocates a queue                            | lib/snap.c
| snap_queue_free         | deallocate a queue                           | lib/snap.c

| 3 ways calling a job in Serial mode (lib/snap.c)    | Description                                 
|:----------------------------------------------------|:-----------------------------------------------------------
| snap_sync_execute_job                               | snap_attach_action + snap_action_sync_execute_job + snap_detach_action
| **snap_action_sync_execute_job**                    | snap_action_sync_execute_job_set_regs + snap_action_start + snap_action_sync_execute_job_check_completion
| snap_queue_sync_execute_job                         | snap_sync_execute_job

| 3 steps to call a job in Parallel mode (lib/snap.c) | Description                                 
|:----------------------------------------------------|:---------------------------------------------
| snap_action_sync_execute_job_set_regs               | Write all MMIO actions registers
| snap_action_start                                   | Start the FPGA action
| snap_action_sync_execute_job_check_completion       | snap_action_completed + Read all MMIO actions registers

