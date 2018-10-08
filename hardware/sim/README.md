# Simulation
SNAP supports *Xilinx xsim* and *Cadence irun or xcelium* tools for simulation.
Other simulators like Mentor Modelsim or questa are supported by the respective Xilinx Vivado version and can be used as well, 
but due to lack of licenses this support is not tested and is built into the SNAP framework as "experimental use" without warranty.
The environment variable `SIMULATOR` (see make snap_config) selects the simulator.

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
During Simulation only the SNAP framework + action is part of the simulation model,
and the PSL functionality is replaced by the PSL simulation environment (PSLSE), a behavioral simulator running on the X86 host.

You may clone `PSLSE` from github [https://github.com/ibm-capi/pslse](https://github.com/ibm-capi/pslse).
Starting with March 1st 2018, the 'master' branch in PSLSE supports both PSL functions for POWER8 or POWER9,
but you have to specify which version you need with the environment variable PSLVER=8 or PSLVER=9.

The simulation runtime script 'run_sim' will
```
* start the hardware simulator and load the SNAP framework+action simulation model
* start the PSLSE behavioral simulator and connect it to the hardware simulator
* start any software application and connect it to PSLSE to run testcases against the hardware model
```

In order to enable SNAP's build and simulation process to make use of `PSLSE`,
the variable `PSLSE_ROOT` (defined in `${SNAP_ROOT}/snap_env.sh`) needs to point to the directory containing the github pslse clone.
```
 export PSLSE_ROOT=             # path for the PSL simulation environment
 export PSLVER=                 # PSLSE functionality for POWER8 or POWER9
 export PSL_DCP=                # path to the PSL checkpoint fitting your target card. For Simulation this is not needed and usually commented out
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
Currently supported are AlphaData KU3 and 8K5, Nallatech 250S and 250S+, Semptian NSA121B

Regression tests are in place for the following cards:
```
card         ADKU3      AD8K5      N250S      N250SP     S121B          # set with
system       POWER8     POWER8     POWER8     POWER9     POWER8         #
memory_avail DDR3/BRAM  DDR4/BRAM  DDR4/BRAM  DDR4/BRAM  DDR4/BRAM      # SDRAM_USED, BRAM_USED
NVMe         no         no         yes        no         no             # NVME_USED=TRUE
cloud access yes        no         partial    no         no             # not avail yet for NVMe
```
Depending on the used memory, the card and framework can be combined with the following actions (one action only):
```
memory_used  DDR               BRAM             none
action       hdl_example       hdl_example      hdl_example
             hdl_nvme_example  hdl_nvme_example
             hls_nvme_memcopy
             hls_intersect     hls_intersect    hls_bfs
             hls_hashjoin                       hls_sponge
             hls_memcopy                        hls_helloworld
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
Two set of useful signals have been added to help debugging an action
```
 iruntrace                           # for Cadence irun - it will open automatically debug_action_gmem_ddr4.svwf file
 xsimtrace                           # for Xilinx xsim - it will open automatically debug_action_gmem_ddr4.wcfg file
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
