FROM gluufederation/base

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

# ===============
# Ubuntu packages
# ===============

# SoftHSM2 repo
RUN echo "deb http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && echo "deb-src http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 26535DB3

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    softhsm2 \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ======
# Tomcat
# ======

ENV TOMCAT_VERSION 7.0.65
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Install Tomcat
RUN wget -q ${TOMCAT_DOWNLOAD_URL} -O /tmp/tomcat.tar.gz \
    && tar -xzf /tmp/tomcat.tar.gz -C /opt \
    && mv /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat \
&& rm -f /tmp/tomcat.tar.gz

# ========
# oxEleven
# ========

ENV OX_VERSION 3.0.0-SNAPSHOT
ENV OX_BUILD_DATE 2017-01-25
ENV OXELEVEN_DOWNLOAD_URL https://ox.gluu.org/maven/org/gluu/oxeleven-server/${OX_VERSION}/oxeleven-server-${OX_VERSION}.war

# Install oxEleven in tomcat
RUN wget -q ${OXELEVEN_DOWNLOAD_URL} -O /tmp/oxeleven.war \
    && unzip -qq /tmp/oxeleven.war -d /opt/tomcat/webapps/oxeleven \
    && rm -f /tmp/oxeleven.war

# Directory for tokens
RUN mkdir -p  /var/lib/softhsm/tokens

# Directory for config required by oxEleven (e.g. oxeleven-config.json)
COPY oxeleven-config.json.tmpl /tmp
COPY setup_n_render.sh /tmp
RUN chmod +x /tmp/setup_n_render.sh
RUN /tmp/setup_n_render.sh
RUN cp /tmp/oxeleven-config.json /opt/tomcat/conf \
    && rm /tmp/oxeleven-config.json.tmpl \
    && rm /tmp/setup_n_render.sh
COPY tomcat.supervisord.conf /etc/supervisor/conf.d

# Set openjdk 7 as default java
RUN cd /usr/lib/jvm && ln -s java-1.7.0-openjdk-amd64 default-java

LABEL vendor="Gluu Federation" \
      org.gluu.oxeleven-server.version="${OX_VERSION}" \
      org.gluu.oxeleven-server.build-date="${OX_BUILD_DATE}"

# Ports required by tomcat
EXPOSE 8080
