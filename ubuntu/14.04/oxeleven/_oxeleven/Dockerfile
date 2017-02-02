FROM gluufederation/base

MAINTAINER Shouro <shouro@gluu.org>

ENV OXELEVENLINK https://ox.gluu.org/maven/org/gluu/oxeleven-server/3.0.0-SNAPSHOT/oxeleven-server-3.0.0-SNAPSHOT.war

RUN groupadd -r jetty && useradd -r -g jetty jetty

# SoftHSM2 repo
RUN echo "deb http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && echo "deb-src http://ppa.launchpad.net/pkg-opendnssec/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/opendnssec.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 26535DB3

# JDK 8 repo
#RUN echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
#    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/openjdk.list \
#    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 86F44E2A

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    tomcat7 \
    softhsm2 \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# workaround for bug on ubuntu 14.04 with openjdk-8-jre-headless
#RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

#ENV JETTY_VERSION 9.3.12.v20160915
#ENV JETTY_TGZ_URL https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${JETTY_VERSION}/jetty-distribution-${JETTY_VERSION}.tar.gz

# Install jetty
#RUN wget -q ${JETTY_TGZ_URL} -O /tmp/jetty.tar.gz \
#    && tar -xzf /tmp/jetty.tar.gz -C /opt \
#    && mv /opt/jetty-distribution-${JETTY_VERSION} /opt/jetty \
#    && rm -rf /tmp/jetty.tar.gz

# Install oxEleven in jetty
#RUN wget -q https://ox.gluu.org/maven/org/gluu/oxeleven-server/3.0.0-SNAPSHOT/oxeleven-server-3.0.0-SNAPSHOT.war -O /tmp/oxeleven.war \
#    && mkdir -p /opt/jetty_base/oxeleven/webapps \
#    && unzip -qq /tmp/oxeleven.war -d /opt/jetty_base/oxeleven/webapps/oxeleven \
#    && cd /opt/jetty_base/oxeleven \
#    && java -jar /opt/jetty/start.jar --add-to-start=deploy,http,logging,jsp \
#    && rm -f /tmp/oxeleven.war

# Install oxEleven in tomcat
RUN wget -q "$OXELEVENLINK" -O /var/lib/tomcat7/webapps/oxeleven.war

# Directory for certificates
#RUN mkdir -p /etc/certs

# Directory for config required by oxEleven (e.g. oxeleven-config.json)
COPY oxeleven-config.json.tmpl /tmp
COPY setup_n_render.sh /tmp
RUN chmod +x /tmp/setup_n_render.sh
RUN /tmp/setup_n_render.sh
RUN cp /tmp/oxeleven-config.json /var/lib/tomcat7/conf
RUN rm /tmp/oxeleven-config.json.tmpl
RUN rm /tmp/setup_n_render.sh
COPY jetty.conf /etc/supervisor/conf.d

LABEL vendor="Gluu Federation" \
      org.gluu.oxeleven-server.version="3.0.0-SNAPSHOT" \
      org.gluu.oxeleven-server.build-date="2017-01-25"

# Ports required by jetty
EXPOSE 8080
