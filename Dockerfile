#
# Debian Docker Core OS
#
FROM debian:8.0
MAINTAINER Samuel Jean "jamael.seun@gmail.com"

RUN /bin/sh -xc "\
`### Update repositories ###` \
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
`### Download live packages ###` \
mkdir -p /tmp/live; (cd /tmp/live; apt-get -sy install \
    live-boot \
    live-tools \
    linux-image-amd64 \
    firmware-linux-free \
    mdadm \
| awk '/^Inst /{print \$2}' | xargs apt-get download) \
&& \
`### Clean up ###` \
apt-get clean; rm -rf /var/lib/apt/lists/*; \
rm -rf /usr/share/man; \
rm -rf /usr/share/locale; \
rm -rf /usr/share/doc"

ENTRYPOINT ["/bin/dash", "-c"]
CMD ["/tmp/scripts/build.sh"]
VOLUME ["/data"]
COPY scripts /tmp/scripts
COPY isolinux /tmp/isolinux

ENV VERSION "8.0-1.0-dev"
