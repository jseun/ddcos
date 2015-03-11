#!/bin/bash

/etc/init.d/mountkernfs.sh start
/etc/init.d/mountdevsubfs.sh start

ipconfig eth0
ipaddr=$(ifconfig eth0 | awk '/inet addr/ {gsub("addr:", "", $2); print $2}')

mkdir -p /tmp/ctrl; touch /tmp/ctrl/start

if mountpoint -q "/var" && test -x /etc/init.d/docker; then
  cd /tmp/ctrl
  while :
  do
    for cmd in *; do
      case "$cmd" in
        start|stop|restart)
          /etc/init.d/docker $cmd
          break
          ;;
        reboot|shutdown)
          /etc/init.d/docker stop
          /etc/init.d/mountdevsubfs.sh stop
          /etc/init.d/mountkernfs.sh stop
          exec "$@"
          ;;
        *) echo "Unknown command: $cmd"
          ;;
      esac
      rm -f $cmd
    done

    clear
    if /etc/init.d/docker status >/dev/null; then
      docker ps 2>/dev/null && echo && \
        echo "Docker is reachable at tcp://${ipaddr}:2375"
    else
      echo "Docker is not started."
    fi

    sleep 5
  done
elif [ -x "/install.sh" ]; then
  exec /install.sh
else
  echo "E: Operating system left unconfigured."
  /bin/bash --norc
fi

reboot
