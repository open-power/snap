# How to link to the string-match IP

## 1. Git Clone string-match IP (Private)
```
git clone git@github.ibm.com:shgoupf/string-match-fpga.git -b <BRANCH_NAME>
```

## 2. After `make snap_config`, set following variables in snap_env.sh

```
export STRING_MATCH_VERILOG=<.....Local Path.....>/string-match-fpga/verilog
export USER_DEFINED_DESIGN=TRUE
export USER_DEFINED_TCLPATH=${ACTION_ROOT}/hw/tcl
```

## 3. Continue build model for simulation and so on.
```
make model
make sim
```

$ACTION_ROOT/tests/test_*.sh can be used for a quick simulation.

## 4. Build image. 

Current it is under testing only on vivado2017.4 and S121B card.

