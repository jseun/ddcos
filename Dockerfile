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
    live-tools \
    linux-image-amd64 \
    firmware-linux-free \
    mdadm \
&& \
`### Bundle installer packages ###` \
scripts/bundle.sh "install" \
    grub2 \
    squashfs-tools \
    xorriso \
&& \
`### Bundle core packages ###` \
scripts/bundle.sh "core" \
    lxc-docker \
    apparmor \
    iptables \
    ssh \
    sudo \
&& \
`### Clean up ###` \
apt-get clean; rm -rf /var/lib/apt/lists/*"; \
rm -rf /usr/share/man; \
rm -rf /usr/share/locale; \
rm -rf /usr/share/doc

ENTRYPOINT ["/bin/dash", "-c"]
CMD ["/tmp/scripts/build.sh"]
VOLUME ["/data"]
COPY scripts /tmp/scripts
COPY isolinux /tmp/isolinux

ENV VERSION "8.0-1.0-dev"
