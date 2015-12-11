FROM gluubase

MAINTAINER Isman <isman@gluu.org>

RUN echo 'deb http://ppa.launchpad.net/rob-gallagher-6/nginx-upstream-sticky/ubuntu trusty main' >> /etc/apt/sources.list.d/ngx_sticky.list \
    && echo 'deb-src http://ppa.launchpad.net/rob-gallagher-6/nginx-upstream-sticky/ubuntu trusty main' >> /etc/apt/sources.list.d/ngx_sticky.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7881406D

RUN apt-get update \
    && apt-get install -y nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Directory for certificates
RUN mkdir -p /etc/certs
RUN openssl dhparam -out /etc/certs/dhparams.pem 2048

# Ports for nginx
EXPOSE 80
EXPOSE 443
