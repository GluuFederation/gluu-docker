FROM gluufederation/base

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r jetty && useradd -r -g jetty jetty

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

RUN mv ${JETTY_HOME}/etc/webdefault.xml ${JETTY_HOME}/etc/webdefault.xml.bak
RUN mv ${JETTY_HOME}/etc/jetty.xml ${JETTY_HOME}/etc/jetty.xml.bak
COPY webdefault.xml ${JETTY_HOME}/etc/
COPY jetty.xml ${JETTY_HOME}/etc/

# ======
# Jython
# ======

ENV JYTHON_VERSION 2.7.0
ENV JYTHON_DOWNLOAD_URL http://central.maven.org/maven2/org/python/jython-standalone/${JYTHON_VERSION}/jython-standalone-${JYTHON_VERSION}.jar

# Install Jython
RUN wget -q ${JYTHON_DOWNLOAD_URL} -O /tmp/jython.jar \
    && unzip -q /tmp/jython.jar -d /opt/jython \
    && rm -f /tmp/jython.jar

# ======
# oxAuth
# ======

ENV OX_VERSION 3.0.0-SNAPSHOT
ENV OX_BUILD_DATE 2017-02-02
ENV OXAUTH_DOWNLOAD_URL https://ox.gluu.org/maven/org/xdi/oxauth-server/${OX_VERSION}/oxauth-server-${OX_VERSION}.war

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
LABEL vendor="Gluu Federation" \
      org.gluu.oxauth-server.version="${OX_VERSION}" \
      org.gluu.oxauth-server.build-date="${OX_BUILD_DATE}"

# Install oxAuth
RUN wget -q ${OXAUTH_DOWNLOAD_URL} -O /tmp/oxauth.war \
    && mkdir -p ${JETTY_BASE}/oxauth/webapps \
    && unzip -qq /tmp/oxauth.war -d ${JETTY_BASE}/oxauth/webapps/oxauth \
    && java -jar ${JETTY_HOME}/start.jar jetty.home=${JETTY_HOME} jetty.base=${JETTY_BASE}/oxauth --add-to-start=deploy,http,logging,jsp,servlets,ext,http-forwarded \
    && rm -f /tmp/oxauth.war

RUN mkdir -p ${JETTY_USER_HOME_LIB}
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk16/1.46/bcprov-jdk16-1.46.jar -O ${JETTY_USER_HOME_LIB}/bcprov-jdk16-1.46.jar

# Directory for certificates
RUN mkdir -p /etc/certs

# Directory for scripts, e.g. duo_web.py
RUN mkdir -p /opt/gluu/python/libs

# Directory for custom pages and static files
RUN mkdir -p ${JETTY_BASE}/oxauth/custom/pages ${JETTY_BASE}/oxauth/custom/static

# Copy static templates
COPY duo_web.py /opt/gluu/python/libs
COPY python.txt /opt/gluu/python/libs
COPY duo_creds.json /etc/certs
COPY gplus_client_secrets.json /etc/certs
COPY super_gluu_creds.json /etc/certs
COPY cert_creds.json /etc/certs
COPY otp_configuration.json /etc/certs
COPY oxauth_web_resources.xml ${JETTY_BASE}/oxauth/webapps
COPY jetty.supervisord.conf /etc/supervisor/conf.d

# Ports required by jetty
EXPOSE 8080
