# Recommended directory structure:

You need to define the environment variable FRAMEWORK_ROOT pointing to your local workspace base.
A script that may be sourced in order to set up the required environment variables
for a given FRAMEWORK_ROOT can be found here:

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
https://support.alpha-data.com/Portals/0/Downloads/dimm_test-admpcieku3-v3_0_0.tar.gz

The environment variable DIMMTEST needs to point to the directory containing that project:

    DIMMTEST            = <path to dimm test project>

# Image and model build

In order to prepare the vivado environment for this project call:

    make config

from within ./setup. Pre-requisite for this is that the environment variables for this project
are defined (e.g. by sourcing the ./setup/donut_settings script).
The variable SIMULATOR is used to determine for which of the simulators xsim or ncsim
the environment will be prepared. 

A memcopy action example will be included if the environment variable EXAMPLE is defined:

    make config EXAMPLE=1

If you call make w/o any targets then the environment is created and an image build is kicked off.
In order to build an image including the memcopy action example call:

    make EXAMPLE=1

If you want to build an image (a bitstream) you may call make with target image:

    make config image

Note: The decision if the memcopy action example gets included is made in the configuration step.
If the configuration step was already executed you may just call:

    make image

To build a binfile to program into a flash module, run the `write_bitstream.tcl` script from the `donut/hardware/build` directory:

    vivado -mode batch -source write_bitstream.tcl

A simulation model (for the simulator defined by the environment variable SIMULATOR) may be created
via the target model:

    make config model

Please refer to ./setup/Makefile for more supported targets like clean, create_environment, copy, ...

# Simulation

You may kick off simulation from within subdirectory sim using the script run_sim.
For a memcopy example (after building the simulation model with EXAMPLE=1) call:

    ./run_sim -app "tools/stage2 -a 2"
