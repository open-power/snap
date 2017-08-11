# SNAP setup

In order to set up the required environment variables for the SNAP build process, you may source the script [./snap_settings](./snap_settings):

```bash
    . ./snap_settings
```

The following commands need to be executed before calling this script:

```bash
    source <xilinx_root>/Vivado/<version>/settings64.sh
    export XILINXD_LICENSE_FILE=<pointer to Xilinx license>
    export PSL_DCP=<CAPI PSL Checkpoint file (b_route_design_dcp)>
```

This script will define the following environment variables (if they are not already pre-defined
differently):

```
    FPGACARD            = FGT                                                    # CAPI FPGA card to be used - currently supported are KU3, FGT
    FPGACHIP            = xcku060-ffva1156-2-e                                   # version of the FPGA chip
    SNAP_ROOT           = <parent of the directory containing snap_settings>     # snap clone from github
    ACTION_ROOT         = $SNAP_ROOT/actions/hdl_example                         # directory containing the action's source code
    SIMULATOR           = xsim                                                   # currently supported simulators are xsim and irun (IES)
    NUM_OF_ACTIONS      = 1                                                      # number of actions to be implemented with the card (up to 16)
    SDRAM_USED          = FALSE                                                  # adding access to the on card SDRAM via an AXI interface?
    NVME_USED           = FALSE                                                  # adding access to flash memory via NVMe
    ILA_DEBUG           = FALSE                                                  # adding debug support? (expecting probes definition in $SNAP_ROOT/hardware/setup/debug.xdc)
    FACTORY_IMAGE       = FALSE                                                  # build a factory image?
```

# Image and model build

In order to prepare the vivado environment for this project, call:

```bash
    make config
```

from within `$SNAP_ROOT` or from `$SNAP_ROOT/hardware`.
Pre-requisite for this is that the environment variables for this project
are defined (e.g. by sourcing the [./snap_settings](./snap_settings) script).  
The variable `$SIMULATOR` is used to determine for which of the simulators xsim or ncsim
the environment will be prepared.

If the variable `$ACTION_ROOT` is not set, the make process will terminate. 
The HDL based default action example will be included if that environment variable is set to
`$SNAP_ROOT/actions/hdl_example`.
As usual you may set the variable with the call of make:

```bash
    make config ACTION_ROOT=$SNAP_ROOT/actions/hdl_example
```

