FROM saltminion

MAINTAINER Shouro shouro@gluu.org

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    wget \
    apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
&& gpg --verify /usr/local/bin/gosu.asc \
&& rm /usr/local/bin/gosu.asc \
&& chmod +x /usr/local/bin/gosu

#ENV variables
ENV OXTRUST_DOWNLOAD_URL http://ox.gluu.org/maven/org/xdi/oxtrust-server/1.7.0.Beta6/oxtrust-server-1.7.0.Beta6.war
ENV TOMCAT_DOWNLOAD_URL http://mirrors.advancedhosters.com/apache/tomcat/tomcat-7/v7.0.57/bin/apache-tomcat-7.0.57.tar.gz

RUN wget -q "$TOMCAT_DOWNLOAD_URL" -P /tmp && tar -xzf /tmp/apache-tomcat-7.0.57.tar.gz -C /opt && rm -f /tmp/apache-tomcat-7.0.57.tar.gz
RUN ln -sf /opt/apache-tomcat-7.0.57 /opt/tomcat
RUN wget -q "$OXTRUST_DOWNLOAD_URL" -P /tmp && mv /tmp/oxtrust-server-1.7.0.Beta6.war /tmp/oxtrust.war && cp /tmp/oxtrust.war /opt/tomcat/webapps && rm -f /tmp/oxtrust.war

EXPOSE 8009
EXPOSE 8005
EXPOSE 80