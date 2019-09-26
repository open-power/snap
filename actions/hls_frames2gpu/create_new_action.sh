#!/bin/bash
bold=$(tput bold)
normal=$(tput sgr0)
if [[ $1 == "-h" ]] || [[ $1 == "h" ]] || [[ $1 == "help" ]]
then
  echo "usage: ${bold}./reset_action.sh <new_action_name> <new_action_type>${normal}"
  echo "Prior to launch go SNAP dir : change hls_newaction directory name to <new_action_name>"
  echo "cd <SNAP_ROOT>/actions/<new_action_name>; cp -r ../hls_helloworld/* .;"
  echo "${bold}./reset_action.sh <new_action_name> <new_action_type>${normal}"
  echo "<new_action_name> default to be the same as the folder name."
  echo "<new_action_type> default to be 0x00000001"
  echo "after script run please edit <SNAP_ROOT>/scripts/Kconfig to update with your configuration, DRAM y/n, etc...."
  echo "then update <SNAP_ROOT>/ActionTypes.md to register your ID" 
  exit 0
fi
echo "${bold}[reset] START${normal}"
#remove unrelated files
files=$(shopt -s nullglob dotglob; echo doc/*)
if (( ${#files} ))
then
  rm doc/*
fi
files=$(shopt -s nullglob dotglob; echo tests/*)
if (( ${#files} ))
then
  rm tests/*
fi
echo "[reset] Remove doc/* and tests/* files."
#get newaction name : defualt to be the same as folder name
newActionName=$(echo "${PWD##*/}")
if [[ $newActionName == "hls_helloworld" ]]
then 
  if [[ $# -eq 0 ]] #change the newName to the 1st argument
  then
    echo "[reset] Please give a new action name(1st argument) as running this script."
    echo "[reset]${bold}FAIL${normal}"
    exit 1 
  fi
  $newActionName=$1
fi
echo "[reset] Setup for new action called $newActionName."
newNameShort=$(echo $newActionName | sed -E 's/hls_//1') #remove the "hls_" prefix in the name
###############################
# adapt the include directory #
###############################
commonHeaderFileName="include/"$newNameShort"_commonheader.h"
echo "${bold}[reset]${normal} Building ${bold}include${normal} directory."
oldCommonHeader="include/action_changecase.h"
if [[ -e $oldCommonHeader ]]
then
  mv $oldCommonHeader $commonHeaderFileName 
fi 
#change the ActionTypes in $commonHeaderFileName
newActionType=${newNameShort^^}"_ACTION_TYPE"
if [[ $# -lt 2 ]]
then # ActionType default to be 0x00000001
  echo "[reset] Set the ActionType to 0x00000001."
  sed -i "s/HELLOWORLD_ACTION_TYPE 0x10141008/$newActionType 0x00000001/g" $commonHeaderFileName
else # change the ActionType to be the 2nd argument
  echo "[reset] Set the ActionType to "$newActionNum
  sed -i "s/HELLOWORLD_ACTION_TYPE 0x10141008/$newActionType $2/g" $commonHeaderFileName
fi
#change the struct
newDataStruct=$newNameShort"_job"
echo "[reset] Change the structure exchanged between action and application."
sed -i "s/helloworld_job/$newDataStruct/g" $commonHeaderFileName
#change the MACRO
sed -i "s/ACTION_CHANGECASE_H/NEWACTION_COMMONHEADER_H/g" $commonHeaderFileName
##########################
# adapt the sw directory #
##########################
newSoftwareFile="sw/"$newNameShort"_software.c"
newSoftwareActionFile="sw/snap_"$newNameShort".c"
echo "${bold}[reset]${normal} Building ${bold}sw${normal} directory."
if [[ -e "sw/action_lowercase.c" ]]
then 
  mv sw/action_lowercase.c $newSoftwareFile
fi
if [[ -e "sw/snap_helloworld.c" ]]
then
  mv sw/snap_helloworld.c $newSoftwareActionFile
fi
#change the makefile
newSoftware=$newNameShort"_software"
newSoftwareAction="snap_"$newNameShort
sed -i "s/snap_helloworld/$newSoftwareAction/g" sw/Makefile
sed -i "s/action_lowercase/$newSoftware/g" sw/Makefile
echo "[reset] Update the sw/Makefile."
#change the $newSoftwareFile
commonHeader=$newNameShort"_commonheader"
sed -i "s/action_changecase/$commonHeader/g" $newSoftwareFile
sed -i "s/helloworld_job/$newDataStruct/g" $newSoftwareFile
sed -i "s/HELLOWORLD_ACTION_TYPE/$newActionType/g" $newSoftwareFile
echo "[reset] Update the $newSoftwareFile"
#change the $newSoftwareActionFile
sed -i "s/action_changecase/$commonHeader/g" $newSoftwareActionFile
sed -i "s/helloworld_job/$newDataStruct/g" $newSoftwareActionFile
sed -i "s/HELLOWORLD_ACTION_TYPE/$newActionType/g" $newSoftwareActionFile 
sed -i "s/snap_helloworld/$newSoftwareAction/g" $newSoftwareActionFile
sed -i "s/hls_helloworld/$newActionName/g" $newSoftwareActionFile
sed -i "s/helloworld/$newNameShort/g" $newSoftwareActionFile
echo "[reset] Update the $newSoftwareActionFile"
##########################
# adapt the hw directory #
##########################
newHardwareActionFile="hw/"$newNameShort"_hardware.cpp"
newHardwareHeaderFile="hw/"$newNameShort"_hardware.H"
echo "${bold}[reset]${normal} Building ${bold}hw${normal} directory."
if [[ -e "hw/action_uppercase.cpp" ]]
then 
  mv hw/action_uppercase.cpp $newHardwareActionFile
fi
if [[ -e "hw/action_uppercase.H" ]]
then
  mv hw/action_uppercase.H $newHardwareHeaderFile
fi
#change the makefile
SOLUTION_NAME=$newNameShort
SOLUTION_DIR="hls"$newNameShort
newHardwareAction=$newNameShort"_hardware"
sed -i "s/helloworld/$SOLUTION_NAME/g" hw/Makefile
sed -i "s/hlsUpperCase/$SOLUTION_DIR/g" hw/Makefile
sed -i "s/action_uppercase/$newHardwareAction/g" hw/Makefile
echo "[reset] Update the hw/Makefile."
#change the $newHardwareActionFile
sed -i "s/action_uppercase/$newHardwareAction/g" $newHardwareActionFile
sed -i "s/HELLOWORLD_ACTION_TYPE/$newActionType/g" $newHardwareActionFile
#change the $newHardwareHeaderFile 
sed -i "s/action_changecase/$commonHeader/g" $newHardwareHeaderFile
sed -i "s/helloworld_job/$newDataStruct/g" $newHardwareHeaderFile
sed -i "s/ACTION_UPPERCASE_H/${newHardwareAction^^}_H/g" $newHardwareHeaderFile
sed -i "s/action_change_case/$commonHeader/g" $newHardwareHeaderFile
sed -i "s/hls_helloworld/$newActionName/g" $newHardwareHeaderFile
