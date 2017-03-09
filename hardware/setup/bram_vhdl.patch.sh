#!/bin/bash
#
# Copyright 2017, International Business Machines
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
###############################################################################

sed -i '/ENTITY psl_fpga IS/,/PORT/ {
  /ENTITY psl_fpga IS/n
  /PORT/ a\
       refclk200_p        : in      std_logic;\
       refclk200_n        : in      std_logic;
}' $1
 
sed -i '/ah_cvalid =>/ i\
         refclk200_n     => refclk200_n,\
         refclk200_p     => refclk200_p,' $1

