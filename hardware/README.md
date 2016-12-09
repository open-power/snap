# Recommended directory structure

You need to define the environment variable `FRAMEWORK_ROOT` pointing to your local workspace base.
A script that may be sourced in order to set up the required environment variables
for a given `FRAMEWORK_ROOT` can be found here:

    ./setup/donut_settings

This script will define the following environment variables (if they are not already pre-defined
differently):

    FRAMEWORK_ROOT      = <your local workspace base>
    USERHOME            = $FRAMEWORK_ROOT/$USER                  # each user has his own workspace
    PSLSE_ROOT          = $USERHOME/pslse                        # PSLSE clone from github
    DONUT_ROOT          = $USERHOME/donut                        # donut clone from github
    DONUT_SOFTWARE_ROOT = $DONUT_ROOT/software                   # path to donut software
    DONUT_HARDWARE_ROOT = $DONUT_ROOT/hardware                   # path to donut hardware
    FPGACARD            = $FRAMEWORK_ROOT/card/<your hdk>        # path to card HDK

    SIMULATOR           = xsim                                   # currently supported simulators are xsim, ncsim

Besides the HDK for the card a DIMM test project is required which can be obtained from
the Alpha Data Support Portal:
`https://support.alpha-data.com/Portals/0/Downloads/dimm_test-admpcieku3-v3_0_0.tar.gz`

The environment variable `DIMMTEST` needs to point to the directory containing that project:

    DIMMTEST            = <path to dimm test project>

# Action wrapper

The path to the set of actions that shall be included is defined via the environment variable ACTION_ROOT.
Currently it has to point to a directory within `$DONUT_HARDWARE_ROOT/action_examples`.
This directory needs to contain an action_wrapper entity as interface between the actions and the SNAP framework.
Corresponding to the ports that the SNAP framework provides:
* an AXI master port for MMIO based control
* an AXI slave port for host DMA traffic
* an optional AXI slave port for on card DDR3 RAM traffic

the port map of the action_wrapper has to consist of the correspondig counterparts.  
Examples for actions together with their wrappers may be found in `$DONUT_HARDWARE_ROOT/action_examples/empty` and in `$DONUT_HARDWARE_ROOT/action_examples/memcopy`.

# DDR3 Card Memory

The SNAP framework supports the usage of the on-card DRAM. It is accessible for the actions via the action wrapper through an AXI master interface. The existence of that interface is configurable via the environment variable `DDR3_USED`. When setting

    DDR3_USED=TRUE

the interface will be instantiated and the access to the DDR3 memory will be provided.

The examples in `$DONUT_HARDWARE_ROOT/action_examples/empty` and in `$DONUT_HARDWARE_ROOT/action_examples/memcopy` show how the card memory can be connected via the action_wrapper. When `DDR3_USED` is not set to true all the lines containing the comment

    -- only for DDR3_USED=TRUE

will be removed in the build process during the step build config. If `DDR3_USED` is set to `TRUE` then these lines will stay active and the connection to the card memory will be established.

# Image and model build

In order to prepare the vivado environment for this project call:

    make config

from within `$DONUT_HARDWARE_ROOT`. Pre-requisite for this is that the environment variables for this project
are defined (e.g. by sourcing the ./setup/donut_settings script).
The variable `SIMULATOR` is used to determine for which of the simulators xsim or ncsim
the environment will be prepared. 

If the variable `ACTION_ROOT` is not set the make process will set it to `$DONUT_HARDWARE_ROOT/action_examples/empty`
containing a dummy action wrapper file that drives zeros on all interfaces.
A memcopy action example will be included if the environment variable  is set to
`$DONUT_HARDWARE_ROOT/action_examples/memcopy`.
As usual you may set the variable with the call of make:

    make config ACTION_ROOT=$DONUT_HARDWARE_ROOT/action_examples/memcopy

If you call make w/o any targets then the environment is created and a simulation model build
as well as a card image build are kicked off.
In order to build a model and an image including the memcopy action example call:

    make ACTION_ROOT=$DONUT_HARDWARE_ROOT/action_examples/memcopy

If you want to build an image (a bitstream) for a given `ACTION_ROOT` you may call make with target image:

    make config image

Note: The decision if the memcopy action example gets included is made in the configuration step.
If the configuration step was already executed you may just call:

    make image

A simulation model (for the simulator defined by the environment variable `SIMULATOR`) may be created
via the target model:

    make config model

Please refer to `$DONUT_HARDWARE_ROOT/Makefile` for more supported targets like clean, gitclean, create_environment, copy, ...

# Simulation

You may kick off simulation from within subdirectory sim using the script run_sim.
For the memcopy example (`ACTION_ROOT=$DONUT_HARDWARE_ROOT/action_examples/memcopy`) call:

    ./run_sim -app "tools/stage2 -a 2"
