
SCISNAP version

* This version is backward-compatible with SNAP (master branch as of 11/23/2018)
* SNAP provides means of data-conversion for both single- and double-precision floating-point numbers based on application note[1]. However, this proposed solution is known to be costly (e.g., performance, area) [2, 3]. To this end, this SCISNAP branch makes it possible to leverage the Xilinx data-type ap_fixed for both the software- and hardware-actions development. Due to compiler requirements and C coding-styles the master branch does not provide this capability. 
* Provides specific app example. See actions/hls_double_mult app which defines a 16-bit floating-point version based on ap_fixed<16,10>

Requirements:

a. GNU G++ 6.2 or later
b. Environment variables:
   . SCISNAP=1                      - Enables this version. Leaving it unset will make it fallback to SNAP 
   . COMPILER_BIN_PATH=/opt/gcc/bin - Set it to the proper path in your system. This variable has only effect when SCISNAP=1. 
   . LD_LIBRARY_PATH=/opt/gcc/lib   - Set it to the proper path in your system. This variable has only effect when SCISNAP=1


Limitations:

- None other than hls_double_mult is currently supported on SCISNAP
- Porting existing apps to work with SCISNAP requires manual changes to the software application:
	. The C99 based initialization of "struct snap_sim_action action" is not forward compatible with GNU G++. See actions/hls_double_mult/sw for an exact example on how to port it.
	. Add #include <ap_fixed.h> and define the ap_* variables you need in your include/action_*.h file


Refrences:
[1] XAPP599 (v1.0) Web-Link: https://www.xilinx.com/support/documentation/application_notes/xapp599-floating-point-vivado-hls.pdf. Downloaded on 11/23/2018
[2] WP491 (v1.0) Web-Link: https://www.xilinx.com/support/documentation/white_papers/wp491-floating-to-fixed-point.pdf. Downloaded on 11/23/2018
[3] ) Yohann Uguen, Florent De Dinechin, Steven Derrien. A high-level synthesis approach optimizing ac-
cumulations in floating-point programs using custom formats and operators, 2017. Web-Link: perso.eleves.ens-rennes.fr/~yugue555/ArithHLS.pdf. Downloaded on 11/23/2018