As part of the configuration step, the make process will call the target `hw` that is expected to exist in a `Makefile`
contained in the directory that `$ACTION_ROOT` is pointing to (see section [Action wrapper](#action-wrapper)).
Specific configurations/preparations for the action may be added via this make process step.

If you call make without any targets, then the environment is created and a simulation model build
as well as a card image build are kicked off.
In order to build a model and an image including the HDL action example, call:

```bash
    make ACTION_ROOT=$SNAP_ROOT/actions/hdl_example
```

If you want to build an image (a bitstream) for a given `$ACTION_ROOT`, you may call `make` with target `image`:

```bash
    make config image
```

***Note:*** All preparations for the build process, including the decision which actions get included, are made in the configuration step.
Each environment variable change requires to execute a `make clean` step prior to `make config`.

If the configuration step was already executed, you may just call:

```bash
    make image
```
***Note*** that you must still build the software tools on the POWER target system.

A simulation model (for the simulator defined by the environment variable `$SIMULATOR`) may be created
via the target `model`:

```bash
    make config model
```
This will also build the software tools and the PSLSE which are required to run the simulation.

Please refer to `$SNAP_ROOT/hardware/Makefile` for more supported targets like clean, gitclean, create_environment, ...

## FPGA bitstream image update
Please see [snap/hardware/doc/Bitstream_flashing.md](./doc/Bitstream_flashing.md) for instructions on how to update the FPGA bitstream image, build factory images and program cards from scratch.

# Action wrapper

The environment variable `$ACTION_ROOT` defines the path to the set of actions that shall be included.
**It has to point to a directory within** [snap/actions](../actions).  
The SNAP hardware build process is expecting each action example's root directory to contain a Makefile
providing at least the targets `clean` and `hw` (see also [snap/actions/README.md](../actions/README.md)).

At this point SNAP supports the integration of one action. Multi-action support will follow.

Corresponding to the ports that the SNAP framework provides, each action has to provide ports for the following AXI interfaces:
* an AXI slave port for MMIO based control
* an AXI master port for host DMA traffic
* an optional AXI master port for on card SDRAM traffic
* an optional AXI master port for communication with an NVMe host controller
Furthermore, HDL actions have to implement the interrupt ports as shown in the [HDL example action wrapper](../actions/hdl_example/hw/action_wrapper.vhd_source).  
For HLS actions, the HLS compiler will automatically generate the necessary interrupt logic.

***Note*** that the ID widths of the AXI interfaces to host memory and to the on-card SDRAM have to be
large enough to support the number of actions that shall be instantiated.
For the build process this is controlled via the environment variable `$NUM_OF_ACTIONS`
which defaults to `1` if not set differently.

The support for actions created with HLS as opposed to HDL actions written directly in VHDL or Verilog differs slightly.

### HDL Action
In order to integrate an HDL action into the SNAP framework the directory that `$ACTION_ROOT` is pointing to needs to contain an entity named `action_wrapper` which is serving as interface between the action and the SNAP framework.

An example for such an action together with a corresponding wrapper may be found in [snap/actions/hdl_example/hw](../actions/hdl_example/hw).
It can be used for various verification scenarios like copying memory content.

### HLS Actions
The top level entity for an HLS action needs to be named `hls_action`.

You'll also find examples for HLS actions in [snap/actions](../actions). For each example, the HLS action to be integrated into the SNAP framework is contained in a file `hls_<action>.cpp`. Before initiating the SNAP framework's make process, you need to create the necessary RTL files (VHDL or Verilog) out of the `hls_<action>.cpp` file. Each example contains a `Makefile` that takes care of this. In order to make sure that the resulting top level entity fits into the SNAP framework, the HLS actions top level function needs to be named `hls_action`.

The environment variable `$ACTION_ROOT` needs to point to a subdirectory of [snap/actions](../actions). That directory should  contain a `Makefile` for generating the RTL code from the HLS `.cpp` sources. As shown in the examples, the `Makefile` should include the file [snap/actions/hls.mk](../actions/hls.mk). That way the RTL code for the HLS action will be placed into a subdirectory `hw` contained in the directory that `$ACTION_ROOT` points to, and the SNAP framework's make process is able to include it.

For instance, if you want to configure the SNAP framework for integrating the HLS memcopy example contained in [snap/actions/hls_memcopy](../actions/hls_memcopy), call

```bash
  export ACTION_ROOT=$SNAP_ROOT/actions/hls_memcopy
```  
before initiating the SNAP framework's make process.

***Note*** that for the integration of HLS actions into the SNAP framework, the environment variable `$ACTION_ROOT` needs to point to (a subdirectory of) a directory starting with `hls` (case doesn't matter), or the environment variable `$HLS_SUPPORT` needs to be defined and to be set to `TRUE` (case doesn't matter).

# SDRAM Card Memory

The SNAP framework supports the usage of the on-card SDRAM. It is accessible for the actions via the action wrapper
through an AXI master interface. The existence of that interface is configurable via the environment variable `$SDRAM_USED`.
When setting

```bash
    SDRAM_USED=TRUE
```

the interface will be instantiated and the access to the SDRAM will be provided.

# NVMe support

For FPGA cards with NVMe flash attached, the SNAP framework supports the integration of up to two Flash drives. When setting

```bash
    NVME_USED=TRUE
```

the support will be enabled by instantiating an NVMe host controller together with the corresponding PCIe root complexes and the required AXI interfaces.

# Hardware debug with ILA cores

In order to create an image that allows debugging the design using the
Vivado Integrated Logic Analyzer (ILA) you may prepare a `.xdc` file for
adding ILA cores to the design
(an example for such a file is located here: [./doc/ila_debug.xdc](./doc/ila_debug.xdc)).  
Letting the environment variable
```
    ILA_SETUP_FILE
```
point to that `.xdc` file and setting
```bash
    ILA_DEBUG=TRUE
```
will prepare the ILA cores accordingly during the image build process.
Additionally to the image files itself, the build process will create
the required `.ltx` debug probes file which will be located in the results
directory `$SNAP_ROOT/hardware/build/Images`.

# Simulation

SNAP supports *Xilinx xsim* and *Cadence irun* tools for simulation.

### PSLSE setup
The SNAP framework's simulation depends on the PSL simulation environment (PSLSE).

You may clone `PSLSE` from github [https://github.com/ibm-capi/pslse](https://github.com/ibm-capi/pslse).

In order to enable SNAP's build and simulation process to make use of `PSLSE` the environment variable `$PSLSE_ROOT` needs to point to the directory containing `PSLSE`.

### Cadence setup

If you want to use Cadence tools (irun) for simulation you need to compile the Xilinx IP and let the environment variable

```
   export IES_LIBS      = <pointer to precompiled Xilinx IP for Cadence tools>
   export CDS_LIC_FILE  = <pointer to Cadence license>
```

point to the resulting compiled library.

Furthermore, the environment variables `$PATH` and `$LD_LIBRARY_PATH` need to contain the paths
to the Cadence tools and libraries. In case `$SIMULATOR == irun`, the script
[./snap_settings](./snap_settings) will set the Cadence specific environment variable

```
   CDS_INST_DIR         = <Cadence Installation Directory>                       # path to Cadence installation
```

if it is not already pre-defined.

### Running simulation
You may kick off simulation from within the subdirectory `sim` using the script `run_sim`.
Calling this script without any parameter will open an xterm window from which the simulation can be controlled interactively.

To initialize the SNAP framework, run `$SNAP_ROOT/software/tools/snap_maint` first.

For the VHDL based example `ACTION_ROOT=$SNAP_ROOT/hardware/actions/hdl_example` you may then execute the example application
`snap_example` contained in [$ACTION_ROOT/sw](../actions/hdl_example/sw). Calling this application with option `-h` will present usage informations.

