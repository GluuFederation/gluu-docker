FROM gluubase

MAINTAINER Shouro <shouro@gluu.org>

RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-evasive \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80
EXPOSE 443
