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
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# workaround for bug on ubuntu 14.04 with openjdk-8
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# =====
# Jetty
# =====

ENV JETTY_VERSION 9.3.14.v20161028
ENV JETTY_TGZ_URL https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${JETTY_VERSION}/jetty-distribution-${JETTY_VERSION}.tar.gz
ENV JETTY_HOME /opt/jetty
ENV JETTY_BASE /opt/gluu/jetty
ENV JETTY_USER_HOME_LIB /home/jetty/lib

# Install jetty
RUN wget -q ${JETTY_TGZ_URL} -O /tmp/jetty.tar.gz \
    && tar -xzf /tmp/jetty.tar.gz -C /opt \
    && mv /opt/jetty-distribution-${JETTY_VERSION} ${JETTY_HOME} \
    && rm -rf /tmp/jetty.tar.gz

# ====================
# oxShibboleth (oxIdp)
# ====================

ENV OX_VERSION 3.0.0-SNAPSHOT
ENV OX_BUILD_DATE 2017-01-20
ENV OXIDP_DOWNLOAD_URL https://ox.gluu.org/maven/org/xdi/oxshibbolethIdp/${OX_VERSION}/oxshibbolethIdp-${OX_VERSION}.war

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
LABEL vendor="Gluu Federation" \
      org.gluu.oxidp.version="${OX_VERSION}" \
      org.gluu.oxidp.build-date="${OX_BUILD_DATE}"

# RUN mkdir -p /opt/idp/war /opt/idp/sp /opt/idp/metadata /opt/idp/logs /opt/idp/lib /opt/idp/conf /opt/idp/ssl /opt/idp/temp_metadata \
    # && mkdir -p /opt/tomcat/conf/shibboleth2/idp /opt/tomcat/conf/Catalina/localhost

# Creates directories for oxIdp setup
RUN mkdir -p /opt/shibboleth-idp/metadata \
    /opt/shibboleth-idp/logs \
    /opt/shibboleth-idp/lib \
    /opt/shibboleth-idp/conf/authn \
    /opt/shibboleth-idp/credentials

# Install oxIDP
RUN wget -q ${OXIDP_DOWNLOAD_URL} -O /tmp/idp.war \
    && mkdir -p ${JETTY_BASE}/idp/webapps \
    && unzip -qq /tmp/idp.war -d ${JETTY_BASE}/idp/webapps/idp \
    && java -jar ${JETTY_HOME}/start.jar jetty.home=${JETTY_HOME} jetty.base=${JETTY_BASE}/idp --add-to-start=deploy,http,logging,jsp,http-forwarded \
    && rm -f /tmp/idp.war

# Directory for certificates
RUN mkdir -p /etc/certs

# Copy static templates
COPY saml-nameid.properties /opt/shibboleth-idp/conf
COPY services.properties /opt/shibboleth-idp/conf
COPY password-authn-config.xml /opt/shibboleth-idp/conf/authn/password-authn-config.xml
COPY jetty.supervisord.conf /etc/supervisor/conf.d

# Set openjdk 8 as default java
RUN cd /usr/lib/jvm && ln -s java-1.8.0-openjdk-amd64 default-java

# Ports required by jetty
EXPOSE 8080
