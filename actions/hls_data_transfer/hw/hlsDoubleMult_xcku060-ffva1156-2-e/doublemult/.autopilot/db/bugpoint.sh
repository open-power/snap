export PATH=/afs/bb/proj/fpga/xilinx/Vivado/2016.4/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/gcc/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/msys/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/clang/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/tps/lnx64/jre/bin:/afs/bb/proj/fpga/xilinx/SDK/2016.4/bin:/afs/bb/proj/cte/tools/cds/Incisiv/15.10.s19/tools/bin:/afs/bb/proj/fpga/xilinx//DocNav:/afs/bb/proj/fpga/xilinx//Vivado/2016.4/bin:/afs/bb/proj/fpga/xilinx//Vivado_HLS/2016.4/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/microblaze/lin/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/arm/lin/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/microblaze/linux_toolchain/lin64_be/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/microblaze/linux_toolchain/lin64_le/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/aarch32/lin/gcc-arm-none-eabi/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/aarch64/lin/aarch64-linux/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/aarch64/lin/aarch64-none/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/gnu/armr5/lin/gcc-arm-none-eabi/bin:/afs/bb/proj/fpga/xilinx//SDK/2016.4/tps/lnx64/cmake-3.3.2/bin:/afs/bb/u/de165079/bin:/usr/lib64/qt-3.3/bin:/opt/maven/bin:/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/etc:/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/afs/bb/@sys/usr/local/bin
export LD_LIBRARY_PATH=/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/graphviz/lib:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/bin:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lib/lnx64.o:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/tps/lnx64/jre/lib/amd64:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/tps/lnx64/jre/lib/amd64/server:/usr/lib64:/afs/bb/proj/cte/tools/cds/Incisiv/15.10.s19/tools/lib/64bit:/home/lsfbb/prod/9.1/linux2.6-glibc2.3-x86_64/lib:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/bin/../lnx64/tools/dot/lib:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/fpo_v6_1:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/fpo_v7_0:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/fft_v9_0:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/opencv:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/fir_v7_0:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/dds_v6_0:/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/gdb_v7_2
export HDI_APPROOT=/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4
export XILINX_OPENCL_CLANG=/afs/bb/proj/fpga/xilinx/Vivado_HLS/2016.4/lnx64/tools/clang
export RDI_PLATFORM=lnx64
bugpoint -mlimit=32000  --load libhls_support.so  --load libhls_bugpoint.so  -hls -strip  -function-uniquify -auto-function-inline -globaldce  -ptrArgReplace -mem2reg -instcombine -dce  -reset-lda  -loop-simplify -indvars -licm -loop-dep  -loop-bound -licm -loop-simplify -flattenloopnest  -array-flatten -gvn -instcombine -dce  -array-map -dce -func-legal  -gvn -adce -instcombine -cfgopt -simplifycfg -loop-simplify   -array-burst -promote-global-argument -dce  -axi4-lower -array-seg-normalize  -basicaa -aggrmodref-aa -globalsmodref-aa -aggr-aa -gvn -gvn  -basicaa -aggrmodref-aa -globalsmodref-aa -aggr-aa -dse -adse -adce -licm  -inst-simplify -dce  -globaldce -instcombine -array-stream -eliminate-keepreads -instcombine  -dce   -deadargelim -doublePtrSimplify  -doublePtrElim -dce -doublePtrSimplify -promote-dbg-pointer  -dce -scalarrepl -mem2reg -disaggr -norm-name -mem2reg  -instcombine  -dse -adse -adce -ptrLegalization -dce -auto-rom-infer -array-flatten -dce -instcombine  -loop-rot -constprop -cfgopt -simplifycfg -loop-simplify -indvars -pointer-simplify -dce -loop-bound  -loop-simplify -loop-preproc  -constprop -global-constprop -gvn -mem2reg -instcombine -dce  -loop-bound  -loop-merge -dce  -bitwidthmin  -deadargelim -dce  -canonicalize-dataflow -dce  -scalar-propagation -deadargelim -globaldce -mem2reg  -interface-preproc -interface-gen  -deadargelim -directive-preproc -inst-simplify -dce  -gvn -mem2reg -instcombine -dce -adse  -loop-bound  -instcombine -cfgopt -simplifycfg -loop-simplify  -clean-region -io-protocol  -find-region -mem2reg  -bitop-raise  -inst-simplify -inst-rectify -instcombine -adce -deadargelim  -loop-simplify -phi-opt -bitop-raise  -cfgopt -simplifycfg -strip-dead-prototypes  -interface-lower -bitop-lower -intrinsic-lower -auto-function-inline  -basicaa -aggrmodref-aa -globalsmodref-aa -aggr-aa  -inst-simplify -simplifycfg   -loop-simplify  -mergereturn -inst-simplify -inst-rectify  -dce -bitop-lower  -loop-rewind -pointer-simplify -dce -cfgopt  -read-loop-dep -dce -bitwidth -loop-dep -norm-name -legalize   /afs/vlsilab.boeblingen.ibm.com/proj/fpga/framework/dcelik/GitRepo/snap_fork/actions/hls_data_transfer/hw/hlsDoubleMult_xcku060-ffva1156-2-e/doublemult/.autopilot/db/a.o.2.bc
llvm-dis bugpoint-reduced-simplified.bc 
