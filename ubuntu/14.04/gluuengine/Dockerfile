FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --force-yes \
    python \
    python-dev \
    python-pip \
    swig \
    libssl-dev \
    curl \
    openssh-client \
#    openjdk-7-jre-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#RUN echo "deb http://repo.gluu.org/ubuntu/ trusty-devel main" | tee /etc/apt/sources.list.d/gluu-repo.list
#RUN curl -s https://repo.gluu.org/ubuntu/gluu-apt.key | apt-key add -

#RUN apt-get update && apt-get install -y --force-yes \
#    oxd-license-validator \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/*

RUN pip install -U pip
ADD https://raw.githubusercontent.com/GluuFederation/gluu-engine/master/requirements.txt /tmp
RUN pip install -r /tmp/requirements.txt

RUN curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine
RUN chmod +x /usr/local/bin/docker-machine

RUN mkdir -p /var/log/gluuengine
RUN mkdir -p /var/lib/gluuengine
RUN mkdir -p /app

WORKDIR /app

CMD gunicorn -w $(($(nproc)*2+1)) --threads $(($(nproc)*2+1)) -k gthread -b :8080 --log-level warning --access-logfile - --error-logfile - -e API_ENV=prod wsgi:app

EXPOSE 8080

