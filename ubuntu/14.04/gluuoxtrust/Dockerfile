FROM saltminion

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#ENV variables
ENV OXTRUST_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxtrust-server/1.7.0.Final/oxtrust-server-1.7.0.Final.war
ENV TOMCAT_DOWNLOAD_URL http://mirrors.advancedhosters.com/apache/tomcat/tomcat-7/v7.0.57/bin/apache-tomcat-7.0.57.tar.gz

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp && tar -xzf /tmp/apache-tomcat-7.0.57.tar.gz -C /opt && rm -f /tmp/apache-tomcat-7.0.57.tar.gz
RUN ln -sf /opt/apache-tomcat-7.0.57 /opt/tomcat
RUN wget -q "$OXTRUST_DOWNLOAD_URL" -P /tmp && mv /tmp/oxtrust-server-1.7.0.Final.war /tmp/identity.war && cp /tmp/identity.war /opt/tomcat/webapps && rm -f /tmp/identity.war

EXPOSE 8009
EXPOSE 8005
