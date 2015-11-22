FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

RUN echo "deb http://repo.gluu.org/ubuntu/ trusty-devel main" > /etc/apt/sources.list.d/gluu-repo.list

RUN apt-get update && apt-get install -y --force-yes \
    gluu-cluster-webui \
    supervisor \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl http://repo.gluu.org/ubuntu/gluu-apt.key | apt-key add -

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN a2dissite 000-default

CMD ["/usr/bin/supervisord"]

EXPOSE 8800