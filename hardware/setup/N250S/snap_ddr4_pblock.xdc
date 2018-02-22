#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-----------------------------------------------------------
resize_pblock pblock_snap -add {BITSLICE_RX_TX_X1Y0:BITSLICE_RX_TX_X1Y155} -locs keep_all
resize_pblock pblock_snap -add {BITSLICE_CONTROL_X1Y0:BITSLICE_CONTROL_X1Y23} -locs keep_all
resize_pblock pblock_snap -add {PLLE3_ADV_X1Y0:PLLE3_ADV_X1Y5} -locs keep_all
resize_pblock pblock_snap -add {MMCME3_ADV_X1Y0:MMCME3_ADV_X1Y2} -locs keep_all
resize_pblock pblock_snap -add {HPIO_VREF_SITE_X1Y0:HPIO_VREF_SITE_X1Y5} -locs keep_all
add_cells_to_pblock pblock_snap [get_cells [list a0/ddr4sdram_bank]]
