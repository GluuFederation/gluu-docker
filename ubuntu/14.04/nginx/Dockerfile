FROM gluufederation/base

MAINTAINER Isman <isman@gluu.org>

RUN echo 'deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main' >> /etc/apt/sources.list.d/nginx.list \
    && echo 'deb-src http://ppa.launchpad.net/nginx/stable/ubuntu trusty main ' >> /etc/apt/sources.list.d/nginx.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C

RUN apt-get update \
    && apt-get install -y nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Directory for certificates
RUN mkdir -p /etc/certs
RUN openssl dhparam -out /etc/certs/dhparams.pem 2048

COPY index.html /usr/share/nginx/html

LABEL vendor="Gluu Federation"

# Ports for nginx
EXPOSE 80
EXPOSE 443
