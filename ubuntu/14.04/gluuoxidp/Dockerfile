FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

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
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV TOMCAT_VERSION 7.0.65
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Install Tomcat
RUN wget -q ${TOMCAT_DOWNLOAD_URL} -O /tmp/tomcat.tar.gz \
    && tar -xzf /tmp/tomcat.tar.gz -C /opt \
    && mv /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat \
    && rm -f /tmp/tomcat.tar.gz

# Creates directories for oxIdp setup
RUN mkdir -p /opt/idp/war /opt/idp/sp /opt/idp/metadata /opt/idp/logs /opt/idp/lib /opt/idp/conf /opt/idp/ssl /opt/idp/temp_metadata \
    && mkdir -p /opt/tomcat/conf/shibboleth2/idp /opt/tomcat/conf/Catalina/localhost

ENV OX_VERSION 2.4.4.sp1
ENV OX_BUILD_DATE 2016-10-12
ENV OXIDP_DOWNLOAD_URL https://ox.gluu.org/maven/org/xdi/oxidp/${OX_VERSION}/oxidp-${OX_VERSION}.war

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
LABEL vendor="Gluu Federation" \
      org.gluu.oxidp.version="${OX_VERSION}" \
      org.gluu.oxidp.build-date="${OX_BUILD_DATE}"

# Install oxIDP
RUN wget -q ${OXIDP_DOWNLOAD_URL} -O /opt/idp/war/idp.war

# Directory for certificates
RUN mkdir -p /etc/certs

# Copy static templates
COPY idp.xml /opt/tomcat/conf/Catalina/localhost
COPY idp-metadata.xml /opt/idp/metadata
COPY attribute-resolver.xml /opt/idp/conf
COPY relying-party.xml /opt/idp/conf
COPY attribute-filter.xml /opt/idp/conf
COPY internal.xml /opt/idp/conf
COPY service.xml /opt/idp/conf
COPY logging.xml /opt/idp/conf
COPY handler.xml /opt/idp/conf

# Libs for oxIdp
RUN mkdir -p /tmp/idp \
    && unzip -q /opt/idp/war/idp.war -d /tmp/idp \
    && cp /tmp/idp/WEB-INF/lib/* /opt/idp/lib \
    && rm -rf /tmp/idp
RUN wget -q https://github.com/GluuFederation/community-edition-setup/raw/master/static/idp/lib/jsp-api-2.1.jar -P /opt/idp/lib
RUN wget -q https://github.com/GluuFederation/community-edition-setup/raw/master/static/idp/lib/servlet-api-2.5.jar -P /opt/idp/lib

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
