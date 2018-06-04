#!/bin/bash

set -e

MANAGER_PRIV_ADDR=$(docker-machine ssh manager ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
WORKER_1_PRIV_ADDR=$(docker-machine ssh worker-1 ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
WORKER_2_PRIV_ADDR=$(docker-machine ssh worker-2 ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')

REDIS_1_CONFIG='port 6379
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes'

REDIS_2_CONFIG='port 6380
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes'

REDIS_3_CONFIG='port 6381
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes'

for node in manager worker-1 worker-2; do
    case $node in
        manager)
            priv_addr=$MANAGER_PRIV_ADDR
            ;;
        worker-1)
            priv_addr=$WORKER_1_PRIV_ADDR
            ;;
        worker-2)
            priv_addr=$WORKER_2_PRIV_ADDR
            ;;
    esac

    echo "[I] Deploying redis containers for $node node"
    eval $(docker-machine env $node)

    docker run \
        -d \
        -e REDIS_CONFIG_FILE="/usr/local/etc/redis/redis.conf" \
        -e REDIS_CONFIG="$REDIS_1_CONFIG" \
        -p $priv_addr:6379:6379 \
        -p $priv_addr:16379:16379 \
        -l "SERVICE_IGNORE=yes" \
        --name gluu_redis_1.$node \
        --network gluu \
        --network-alias redis.server \
        --restart unless-stopped \
        redis:alpine sh -c 'mkdir -p $(dirname $REDIS_CONFIG_FILE) && echo "$REDIS_CONFIG" > $REDIS_CONFIG_FILE && redis-server $REDIS_CONFIG_FILE'

    docker run \
        -d \
        -e REDIS_CONFIG_FILE="/usr/local/etc/redis/redis.conf" \
        -e REDIS_CONFIG="$REDIS_2_CONFIG" \
        -p $priv_addr:6380:6380 \
        -p $priv_addr:16380:16380 \
        -l "SERVICE_IGNORE=yes" \
        --name gluu_redis_2.$node \
        --network gluu \
        --network-alias redis.server \
        --restart unless-stopped \
        redis:alpine sh -c 'mkdir -p $(dirname $REDIS_CONFIG_FILE) && echo "$REDIS_CONFIG" > $REDIS_CONFIG_FILE && redis-server $REDIS_CONFIG_FILE'

    docker run \
        -d \
        -e REDIS_CONFIG_FILE="/usr/local/etc/redis/redis.conf" \
        -e REDIS_CONFIG="$REDIS_3_CONFIG" \
        -p $priv_addr:6381:6381 \
        -p $priv_addr:16381:16381 \
        -l "SERVICE_IGNORE=yes" \
        --name gluu_redis_3.$node \
        --network gluu \
        --network-alias redis.server \
        --restart unless-stopped \
        redis:alpine sh -c 'mkdir -p $(dirname $REDIS_CONFIG_FILE) && echo "$REDIS_CONFIG" > $REDIS_CONFIG_FILE && redis-server $REDIS_CONFIG_FILE'

    eval $(docker-machine env -u)
done

echo "[I] Creating Redis cluster"
eval $(docker-machine env manager)

# run the redis-trib.rb script
docker run -it --rm --network gluu ruby:alpine sh -c "\
    gem install redis \
    && wget -q http://download.redis.io/redis-stable/src/redis-trib.rb \
    && ruby redis-trib.rb create --replicas 2 \
        $MANAGER_PRIV_ADDR:6379 $MANAGER_PRIV_ADDR:6380 $MANAGER_PRIV_ADDR:6381 \
        $WORKER_1_PRIV_ADDR:6379 $WORKER_1_PRIV_ADDR:6380 $WORKER_1_PRIV_ADDR:6381 \
        $WORKER_2_PRIV_ADDR:6379 $WORKER_2_PRIV_ADDR:6380 $WORKER_2_PRIV_ADDR:6381"

eval $(docker-machine env -u)
