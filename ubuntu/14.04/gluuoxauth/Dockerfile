FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
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
ENV OXAUTH_DOWNLOAD_URL https://ox.gluu.org/maven/org/xdi/oxauth-server/${OX_VERSION}/oxauth-server-${OX_VERSION}.war

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
LABEL vendor="Gluu Federation" \
      org.gluu.oxauth-server.version="${OX_VERSION}" \
      org.gluu.oxauth-server.build-date="${OX_BUILD_DATE}"

# Install oxAuth
RUN wget -q ${OXAUTH_DOWNLOAD_URL} -O /tmp/oxauth.war \
    && unzip -qq /tmp/oxauth.war -d /opt/tomcat/webapps/oxauth \
    && rm -f /tmp/oxauth.war

ENV JYTHON_VERSION 2.7.0
ENV JYTHON_DOWNLOAD_URL http://central.maven.org/maven2/org/python/jython-standalone/${JYTHON_VERSION}/jython-standalone-${JYTHON_VERSION}.jar

# Install Jython
RUN wget -q ${JYTHON_DOWNLOAD_URL} -O /tmp/jython.jar \
    && unzip -q /tmp/jython.jar -d /opt/jython \
    && ln -sf /opt/jython/Lib /opt/tomcat/webapps/oxauth/WEB-INF/lib/Lib \
    && rm -f /tmp/jython.jar

# Directory for certificates
RUN mkdir -p /etc/certs

# Directory for scripts, e.g. duo_web.py
RUN mkdir -p /opt/tomcat/conf/python

# Directory for custom oxAuth context
RUN mkdir -p /opt/tomcat/conf/Catalina/localhost

# Directory for custom files
RUN mkdir -p /var/gluu/webapps/oxauth \
    && mkdir -p /var/gluu/webapps/oxauth/pages \
    && mkdir -p /var/gluu/webapps/oxauth/resources \
    && mkdir -p /var/gluu/webapps/oxauth/libs

# Copy static templates
COPY duo_web.py /opt/tomcat/conf/python
COPY cert_creds.json /etc/certs
COPY duo_creds.json /etc/certs
COPY gplus_client_secrets.json /etc/certs
COPY super_gluu_creds.json /etc/certs
COPY setenv.sh /opt/tomcat/bin

RUN mkdir -p /opt/tomcat/endorsed
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk16/1.46/bcprov-jdk16-1.46.jar -O /opt/tomcat/endorsed/bcprov-jdk16-1.46.jar

# Ports required by tomcat
EXPOSE 8009
EXPOSE 8005

# Ports required by Apache
EXPOSE 80
EXPOSE 443
