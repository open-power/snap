# CAPI Donut Framework Software

Set of tools and library to drive the CAPI streaming framework hardware. The tools are intended to support bringup and debugging of the solution.

Libdonut is intended to provide helper functions for own applications.

Libdonut is planed to provide 3 different modes of operation:

1. Job-queue mode: In this mode jobs can be send to the hardware which are put onto a queue. After completion the caller is notified. The framework offers the possiblity to generate a queue per AFU context, respectively per process using it. Within a process the queue can be exploited by multiple threads at the same time. The hardware job-manager is responsible to connect the job-request to a free FPGA-action. This is done dynamically in round-robin fashion. There is a request and a completion queue. The jobs can finish asyncronously depending on how long they take.
2. *FIXME Not fully in plan yet* Action-assignment mode: A process requests the connection between an AFU-context to an FPGA-action. This connection is managed by the job-manager and supports as many assignments as FPGA-actions are available. Once connected the process can use FPGA-action MMIOs to do further work e.g. implement door-bells, or data-send/receive queues. Interrupts can be used for error or completion notification.
3. Direct access cards AFU-master/slave contexts. This mode is for debugging and global configuration tasks.
