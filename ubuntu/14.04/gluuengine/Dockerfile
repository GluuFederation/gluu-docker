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
    openjdk-7-jre-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/oxlicense-validator
RUN curl -L http://ox.gluu.org/maven/org/xdi/oxlicense-validator/2.4.4.sp1/oxlicense-validator-2.4.4.sp1-jar-with-dependencies.jar > /usr/share/oxlicense-validator/oxlicense-validator.jar

RUN curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine && chmod +x /usr/local/bin/docker-machine

RUN mkdir -p /var/log/gluuengine /var/lib/gluuengine /app

ENV GELINK https://github.com/GluuFederation/gluu-engine/archive/0.5.2.tar.gz

RUN curl -L "$GELINK" > /tmp/ge.tar.gz \
    && tar -zxf /tmp/ge.tar.gz --strip-components=1 -C /app \
    && rm -f /tmp/ge.tar.gz

RUN pip install -U pip

# A workaround to address https://github.com/docker/docker-py/issues/1054
# and to make sure latest pip is being used, not from OS one
ENV PYTHONPATH="/usr/local/lib/python2.7/dist-packages:/usr/lib/python2.7/dist-packages"

WORKDIR /app

RUN pip install -r requirements.txt && python setup.py develop

ENTRYPOINT ["gunicorn", "-c", "python:gluuengine.gsettings", "wsgi:app"]

EXPOSE 8080
