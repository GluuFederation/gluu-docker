FROM ubuntu:14.04

MAINTAINER Isman <isman@gluu.org>

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

ENV MAVEN_VERSION 3.3.9
ENV MAVEN_DOWNLOAD_URL http://www-us.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz

RUN wget -q $MAVEN_DOWNLOAD_URL -P /tmp \
    && tar xf /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C /opt \
    && rm -rf /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz

ENV PATH /opt/apache-maven-$MAVEN_VERSION/bin:$PATH

# temporary download location and versioning system as we don't have prebuild JAR file at the moment
ENV MESSAGE_CONSUMER_DOWNLOAD_URL https://github.com/GluuFederation/message-consumer/archive/master.zip
ENV LAST_REV_SHA 67d72ce5159524ce2c9bcb2c023db6f9ac710b7f

RUN wget -q $MESSAGE_CONSUMER_DOWNLOAD_URL -O /tmp/message-consumer.zip \
    && unzip /tmp/message-consumer.zip -d /tmp \
    && mvn -Pprod clean package -f /tmp/message-consumer-master/pom.xml -Dmaven.test.skip=true \
    && mv /tmp/message-consumer-master/target/message-consumer-0.0.1-SNAPSHOT.jar /opt \
    && rm -rf /tmp/message-consumer-master /tmp/message-consumer.zip

RUN mkdir -p /etc/message-consumer

# run message-consumer that loads config file at /etc/message-consumer/prod-mysql.properties
CMD ["java", "-jar", "/opt/message-consumer-0.0.1-SNAPSHOT.jar", "--spring.config.location=/etc/message-consumer/", "--spring.config.name=prod-mysql", "--database=mysql"]

EXPOSE 9339
