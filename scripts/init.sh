#!/bin/bash

/etc/init.d/mountkernfs.sh start

while :
do
  if mountpoint -q "/var"; then
    exec docker -d -s aufs --host tcp://0.0.0.0:2375 --host unix:///var/run/docker.sock \
      -g /var/lib/docker
  elif [ -x "/install.sh" ]; then
    exec /install.sh
  else
    echo "E: Operating system left unconfigured."
    exec /bin/bash --norc
  fi
done
