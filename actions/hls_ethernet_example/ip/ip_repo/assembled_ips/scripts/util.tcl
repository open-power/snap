proc addip {ipName displayName} {
	set vlnv_version_independent [get_ipdefs -filter "NAME == $ipName"]
	create_bd_cell -type ip -vlnv $vlnv_version_independent $displayName
}
