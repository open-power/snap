# Simulation
SNAP supports *Xilinx xsim* and *Cadence irun* tools for simulation.
The environment variable `SIMULATOR` (see make snap_config) selects the simulator and can be set to `xsim` or to `irun`.  

## Building a model
see [Image and model build](../#image-and-model-build) for further instructions
Note: The Makefile for building a model calls Vivado to export a script `top.sh` for compile & elaborate & simulate.
In SNAP the call of the simulator from `top.sh` is disabled. For instructions on simulation please refer to [Running simulation](#running-simulation) instead.  
Cadence also supports a three-step compile/elab/run mode, which lists compile modules differently and is not used for SNAP.
The Cadence one-step irun mode calls irun for compile and for simulator execution, the simulator underneath is called ncsim.  
Xilinx builds models in three steps compile/elaborate/simulate with a `.prj` file similar to Cadence irun
### compile options
```
            Cadence          Xilinx
all         -64bit           -m64
            -relax           --relax
compile     -v93
elaborate   -access +rwc
            -namemap_mixgen
                             --debug typical
                             --mt auto
simulate                     -tclbatch cmd.tcl
logfile                      --log simulate.log
```
## PSLSE setup
The SNAP framework's simulation depends on the PSL simulation environment (PSLSE).

You may clone `PSLSE` from github [https://github.com/ibm-capi/pslse](https://github.com/ibm-capi/pslse).

In order to enable SNAP's build and simulation process to make use of `PSLSE` the variable `PSLSE_ROOT` (defined in `${SNAP_ROOT}/snap_env.sh`) needs to point to the directory containing the github pslse clone.
```
 export PSLSE_ROOT=                                  # path for the PSL simulation environment
 export PSL_DCP=                                     # path to the PSL checkpoint fitting your target card
```

## Cadence irun
* model resides in              $SNAP_ROOT/hardware/sim/ies/ies
* output generated in           $SNAP_ROOT/hardware/sim/ies/<yyyymmdd_hhmmss>
* waveforms in                  $SNAP_ROOT/hardware/sim/ies/<yyyymmdd_hhmmss>/capiWave.shm
* last output seen with symlink $SNAP_ROOT/hardware/sim/ies/latest
If you want to use Cadence tools (irun) for simulation, you need to compile the Xilinx IP and let the environment variable
```bash
export IES_LIBS      = <pointer to precompiled Xilinx IP for Cadence tools>
export CDS_LIC_FILE  = <pointer to Cadence license>
```
point to the resulting compiled library.

Furthermore, the environment variables `$PATH` and `$LD_LIBRARY_PATH` need to contain the paths
to the Cadence tools and libraries. In case `$SIMULATOR == irun`, the SNAP environment setup process will
expect the Cadence specific environment variable being set up via:
```bash
export CDS_INST_DIR=                                # Cadence tools installation root
export PATH=$CDS_INST_DIR/tools/bin:$PATH
export LD_LIBRARY_PATH=$CDS_INST_DIR/tools/lib/64bit:$LD_LIBRARY_PATH
export CDS_LIC_FILE=                                # IP socket to your Cadence license server
export IES_LIBS=                                    # Cadence IP compiled with Vivado
export DENALI=                                      # Cadence DENALI tools path for NVMe+PCIe device simulation

```
## Xilinx xsim
* model resides in              $SNAP_ROOT/hardware/sim/xsim/xsim.dir
* output generated in           $SNAP_ROOT/hardware/sim/xsim/<yyyymmdd_hhmmss>
* waveforms in                  $SNAP_ROOT/hardware/sim/xsim/<yyyymmdd_hhmmss>/top.wdb
* last output seen with symlink $SNAP_ROOT/hardware/sim/xsim/latest
```
 export XILINX_ROOT=                                 # Xilinx tools installation root
 export XILINXD_LICENSE_FILE=                        # Xilinx license server
 . $XILINX_ROOT/Vivado/${VIV_VERSION}/settings64.sh  # settings for SDK+HLS+docnav+vivado
```

## Running simulation
You may kick off simulation by calling `make sim` from the SNAP root directory.
This will start the simulation and then open an xterm window from which the simulation can be controlled interactively.

For the VHDL based example 'hdl_example' you may then execute the example application
`snap_example` contained in [snap/actions/hdl_example/sw](../actions/hdl_example/sw). 
Calling this application with option `-h` will present usage informations.

If you want to run automated from a test list, you can call the simulation script `run_sim` with additional arguments instead.
`run_sim` is called from $SNAP_ROOT/hardware/sim. It will
* start the simulator (irun, xsim) and wait for it to open an IP socket
* start PSLSE and wait for it to connect to this socket and open a second IP socket
* start an application (or list of applications or xwindow, where you can start any app)

    `run_sim -app <application>` to run just this one app  
    `run_sim -list <list.sh>` to run a list of testcases, before ending.

When the app or list or xwindow finishes, this is the signal for PSLSE and the simulator to also end and close all logfiles.
This means, that PSLSE&sim only runs, as long as the app/list/xterm is avail.
If you start an app in the xterm and cntl-C it without exiting from the xterm, the simulation keeps running.  

## card and action settings
Currently supported are Nallatech 250S, AlphaData KU3 and Semptian NSA121B, one action only
Regression tests are in place for
```
card      ADKU3/S121B    ADKU3/S121B   ADKU3/S121B  N250S        N250S        N250S             set with
memory    DDR3/DDR4      BRAM          none         DDR4         BRAM         none              SDRAM_USED, BRAM_USED
NVMe      no             no            no           yes          yes          yes               NVME_USED=TRUE
action    hdl_example    hdl_example   hdl_example  hdl_example  hdl_example  hdl_example
          hls_intersect  hls_intersect hls_bfs
          hls_hashjoin                 hls_sponge
          hls_memcopy
          hls_search
```
## run_sim arguments
```
 -app <app> | -list <list> | -x      # run a single application or a list of application or open another shell for manual input (default=-x)
                                     # sim/testlist.sh is an example list with our sim regression tests for all actions
 -aet | -noaet                       # turn waveform generation on/off (default=on)
 -p <parmsfile>                      # use different PSLSE parameter settings (default=pslse.parms from $PSLSE_ROOT)
 -keep | -clean                      # keep succesful runs or clean them after running (for space reasons, default=keep)
 -par <n>                            # start multiple parallel apps/lists/xterms. This is NOT part of the product support yet.
```
# Debugging a model
## waveform generation
Calling `run_sim` with -aet (waveforms enabled, this is the default) starts a tcl script to include signals.
```
 ncaet.tcl                           # for Cadence irun
 xsaet.tcl                           # for Xilinx xsim
```
The generated waveform can be viewed with
```
 simvision capiWave.shm              # for Cadence waveforms
 simvision capiWave.shm -snapshot xx # with snapshot to get access to design hierarchy
 iccr -gui                           # view interactive coverage

 xsim top.wdb -gui                   # for Xilinx waveforms
```
## controlling PSLSE randomness
By default the PSLSE environment reorders and delays commands/responses in order to get more variations.
```
 TIMEOUT:10                          # Timeout delay in seconds: If 0 then timeouts are disabled.
 CREDITS:64                          # number of credits provided
 SEED:13                             # Randomization seed.  Set this to force reproducible sequence of event
 RESPONSE_PERCENT:10,20              # Percentage chance of PSL driving any pending responses in a clock cycle. used for reordering cmds
 PAGED_PERCENT:2,4                   # Percentage chance of PSL responding with PAGED for any command response.
 REORDER_PERCENT:80,90               # Percentage chance of PSL reordering the execution of commands.
 BUFFER_PERCENT:80,90                # Percentage chance of PSL generating extra buffer read/write activity.
```
For recreation of a dedicated problem you can disable this variation with your own parms file
```
 RESPONSE_PERCENT:100,100            # Percentage chance of PSL driving any pending responses in a clock cycle. used for reordering cmds
 PAGED_PERCENT:0,0                   # Percentage chance of PSL responding with PAGED for any command response.
 REORDER_PERCENT:0,0                 # Percentage chance of PSL reordering the execution of commands.
 BUFFER_PERCENT:0,0                  # Percentage chance of PSL generating extra buffer read/write activity.
```
