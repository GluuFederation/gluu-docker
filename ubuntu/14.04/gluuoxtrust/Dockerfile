FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    facter \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#ENV variables
ENV OXTRUST_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxtrust-server/2.3.2.Final/oxtrust-server-2.3.2.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.59/bin/apache-tomcat-7.0.59.tar.gz
ENV CHECK_SSL_PY https://raw.githubusercontent.com/GluuFederation/gluu-util/master/check_ssl/check_ssl.py

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp && tar -xzf /tmp/apache-tomcat-7.0.59.tar.gz -C /opt && rm -f /tmp/apache-tomcat-7.0.59.tar.gz
RUN ln -sf /opt/apache-tomcat-7.0.59 /opt/tomcat
RUN wget -q "$OXTRUST_DOWNLOAD_URL" -P /tmp && mv /tmp/oxtrust-server-2.3.2.Final.war /tmp/identity.war && cp /tmp/identity.war /opt/tomcat/webapps && rm -f /tmp/identity.war
RUN wget -q "$CHECK_SSL_PY" -O /usr/bin/check_ssl.py && chmod +x /usr/bin/check_ssl.py

EXPOSE 8009
EXPOSE 8005
