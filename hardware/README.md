# Recommended directory structure:

    FRAMEWORK_ROOT      = <your local workspace base>
    USERHOME            = $FRAMEWORK_ROOT/$USER           # each user has his own workspace
    PSLSE_ROOT          = $USERHOME/pslse                 # PSLSE clone from github
    DONUT_ROOT          = $USERHOME/donut                 # donut clone from github
    DONUT_SOFTWARE_ROOT = $DONUT_ROOT/software            # path to donut software
    DONUT_HARDWARE_ROOT = $DONUT_ROOT/hardware            # path to donut hardware
    FPGACARD            = $FRAMEWORK_ROOT/card/<your hdk> # path to card HDK

A script that may be sourced in order to set up the corresponding environment variables
for a given FRAMEWORK_ROOT can be found here:

    ./setup/donut_settings

# Image and model build

In order to prepare the vivado environment for this project call

    make create_environment

from within ./setup. Pre-requisite for this is that the environment variables for this project
are defined (e.g. by sourcing the ./setup/donut_settings script).
The variable SIMULATOR is used by create_environment in order to determine for which of the
simulators xsim, questa or ncsim the environment will be prepared. 

A memcopy action example will be included if the environment variable EXAMPLE is defined:

    make create_environment EXAMPLE=1

If you call make w/o any targets then the environment is created and an image build is kicked off.
In order to build an image including the memcopy action example call:

    make EXAMPLE=1

If you want to build an image after the environment was prepared already you may skip the step
create_environment and call make with target build:

    make build

(Note: the decision if the memcopy action example gets included is made in the create_environment
step.)

Please refer to ./setup/Makefile for the more supported targets like clean, config, copy, ...

# Simulation

You may kick off simulation from within subdirectory sim using the script run_sim.
For a memcopy example (after creating the environment with option -e) call:

    ./run_sim -app "tools/stage2 -a 2"
