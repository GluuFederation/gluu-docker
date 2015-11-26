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
    apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Tomcat
RUN wget -q http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.65/bin/apache-tomcat-7.0.65.tar.gz -O /tmp/tomcat.tar.gz \
    && tar -xzf /tmp/tomcat.tar.gz -C /opt \
    && mv /opt/apache-tomcat-7.0.65 /opt/tomcat \
    && rm -f /tmp/tomcat.tar.gz

# Creates directories for oxIdp setup
RUN mkdir -p /opt/idp/war /opt/idp/sp /opt/idp/metadata /opt/idp/logs /opt/idp/lib /opt/idp/conf /opt/idp/ssl /opt/idp/temp_metadata \
    && mkdir -p /opt/tomcat/conf/shibboleth2/idp /opt/tomcat/conf/Catalina/localhost

# Install oxIDP
RUN wget -q http://ox.gluu.org/maven/org/xdi/oxidp/2.4.1.Final/oxidp-2.4.1.Final.war -O /opt/idp/war/idp.war

# Additional JARs required by oxIdp
RUN mkdir -p /opt/tomcat/endorsed
RUN wget -q http://ox.gluu.org/maven/xerces/xercesImpl/2.10.0/xercesImpl-2.10.0.jar -O /opt/tomcat/endorsed/xercesImpl-2.10.0.jar
RUN wget -q http://ox.gluu.org/maven/xml-apis/xml-apis/1.4.01/xml-apis-1.4.01.jar -O /opt/tomcat/endorsed/xml-apis-1.4.01.jar

# Directory for certificates
RUN mkdir -p /etc/certs

# Ports required by tomcat
EXPOSE 8009
EXPOSE 8005

# twemproxy port
EXPOSE 22122

# memcached port
EXPOSE 11211

# apache port
EXPOSE 80
EXPOSE 443
