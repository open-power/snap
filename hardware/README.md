# SNAP setup

Executing the following commands is pre-requisite for the usage of the SNAP framework:
```bash
    source <xilinx_root>/Vivado/<version>/settings64.sh
    export XILINXD_LICENSE_FILE=<pointer to Xilinx license>
```

In order to configure the SNAP framework and to prepare the environment
for the SNAP build process, you may call

```bash
    make snap_config
```

from the SNAP root directory (called `${SNAP_ROOT}` from now on, which is a variable internally
defined and used by SNAP make process).  
This step basically produces two files: `${SNAP_ROOT}/.snap_config.sh` and `${SNAP_ROOT}/.snap_env.sh`  
The file `${SNAP_ROOT}/.snap_env.sh` is defining at least three paths:

```
    PSL_DCP=<pointer to the Vivado CAPI PSL design checkpoint file (b_route_design.dcp)>
    ACTION_ROOT=<pointer to the directory containing the action sources>
    PSLSE_ROOT=<pointer to the path containing the PSLSE github clone>
```

In case of a setup for cloud builds (see [Cloud Support](#cloud-support)) the file `${SNAP_ROOT}/.snap_env.sh`
needs to also define the following path:

```
    DCP_ROOT=<pointer to the directory for design checkpoints required in the PR flow>
```

# Image and model build

Which action is getting integrated into the SNAP framework is specified in `${SNAP_ROOT}/.snap_env.sh`
via the path `ACTION_ROOT`.
If that is not automatically set by calling `make snap_config`, you may simply modify the file
`${SNAP_ROOT}/.snap_env.sh` manually to let `ACTION_ROOT` point to the directory containing the action.

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

If you want to change the configuration (another card, another action, different NVMe and/or SDRAM settings, ...)
it is recommended that you clear the current configuration settings by calling

```bash
    make clean_config
```

Please refer to [snap/Makefile](../Makefile) for more supported targets like clean, ...

## FPGA bitstream image update
Please see [snap/hardware/doc/Bitstream_flashing.md](./doc/Bitstream_flashing.md) for instructions on how to update the FPGA bitstream image, build factory images and program cards from scratch.

# Action wrapper

The definition of `ACTION_ROOT` in `${SNAP_ROOT}/.snap_env.sh` specifies the path to the set of actions that shall be included.
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
For the build process this is controlled via the variable `NUM_OF_ACTIONS`
which is defined in `${SNAP_ROOT}/snap_config.sh`.  
***Note*** The SNAP framework currently does not support more than one action.

The support for actions created with HLS as opposed to HDL actions written directly in VHDL or Verilog differs slightly.

### HDL Action
In order to integrate an HDL action into the SNAP framework the directory that `ACTION_ROOT` is pointing to, needs to contain an entity named `action_wrapper` which is serving as interface between the action and the SNAP framework.

An example for such an action together with a corresponding wrapper may be found in [snap/actions/hdl_example/hw](../actions/hdl_example/hw).
It can be used for various verification scenarios like copying memory content.

### HLS Actions
The top level entity for an HLS action needs to be named `hls_action`.

You'll also find examples for HLS actions in [snap/actions](../actions). For each example, the HLS action to be integrated into the SNAP framework is contained in a file `hls_<action>.cpp`. Before initiating the SNAP framework's make process, you need to create the necessary RTL files (VHDL or Verilog) out of the `hls_<action>.cpp` file. Each example contains a `Makefile` that takes care of this. In order to make sure that the resulting top level entity fits into the SNAP framework, the HLS actions top level function needs to be named `hls_action`.

The variable `ACTION_ROOT` needs to point to a subdirectory of [snap/actions](../actions). That directory should  contain a `Makefile` for generating the RTL code from the HLS `.cpp` sources. As shown in the examples, the `Makefile` should include the file [snap/actions/hls.mk](../actions/hls.mk). That way the RTL code for the HLS action will be placed into a subdirectory `hw` contained in the directory that `$ACTION_ROOT` points to, and the SNAP framework's make process is able to include it.

Example: By setting up `${SNAP_ROOT}/.snap_env.sh` such that `ACTION_ROOT` points to `${SNAP_ROOT}/actions/hls_memcopy` the HLS memcopy example contained in [snap/actions/hls_memcopy](../actions/hls_memcopy) will get integrated into the SNAP framework.

***Note:*** For the integration of HLS actions into the SNAP framework, `ACTION_ROOT` needs to point to (a subdirectory of) a directory starting with `hls` (case doesn't matter), or the environment variable `$HLS_SUPPORT` needs to be defined and to be set to `TRUE` (this is an option that is handled during the environment setup via `make snap_env`).

# SDRAM Card Memory

The SNAP framework supports the usage of the on-card SDRAM. It is accessible for the actions via the action wrapper
through an AXI master interface. In the SNAP configuration step the existence of that interface is controlled via the option 'Enable SDRAM' which is defining the value of `SDRAM_USED` in `${SNAP_ROOT}/.snap_config.sh`.

# NVMe support

For FPGA cards with NVMe flash attached, the SNAP framework supports the integration of up to two Flash drives. Via the SNAP configuration option 'Enable NVMe' the instantiation of the NVMe host controller together with the corresponding PCIe root complexes and the required AXI interfaces can be configured.

# Hardware debug with ILA cores

In order to create an image that allows debugging the design using the
Vivado Integrated Logic Analyzer (ILA) you may prepare a `.xdc` file for
adding ILA cores to the design
(an example for such a file is located here: [./doc/ila_debug.xdc](./doc/ila_debug.xdc)).  
Letting the environment variable
```
    ILA_SETUP_FILE
```
point to that `.xdc` file and enabling 'ILA Debug' during environment setup
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

In order to enable SNAP's build and simulation process to make use of `PSLSE` the variable `PSLSE_ROOT` (defined in `${SNAP_ROOT}/.snap_env.sh`) needs to point to the directory containing the github pslse clone.

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
