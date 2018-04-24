#!/bin/bash

NODE_ID=$(docker node inspect worker-1 --format '{{.ID}}')

docker-machine ssh worker-1 \
    docker run \
    -d \
    -e GLUU_LDAP_INIT=false \
    -e GLUU_KV_HOST=consul.server \
    -e GLUU_LDAP_ADDR_INTERFACE=eth0 \
    -e GLUU_LDAP_ADVERTISE_ADDR=ldap.$NODE_ID \
    -v /opt/opendj/db:/opt/opendj/db \
    -v /opt/opendj/config:/opt/opendj/config \
    -v /opt/opendj/ldif:/opt/opendj/ldif \
    -v /opt/opendj/logs:/opt/opendj/logs \
    --name gluu_ldap_peer.$NODE_ID \
    --network-alias ldap.server \
    --network-alias ldap.$NODE_ID \
    --network gluu \
    --restart unless-stopped \
    gluufederation/opendj:3.1.2_dev
