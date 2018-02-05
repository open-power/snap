set action_hw $::env(ACTION_ROOT)/hw
set verilog_dir  $::env(ACTION_ROOT)/hw/verilog

add_files -scan_for_includes -norecurse $action_hw
add_files -scan_for_includes -norecurse $verilog_dir/snap_adapter
add_files -scan_for_includes -norecurse $verilog_dir/core

#User IPs
foreach usr_ip [list \
                $verilog_dir/core/ip/bram_1744x16                   \
                $verilog_dir/core/ip/bram_dual_port_512x32          \
                $verilog_dir/core/ip/fifo_48x16_async               \
                $verilog_dir/core/ip/fifo_512x64_sync_bram          \
                $verilog_dir/core/ip/fifo_80x16_async               \
                $verilog_dir/core/ip/unit_fifo_48x16_async          \
                $verilog_dir/snap_adapter/ip/fifo_sync_32_512i512o  \
                $verilog_dir/snap_adapter/ip/ram_512i_512o_dual_64  \
               ] {
  foreach usr_ip_xci [exec find $usr_ip -name *.xci] {
    puts "                        importing user IP $usr_ip_xci (in string_match core)"
    add_files -norecurse $usr_ip_xci >> $log_file
    set_property generate_synth_checkpoint false  [get_files "$usr_ip_xci"]
    export_ip_user_files -of_objects  [get_files "$usr_ip_xci"] -force >> $log_file
  }
}

