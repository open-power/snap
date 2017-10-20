set clock_constraint { \
    name clk \
    module hls_action \
    port ap_clk \
    period 4 \
    uncertainty 0.5 \
}

set all_path {}

set false_path {}

