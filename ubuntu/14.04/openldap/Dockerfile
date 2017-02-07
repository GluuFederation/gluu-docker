FROM gluufederation/base

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r ldap && useradd -r -g ldap ldap

# ===============
# Ubuntu packages
# ===============

# JDK 8 repo
RUN echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86F44E2A

RUN apt-get update && apt-get install -y \
    openjdk-8-jre-headless \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# workaround for bug on ubuntu 14.04 with openjdk-8-jre-headless
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# ======
# OpenDJ
# ======

ENV OPENDJ_VERSION 3.0.0.gluu-SNAPSHOT
ENV OPENDJ_BUILD_DATE 2016-04-11
ENV OPENDJ_DOWNLOAD_URL http://ox.gluu.org/maven/org/forgerock/opendj/opendj-server-legacy/${OPENDJ_VERSION}/opendj-server-legacy-${OPENDJ_VERSION}.zip

RUN wget -q "$OPENDJ_DOWNLOAD_URL" -P /tmp \
    && unzip -qq /tmp/opendj-server-legacy-${OPENDJ_VERSION}.zip -d /opt \
    && rm -f /tmp/opendj-server-legacy-${OPENDJ_VERSION}.zip

# ========
# OpenLDAP
# ========

ENV OPENLDAP_DEB_URL https://repo.gluu.org/ubuntu/symas-openldap-gluu.amd64_2.4.44-20161020_amd64.deb

RUN wget -q ${OPENLDAP_DEB_URL} -O /tmp/openldap.deb \
    && dpkg -i /tmp/openldap.deb \
    && rm -rf /tmp/openldap.deb

RUN mkdir -p /var/log/openldap /opt/gluu/schema/openldap /opt/gluu/data

COPY custom.schema /opt/gluu/schema/openldap
COPY gluu.schema /opt/gluu/schema/openldap
COPY openldap-syslog.conf /etc/rsyslog.d
COPY openldap_logrotate /etc/logrotate.d

# =======
# ox Libs
# =======

ENV OX_VERSION 3.0.0
ENV OX_BUILD_DATE 2017-02-06

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
LABEL vendor="Gluu Federation" \
      org.gluu.gluu-opendj.version="${OPENDJ_VERSION}" \
      org.gluu.gluu-opendj.build-date="${OPENDJ_BUILD_DATE}" \
      org.gluu.oxauth-server.version="${OX_VERSION}" \
      org.gluu.oxauth-server.build-date="${OX_BUILD_DATE}" \
      org.gluu.oxauth-model.version="${OX_VERSION}" \
      org.gluu.oxauth-model.build-date="${OX_BUILD_DATE}"

# JAR files required to generate OpenID Connect keys
RUN mkdir -p /opt/gluu/lib
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.54/bcprov-jdk15on-1.54.jar -O /opt/gluu/lib/bcprov-jdk15on-1.54.jar
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcpkix-jdk15on/1.54/bcpkix-jdk15on-1.54.jar -O /opt/gluu/lib/bcpkix-jdk15on-1.54.jar
RUN wget -q http://central.maven.org/maven2/org/codehaus/jettison/jettison/1.3/jettison-1.3.jar -O /opt/gluu/lib/jettison-1.3.jar
RUN wget -q http://central.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar -O /opt/gluu/lib/commons-lang-2.6.jar
RUN wget -q http://central.maven.org/maven2/log4j/log4j/1.2.14/log4j-1.2.14.jar -O /opt/gluu/lib/log4j-1.2.14.jar
RUN wget -q http://central.maven.org/maven2/commons-codec/commons-codec/1.5/commons-codec-1.5.jar -O /opt/gluu/lib/commons-codec-1.5.jar
RUN wget -q http://central.maven.org/maven2/commons-cli/commons-cli/1.2/commons-cli-1.2.jar -O /opt/gluu/lib/commons-cli-1.2.jar
RUN wget -q https://ox.gluu.org/maven/org/xdi/oxauth-model/${OX_VERSION}/oxauth-model-${OX_VERSION}.jar -O /opt/gluu/lib/oxauth-model.jar
RUN wget -q https://ox.gluu.org/maven/org/xdi/oxauth-server/${OX_VERSION}/oxauth-server-${OX_VERSION}.jar -O /opt/gluu/lib/oxauth-server.jar

# Directory for certificates
RUN mkdir -p /etc/certs

RUN mkdir -p /opt/opendj/template/config/schema
RUN mkdir -p /opt/opendj/ldif

# Copy static templates
COPY opendj_index.json /opt/opendj
COPY o_site.ldif /opt/opendj/ldif
# COPY 101-ox.ldif /opt/opendj/template/config/schema
# COPY 77-customAttributes.ldif /opt/opendj/template/config/schema
COPY 96-eduperson.ldif /opt/opendj/template/config/schema

# Set openjdk 8 as default java
RUN cd /usr/lib/jvm && ln -s java-1.8.0-openjdk-amd64 default-java

# LDAPS port
EXPOSE 1636

# replication port
EXPOSE 8989
