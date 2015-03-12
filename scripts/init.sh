#!/bin/bash

/etc/init.d/mountkernfs.sh start
/etc/init.d/mountdevsubfs.sh start
/etc/init.d/procps start

ipconfig eth0
ipaddr=$(ifconfig eth0 | awk '/inet addr/ {gsub("addr:", "", $2); print $2}')

mkdir -p /tmp/ctrl; touch /tmp/ctrl/start

if mountpoint -q "/var/lib/docker" && test -x /etc/init.d/docker; then
  cd /tmp/ctrl
  while :
  do
    for cmd in *; do
      case "$cmd" in
        start|restart)
          /etc/init.d/docker $cmd
          ;;
        reboot|shutdown)
          /etc/init.d/docker stop
          /etc/init.d/mountdevsubfs.sh stop
          /etc/init.d/mountkernfs.sh stop
          $cmd
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
      echo "Docker failed to start. Here's the last 10 lines of /var/log/docker.log"
      echo; tail -10 /var/log/docker.log; echo
      echo; echo "Use 'touch /tmp/ctrl/start; exit' to start again."
      /bin/bash --norc
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
