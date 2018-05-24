#!/bin/bash

MANAGER_1_NODE_ID=manager-1
WORKER_1_NODE_ID=worker-1

MANAGER_1_PRIV_ADDR=$(docker-machine ssh manager-1 ifconfig eth1|grep 'inet addr'|cut -d: -f2|awk '{print $1}')
WORKER_1_PRIV_ADDR=$(docker-machine ssh worker-1 ifconfig eth1|grep 'inet addr'|cut -d: -f2|awk '{print $1}')

docker-machine ssh manager-1 \
    docker run \
    -d \
    -p $MANAGER_1_PRIV_ADDR:6379:6379 \
    -v /opt/redis:/data \
    --name gluu_redis.$MANAGER_1_NODE_ID \
    --network gluu \
    --network-alias redis.$MANAGER_1_NODE_ID \
    --network-alias redis.server \
    --restart unless-stopped \
    redis:alpine redis-server --appendonly yes

docker-machine ssh worker-1 \
    docker run \
    -d \
    -p $WORKER_1_PRIV_ADDR:6379:6379 \
    -v /opt/redis:/data \
    --name gluu_redis.$WORKER_1_NODE_ID \
    --network gluu \
    --network-alias redis.$WORKER_1_NODE_ID \
    --network-alias redis.server \
    --restart unless-stopped \
    redis:alpine redis-server --appendonly yes

sed -e "s@MANAGER_1_PRIV_ADDR@$MANAGER_1_PRIV_ADDR@" \
    -e "s@WORKER_1_PRIV_ADDR@$WORKER_1_PRIV_ADDR@" $PWD/nutcracker.yml.tmpl > $PWD/volumes/nutcracker.yml
docker-machine scp $PWD/volumes/nutcracker.yml manager-1:/root/
docker-machine scp $PWD/volumes/nutcracker.yml worker-1:/root/
docker stack deploy -c $PWD/cache.yml gluu
