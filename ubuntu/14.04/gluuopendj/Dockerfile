FROM ubuntu:14.04

MAINTAINER shouro@gluu.org

RUN groupadd -r ldap && useradd -r -g ldap ldap

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    unzip \
    wget \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
&& gpg --verify /usr/local/bin/gosu.asc \
&& rm /usr/local/bin/gosu.asc \
&& chmod +x /usr/local/bin/gosu

#ENV variables
ENV OPENDJ_DOWNLOAD_URL http://ox.gluu.org/maven/org/gluu/gluu-opendj/2.6.0/gluu-opendj-2.6.0.zip

RUN wget -q "$OPENDJ_DOWNLOAD_URL" -P /tmp && unzip -qq /tmp/gluu-opendj-2.6.0.zip -d /opt && rm -f /tmp/gluu-opendj-2.6.0.zip

COPY ldappw /root/.ldappw

#opendj setup
RUN /opt/opendj/setup \
    --cli \
    --no-prompt \
    --doNotStart \
    --baseDN o=gluu \
    --hostname localhost \
    --ldapPort 1389 \
    --ldapsPort 1636 \
    --adminConnectorPort 4444 \
    --rootUserDN "cn=Directory Manager" \
    --rootUserPasswordFile /root/.ldappw \
    --noPropertiesFile \
    --generateSelfSignedCertificate \
    --acceptLicense

#todo opendj config
RUN /opt/opendj/bin/dsconfig \
    --trustAll \
    --no-prompt \
    --hostname localgost \
    --port 4444 \
    --bindDN "cn=directory manager" \
    --bindPasswordFile /root/.ldappw \
    set-global-configuration-prop --set single-structural-objectclass-behavior:accept \
    set-attribute-syntax-prop --syntax-name "Directory String" --set allow-zero-length-values:true \
    set-password-policy-prop --policy-name "Default Password Policy" --set allow-pre-encoded-passwords:true \
    set-log-publisher-prop --publisher-name "File-Based Audit Logger" --set enabled:true \
    create-backend --backend-name site --set base-dn:o=site --type local-db --set enabled:true

RUN mkdir /etc/certs
RUN touch /root/.ldappw

VOLUME ["/etc/certs"]

COPY schema /opt/opendj/config/schema

