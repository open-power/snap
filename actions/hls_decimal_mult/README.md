# HLS_DECIMAL_MULT EXAMPLE

* Provides a simple base allowing to discover how to exchange ***single precision floating points (float) or double precision floating points (double)*** between the application on server and the action in the FPGA.
* C code is multiplying 3 decimal numbers read from host memory and writing result in host memory
  * code can be executed on the CPU (application + software action)
  * code can be simulated (application + software and hardware action)
  * code can then run in hardware when the FPGA is programmed (application + software and hardware action)
* The example code shows the following:
  * **application** writes floats or doubles to system host memory and read results to display and compare results processed and expected
  * **software or hardware action** reads floats or doubles from system memory, multiply decimals 3 by 3 and write the results back in memory
  The key point here is for the FPGA to ***understand*** the data read from the host memory and formatted by the server Operating System. The code shows the conversion to be done so that the number read can be used as a float or double in HLS code.
As an example it is important to understand that 4.5 is represented in host memory differently depending on the type used:
    * as a double as 0x4012_0000_0000_0000
    * as a float  as 0x4090_0000. 

 __Usage:__
 * `./snap_decimal_mult -n12 -v` Application calls the hardware action and multiply 12 values 3 by 3. Dumps of data displayed
 * `SNAP_CONFIG=CPU ./snap_decimal_mult` Application calls the software action
 * `SNAP_TRACE=0xF  ./snap_decimal_mult` to display all MMIO exchanged between application and action
 * `././tests/test_0x1014100B.sh` to execute automatic testing
 
 __Parameters:__
*  arguments in command line:
   * `-n [value]` defines the number of decimals to process (lower or equal than MAX_NB_OF_DECIMAL_READ)
   * `-w` writes to files the result processed by the action (dec_mult_action.bin) and the expected results (dec_mult_ref.bin). Used for automatic testing.
   * `-v` verbose mode which will display a dump of the inputs and results from host memory 
* parameters in include/common_decimal.h:
   * `#define MAX_NB_OF_DECIMAL_READ  16` defines the maximum number of decimals to read
   * `typedef float  mat_elmt_t;` definse the type used: float or double

__Files used__:
|
�~T~B   Makefile                      General Makefile used to automatically prepare the final files
�~T~B   README.md                     Documentation file for this example
�~T~B
�~T~\�~T~@�~T~@�~T~@sw                            Software directory containing application called from POWER host and software action
�~T~B       snap_decimal_mult.c       ***application*** which calls the software or the hardware action depending on the flag used (SNAP_CONFIG=FPGA or SNAP_CONFIG=CPU)
�~T~B       action_decimal_mult.c     ***software action*** which will be executed on the CPU only
�~T~B       Makefile                  Makefile to compile the software files
�~T~B
�~T~T�~T~@�~T~@�~T~@include                       Common directory to sw and hw
        common_decimal.h          ***Common header*** file used by the application and the software/hardware action. It contains the main structure and the defines parameters
�~T~B
�~T~\�~T~@�~T~@�~T~@hw                            Hardware directory containing the hardware action
�~T~B       action_decimal_mult.cpp   ***hardware action*** which will be executed on FPGA and is called by the application 
�~T~B       action_decimal_mult.H     header file containing hardware action parameters
�~T~B       Makefile                  Makefile to compile the hardware action using Vivado HLS synthesizer
�~T~B
�~T~T�~T~@�~T~@�~T~@tests                         Test directory containing all automated tests
        test_0x1014100B.sh        Basic test shell running snap_decimal_mult application
 
