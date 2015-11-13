FROM gluubase

MAINTAINER Isman <isman@gluu.org>

RUN apt-get update && apt-get install -y \
    nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Directory for certificates
RUN mkdir -p /etc/certs

# Ports for nginx
EXPOSE 80
EXPOSE 443
