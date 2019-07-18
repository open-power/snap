# HLS_VECTOR_GENERATOR EXAMPLE

* Provides an example to show how generate a vector in FPGA and to write it in HOST memory using optimized memcpy. 
* To maximixe memcpy performance, data is written in 4KB chunks (MAX_BURST size) to maximize bandwidth.

Files hierarchy: 
```
hls_vector_generator
├── Makefile                       General Makefile used to automatically prepare the final files
├── README.md                      Documentation file for this example
|
├── sw                             Software directory containing application called from POWER host and software action
|   ├── snap_vector_generator.c    APPLICATION which calls the hardware(software) action
|   ├── action_create_vector.c     SW version of the action
|   └── Makefile		               Makefile to compile the software files
|
├── include                        Common directory to sw and hw
|   └── action_create_vector.h     COMMON HEADER file used by the application and the software/hardware action.
|
└── hw                             Hardware directory containing the hardware action
    ├── action_create_vector.cpp   HARDWARE ACTION which will be executed on FPGA and is called by the application 
    ├── action_create_vector.H     header file containing hardware action parameters
    └── Makefile                   Makefile to compile the hardware action using Vivado HLS synthesizer

```
