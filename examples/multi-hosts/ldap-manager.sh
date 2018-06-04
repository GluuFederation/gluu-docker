#!/bin/sh

set -e

MANAGER_PRIV_ADDR=$(docker-machine ssh manager ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
WORKER_1_PRIV_ADDR=$(docker-machine ssh worker-1 ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
WORKER_2_PRIV_ADDR=$(docker-machine ssh worker-2 ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')

REDIS_CLUSTER_URL="$MANAGER_PRIV_ADDR:6379,$MANAGER_PRIV_ADDR:6380,$MANAGER_PRIV_ADDR:6381,$WORKER_1_PRIV_ADDR:6379,$WORKER_1_PRIV_ADDR:6380,$WORKER_1_PRIV_ADDR:6381,$WORKER_2_PRIV_ADDR:6379,$WORKER_2_PRIV_ADDR:6380,$WORKER_2_PRIV_ADDR:6381"

docker-machine ssh manager \
    docker run \
    -d \
    -e GLUU_LDAP_INIT=true \
    -e GLUU_LDAP_INIT_HOST=ldap.server \
    -e GLUU_CACHE_TYPE=REDIS \
    -e GLUU_REDIS_URL=$REDIS_CLUSTER_URL \
    -e GLUU_REDIS_TYPE=CLUSTER \
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
    gluufederation/opendj:3.1.3_dev
