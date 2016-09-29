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

Kick off simulation from subdirectory sim using the script run_sim
For a memcopy example (after creating the environment with option -e) call:
run_sim -app "tools/stage2 -m 2"
