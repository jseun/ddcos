#!/bin/sh

echo -n "Unpacking bootstrap bundle... "
dpkg -i /tmp/bootstrap/initramfs-tools* >/dev/null 2>&1
echo "done"

. /tmp/scripts/functions
run_scripts /tmp/scripts/build
