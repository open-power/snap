#!/bin/bash
#
# Copyright 2017 International Business Machines
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
cd ${PSLSE_ROOT}
version=`git describe --tags`
branch=`git branch`
echo "checking PSLSE_ROOT=${PSLSE_ROOT} card=$FPGACARD version=$version branch=$branch"
case $FPGACARD in
  "N250SP") if [ $branch != "\* capi2" ];then echo "WARNING: PSLSE branch=$branch should be capi2";fi;;
  *)        if [ $version != "v3.1"    ];then echo "WARNING: PSLSE version=$(version) should be v3.1";fi;;
esac
cd -
