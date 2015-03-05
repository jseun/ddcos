#
# Debian Docker Core OS
#
FROM debian:8.0
MAINTAINER Samuel Jean "jamael.seun@gmail.com"

ENTRYPOINT ["/bin/dash", "-c"]
CMD ["/scripts/entrypoint.sh", "run"]

COPY scripts /scripts
RUN /scripts/entrypoint.sh build

ENV DATADIR /data
VOLUME ["/data"]

COPY isolinux /tmp/isolinux
ENV VERSION "8.0-1.0-dev"
