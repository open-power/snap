create_pblock pblock_snap
resize_pblock pblock_snap -add CLOCKREGION_X3Y0:CLOCKREGION_X3Y4
add_cells_to_pblock pblock_snap [get_cells [list a0/snap_core_i]] -clear_locs
