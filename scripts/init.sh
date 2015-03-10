#!/bin/bash

/etc/init.d/mountkernfs.sh start
/etc/init.d/mountdevsubfs.sh start

ipconfig eth0
ipaddr=$(ifconfig eth0 | awk '/inet addr/ {gsub("addr:", "", $2); print $2}')

if mountpoint -q "/var" && test -x /etc/init.d/docker; then
  while [ ! -f /gracefull_system_reboot ];
  do
    if /etc/init.d/docker status >/dev/null; then
      clear
      docker ps 2>/dev/null && echo && \
        echo "Docker is reachable at tcp://${ipaddr}:2375"
    else
      /etc/init.d/docker start
    fi
    sleep 5
  done
  /etc/init.d/docker stop
elif [ -x "/install.sh" ]; then
  exec /install.sh
else
  echo "E: Operating system left unconfigured."
  /bin/bash --norc
fi

reboot
