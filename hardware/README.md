# SNAP setup
Please check [../README.md](../README.md) for [dependencies](../README.md#dependencies).

Executing the following commands is pre-requisite for the usage of the SNAP framework:
```bash
source <xilinx_root>/Vivado/<version>/settings64.sh
export XILINXD_LICENSE_FILE=<pointer to Xilinx license>
```

The SNAP make process is internally defining a variable `${SNAP_ROOT}` which is pointing to SNAP's [root directory](..).
From now on we will use this variable in the notation of file names.

## snap_config
In order to configure the SNAP framework and to prepare the environment
for the SNAP build process, you may call
```bash
make snap_config
```

from the SNAP root directory. Making use of the Linux kconfig process the features for a specific SNAP framework configuration can be selected.
Among the features that get configured via `make snap_config` are
* the card type
* the action type
* enablement of the on-card SDRAM
* enablement of the Xilinx Integrated Logic Analyzer
* the simulator

By calling `make snap_config` again a previously defined configuration may be modified.

If you want to clean your repository (i.e. remove the generated files) you may do so by calling
```bash
make clean
```
But, that call will keep the configuration settings. If you want to also reset the configuration settings you may call
```bash
make clean_config
```
It is recommended to call `make clean_config` each time you want to start over with a new configuration.

## snap_env
A side effect of calling `make snap_config` is the modification of the file `${SNAP_ROOT}/snap_env.sh`.
The main purpose of this file is the definition of paths that are required during the SNAP build and simulation process. The file gets sourced during SNAP's `make` process.
As a result of the execution of `make snap_config` a version of `${SNAP_ROOT}/snap_env.sh` containing at least three lines will exist:
```bash
export PSL_DCP=<pointer to the Vivado CAPI PSL design checkpoint file (b_route_design.dcp)>
export ACTION_ROOT=<pointer to the directory containing the action sources>
export PSLSE_ROOT=<pointer to the path containing the PSLSE github clone>
```

If a file `${SNAP_ROOT}/snap_env.sh` is already existing when calling `make snap_config` that file will be taken, and the definition of
`ACTION_ROOT` will be adapted according to the selection of the action type.

In case of a setup for cloud builds (see [Cloud Support](#cloud-support)) the following setup will be modified
as well:
```
DCP_ROOT=<pointer to the directory for design checkpoints required in the Partial Reconfiguration flow>
```

The notation `${SNAP_ROOT}` may be used when pointing to directories or files below the SNAP root directory. For instance, if during the `make snap_config` process you select `hdl_example` as action the file `${SNAP_ROOT}/snap_env.sh` will contain the line
```bash
export ACTION_ROOT=${SNAP_ROOT}/actions/hdl_example
```

***Note:*** When calling `make snap_config` for the first time, you need to edit the generated
file `${SNAP_ROOT}/snap_env.sh` in order to set the correct path names.

# Image and model build

Which action is getting integrated into the SNAP framework is specified in `${SNAP_ROOT}/snap_env.sh`
via the path `ACTION_ROOT`.
If that is not automatically set by calling `make snap_config`, you may simply modify the file
`${SNAP_ROOT}/snap_env.sh` manually to let `ACTION_ROOT` point to the directory containing the action.

As part of the Vivado project configuration step, the make process will call the target `hw` that is expected to exist in a `Makefile`
contained in the directory that `ACTION_ROOT` is pointing to (see section [Action wrapper](#action-wrapper)).
Specific configurations/preparations for the action may be added via this make process step.

If you call `make` without any targets (on an X86 machine), then the SNAP software build, a simulation model build
as well as a card image build are kicked off.

Just a simulation model (for the simulator defined in the `snap_config` step) may be created
via the target `model`:

```bash
make model
```
This will also build the software tools and the PSLSE which are required to run the simulation.

If you want to build an image (a bitstream), you may call `make` with target `image`:

```bash
make image
```

***Note:*** You must still build the software tools on the POWER target system.

Please refer to [snap/Makefile](../Makefile) for more supported targets like clean, ...

## FPGA bitstream image update
Please see [snap/hardware/doc/Bitstream_flashing.md](./doc/Bitstream_flashing.md) for instructions on how to update the FPGA bitstream image, build factory images and program cards from scratch.

# Action wrapper

The definition of `ACTION_ROOT` in `${SNAP_ROOT}/snap_env.sh` specifies the path to the set of actions that shall be included.
**It has to point to a directory within** [snap/actions](../actions).  
The SNAP hardware build process is expecting each action example's root directory to contain a Makefile
providing at least the targets `clean` and `hw` (see also [snap/actions/README.md](../actions/README.md)).

At this point SNAP supports the integration of one action. Multi-action support will follow.

Corresponding to the ports that the SNAP framework provides, each action has to provide ports for the following AXI interfaces:
* an AXI slave port for MMIO based control
* an AXI master port for host DMA traffic
* an optional AXI master port for on-card SDRAM traffic
* an optional AXI master port for communication with an NVMe host controller
Furthermore, HDL actions have to implement the interrupt ports as shown in the [HDL example action wrapper](../actions/hdl_example/hw/action_wrapper.vhd_source).  
For HLS actions, the HLS compiler will automatically generate the necessary interrupt logic.

***Note*** that the ID widths of the AXI interfaces to host memory and to the on-card SDRAM have to be
large enough to support the number of actions that shall be instantiated.
For the build process this is controlled via the option `NUM_OF_ACTIONS` which is configurable in the `make snap_config` step.  
**Note*** The SNAP framework currently does not support more than one action.

The support for actions created with HLS as opposed to HDL actions written directly in VHDL or Verilog differs slightly.

### HDL Action
In order to integrate an HDL action into the SNAP framework the directory that `ACTION_ROOT` is pointing to, needs to contain an entity named `action_wrapper` which is serving as interface between the action and the SNAP framework.

An example for such an action together with a corresponding wrapper may be found in [snap/actions/hdl_example/hw](../actions/hdl_example/hw).
It can be used for various verification scenarios like copying memory content.

### HLS Actions
The top level entity for an HLS action needs to be named `hls_action`.

You'll also find examples for HLS actions in [snap/actions](../actions). For each example, the HLS action to be integrated into the SNAP framework is contained in a file `hls_<action>.cpp`. Before initiating the SNAP framework's make process, you need to create the necessary RTL files (VHDL or Verilog) out of the `hls_<action>.cpp` file. Each example contains a `Makefile` that takes care of this. In order to make sure that the resulting top level entity fits into the SNAP framework, the HLS actions top level function needs to be named `hls_action`.

The variable `ACTION_ROOT` needs to point to a subdirectory of [snap/actions](../actions). That directory should  contain a `Makefile` for generating the RTL code from the HLS `.cpp` sources. As shown in the examples, the `Makefile` should include the file [snap/actions/hls.mk](../actions/hls.mk). That way the RTL code for the HLS action will be placed into a subdirectory `hw` contained in the directory that `$ACTION_ROOT` points to, and the SNAP framework's make process is able to include it.

Example: By setting up `${SNAP_ROOT}/snap_env.sh` such that `ACTION_ROOT` points to `${SNAP_ROOT}/actions/hls_memcopy` the HLS memcopy example contained in [snap/actions/hls_memcopy](../actions/hls_memcopy) will get integrated into the SNAP framework.

***Note:*** For the integration of HLS actions into the SNAP framework, `ACTION_ROOT` needs to point to (a subdirectory of) a directory starting with `hls` (case doesn't matter), or the environment variable `$HLS_SUPPORT` needs to be defined and to be set to `TRUE` (this is an option that is handled during the environment setup via `make snap_env`).

# SDRAM Card Memory

The SNAP framework supports the usage of the on-card SDRAM. It is accessible for the actions via the action wrapper
through an AXI master interface. In the SNAP configuration step the existence of that interface is controlled via the option 'Enable SDRAM'.

# NVMe support

For FPGA cards with NVMe flash attached, the SNAP framework supports the integration of up to two Flash drives. Via the SNAP configuration option 'Enable NVMe' the instantiation of the NVMe host controller together with the corresponding PCIe root complexes and the required AXI interfaces can be configured.

# Hardware debug with ILA cores

In order to create an image that allows debugging the design using the
Vivado Integrated Logic Analyzer (ILA) you may prepare a `.xdc` file for
adding ILA cores to the design
(an example for such a file is located here: [./doc/ila_debug.xdc](./doc/ila_debug.xdc)).  
Enabling `ILA_DEBUG` in the SNAP configuration and defining the environment variable
```
ILA_SETUP_FILE
```
in `${SNAP_ROOT}/snap_env.sh` such that it points to a `.xdc` file with ILA core definitions,
will configure the preparation of the ILA cores during the image build process.
Additionally to the image files itself, the build process will create
the required `.ltx` debug probes file which will be located in the results
directory `${SNAP_ROOT}/hardware/build/Images`.

# Cloud support

TBD...

# Simulation

SNAP supports *Xilinx xsim* and *Cadence irun* tools for simulation.

### PSLSE setup
The SNAP framework's simulation depends on the PSL simulation environment (PSLSE).

You may clone `PSLSE` from github [https://github.com/ibm-capi/pslse](https://github.com/ibm-capi/pslse).

In order to enable SNAP's build and simulation process to make use of `PSLSE` the variable `PSLSE_ROOT` (defined in `${SNAP_ROOT}/snap_env.sh`) needs to point to the directory containing the github pslse clone.

### Cadence setup

If you want to use Cadence tools (irun) for simulation you need to compile the Xilinx IP and let the environment variable

```bash
export IES_LIBS      = <pointer to precompiled Xilinx IP for Cadence tools>
export CDS_LIC_FILE  = <pointer to Cadence license>
```

point to the resulting compiled library.

Furthermore, the environment variables `$PATH` and `$LD_LIBRARY_PATH` need to contain the paths
to the Cadence tools and libraries. In case `$SIMULATOR == irun`, the SNAP environment setup process will
expect the Cadence specific environment variable being set up via:

```bash
export CDS_INST_DIR  = <pointer to Cadence Installation Directory>
```

### Running simulation
You may kick off simulation from within the subdirectory `sim` using the script `run_sim`.
Calling this script without any parameter will open an xterm window from which the simulation can be controlled interactively.

To initialize the SNAP framework, run `${SNAP_ROOT}/software/tools/snap_maint` first.

For the VHDL based example `ACTION_ROOT=${SNAP_ROOT}/actions/hdl_example` you may then execute the example application
`snap_example` contained in [snap/actions/hdl_example/sw](../actions/hdl_example/sw). Calling this application with option `-h` will present usage informations.
