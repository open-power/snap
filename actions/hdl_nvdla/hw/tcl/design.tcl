# Add vlib files
add_files -scan_for_includes $action_dir/vlibs/RANDFUNC.vlib -verbose
add_files -scan_for_includes $action_dir/vlibs/nv_assert_no_x.vlib -verbose
set_property file_type {Verilog} [get_files *.vlib]
set_property is_global_include true [get_files -of_objects [get_filesets sources_1] $action_dir/include/NV_NVDLA_global_include.vh]
set_property is_global_include true [get_files -of_objects [get_filesets sources_1] $action_dir/include/NV_NVDLA_global_include_syn.vh]
set_property is_global_include true [get_files -of_objects [get_filesets sources_1] $action_dir/defs/project.vh]
set_property file_type {Verilog} [get_files -of_objects [get_filesets sources_1] $action_dir/include/NV_NVDLA_global_include.vh]
set_property file_type {Verilog} [get_files -of_objects [get_filesets sources_1] $action_dir/include/NV_NVDLA_global_include_syn.vh]
set_property file_type {Verilog} [get_files -of_objects [get_filesets sources_1] $action_dir/defs/project.vh]

# Use fifo in fifo directory
foreach fifo_file [glob -nocomplain -dir $action_dir/fifos *.v] {
    set fifo_file_name [exec basename $fifo_file]

    foreach tmp_file [get_files $fifo_file_name] {
        set dir_name [exec dirname $tmp_file]
        if {$dir_name != "$action_dir/fifos"} {
            puts "                        NOT from fifo directory: $fifo_file_name " >> $log_file
            remove_files $tmp_file
        }
    }
}

set action_ipdir $::env(ACTION_ROOT)/fpga_ip

#User IPs
foreach usr_ip [glob -nocomplain -dir $action_ipdir *] {
    foreach usr_ip_xci [exec find $usr_ip -name *.xci] {
        set ip_name [file rootname [file tail $usr_ip_xci]]
        puts "                        importing user IP $ip_name (in nvdla)"
        add_files -norecurse $usr_ip_xci >> $log_file
        set_property generate_synth_checkpoint false [ get_files $usr_ip_xci] >> $log_file
        generate_target {instantiation_template}     [ get_files $usr_ip_xci] >> $log_file
        generate_target all                          [ get_files $usr_ip_xci] >> $log_file
        export_ip_user_files -of_objects             [ get_files $usr_ip_xci] -no_script -sync -force -quiet >> $log_file
    }
}

