#!/bin/bash

exec /bin/bash --norc </dev/console >/dev/console

cat <<EOF > ${ROOTFS}/etc/restartd.conf
docker ".*docker*" "docker -d -s aufs" "/bin/true"
EOF

exec /usr/sbin/restartd --debug --foreground
