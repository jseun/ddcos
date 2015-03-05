#
# Debian Docker Core OS
#
FROM debian:8.0
MAINTAINER Samuel Jean "jamael.seun@gmail.com"

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/scripts/entrypoint.sh", "run"]

ADD scripts/functions /scripts/
ADD scripts/entrypoint.sh /scripts/
ADD scripts/build/ /scripts/build/
RUN /scripts/entrypoint.sh build

ENV DATADIR /data
VOLUME ["/data"]
ENV VERSION "8.0-1.0-dev"
ADD scripts/run/ /scripts/run/
ADD isolinux /tmp/
