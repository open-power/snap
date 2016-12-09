set_property EXCLUDE_PLACEMENT 1 [get_pblocks b_baseimg]
set_property CONTAIN_ROUTING   1 [get_pblocks b_baseimg]
opt_design -directive Explore
place_design -directive Explore
phys_opt_design -force_replication_on_nets [get_nets -hierarchical *rstn*]
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
