FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#ENV variables
ENV OXIDP_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxidp/1.7.0.Final/oxidp-1.7.0.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.59/bin/apache-tomcat-7.0.59.tar.gz

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp && tar -xzf /tmp/apache-tomcat-7.0.59.tar.gz -C /opt && rm -f /tmp/apache-tomcat-7.0.59.tar.gz
RUN ln -sf /opt/apache-tomcat-7.0.59 /opt/tomcat
RUN mkdir -p /opt/idp/war
RUN wget -q "$OXIDP_DOWNLOAD_URL" -P /tmp && mv /tmp/oxidp-1.7.0.Final.war /tmp/idp.war && cp /tmp/idp.war /opt/idp/war && rm -f /tmp/idp.war

EXPOSE 8009
EXPOSE 8005
