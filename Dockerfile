#
# Debian Docker Core OS
#
FROM debian:8.0
MAINTAINER Samuel Jean "jamael.seun@gmail.com"

COPY scripts/bundle.sh /tmp/scripts/
RUN /bin/dash -xc "cd /tmp; \
`### Update repositories ###` \
printf 'APT::Install-Recommends "0";\n' > \
    /etc/apt/apt.conf.d/99no-install-recommends && \
printf 'Acquire::Languages "none";\n' > \
    /etc/apt/apt.conf.d/99no-translations && \
apt-get update \
&& \
`### Install primary tools ###` \
DEBIAN_FRONTEND=noninteractive apt-get install -qqy \
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
    syslinux \
    squashfs-tools \
    xorriso \
&& \
`### Bundle core packages ###` \
scripts/bundle.sh "core" \
    grub2 \
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
CMD ["/tmp/scripts/build.sh"]
ENV VERSION "8.0-1.0-dev"
COPY scripts /tmp/scripts/
