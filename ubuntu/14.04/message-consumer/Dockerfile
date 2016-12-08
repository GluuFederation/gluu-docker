FROM ubuntu:14.04

MAINTAINER Isman <isman@gluu.org>

# JDK 8 repo
RUN echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86F44E2A

RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    maven \
    wget \
    unzip \
    && apt-get remove -y openjdk-7-jre openjdk-7-jre-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV MESSAGE_CONSUMER_DOWNLOAD_URL https://github.com/GluuFederation/message-consumer/archive/master.zip
ENV LAST_REV_SHA 6f391aa582c52badc8a8ceb76efbe1178f83a175

RUN wget $MESSAGE_CONSUMER_DOWNLOAD_URL -O /tmp/message-consumer.zip \
    && unzip /tmp/message-consumer.zip -d /tmp \
    && mvn -Pprod-mysql clean package -f /tmp/message-consumer-master/pom.xml -Dmaven.test.skip=true \
    && mv /tmp/message-consumer-master/target/message-consumer-0.0.1-SNAPSHOT.jar /opt \
    && rm -rf /tmp/message-consumer-master /tmp/message-consumer.zip

RUN mkdir -p /etc/message-consumer
COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh", "message-consumer"]

EXPOSE 9339
