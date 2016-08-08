FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

ENV DEBIAN_FRONTEND noninteractive
ENV GELINK https://github.com/GluuFederation/gluu-engine/archive/0.5.0-beta8.tar.gz

RUN apt-get update && apt-get install -y --force-yes \
    python \
    python-dev \
    python-pip \
    swig \
    libssl-dev \
    curl \
    openssh-client \
    openjdk-7-jre-headless \
    apt-transport-https \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "deb http://repo.gluu.org/ubuntu/ trusty-devel main" | tee /etc/apt/sources.list.d/gluu-repo.list
RUN curl -s https://repo.gluu.org/ubuntu/gluu-apt.key | apt-key add -

RUN apt-get update && apt-get install -y --force-yes \
    oxd-license-validator \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine && chmod +x /usr/local/bin/docker-machine

RUN mkdir -p /var/log/gluuengine /var/lib/gluuengine /etc/gunicorn /app

COPY gunicorn.conf.py /etc/gunicorn

RUN curl -L "$GELINK" > /tmp/ge.tar.gz \
    && tar -zxf /tmp/ge.tar.gz --strip-components=1 -C /app \
    && rm -f /tmp/ge.tar.gz

RUN pip install -U pip && pip install -r /app/requirements.txt

WORKDIR /app

ENTRYPOINT ["gunicorn", "--config", "file:/etc/gunicorn/gunicorn.conf.py", "wsgi:app"]

EXPOSE 8080
