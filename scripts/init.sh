#!/bin/bash

/etc/init.d/mountkernfs.sh start

[ -x "/install.sh" ] && exec /install.sh

while :
do
  if mountpoint -q "/var"; then
    exec docker -d -s aufs --host tcp://0.0.0.0:2375 --host unix:///var/run/docker.sock \
      -g /var/lib/docker --ipv6=false --registry-mirror docker.idsmicronet.com
  else
    echo "E: /var/lib/docker must be mounted."
    exec /bin/bash --norc
  fi
done
