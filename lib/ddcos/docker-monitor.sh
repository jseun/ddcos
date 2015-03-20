#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin

trap "echo" SIGINT SIGTERM

while :
do
  clear
  docker ps
  echo
  ipaddr=$(ip addr sh eth0 | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
  echo "Docker is reachable at tcp://${ipaddr}:2375"
  sleep 1
done
