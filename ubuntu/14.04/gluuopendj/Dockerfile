FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r ldap && useradd -r -g ldap ldap

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    unzip \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ENV variables
ENV OPENDJ_DOWNLOAD_URL http://ox.gluu.org/maven/org/gluu/gluu-opendj/2.6.0/gluu-opendj-2.6.0.zip

RUN wget -q "$OPENDJ_DOWNLOAD_URL" -P /tmp && unzip -qq /tmp/gluu-opendj-2.6.0.zip -d /opt && rm -f /tmp/gluu-opendj-2.6.0.zip

# JAR files required to generate OpenID Connect keys
RUN mkdir -p /opt/gluu/lib
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk16/1.46/bcprov-jdk16-1.46.jar -O /opt/gluu/lib/bcprov-jdk16-1.46.jar
RUN wget -q http://central.maven.org/maven2/org/codehaus/jettison/jettison/1.3/jettison-1.3.jar -O /opt/gluu/lib/jettison-1.3.jar
RUN wget -q http://central.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar -O /opt/gluu/lib/commons-lang-2.6.jar
RUN wget -q http://central.maven.org/maven2/log4j/log4j/1.2.17/log4j-1.2.17.jar -O /opt/gluu/lib/log4j-1.2.17.jar
RUN wget -q http://central.maven.org/maven2/commons-codec/commons-codec/1.5/commons-codec-1.5.jar -O /opt/gluu/lib/commons-codec-1.5.jar
RUN wget -q http://ox.gluu.org/maven/org/xdi/oxauth-model/2.4.3.Final/oxauth-model-2.4.3.Final.jar -O /opt/gluu/lib/oxauth-model-2.4.3.Final.jar
RUN wget -q http://ox.gluu.org/maven/org/xdi/oxauth-server/2.4.3.Final/oxauth-server-2.4.3.Final.jar -O /opt/gluu/lib/oxauth-server-2.4.3.Final.jar

# Directory for certificates
RUN mkdir -p /etc/certs

RUN mkdir -p /opt/opendj/template/config/schema
RUN mkdir -p /opt/opendj/ldif

# Copy static templates
COPY opendj_index.json /opt/opendj
COPY o_site.ldif /opt/opendj/ldif
COPY 101-ox.ldif /opt/opendj/template/config/schema
COPY 77-customAttributes.ldif /opt/opendj/template/config/schema
COPY 96-eduperson.ldif /opt/opendj/template/config/schema

LABEL vendor="Gluu Federation" \
      org.gluu.gluu-opendj.version="2.6.0" \
      org.gluu.gluu-opendj.build-date="2016-02-10" \
      org.gluu.oxauth-server.version="2.4.3" \
      org.gluu.oxauth-server.build-date="2016-04-08" \
      org.gluu.oxauth-model.version="2.4.3" \
      org.gluu.oxauth-model.build-date="2016-04-08"

# LDAP port
EXPOSE 1389

# LDAPS port
EXPOSE 1636

# admin connector port
EXPOSE 4444

# JMX port
EXPOSE 1689

# replication port
EXPOSE 8989
