#!/bin/bash

NODE_ID=$(docker node inspect manager-1 --format '{{.ID}}')

docker-machine ssh manager-1 \
    docker run \
    -d \
    -e GLUU_LDAP_INIT=true \
    -e GLUU_LDAP_INIT_HOST=ldap.server \
    -e GLUU_CACHE_TYPE=REDIS \
    -e GLUU_REDIS_URL=redis.server:6379 \
    -e GLUU_KV_HOST=consul.server \
    -e GLUU_OXTRUST_CONFIG_GENERATION=true \
    -e GLUU_LDAP_ADDR_INTERFACE=eth0 \
    -e GLUU_LDAP_ADVERTISE_ADDR=ldap.$NODE_ID \
    -v /opt/opendj/db:/opt/opendj/db \
    -v /opt/opendj/config:/opt/opendj/config \
    -v /opt/opendj/ldif:/opt/opendj/ldif \
    -v /opt/opendj/logs:/opt/opendj/logs \
    -v /flag:/flag \
    --name gluu_ldap_init.$NODE_ID \
    --network-alias ldap.server \
    --network-alias ldap.$NODE_ID \
    --network gluu \
    --restart unless-stopped \
    gluufederation/opendj:3.1.2_dev
