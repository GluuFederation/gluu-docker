FROM gluufederation/base

MAINTAINER Isman <isman@gluu.org>

# ===============
# Ubuntu packages
# ===============

# JDK 8 repo
RUN echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86F44E2A

RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    wget \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# workaround for bug on ubuntu 14.04 with openjdk-8
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Set openjdk 8 as default java
RUN cd /usr/lib/jvm && ln -s java-1.8.0-openjdk-amd64 default-java

# =====
# Maven
# =====

ENV MAVEN_VERSION 3.3.9
ENV MAVEN_DOWNLOAD_URL http://www-us.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

RUN wget -q $MAVEN_DOWNLOAD_URL -P /tmp \
    && tar xf /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C /opt \
    && rm -rf /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz

ENV PATH /opt/apache-maven-$MAVEN_VERSION/bin:$PATH

# ================
# Message Consumer
# ================

ENV MESSAGE_CONSUMER_DOWNLOAD_URL https://github.com/GluuFederation/message-consumer/archive/master.zip
ENV LAST_REV_SHA 67d72ce5159524ce2c9bcb2c023db6f9ac710b7f

RUN wget -q $MESSAGE_CONSUMER_DOWNLOAD_URL -O /tmp/message-consumer.zip \
    && unzip /tmp/message-consumer.zip -d /tmp \
    && mvn -Pprod-mysql clean package -f /tmp/message-consumer-master/pom.xml -Dmaven.test.skip=true \
    && mv /tmp/message-consumer-master/target/message-consumer-0.0.1-SNAPSHOT.jar /opt \
    && rm -rf /tmp/message-consumer-master /tmp/message-consumer.zip

RUN mkdir -p /etc/message-consumer /var/log/message-consumer
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
COPY mc.supervisord.conf /etc/supervisor/conf.d

EXPOSE 9339
