FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

# We need to install JDK to have jar executable which is required for
# customizing and re-building cas.war
RUN apt-get update && apt-get install -y \
    openjdk-7-jdk \
    wget \
    unzip \
    apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ENV variables
ENV CAS_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/ox-cas-server-webapp/2.4.2.Final/ox-cas-server-webapp-2.4.2.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.65/bin/apache-tomcat-7.0.65.tar.gz

# Install Tomcat
RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp \
    && tar -xzf /tmp/${TOMCAT_DOWNLOAD_URL##*/} -C /opt \
    && rm -f /tmp/${TOMCAT_DOWNLOAD_URL##*/} \
    && mv /opt/apache-tomcat-7.0.65 /opt/tomcat

# Install oxCas
RUN wget -q "$CAS_DOWNLOAD_URL" -P /tmp \
    && mv /tmp/${CAS_DOWNLOAD_URL##*/} /tmp/oxcas.war \
    && cp /tmp/oxcas.war /opt/tomcat/webapps \
    && rm -f /tmp/oxcas.war

LABEL vendor="Gluu Federation" \
      org.gluu.oxcas.version="2.4.2" \
      org.gluu.oxcas.build-date="2016-02-12"

RUN mkdir -p /etc/certs
RUN mkdir -p /tmp/cas

# Ports required by Tomcat
EXPOSE 8009
EXPOSE 8005

# Ports required by apache2
EXPOSE 80
EXPOSE 443
