# Add vlib files
add_files -scan_for_includes $action_dir/vlibs/RANDFUNC.vlib -verbose
add_files -scan_for_includes $action_dir/vlibs/nv_assert_no_x.vlib -verbose
set_property file_type {Verilog} [get_files *.vlib]

# Use fifo in fifo directory
foreach fifo_file [glob -nocomplain -dir $action_dir/fifos *.v] {
    set fifo_file_name [exec basename $fifo_file]

    foreach tmp_file [get_files $fifo_file_name] {
        set dir_name [exec dirname $tmp_file]
        if {$dir_name != "$action_dir/fifos"} {
            puts "                        NOT from fifo directory: $fifo_file_name "
            remove_files $tmp_file
        }
    }
}

