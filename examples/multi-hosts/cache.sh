#!/bin/bash

MANAGER_1_NODE_ID=$(docker node inspect manager-1 --format '{{.ID}}')
WORKER_1_NODE_ID=$(docker node inspect worker-1 --format '{{.ID}}')

docker-machine ssh manager-1 \
    docker run \
    -d \
    --name gluu_redis.$MANAGER_1_NODE_ID \
    --network gluu \
    --network-alias redis.$MANAGER_1_NODE_ID \
    --network-alias redis.server \
    --restart unless-stopped \
    redis:alpine

docker-machine ssh worker-1 \
    docker run \
    -d \
    --name gluu_redis.$WORKER_1_NODE_ID \
    --network gluu \
    --network-alias redis.$WORKER_1_NODE_ID \
    --network-alias redis.server \
    --restart unless-stopped \
    redis:alpine

sed -e "s@REDIS_MANAGER_1@redis.$MANAGER_1_NODE_ID@" \
    -e "s@REDIS_WORKER_1@redis.$WORKER_1_NODE_ID@" $PWD/nutcracker.yml.tmpl > $PWD/volumes/nutcracker.yml
docker-machine scp $PWD/volumes/nutcracker.yml manager-1:/root/
docker-machine scp $PWD/volumes/nutcracker.yml worker-1:/root/
docker stack deploy -c $PWD/cache.yml gluu
