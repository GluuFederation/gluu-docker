FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

# We need to install JDK to have jar executable which is required for
# customizing and re-building asimba.war
RUN apt-get update && apt-get install -y \
    openjdk-7-jdk \
    wget \
    unzip \
    apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ENV variables
ENV ASIMBA_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxasimba-proxy/2.4.1.Final/oxasimba-proxy-2.4.1.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.65/bin/apache-tomcat-7.0.65.tar.gz

# Install Tomcat
RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp \
    && tar -xzf /tmp/${TOMCAT_DOWNLOAD_URL##*/} -C /opt \
    && rm -f /tmp/${TOMCAT_DOWNLOAD_URL##*/} \
    && mv /opt/apache-tomcat-7.0.65 /opt/tomcat

# Install oxAsimba
RUN wget -q "$ASIMBA_DOWNLOAD_URL" -P /tmp \
    && mv /tmp/${ASIMBA_DOWNLOAD_URL##*/} /tmp/oxasimba.war \
    && cp /tmp/oxasimba.war /opt/tomcat/webapps \
    && rm -f /tmp/oxasimba.war

# Directory for certificates
RUN mkdir -p /etc/certs

RUN mkdir -p /tmp/asimba

# Ports required by Tomcat
EXPOSE 8009
EXPOSE 8005

# Ports required by apache2
EXPOSE 80
EXPOSE 443
