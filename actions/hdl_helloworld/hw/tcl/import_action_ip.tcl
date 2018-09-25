set action_ipdir $::env(ACTION_ROOT)/ip/action_ip_prj/action_ip_prj.srcs/sources_1/ip

set_property target_simulator IES [current_project]

#Import User IPs
foreach usr_ip [glob -nocomplain -dir $action_ipdir *] {
    foreach usr_ip_xci [exec find $usr_ip -name *.xci] {
        set ip_name [file rootname [file tail $usr_ip_xci]]
        puts "                        importing user IP $ip_name (in hdl_pie)"
        add_files -norecurse $usr_ip_xci >> $log_file
        set_property generate_synth_checkpoint false [ get_files $usr_ip_xci] >> $log_file
#generate_target {instantiation_template}     [ get_files $usr_ip_xci] >> $log_file
#generate_target all                          [ get_files $usr_ip_xci] >> $log_file
        export_ip_user_files -of_objects             [ get_files $usr_ip_xci] -no_script -sync -force -quiet >> $log_file
    }
}
