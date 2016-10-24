FROM tomcat:7

MAINTAINER Shouro <shouro@gluu.org>

ENV OXELINK https://ox.gluu.org/maven/org/gluu/oxeleven-server/2.4.4.sp1/oxeleven-server-2.4.4.sp1.war

RUN buildDeps=' \
        autoconf \
        automake \
        build-essential \
        libtool \
        libssl-dev \
        libsqlite3-dev \
    ' \
    && apt-get update && apt-get install -y $buildDeps git \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/opendnssec/SoftHSMv2.git /usr/src/SoftHSMv2 \
    && cd /usr/src/SoftHSMv2 \
    && sh autogen.sh \
    && ./configure \
    && make \
    && make install \
    && rm -rf /usr/src/SoftHSMv2 \
    && apt-get purge -y --auto-remove $buildDeps \
    && curl -L "$OXELINK" > /usr/local/tomcat/webapps/oxeleven.war

COPY oxeleven-config.json /usr/local/tomcat/conf

EXPOSE 8080