FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y \
    wget \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV NODE_EXPORTER_URL https://github.com/prometheus/node_exporter/releases/download/0.10.0/node_exporter-0.10.0.linux-amd64.tar.gz
RUN mkdir /opt/node_exporter
RUN wget -q "$NODE_EXPORTER_URL" -P /tmp && tar xf /tmp/node_exporter-0.10.0.linux-amd64.tar.gz -C /opt/node_exporter && rm -f /tmp/node_exporter-0.10.0.linux-amd64.tar.gz

RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]

EXPOSE 9100
