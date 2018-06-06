#!/bin/bash

set -e

docker-machine ssh worker-2 \
    docker run \
    -d \
    -e GLUU_LDAP_INIT=false \
    -e GLUU_KV_HOST=consul.server \
    -e GLUU_LDAP_ADDR_INTERFACE=eth0 \
    -e GLUU_LDAP_ADVERTISE_ADDR=ldap.worker-2 \
    -v /opt/opendj/db:/opt/opendj/db \
    -v /opt/opendj/config:/opt/opendj/config \
    -v /opt/opendj/ldif:/opt/opendj/ldif \
    -v /opt/opendj/logs:/opt/opendj/logs \
    -l "SERVICE_IGNORE=yes" \
    --hostname ldap.worker-2 \
    --name gluu_ldap_peer.worker-2 \
    --network-alias ldap.server \
    --network-alias ldap.worker-2 \
    --network gluu \
    --restart unless-stopped \
    gluufederation/opendj:latest
