FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#ENV variables
ENV OXIDP_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxidp/2.3.3.Final/oxidp-2.3.3.Final.war
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.59/bin/apache-tomcat-7.0.59.tar.gz

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp \
    && tar -xzf /tmp/apache-tomcat-7.0.59.tar.gz -C /opt \
    && rm -f /tmp/apache-tomcat-7.0.59.tar.gz

RUN ln -sf /opt/apache-tomcat-7.0.59 /opt/tomcat

RUN mkdir -p /opt/idp/war
RUN wget -q "$OXIDP_DOWNLOAD_URL" -O /opt/idp/war/idp.war
RUN mkdir -p /opt/idp/sp
RUN mkdir -p /opt/idp/metadata
RUN mkdir -p /opt/idp/logs
RUN mkdir -p /opt/idp/lib
RUN mkdir -p /opt/idp/conf
RUN mkdir -p /opt/idp/ssl
RUN mkdir -p /opt/idp/temp_metadata

RUN mkdir -p /opt/tomcat/conf/shibboleth2/idp
RUN mkdir -p /opt/tomcat/conf/Catalina/localhost

RUN mkdir -p /opt/tomcat/endorsed
RUN wget -q http://ox.gluu.org/maven/xerces/xercesImpl/2.10.0/xercesImpl-2.10.0.jar -O /opt/tomcat/endorsed/xercesImpl-2.10.0.jar
RUN wget -q http://ox.gluu.org/maven/xml-apis/xml-apis/1.4.01/xml-apis-1.4.01.jar -O /opt/tomcat/endorsed/xml-apis-1.4.01.jar

EXPOSE 8009
EXPOSE 8005
