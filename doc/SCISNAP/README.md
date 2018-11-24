
SCISNAP version
* SNAP provide means of data-conversion for both single- and double-precision floating-point numbers based on application note[1]. However, this proposed solution is known to be costly (e.g., performance, area) [2, 3]. To this end, this SCISNAP branch makes it possible to leverage the Xilinx data-type ap_fixed for both the software- and hardware-actions development. Due to compiler requirements and C coding-styles the master branch does not provide this capability. 
* For example, see actions/hls_double_mult app which defines a 16-bit floating-point version based on ap_fixed<16,10>


Refrences:
[1] XAPP599 (v1.0) Web-Link: https://www.xilinx.com/support/documentation/application_notes/xapp599-floating-point-vivado-hls.pdf. Downloaded on 11/23/2018
[2] WP491 (v1.0) Web-Link: https://www.xilinx.com/support/documentation/white_papers/wp491-floating-to-fixed-point.pdf. Downloaded on 11/23/2018
[3] ) Yohann Uguen, Florent De Dinechin, Steven Derrien. A high-level synthesis approach optimizing ac-
cumulations in floating-point programs using custom formats and operators, 2017. Web-Link: perso.eleves.ens-rennes.fr/~yugue555/ArithHLS.pdf. Downloaded on 11/23/2018

