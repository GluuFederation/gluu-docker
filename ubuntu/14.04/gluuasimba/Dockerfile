FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ENV variables
ENV ASIMBA_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxasimba-proxy/2.4.0.Final/oxasimba-proxy-2.4.0.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.59/bin/apache-tomcat-7.0.59.tar.gz

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp && tar -xzf /tmp/${TOMCAT_DOWNLOAD_URL##*/} -C /opt && rm -f /tmp/${TOMCAT_DOWNLOAD_URL##*/}
RUN ln -sf /opt/apache-tomcat-7.0.59 /opt/tomcat
RUN wget -q "$ASIMBA_DOWNLOAD_URL" -P /tmp && mv /tmp/${ASIMBA_DOWNLOAD_URL##*/} /tmp/oxasimba.war && cp /tmp/oxasimba.war /opt/tomcat/webapps && rm -f /tmp/oxasimba.war

EXPOSE 8009
EXPOSE 8005
EXPOSE 8443
