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

## Directory Structure

    .
    |-- examples       Contains host-code examples either for HDL or for HLS written SNAP actions
    |                  action_*.h should define the SNAP job executed by the SNAP action. These files
    |                  should only include <snap_types.h> and are shared with the HLS action
    |                  hardware implementation.
    |                  action_*.c is a software written emulation of the SNAP action. This should
    |                  be used to try out the job interface between host-code and SNAP action.
    |-- include        libsnap.h and auxiliary C-headers
    |                  snap_types.h contains shared data types and definitions between the host-code
    |                  and HLS written SNAP actions
    |-- lib            libsnap.so/.a
    |-- scripts        Testcases
    `-- tools          Generic tools for SNAP users. E.g.:
                       snap_maint setup tool which needs to be called one 
                       time before using the card.
                       It sets up the SNAP action assignment hardware.
                       snap_peek/poke debug tools to read/write SNAP MMIO registers.
