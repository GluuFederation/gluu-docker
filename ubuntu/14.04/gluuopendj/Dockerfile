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
ENV OPENDJ_DOWNLOAD_URL http://ox.gluu.org/maven/org/forgerock/opendj/opendj-server-legacy/3.0.0.gluu-SNAPSHOT/opendj-server-legacy-3.0.0.gluu-SNAPSHOT.zip

RUN wget -q "$OPENDJ_DOWNLOAD_URL" -P /tmp \
    && unzip -qq /tmp/opendj-server-legacy-3.0.0.gluu-SNAPSHOT.zip -d /opt \
    && rm -f /tmp/opendj-server-legacy-3.0.0.gluu-SNAPSHOT.zip

# JAR files required to generate OpenID Connect keys
RUN mkdir -p /opt/gluu/lib
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.54/bcprov-jdk15on-1.54.jar -O /opt/gluu/lib/bcprov-jdk15on-1.54.jar
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcpkix-jdk15on/1.54/bcpkix-jdk15on-1.54.jar -O /opt/gluu/lib/bcpkix-jdk15on-1.54.jar
RUN wget -q http://central.maven.org/maven2/org/codehaus/jettison/jettison/1.3/jettison-1.3.jar -O /opt/gluu/lib/jettison-1.3.jar
RUN wget -q http://central.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar -O /opt/gluu/lib/commons-lang-2.6.jar
RUN wget -q http://central.maven.org/maven2/log4j/log4j/1.2.14/log4j-1.2.14.jar -O /opt/gluu/lib/log4j-1.2.14.jar
RUN wget -q http://central.maven.org/maven2/commons-codec/commons-codec/1.5/commons-codec-1.5.jar -O /opt/gluu/lib/commons-codec-1.5.jar
RUN wget -q http://central.maven.org/maven2/commons-cli/commons-cli/1.2/commons-cli-1.2.jar -O /opt/gluu/lib/commons-cli-1.2.jar
RUN wget -q https://ox.gluu.org/maven/org/xdi/oxauth-model/2.4.4.sp1/oxauth-model-2.4.4.sp1.jar -O /opt/gluu/lib/oxauth-model.jar
RUN wget -q https://ox.gluu.org/maven/org/xdi/oxauth-server/2.4.4.sp1/oxauth-server-2.4.4.sp1.jar -O /opt/gluu/lib/oxauth-server.jar

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
      org.gluu.gluu-opendj.version="3.0.0-gluu" \
      org.gluu.gluu-opendj.build-date="2016-04-11" \
      org.gluu.oxauth-server.version="2.4.4.sp1" \
      org.gluu.oxauth-server.build-date="2016-09-28" \
      org.gluu.oxauth-model.version="2.4.4.sp1" \
      org.gluu.oxauth-model.build-date="2016-09-28"

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
