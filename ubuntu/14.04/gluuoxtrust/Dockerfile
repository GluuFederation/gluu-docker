FROM gluufederation/base

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r jetty && useradd -r -g jetty jetty

# ===============
# Ubuntu packages
# ===============

# Jetty requires Java 8, hence we need to get latest OpenJDK 8 from PPA
RUN echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86F44E2A

RUN apt-get update && apt-get install -y \
    openjdk-8-jre-headless \
    apache2 \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# workaround for bug on ubuntu 14.04 with openjdk-8
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# =====
# Jetty
# =====

ENV JETTY_VERSION 9.3.12.v20160915
ENV JETTY_TGZ_URL https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${JETTY_VERSION}/jetty-distribution-${JETTY_VERSION}.tar.gz
ENV JETTY_HOME /opt/jetty

# This is where we put our ox app
ENV JETTY_BASE /opt/gluu/jetty

# Endorsed lib required for running the app should be put under this directory
ENV JETTY_USER_HOME_LIB /home/jetty/lib

# Install jetty
RUN wget -q ${JETTY_TGZ_URL} -O /tmp/jetty.tar.gz \
    && tar -xzf /tmp/jetty.tar.gz -C /opt \
    && mv /opt/jetty-distribution-${JETTY_VERSION} ${JETTY_HOME} \
    && rm -rf /tmp/jetty.tar.gz

# ======
# Jython
# ======

ENV JYTHON_VERSION 2.7.0
ENV JYTHON_DOWNLOAD_URL http://central.maven.org/maven2/org/python/jython-standalone/${JYTHON_VERSION}/jython-standalone-${JYTHON_VERSION}.jar

# Install Jython
RUN wget -q ${JYTHON_DOWNLOAD_URL} -O /tmp/jython.jar \
    && unzip -q /tmp/jython.jar -d /opt/jython \
    && rm -f /tmp/jython.jar

# =======
# oxTrust
# =======

ENV OX_VERSION 3.0.0-SNAPSHOT
ENV OX_BUILD_DATE 2016-12-17
ENV OXTRUST_DOWNLOAD_URL https://ox.gluu.org/maven/org/xdi/oxtrust-server/${OX_VERSION}/oxtrust-server-${OX_VERSION}.war

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
LABEL vendor="Gluu Federation" \
      org.gluu.oxtrust-server.version="${OX_VERSION}" \
      org.gluu.oxtrust-server.build-date="${OX_BUILD_DATE}"

# Install oxTrust
RUN wget -q ${OXTRUST_DOWNLOAD_URL} -O /tmp/oxtrust.war \
    && mkdir -p ${JETTY_BASE}/identity/webapps \
    && unzip -qq /tmp/oxtrust.war -d ${JETTY_BASE}/identity/webapps/identity \
    && java -jar ${JETTY_HOME}/start.jar jetty.home=${JETTY_HOME} jetty.base=${JETTY_BASE}/identity --add-to-start=deploy,http,logging,jsp,ext,http-forwarded \
    && rm -f /tmp/oxtrust.war

# Install utility scripts
RUN wget -q https://raw.githubusercontent.com/GluuFederation/gluu-util/master/check_ssl/check_ssl.py -O /usr/bin/check_ssl.py \
    && chmod +x /usr/bin/check_ssl.py

RUN mkdir -p ${JETTY_USER_HOME_LIB}
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk16/1.46/bcprov-jdk16-1.46.jar -O ${JETTY_USER_HOME_LIB}/bcprov-jdk16-1.46.jar

 # Directory for certificates
RUN mkdir -p /etc/certs

# Directory for custom config
RUN mkdir -p /etc/gluu

# Directory required by oxTrust
RUN mkdir -p /var/ox/photos /var/ox/identity/removed /var/ox/identity/cr-snapshots

# Directory for custom pages and resources
RUN mkdir -p ${JETTY_BASE}/identity/pages

# Unpack Shib config
RUN unzip -q ${JETTY_BASE}/identity/webapps/identity/WEB-INF/lib/oxtrust-configuration-${OX_VERSION}.jar shibboleth3/* -d /opt/gluu/jetty/identity/conf

# Copy static templates
COPY identity_web_resources.xml ${JETTY_BASE}/identity/webapps
COPY oxTrustLogRotationConfiguration.xml /etc/gluu
# COPY attribute-resolver.xml.vm /opt/tomcat/conf/shibboleth2/idp
# COPY index.html /opt/tomcat/webapps/ROOT

# Ports required by jetty
EXPOSE 8080

# Ports required by Apache
EXPOSE 443
