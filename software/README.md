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
_All definitions of APIs are in snap/software/lib/snap.c and snap/software/include/lib_snap.h_

| Helper functions        | Description                                  | Declaration location
|:------------------------|:---------------------------------------------|:----------------------------------
| **snap_addr_set**       | Helps to setup snap_addr structure           | include/snap_types.h
| **snap_job_set**        | Helps to setup the job request               | include/libsnap.h

| Useful API name                                | Description
|:-----------------------------------------------|:---------------------------------------------
| snap_mmio_write32                              | MMIO 32b write access functions for card
| snap_mmio_read32                               | MMIO 32b read access functions for card
| snap_card_alloc_dev                            | Opens the device given by the path
| snap_card_free                                 | Free the specified device
| snap_attach_action                             | Attach the specified action
| snap_detach_action                             | Detach the specified action
| snap_action_start                              | Starts the action
| snap_action_is_idle                            | Test if the action is idle 
| snap_action_completed                          | Wait for completion of the action (timeout or IRQ) - **blocks until job is done**
| snap_queue_alloc                               | Allocates a queue
| snap_queue_free                                | Release the queue
| snap_action_sync_execute_job_set_regs          | Writes all MMIO actions registers to card
| snap_sync_execute_job                          | Calls the following APIs: _snap_attach_action_ + _snap_action_sync_execute_job_ + _snap_detach_action_
| snap_action_sync_execute_job                   | Calls the following APIs: _snap_action_sync_execute_job_set_regs_ + _snap_action_start_ + _snap_action_sync_execute_job_check_completion_
| snap_queue_sync_execute_job                    | Calls the following API:  _snap_sync_execute_job_
| snap_action_sync_execute_job_check_completion  | Calls the following API: _snap_action_completed_ + Read all MMIO actions registers

### SNAP modes and associated API calls sequence

Most examples provided in snap/actions are built using the following **Serial mode**. 
**Parallel mode** has been used in _**hls_latency_eval**_ to show how to deal with parallel processing.

| SNAP fixed action assignment (Serial mode)         | Description
|:---------------------------------------------------|:-----------------------------------------------------------
| snap_card_alloc_dev                                | Opens the device given by the path
| snap_attach_action                                 | Attach process to the specified action 
| snap_action_sync_execute_job                       | **Execute job and _WAIT_ for completion:** Write all MMIO registers to card + Start action + wait for completion (timeout or IRQ) + Read all MMIO registers
|                                                    | _**Application is blocked until completion of the action**_
| snap_detach_action                                 | Detach the specified action 
| snap_card_free                                     | Free the device
|                                                    |
| **SNAP fixed action assignment (Parallel mode)**   | **Description**
| snap_card_alloc_dev                                | Opens the device given by the path
| snap_attach_action                                 | Attach process to the specified action 
| snap_action_sync_execute_job_set_regs              | Writes all MMIO actions registers to card
| snap_action_start                                  | **Execute job:** Starts the FPGA action
|                                                    | _**Application is free from doing other tasks in parallel with FPGA card. MMIO access are possible during action execution**_
| snap_action_sync_execute_job_check_completion      | Wait for completion of the action (timeout or IRQ) + Read all MMIO registers
| snap_detach_action                                 | Detach the specified action 
| snap_card_free                                     | Free the device

Other modes

| SNAP collaborative action         | Description
|:----------------------------------|:-----------------------------------------------------------
| snap_card_alloc_dev               | Opens the device given by the path
| snap_sync_execute_job             | **Attach action + execute job** _(Write all MMIO registers to card + Start action + wait for completion (timeout or IRQ)) + Read all MMIO registers_ **+ release action:**
| snap_card_free                    | Free the device
|                                   |
| **SNAP job-queue mode (future)**  | **Description**
| snap_card_alloc_dev               | Opens the device given by the path
| snap_queue_alloc                  | Allocate a queue
| snap_queue_sync_execute_job       | **Execute:** Write all MMIO registers to card + Start action + wait for completion (timeout or IRQ)
|                                   | _**The Job-Manager owns the action. The action is shared between multiple queues of the same action-type**_
| snap_queue_free                   | Release the queue
| snap_card_free                    | Release the card

