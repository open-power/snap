# SNAP setup
Please check [../README.md](../README.md) for [dependencies](../README.md#dependencies).

Executing the following commands is pre-requisite for the usage of the SNAP framework:
```bash
source <xilinx_root>/Vivado/<version>/settings64.sh
export XILINXD_LICENSE_FILE=<pointer to Xilinx license>
```
In order to handle paths and other environment settings, the SNAP `make` process is always sourcing the script `${SNAP_ROOT}/snap_env.sh`. You may modify that script (or create it if it doesn't already exist) and add your environment settings to that script (see also [SNAP environment variables](#snap-environment-variables)).

***Note:*** The SNAP `make` process is internally defining a variable `${SNAP_ROOT}` which is pointing to SNAP's [root directory](https://github.com/open-power/snap).
Therefore, this variable may be used in the specification of paths for the `make` process, and we are using this variable in this document in the notation of file names.

## SNAP configuration
In order to configure the SNAP framework and to prepare the environment
for the SNAP build process, you may call
```bash
make snap_config
```

from the SNAP root directory. Making use of [a standalone application configuration tool based on kernel kconfig](https://github.com/guillon/kconfig) the features for a specific SNAP framework configuration can be selected.
Among the features that get configured via `make snap_config` are
* the card type
* the action type (see also [Specifying the action](#specifying-the-action))
* enablement of the on-card SDRAM
* enablement of the Xilinx Integrated Logic Analyzer
* the simulator

If additional path settings are required, the step `make snap_config` will tell you which variable definitions to add to the script `${SNAP_ROOT}/snap_env.sh` (see also [SNAP environment variables](#snap-environment-variables)).

By calling `make snap_config` again, a previously defined configuration may be modified.

If you want to clean your repository (i.e. remove the generated files) you may do so by calling
```bash
make clean
```
But, that call will keep the configuration settings. If you want to also reset the configuration settings you may call
```bash
make clean_config
```
It is recommended to call `make clean_config` each time you want to start over with a new configuration.

## SNAP environment variables
A side effect of calling `make snap_config` is the modification (or creation in case of first time execution) of the file `${SNAP_ROOT}/snap_env.sh`.
The main purpose of this file is the definition of paths that are required during the SNAP build and simulation process. The file gets sourced during SNAP's `make` process.
As a result of the execution of `make snap_config` a version of `${SNAP_ROOT}/snap_env.sh` containing at least five (maybe commented and incomplete) lines will exist:
```bash
export TIMING_LABLIMIT=<lower slack limit for timing considered acceptable for bitstream build>
export ACTION_ROOT=<pointer to the directory containing the action sources>
export PSLVER=<8: PSL version for POWER8 | 9: PSL version for POWER9>
export PSL_DCP=<pointer to the Vivado CAPI PSL design checkpoint file (b_route_design.dcp)>
export PSLSE_ROOT=<pointer to the path containing the PSLSE github clone>
```

If a file `${SNAP_ROOT}/snap_env.sh` is already existing when calling `make snap_config` that file will be taken, and the definition of
`ACTION_ROOT` will be adapted according to the selection of the action type.

In case of a setup for cloud builds (see [Cloud Support](#cloud-support)) the following setup will be modified
as well:
```
DCP_ROOT=<pointer to the directory for design checkpoints required in the Partial Reconfiguration flow>
```

As already indicated above, the notation `${SNAP_ROOT}` may be used when pointing to directories or files below the SNAP root directory. For instance, if during the `make snap_config` step you select `hdl_example` as action the file `${SNAP_ROOT}/snap_env.sh` will contain the line
```bash
export ACTION_ROOT=${SNAP_ROOT}/actions/hdl_example
```

***Note:*** When calling `make snap_config` for the first time without a given `${SNAP_ROOT}/snap_env.sh`, you need to edit the generated
file `${SNAP_ROOT}/snap_env.sh` in order to set the correct path names.

# Image and model build
## Specifying the action
Which action is getting integrated into the SNAP framework is specified in `${SNAP_ROOT}/snap_env.sh`
via the path `ACTION_ROOT`.
When selecting "HDL Action" or "HLS Action" (for example when creating your own new action), the variable `ACTION_ROOT` is either set to an empty string or to the value that was selected in the previous run of `make snap_config`. You may simply modify the file `${SNAP_ROOT}/snap_env.sh` manually to let `ACTION_ROOT` point to the directory containing the action.

As part of the Vivado project configuration step, the make process will call the target `hw` that is expected to exist in a `Makefile`
contained in the directory that `ACTION_ROOT` is pointing to (see section [Action wrapper](#action-wrapper)).
Specific configurations/preparations for the action may be added via this make process step.

## CAPI board support and PSL for image build
In order to benefit from the advantage of CAPI (low latency high bandwith access to host memory as well as memory coherency) a specific  implementation of the FPGA is required to use the PCIe link and CAPP (**C**oherent **A**ccelerator **P**rocessor **P**roxy which is located in the POWER processor) properly. The PSL (**P**OWER **S**ervice **L**ayer) is providing the necessary infrastructure.
The PSL differs whether we have a POWER8 with CAPI 1.0 or a POWER9 with CAPI 2.0.

In any case, to get the latest CAPI board support and PSL download, visit **IBM Portal for OpenPOWER** at

https://www.ibm.com/systems/power/openpower

From the menu, select "CAPI"->"Coherent Accelerator Processor Interface (CAPI)" or directly click the "CAPI" icon to go to the CAPI section.
Then download the appropriate files depending on your target system being POWER8 (CAPI 1.0) or POWER9 (CAPI 2.0).

#### POWER8
CAPI board support and PSL are provided combined in a Vivado DCP (**D**esign **C**heck**P**oint).
Please go to the IBM Portal for OpenPOWER and download the required files under "**PSL Checkpoint Files for the POWER8 CAPI SNAP Design Kit**" according to the selected FPGA card.  
For the image build process you need to make sure that in `snap_env.sh` the environment variable `PSL_DCP` is defined such that it is pointing to the downloaded Vivado DCP.

#### POWER9
CAPI BSP (**B**oard **S**upport **P**ackage) and PSL got separated. For the CAPI 2.0 BSP, the open source git repository https://github.com/open-power/capi2-bsp is integrated into the SNAP framework as git submodule under [hardware/capi2-bsp](https://github.com/open-power/capi2-bsp).

The PSL is integrated into the CAPI BSP as an IP core with encrypted sources.
Please go to the IBM Portal for OpenPOWER and download the required files under "**PSL IP Source Files for POWER9 CAPI**".

Note : for AD9Hx cards containing HBM, HBM lib needs to added manually (see [hardware/setup/AD9H3/README.md](./setup/AD9H3/README.md))

Alternatively, the following link will provide direct access:

https://www-355.ibm.com/systems/power/openpower/posting.xhtml?postingId=1BED44BCA884D845852582B70076A89A

If the environment variable `PSL9_IP_CORE` is defined (e.g. via `snap_env.sh`), the build process uses it as a pointer to the archived PSL9 IP core.
Otherwise, the build process is assuming the archived PSL9 IP core is located in the directory `snap/hardware/capi2-bsp/psl`.

## The make process
If you call `make` without any targets, then a help message will be printed explaining the different targets supported by the make process.

A simulation model (for the simulator defined in the `snap_config` step) may be created
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

***Note:*** For the integration of HLS actions into the SNAP framework, `ACTION_ROOT` needs to point to (a subdirectory of) a directory starting with `hls` (case doesn't matter), or the environment variable `$HLS_SUPPORT` needs to be defined and to be set to `TRUE` (this is an option that is handled during the environment setup via `make snap_config`).

# SDRAM Card Memory
The SNAP framework supports the usage of the on-card SDRAM. It is accessible for the actions via the action wrapper
through an AXI master interface. In the SNAP configuration step the existence of that interface is controlled via the option 'Enable SDRAM'.

# NVMe support
For FPGA cards with NVMe flash attached, the SNAP framework supports the integration of up to two Flash drives. Via the SNAP configuration option 'Enable NVMe' the instantiation of the NVMe host controller together with the corresponding PCIe root complexes and the required AXI interfaces can be configured.

The actions directory contains HDL and HLS based examples on how to use NVMe:
- [snap/actions/hdl_example](../actions/hdl_example) provides automated data checking (read and write of arbitrary data)
- [snap/actions/hdl_nvme_example](../actions/hdl_nvme_example) shows file transfers using fixed 4k block reads and writes
- [snap/actions/hls_nvme_memcopy](../actions/hls_nvme_memcopy) implements a generic HLS memcopy function

Note the data itself doesn't flow through the NVMe host controller, but transits through the on-card SDRAM. Please see the [NVMe main documentation page](../hardware/doc/NVMe.md) for more details.

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
see [./sim/README.md](./sim/README.md) for further instructions about Simulation
