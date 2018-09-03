set action_ipdir $::env(ACTION_ROOT)/ip
#add_files -scan_for_includes -norecurse $action_hw

#User IPs
foreach usr_ip [list \
                $action_ipdir/fifo_sync_32_512i512o  \
               ] {
  foreach usr_ip_xci [exec find $usr_ip -name *.xci] {
    puts "                        importing user IP $usr_ip_xci (in string_match core)"
    add_files -norecurse $usr_ip_xci >> $log_file
    export_ip_user_files -of_objects  [get_files "$usr_ip_xci"] -force >> $log_file
  }
}
