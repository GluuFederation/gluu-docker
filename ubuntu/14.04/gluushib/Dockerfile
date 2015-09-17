FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

# Adds repo for twemproxy
RUN echo 'deb http://ppa.launchpad.net/twemproxy/stable/ubuntu trusty main' >> /etc/apt/sources.list.d/twemproxy.list \
    && echo 'deb-src http://ppa.launchpad.net/twemproxy/stable/ubuntu trusty main' >> /etc/apt/sources.list.d/twemproxy.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F9DFF4ACC692420F

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    memcached \
    twemproxy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ENV variables
ENV OXIDP_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxidp/2.3.4.Final/oxidp-2.3.4.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.59/bin/apache-tomcat-7.0.59.tar.gz

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp \
    && tar -xzf /tmp/apache-tomcat-7.0.59.tar.gz -C /opt \
    && rm -f /tmp/apache-tomcat-7.0.59.tar.gz
RUN ln -sf /opt/apache-tomcat-7.0.59 /opt/tomcat

# Creates directories for oxIdp setup
RUN mkdir -p /opt/idp/war \
    && mkdir -p /opt/idp/sp \
    && mkdir -p /opt/idp/metadata \
    && mkdir -p /opt/idp/logs \
    && mkdir -p /opt/idp/lib \
    && mkdir -p /opt/idp/conf \
    && mkdir -p /opt/idp/ssl \
    && mkdir -p /opt/idp/temp_metadata \
    && mkdir -p /opt/tomcat/conf/shibboleth2/idp \
    && mkdir -p /opt/tomcat/conf/Catalina/localhost
RUN wget -q "$OXIDP_DOWNLOAD_URL" -O /opt/idp/war/idp.war

# Additional JARs required by oxIdp
RUN mkdir -p /opt/tomcat/endorsed
RUN wget -q http://ox.gluu.org/maven/xerces/xercesImpl/2.10.0/xercesImpl-2.10.0.jar -O /opt/tomcat/endorsed/xercesImpl-2.10.0.jar
RUN wget -q http://ox.gluu.org/maven/xml-apis/xml-apis/1.4.01/xml-apis-1.4.01.jar -O /opt/tomcat/endorsed/xml-apis-1.4.01.jar

RUN mkdir -p /etc/certs

# Ports required by tomcat
EXPOSE 8009
EXPOSE 8005

# twemproxy port
EXPOSE 22122

# memcached port
EXPOSE 11211
