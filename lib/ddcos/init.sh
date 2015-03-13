#!/bin/bash

if mountpoint -q "/var/lib/docker" && \
  test -f /etc/init/docker.conf; then
  exec /sbin/init
elif [ -x "/lib/ddcos/install.sh" ]; then
  exec /lib/ddcos/install.sh
fi
echo "E: Operating system left unconfigured."
/bin/bash --norc
reboot
