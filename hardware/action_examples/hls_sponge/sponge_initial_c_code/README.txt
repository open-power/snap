Benchmark Sponge
==============

Description
===========

Sponge sequentially computes sha-3 based on the keccak algorithm.

Specificities
============

The keccak code provided is in a readable but not optimized form:
http://keccak.noekeon.org/readable_code.html
This implementation works in 64-bit little-endian.

Conditions of validity of the benchmark
============================================

The sponge benchmark runs on CPU, or with the possible help of CUDA-compatible GPU or coprocessor compatible with the x86 instruction set. The porting of the supplied code to these calculation components is thus authorized.

The maximum duration of this benchmark is 30 minutes, whatever the solution used and whatever the level of performance.
The validity of the overall checksum will be verified by the administration at the time of the aptitude check.

Optimizations due to compilation options are allowed.

The optimizations allowed on this benchmark are:
- vectorization / prefetching / cache blocking / loop unrolling / inlining,
- use of intrinsic functions and / or volatile asm,
- align the data in memory,
- use other more optimized keccak implementations, working on authorized computing components.


Implementation
==============

 Description of arguments
 -------------------------
 ./sponge <pe> <nb_pe>
 where:
 <pe> is the current processing element, between 0 and <nb_pe> -1.
 <nb_pe> is the total number of processes started.

 Example
 -------
 "./sponge 0 1024" executes the processing element of rank 0 among 1024 processing elements.

 Execution check
 ------------------------
 The global checksum of the benchmark is obtained by applying an XOR on the checksum of each processing element.
 In test mode, the expected global checksum is 948dd5b0109342d4:

 Make test
 ./sponge_test 0 1
 948dd5b0109342d4