Recommended directory structure:

    FRAMEWORK_ROOT      = <your local workspace base>
    USERHOME            = $FRAMEWORK_ROOT/$USER           # each user has his own workspace
    PSLSE_ROOT          = $USERHOME/pslse                 # PSLSE clone from github
    DONUT_ROOT          = $USERHOME/donut                 # donut clone from github
    DONUT_SOFTWARE_ROOT = $DONUT_ROOT/software            # path to donut software
    DONUT_HARDWARE_ROOT = $DONUT_ROOT/hardware            # path to donut hardware
    FPGACARD            = $FRAMEWORK_ROOT/card/<your hdk> # path to card HDK

A script to set up the corresponding environment variables for a given FRAMEWORK_ROOT can be
found here:

    ./setup/donut_settings

Create the environment after environment variables are set (e.g. via ./setup/donut_settings):

    ./setup/create_environment

If you want to include the memcopy action example you need to pass option -e to this script:

    ./setup/create_environment -e

Instead of calling create_environment you may also call make from within ./setup. Pre-requisite
for this is that the environment variables for this project are defined (e.g. by calling the
donut_settings script). The memcopy example will be included if the environment variable EXAMPLE
is defined.

    make create_environment

The memcopy action example will be included if the environment variable EXAMPLE is defined.

    make create_environment EXAMPLE=1

If you call make w/o any targets then the image build is kicked off. In order to build an image
including the memcopy action example call

    make EXAMPLE=1

Kick off simulation from subdirectory sim using the script run_sim.
For a memcopy example (after creating the environment with option -e) call:

    ./run_sim -app "tools/stage2 -m 2"
