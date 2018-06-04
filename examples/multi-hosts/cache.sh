#!/bin/bash

set -e

MANAGER_PRIV_ADDR=$(docker-machine ssh manager ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
WORKER_1_PRIV_ADDR=$(docker-machine ssh worker-1 ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
WORKER_2_PRIV_ADDR=$(docker-machine ssh worker-2 ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')

sed -e "s@MANAGER_PRIV_ADDR@$MANAGER_PRIV_ADDR@" \
    -e "s@WORKER_1_PRIV_ADDR@$WORKER_1_PRIV_ADDR@" \
    -e "s@WORKER_2_PRIV_ADDR@$WORKER_2_PRIV_ADDR@" \
    nutcracker.yml.tmpl > volumes/nutcracker.yml

for node in manager worker-1 worker-2; do
    priv_ip=$(docker-machine ssh $node ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')

    docker-machine ssh $node docker run \
        -d \
        -p $priv_ip:6379:6379 \
        -v /opt/redis:/data \
        -l "SERVICE_IGNORE=yes" \
        --name gluu_redis.$node \
        --network gluu \
        --network-alias redis.$node \
        --network-alias redis.server \
        --restart unless-stopped \
        redis:alpine redis-server --appendonly yes
    docker-machine scp volumes/nutcracker.yml $node:/root/
done

docker stack deploy -c cache.yml gluu
