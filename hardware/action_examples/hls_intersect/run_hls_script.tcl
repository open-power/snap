open_project "hlsIntersect_xcku060-ffva1156-2-e"

set_top hls_action

# Can that be a list?
foreach file [ list kernel.cpp  ] {
  add_files ${file} -cflags "-I../include"
}

open_solution "intersect"
set_part xcku060-ffva1156-2-e

create_clock -period 4 -name default
config_interface -m_axi_addr64=true
#config_rtl -reset all -reset_level low

csynth_design
exit
