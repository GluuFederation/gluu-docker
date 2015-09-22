FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    unzip \
    apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ENV variables
ENV OXAUTH_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxauth-server/2.3.4.Final/oxauth-server-2.3.4.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.59/bin/apache-tomcat-7.0.59.tar.gz
ENV JYTHON_DOWNLOAD_URL http://search.maven.org/remotecontent?filepath=org/python/jython-standalone/2.7.0/jython-standalone-2.7.0.jar

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp \
    && tar -xzf /tmp/apache-tomcat-7.0.59.tar.gz -C /opt \
    && rm -f /tmp/apache-tomcat-7.0.59.tar.gz
RUN ln -sf /opt/apache-tomcat-7.0.59 /opt/tomcat

RUN wget -q "$OXAUTH_DOWNLOAD_URL" -O /opt/tomcat/webapps/oxauth.war

RUN wget -q "$JYTHON_DOWNLOAD_URL" -O /tmp/jython-standalone-2.7.0.jar \
    && unzip -q /tmp/jython-standalone-2.7.0.jar -d /opt/jython \
    && rm -f /tmp/jython-standalone-2.7.0.jar

RUN mkdir -p /etc/certs \
    && mkdir -p /opt/tomcat/conf/python

# Ports required by Tomcat
EXPOSE 8009
EXPOSE 8005

# Ports required by Apache
EXPOSE 443
