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

# Install Tomcat
RUN wget -q https://olex-secure.openlogic.com/content/openlogic/tomcat/7.0.65/apache-tomcat-7.0.65.tar.gz -O /tmp/tomcat.tar.gz \
    && tar -xzf /tmp/tomcat.tar.gz -C /opt \
    && mv /opt/apache-tomcat-7.0.65 /opt/tomcat \
    && rm -f /tmp/tomcat.tar.gz

# Install oxTrust
RUN wget -q https://ox.gluu.org/maven/org/xdi/oxtrust-server/2.4.4/oxtrust-server-2.4.4.war -O /tmp/oxtrust.war \
    && unzip -qq /tmp/oxtrust.war -d /opt/tomcat/webapps/identity \
    && rm -f /tmp/oxtrust.war

# Install utility scripts
RUN wget -q https://raw.githubusercontent.com/GluuFederation/gluu-util/master/check_ssl/check_ssl.py -O /usr/bin/check_ssl.py \
    && chmod +x /usr/bin/check_ssl.py

# Install Jython
RUN wget -q http://central.maven.org/maven2/org/python/jython-standalone/2.7.0/jython-standalone-2.7.0.jar -O /tmp/jython-standalone-2.7.0.jar \
    && unzip -q /tmp/jython-standalone-2.7.0.jar -d /opt/jython \
    && ln -sf /opt/jython/Lib /opt/tomcat/webapps/identity/WEB-INF/lib/Lib \
    && rm -f /tmp/jython-standalone-2.7.0.jar

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
RUN unzip -q /opt/tomcat/webapps/identity/WEB-INF/lib/oxtrust-configuration-2.4.4.jar shibboleth2/* -d /opt/tomcat/conf

# Copy static templates
COPY setenv.sh /opt/tomcat/bin
COPY attribute-resolver.xml.vm /opt/tomcat/conf/shibboleth2/idp
COPY oxTrustLogRotationConfiguration.xml /opt/tomcat/conf
COPY identity.xml /opt/tomcat/conf/Catalina/localhost
COPY index.html /opt/tomcat/webapps/ROOT

RUN mkdir -p /opt/tomcat/endorsed
RUN wget -q http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk16/1.46/bcprov-jdk16-1.46.jar -O /opt/tomcat/endorsed/bcprov-jdk16-1.46.jar

LABEL vendor="Gluu Federation" \
      org.gluu.oxtrust-server.version="2.4.4" \
      org.gluu.oxtrust-server.build-date="2016-08-01"

# Ports required by tomcat
EXPOSE 8009
EXPOSE 8005
EXPOSE 8443

# Ports required by apache
EXPOSE 80
EXPOSE 443
