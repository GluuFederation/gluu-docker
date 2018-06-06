#!/bin/sh

set -e

docker-machine ssh manager \
    docker run \
    -d \
    -e GLUU_LDAP_INIT=true \
    -e GLUU_LDAP_INIT_HOST=ldap.server \
    -e GLUU_CACHE_TYPE=REDIS \
    -e GLUU_REDIS_URL=twemproxy.server:22122 \
    -e GLUU_KV_HOST=consul.server \
    -e GLUU_OXTRUST_CONFIG_GENERATION=true \
    -e GLUU_LDAP_ADDR_INTERFACE=eth0 \
    -e GLUU_LDAP_ADVERTISE_ADDR=ldap.manager \
    -v /opt/opendj/db:/opt/opendj/db \
    -v /opt/opendj/config:/opt/opendj/config \
    -v /opt/opendj/ldif:/opt/opendj/ldif \
    -v /opt/opendj/logs:/opt/opendj/logs \
    -v /opt/opendj/flag:/flag \
    -l "SERVICE_IGNORE=yes" \
    --hostname ldap.manager \
    --name gluu_ldap_init.manager \
    --network-alias ldap.server \
    --network-alias ldap.manager \
    --network gluu \
    --restart unless-stopped \
    gluufederation/opendj:latest
