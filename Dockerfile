#
# Debian Docker Core OS
#
FROM debian:8.0
MAINTAINER Samuel Jean "jamael.seun@gmail.com"

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/scripts/entrypoint.sh run"]

ADD scripts/config /scripts/
ADD scripts/functions /scripts/
ADD scripts/entrypoint.sh /scripts/
ADD scripts/build/ /scripts/build/
RUN /scripts/entrypoint.sh build

ENV DATADIR /data
VOLUME ["/data"]
ENV PUBLISHER github.com/jseun
ENV DISTNAME ddcos
ENV VERSION 8.0-1.1-dev
ADD etc/ /etc
ADD lib/ /lib
ADD scripts/run/ /scripts/run/
ADD isolinux/ /tmp/isolinux
