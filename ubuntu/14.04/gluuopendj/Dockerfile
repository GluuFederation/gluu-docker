FROM saltminion

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y \
    openjdk-7-jre-headless \
    unzip \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#ENV variables
ENV OPENDJ_DOWNLOAD_URL http://ox.gluu.org/maven/org/gluu/gluu-opendj/2.6.0/gluu-opendj-2.6.0.zip

RUN wget -q "$OPENDJ_DOWNLOAD_URL" -P /tmp && unzip -qq /tmp/gluu-opendj-2.6.0.zip -d /opt && rm -f /tmp/gluu-opendj-2.6.0.zip

EXPOSE 1636
