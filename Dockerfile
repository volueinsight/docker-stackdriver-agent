FROM debian:stretch-slim

COPY install-monitoring-agent.sh /
COPY run.sh /

RUN set -eu \
    && mkdir /usr/share/man/man1/ \
    && apt-get update \
    && apt-get install -y -q \
       apt-utils \
       curl \
       gnupg \
       bash \
       lsb-base lsb-compat lsb-release \
       openjdk-8-jdk-headless \
    && sh -x /install-monitoring-agent.sh \
    && chmod +x /run.sh

COPY default_stackdriver-agent /etc/default/stackdriver-agent
COPY collectd.conf.tmpl /opt/stackdriver/collectd/etc/
COPY cassandra-22.conf /opt/stackdriver/collectd/etc/collectd.d/

CMD [ "/run.sh" ]
