FROM gluufederation/base

MAINTAINER Shouro <shouro@gluu.org>

# ===============
# Ubuntu packages
# ===============

# SoftHSM2 repo
RUN echo "deb http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && echo "deb-src http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 26535DB3

# JDK 8 repo
RUN echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86F44E2A

RUN apt-get update && apt-get install -y \
    openjdk-8-jre-headless \
    softhsm2 \
    unzip \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# workaround for bug on ubuntu 14.04 with openjdk-8-jre-headless
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# =====
# gosu
# =====
RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64' && chmod +x /usr/local/bin/gosu

# =====
# Jetty
# =====

ENV JETTY_VERSION 9.3.12.v20160915
ENV JETTY_TGZ_URL https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${JETTY_VERSION}/jetty-distribution-${JETTY_VERSION}.tar.gz
ENV JETTY_HOME /opt/jetty
ENV JETTY_BASE /opt/gluu/jetty
ENV JETTY_USER_HOME_LIB /home/jetty/lib

# Install jetty
RUN wget -q ${JETTY_TGZ_URL} -O /tmp/jetty.tar.gz \
    && tar -xzf /tmp/jetty.tar.gz -C /opt \
    && mv /opt/jetty-distribution-${JETTY_VERSION} /opt/jetty \
    && rm -rf /tmp/jetty.tar.gz

# ========
# oxEleven
# ========

ENV OX_VERSION 3.0.0
ENV OX_BUILD_DATE 2017-02-06
ENV OXELEVEN_DOWNLOAD_URL https://ox.gluu.org/maven/org/gluu/oxeleven-server/${OX_VERSION}/oxeleven-server-${OX_VERSION}.war

# Install oxEleven in jetty
RUN wget -q ${OXELEVEN_DOWNLOAD_URL} -O /tmp/oxeleven.war \
    && mkdir -p ${JETTY_BASE}/oxeleven/webapps \
    && unzip -qq /tmp/oxeleven.war -d ${JETTY_BASE}/oxeleven/webapps/oxeleven \
    && java -jar ${JETTY_HOME}/start.jar jetty.home=${JETTY_HOME} jetty.base=${JETTY_BASE}/oxeleven --add-to-start=deploy,http,logging,jsp \
    && rm -f /tmp/oxeleven.war

# Directory for tokens
RUN mkdir -p  /var/lib/softhsm/tokens

# Directory for certificates
RUN mkdir -p /etc/certs

# Directory for config required by oxEleven (e.g. oxeleven-config.json)
RUN mkdir -p /etc/gluu/conf

# Copy static templates
COPY oxeleven-config.json.tmpl /tmp
COPY jetty.supervisord.conf /etc/supervisor/conf.d

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

LABEL vendor="Gluu Federation" \
      org.gluu.oxeleven-server.version="${OX_VERSION}" \
      org.gluu.oxeleven-server.build-date="${OX_BUILD_DATE}"

# Ports required by jetty
EXPOSE 8080
