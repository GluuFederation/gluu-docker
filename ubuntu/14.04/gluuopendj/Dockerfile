FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r ldap && useradd -r -g ldap ldap

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    unzip \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#ENV variables
ENV OPENDJ_DOWNLOAD_URL http://ox.gluu.org/maven/org/gluu/gluu-opendj/2.6.0/gluu-opendj-2.6.0.zip

RUN wget -q "$OPENDJ_DOWNLOAD_URL" -P /tmp && unzip -qq /tmp/gluu-opendj-2.6.0.zip -d /opt && rm -f /tmp/gluu-opendj-2.6.0.zip

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
