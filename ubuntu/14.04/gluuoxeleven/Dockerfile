FROM tomcat:7

MAINTAINER Shouro <shouro@gluu.org>

ENV OXELINK https://ox.gluu.org/maven/org/gluu/oxeleven-server/2.4.4.sp1/oxeleven-server-2.4.4.sp1.war

#RUN groupadd -r tomcat && useradd -r -g tomcat tomcat

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

#install gosu
RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64' && chmod +x /usr/local/bin/gosu

COPY oxeleven-config.json.tmpl /usr/local/tomcat/conf
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080
CMD ["oxeleven", "1234"]
