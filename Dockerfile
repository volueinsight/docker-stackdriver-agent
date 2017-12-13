FROM debian:stretch-slim

COPY install-monitoring-agent.sh /

RUN set -eu \
    && mkdir /usr/share/man/man1/ \
    && apt-get update \
    && apt-get install -y -q \
       apt-utils \
       curl \
       gnupg \
       lsb-base lsb-compat lsb-release \
       openjdk-8-jdk-headless \
    && sh -x /install-monitoring-agent.sh

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
COPY collectd.conf.tmpl /opt/stackdriver/collectd/etc/
COPY cassandra-22.conf /opt/stackdriver/collectd/etc/collectd.d/

ENTRYPOINT [ "/docker-entrypoint.sh" ]
