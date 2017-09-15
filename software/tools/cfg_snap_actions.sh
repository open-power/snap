#!/bin/bash
############################################################################
############################################################################
##
## Copyright 2017 International Business Machines
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE#2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions AND
## limitations under the License.
##
############################################################################
############################################################################
#

snapdir=$(dirname $(dirname $(dirname $(readlink -f "$BASH_SOURCE")))) # SNAP root directory
ACTION_TYPES_FILE=$snapdir/ActionTypes.md
SNAP_ACTIONS_H=$snapdir/software/tools/snap_actions.h
SNAP_ACTIONS_TMP=$SNAP_ACTIONS_H.tmp

grep '\(|[ ^I]*\([0-9A-Fa-f]\{2\}\.\)\{3\}[0-9A-Fa-f]\{2\}[ ^I]*\)\{2\}|' $ACTION_TYPES_FILE | sed 's/\(.*\)[ ^I]|[ ^I]\([0-9A-Fa-f]\{2\}\)\.\([0-9A-Fa-f]\{2\}\)\.\([0-9A-Fa-f]\{2\}\)\.\([0-9A-Fa-f]\{2\}\)[ ^I]|[ ^I]\([0-9A-Fa-f]\{2\}\.[0-9A-Fa-f]\{2\}\.[0-9A-Fa-f]\{2\}\.[0-9A-Fa-f]\{2\}\)[ ^I]|[ ^I]\(.*\)/  \{\"\1\"\, 0x\2\3\4\5\, 0x\6\, \"\7\"\},/' | sed 's/\(.* 0x[0-9A-Fa-f]\{8\}\, 0x\)\([0-9A-Fa-f]\{2\}\)\.\([0-9A-Fa-f]\{2\}\)\.\([0-9A-Fa-f]\{2\}\)\.\([0-9A-Fa-f]\{2\}\)\(.*\)/\1\2\3\4\5\6/' | sed '$ s/\"},/\"}/' > $SNAP_ACTIONS_TMP

sed '/struct[ ^I]actions_tab[ ^I]snap_actions/ r '$SNAP_ACTIONS_TMP <"$SNAP_ACTIONS_H"_template >$SNAP_ACTIONS_H

rm -f $SNAP_ACTIONS_TMP
