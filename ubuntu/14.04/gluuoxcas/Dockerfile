FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

# We need to install JDK to have jar executable which is required for
# customizing and re-building cas.war
RUN apt-get update && apt-get install -y \
    openjdk-7-jdk \
    wget \
    unzip \
    apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV TOMCAT_VERSION 7.0.65
ENV TOMCAT_DOWNLOAD_URL http://archive.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Install Tomcat
RUN wget -q ${TOMCAT_DOWNLOAD_URL} -O /tmp/tomcat.tar.gz \
    && tar -xzf /tmp/tomcat.tar.gz -C /opt \
    && mv /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat \
    && rm -f /tmp/tomcat.tar.gz

ENV OX_VERSION 2.4.4.sp1
ENV OX_BUILD_DATE 2016-10-12
ENV OXCAS_DOWNLOAD_URL https://ox.gluu.org/maven/org/xdi/ox-cas-server-webapp/${OX_VERSION}/ox-cas-server-webapp-${OX_VERSION}.war

LABEL vendor="Gluu Federation" \
      org.gluu.oxcas-server-webapp.version="${OX_VERSION}" \
      org.gluu.oxcas-server-webapp.build-date="${OX_BUILD_DATE}"

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
# Install oxCas
RUN wget -q ${OXCAS_DOWNLOAD_URL} -O /tmp/oxcas.war \
    && cp /tmp/oxcas.war /opt/tomcat/webapps \
    && rm -f /tmp/oxcas.war

RUN mkdir -p /etc/certs
RUN mkdir -p /tmp/cas

# Ports required by Tomcat
EXPOSE 8009
EXPOSE 8005

# Ports required by apache2
EXPOSE 80
EXPOSE 443
