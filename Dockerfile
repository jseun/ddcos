#
# Debian Docker Core OS
#
FROM debian:8.0
MAINTAINER Samuel Jean "jamael.seun@gmail.com"

COPY scripts/bundle.sh /tmp/scripts/
RUN /bin/dash -xc "cd /tmp; \
`### Update repositories ###` \
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys \
    36A1D7869245C8950F966E92D8576A8BA88D21E9 && \
printf 'deb http://get.docker.io/ubuntu/ docker main\n' > \
    /etc/apt/sources.list.d/docker.list && \
printf 'APT::Install-Recommends "0";\n' > \
    /etc/apt/apt.conf.d/99no-install-recommends && \
printf 'Acquire::Languages "none";\n' > \
    /etc/apt/apt.conf.d/99no-translations && \
apt-get update && \
echo 'debconf debconf/frontend select Noninteractive' | \
    debconf-set-selections \
&& \
`### Install primary tools ###` \
apt-get install -qqy \
    whiptail \
&& \
`### Bundle boot packages ###` \
scripts/bundle.sh "boot" \
    live-boot \
    linux-image-amd64 \
    mdadm \
&& \
`### Bundle iso packages ###` \
scripts/bundle.sh "iso" \
    isolinux \
    squashfs-tools \
    xorriso \
&& \
`### Bundle core packages ###` \
scripts/bundle.sh "core" \
    grub2 \
    lxc-docker \
    apparmor \
    iptables \
    ssh \
    sudo \
&& \
`### Clean up ###` \
apt-get clean; rm -rf /var/lib/apt/lists/*"; \
rm -rf /usr/share/man; rm -rf /usr/share/zoneinfo; \
rm -rf /usr/share/locale; rm -rf /usr/share/doc

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/scripts/build.sh"]
VOLUME ["/tmp", "/data"]
COPY scripts /scripts

ENV VERSION "8.0-1.0-dev"
