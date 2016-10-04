FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

RUN echo "deb http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && echo "deb-src http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 26535DB3

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    softhsm2 \
    apache2 \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Tomcat
RUN wget -q http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.65/bin/apache-tomcat-7.0.65.tar.gz -O /tmp/tomcat.tar.gz \
    && tar -xzf /tmp/tomcat.tar.gz -C /opt \
    && mv /opt/apache-tomcat-7.0.65 /opt/tomcat \
    && rm -f /tmp/tomcat.tar.gz

# Install oxEleven
RUN wget -q https://ox.gluu.org/maven/org/gluu/oxeleven-server/2.4.4.sp1/oxeleven-server-2.4.4.sp1.war -O /tmp/oxeleven.war \
    && unzip -qq /tmp/oxeleven.war -d /opt/tomcat/webapps/oxeleven \
    && rm -f /tmp/oxeleven.war

# Directory for certificates
RUN mkdir -p /etc/certs

LABEL vendor="Gluu Federation" \
      org.gluu.oxeleven-server.version="2.4.4.sp1" \
      org.gluu.oxeleven-server.build-date="2016-09-16"

# Ports required by tomcat
EXPOSE 8009
EXPOSE 8005

# Ports required by Apache
EXPOSE 80
EXPOSE 443
