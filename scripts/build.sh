#!/bin/bash

#rm -f /tmp/bootstrap/linux-*
#echo -n "Unpacking bootstrap bundle... "
#dpkg -i /tmp/bootstrap/* >/dev/null 2>&1
#echo "done"
echo $SHELL
source /tmp/scripts/functions
run_scripts /tmp/scripts/build
