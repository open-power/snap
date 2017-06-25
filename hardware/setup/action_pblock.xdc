create_pblock pblock_action
resize_pblock pblock_action -add CLOCKREGION_X0Y0:CLOCKREGION_X2Y2
add_cells_to_pblock pblock_action [get_cells [list a0/action_w]] -clear_locs
