#!/bin/bash

if [ $DDR3_USED == "TRUE" ]; then
sed -i '/-- only for DDR3_USED!=TRUE/d' $1/$2
else
sed -i '/-- only for DDR3_USED=TRUE/d' $1/$2
fi
