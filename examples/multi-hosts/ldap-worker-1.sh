#!/bin/bash

set -e

docker-machine ssh worker-1 \
    docker run \
    -d \
    -e GLUU_LDAP_INIT=false \
    -e GLUU_KV_HOST=consul.server \
    -e GLUU_LDAP_ADDR_INTERFACE=eth0 \
    -e GLUU_LDAP_ADVERTISE_ADDR=ldap.worker-1 \
    -v /opt/opendj/db:/opt/opendj/db \
    -v /opt/opendj/config:/opt/opendj/config \
    -v /opt/opendj/ldif:/opt/opendj/ldif \
    -v /opt/opendj/logs:/opt/opendj/logs \
    -l "SERVICE_IGNORE=yes" \
    --hostname ldap.worker-1 \
    --name gluu_ldap_peer.worker-1 \
    --network-alias ldap.server \
    --network-alias ldap.worker-1 \
    --network gluu \
    --restart unless-stopped \
    gluufederation/opendj:3.1.3_dev
