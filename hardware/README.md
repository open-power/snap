# Build environment

In order to set up the required environment variables for a given `FRAMEWORK_ROOT` you may source the script [./donut_settings](./donut_settings):

```bash
    . ./donut_settings
```

The script depends on the following environment variables to be already defined:

```
    FRAMEWORK_ROOT       = <your local workspace base>
    XILINX_VIVADO        = <path to Vivado tool>
    XILINXD_LICENSE_FILE = <name of the Vivado license file>
```

This script will define the following environment variables (if they are not already pre-defined
differently):

```
    USERHOME            = $FRAMEWORK_ROOT/$USER                                             # each user has his own workspace
    PSLSE_ROOT          = $USERHOME/pslse                                                   # PSLSE clone from github
    DONUT_ROOT          = <parent of the directory containing the script donut_settings>    # donut clone from github
    DONUT_SOFTWARE_ROOT = $DONUT_ROOT/software                                              # path to donut software
    DONUT_HARDWARE_ROOT = $DONUT_ROOT/hardware                                              # path to donut hardware
    FPGACARD            = $FRAMEWORK_ROOT/cards/adku060_capi_1_1_release                    # path to card HDK
    FPGACHIP            = xcku060-ffva1156-2-e                                              # version of the FPGA chip
    DIMMTEST            = $FRAMEWORK_ROOT/cards/dimm_test-admpcieku3-v3_0_0                 # path to DRAM model for simulation
    SIMULATOR           = xsim                                                              # currently supported simulators are xsim, ncsim, irun
```

Besides the HDK for the card a DIMM test project is required which can be obtained from
the Alpha Data Support Portal:
`https://support.alpha-data.com/Portals/0/Downloads/dimm_test-admpcieku3-v3_0_0.tar.gz`

The environment variable `DIMMTEST` needs to point to the directory containing that project.

## Cadence setup

If you want to use Cadence tools (i.e. ncsim or irun) for simulation you need to compile the Xilinx IP and let the environment variable

```
   IES_LIBS
```

point to the resulting compiled library.

Furthermore, the environment variables `PATH` and `LD_LIBRARY_PATH` need to contain the paths
to the Cadence tools and libraries. In case `SIMULATOR=ncsim` or `SIMULATOR=irun` the script
[./donut_settings](./donut_settings) will set the Cadence specific environment variable

```
   CDS_INST_DIR         = <Cadence Installation Directory>                                  # path to Cadence installation
```

if it is not already pre-defined.

# Action wrapper

The path to the set of actions that shall be included is defined via the environment variable `ACTION_ROOT`.
**Currently it has to point to a directory within**

    $DONUT_HARDWARE_ROOT/action_examples

This directory needs to contain an action_wrapper entity as interface between the actions and the SNAP framework.

Corresponding to the ports that the SNAP framework provides
* an AXI master port for MMIO based control
* an AXI slave port for host DMA traffic
* an optional AXI slave port for on card DDR3 RAM traffic

the port map of the `action_wrapper` has to consist of the correspondig counterparts.
Note that the ID widths of the AXI interfaces to host memory and to the on card DRAM have to be
large enough to support the number of actions that shall be instantiated.
For the build process this is controlled via the environment variable `NUM_OF_ACTIONS`
which defaults to `1` if not set differently.

Examples for actions together with their wrappers may be found in `$DONUT_HARDWARE_ROOT/action_examples/empty`
and in `$DONUT_HARDWARE_ROOT/action_examples/memcopy`.


# DDR3 Card Memory and BRAM

The SNAP framework supports the usage of the on-card DRAM. It is accessible for the actions via the action wrapper
through an AXI master interface. The existence of that interface is configurable via the environment variable `DDR3_USED`.
When setting

```bash
    DDR3_USED=TRUE
```

the interface will be instantiated and the access to the DDR3 memory will be provided.

The examples in `$DONUT_HARDWARE_ROOT/action_examples/empty` and in `$DONUT_HARDWARE_ROOT/action_examples/memcopy` show
how the card memory can be connected via the action_wrapper.
In the `config` step of the `make` process all the lines containing the comment

```vhdl
    -- only for DDR3_USED=TRUE
```

will be de-activated when `DDR3_USED` is not set to `TRUE` while they will be activated (or stay active) when `DDR3_USED`
is set to `TRUE`.
At the same time all lines containing the comment

```vhdl
    -- only for DDR3_USED!=TRUE
```

will be activated (or stay active) when `DDR3_USED` is not set to `TRUE` while they will be de-activated when `DDR3_USED`
is set to `TRUE`.

# Image and model build

In order to prepare the vivado environment for this project call:

```bash
    make config
```

from within `$DONUT_HARDWARE_ROOT`. Pre-requisite for this is that the environment variables for this project
are defined (e.g. by sourcing the ./setup/donut_settings script).
The variable `SIMULATOR` is used to determine for which of the simulators xsim or ncsim
the environment will be prepared.

If the variable `ACTION_ROOT` is not set the make process will set it to `$DONUT_HARDWARE_ROOT/action_examples/empty`
containing a dummy action wrapper file that drives zeros on all interfaces.
A memcopy action example will be included if the environment variable  is set to
`$DONUT_HARDWARE_ROOT/action_examples/memcopy`.
As usual you may set the variable with the call of make:

```bash
    make config ACTION_ROOT=$DONUT_HARDWARE_ROOT/action_examples/memcopy
```

If you call make w/o any targets then the environment is created and a simulation model build
as well as a card image build are kicked off.
In order to build a model and an image including the memcopy action example call:

```bash
    make ACTION_ROOT=$DONUT_HARDWARE_ROOT/action_examples/memcopy
```

If you want to build an image (a bitstream) for a given `ACTION_ROOT` you may call make with target image:

```bash
    make config image
```

Note: The decision if the memcopy action example gets included is made in the configuration step.
If the configuration step was already executed you may just call:

```bash
    make image
```

To build a binfile to program into a flash module, run the `write_bitstream.tcl` script from the `donut/hardware/build` directory:

```bash
    vivado -mode batch -source write_bitstream.tcl
```

A simulation model (for the simulator defined by the environment variable `SIMULATOR`) may be created
via the target model:

```bash
    make config model
```

Please refer to `$DONUT_HARDWARE_ROOT/Makefile` for more supported targets like clean, gitclean, create_environment, copy, ...

# Simulation

You may kick off simulation from within subdirectory sim using the script run_sim.
For the memcopy example (`ACTION_ROOT=$DONUT_HARDWARE_ROOT/action_examples/memcopy`) call:

```bash
    ./run_sim -app tools/stage2 -a2          # -a2 option passed to application by default
    ./run_sim -app tools/stage2 -a2 -t title # -t is a simulator option
    ./run_sim -app tools/stage2 -arg "-t"    # force argument being passed to application
```
