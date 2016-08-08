FROM ubuntu:14.04

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y --force-yes \
    curl \
    unzip \
    python \
    python-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app

RUN curl -L https://github.com/GluuFederation/gluu-webui/archive/master.zip > /tmp/webui.zip \
    && unzip /tmp/webui.zip -d /tmp \
    && mv /tmp/gluu-webui-master/* /app \
    && rm -rf /tmp/webui.zip /tmp/gluu-webui-master

WORKDIR /app

RUN pip install -U pip
RUN pip install -r requirements/prod.txt
RUN pip install gunicorn

ENTRYPOINT ["gunicorn", "-b", ":8800", "--access-logfile", "-", "--error-logfile", "-", "gluuwebui:app"]

EXPOSE 8800
