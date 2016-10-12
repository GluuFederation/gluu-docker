FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    facter \
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
ENV OXTRUST_DOWNLOAD_URL https://ox.gluu.org/maven/org/xdi/oxtrust-server/${OX_VERSION}/oxtrust-server-${OX_VERSION}.war

# the LABEL defined before downloading ox war/jar files to make sure
# it gets the latest build for specific version
LABEL vendor="Gluu Federation" \
      org.gluu.oxtrust-server.version="${OX_VERSION}" \
      org.gluu.oxtrust-server.build-date="${OX_BUILD_DATE}"

# Install oxTrust
RUN wget -q ${OXTRUST_DOWNLOAD_URL} -O /tmp/oxtrust.war \
    && unzip -qq /tmp/oxtrust.war -d /opt/tomcat/webapps/identity \
    && rm -f /tmp/oxtrust.war

# Install utility scripts
RUN wget -q https://raw.githubusercontent.com/GluuFederation/gluu-util/master/check_ssl/check_ssl.py -O /usr/bin/check_ssl.py \
    && chmod +x /usr/bin/check_ssl.py

ENV JYTHON_VERSION 2.7.0
ENV JYTHON_DOWNLOAD_URL http://central.maven.org/maven2/org/python/jython-standalone/${JYTHON_VERSION}/jython-standalone-${JYTHON_VERSION}.jar

# Install Jython
RUN wget -q ${JYTHON_DOWNLOAD_URL} -O /tmp/jython.jar \
    && unzip -q /tmp/jython.jar -d /opt/jython \
    && ln -sf /opt/jython/Lib /opt/tomcat/webapps/identity/WEB-INF/lib/Lib \
    && rm -f /tmp/jython.jar

 # Directory for certificates
RUN mkdir -p /etc/certs

# Directory required by oxTrust
RUN mkdir -p /var/ox/photos /var/ox/oxtrust/removed /var/ox/oxtrust/vds-snapshots

# Directory for custom oxTrust context
RUN mkdir -p /opt/tomcat/conf/Catalina/localhost

# Directory for custom files
RUN mkdir -p /var/gluu/webapps/oxtrust \
    && mkdir -p /var/gluu/webapps/oxtrust/pages \
    && mkdir -p /var/gluu/webapps/oxtrust/resources \
    && mkdir -p /var/gluu/webapps/oxtrust/libs

# Unpack Shib config
RUN unzip -q /opt/tomcat/webapps/identity/WEB-INF/lib/oxtrust-configuration-${OX_VERSION}.jar shibboleth2/* -d /opt/tomcat/conf

# Copy static templates
COPY setenv.sh /opt/tomcat/bin
COPY attribute-resolver.xml.vm /opt/tomcat/conf/shibboleth2/idp
COPY oxTrustLogRotationConfiguration.xml /opt/tomcat/conf
COPY identity.xml /opt/tomcat/conf/Catalina/localhost
COPY index.html /opt/tomcat/webapps/ROOT

RUN mkdir -p /opt/tomcat/endorsed
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk16/1.46/bcprov-jdk16-1.46.jar -O /opt/tomcat/endorsed/bcprov-jdk16-1.46.jar

# Ports required by tomcat
EXPOSE 8009
EXPOSE 8005

# Ports required by apache
EXPOSE 80
EXPOSE 443
