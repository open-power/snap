create_pblock donut
add_cells_to_pblock [get_pblocks donut] [get_cells -quiet [list a0/donut_i]] -clear_locs
resize_pblock [get_pblocks donut] -add {CLOCKREGION_X3Y3:CLOCKREGION_X5Y3}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks b]
set_property CONTAIN_ROUTING   1 [get_pblocks b]