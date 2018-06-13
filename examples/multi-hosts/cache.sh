#!/bin/bash

set -e


get_redis_name() {
    # get the latest redis container
    docker ps --filter name=redis --format '{{.Names}}' -l
}

lookup_redis() {
    docker exec $(get_redis_name) nslookup redis.server 127.0.0.11 2>&1 | tail -n +5 | awk -F ":" '{print $2}' | awk -F " " '{print $1}'
}

create_cluster() {
    ip_list=$(lookup_redis)
    if [ ! -z "$ip_list" ]; then
        # if IP list is not empty, format them as white-space separated value in 'host:port' format,
        # for example `10.0.0.2:6379 10.0.0.3:6379`, to conform to redis-trib command
        REDIS_CLUSTER=$(echo $ip_list | python -c "import sys; print ' '.join(['{}:6379'.format(l) for l in sys.stdin.read().split()])")

        if [ ! -z "$REDIS_CLUSTER" ]; then
            # run a container with tty in order to allow typing 'yes' when prompted
            docker run --rm -ti --network container:$(get_redis_name) iromli/redis-trib create --replicas 2 $REDIS_CLUSTER
        fi
    fi
}

get_cluster_url() {
    docker exec $(docker ps --filter name=redis --format '{{.Names}}' -l) redis-cli cluster nodes | awk -F '@' '{print $1}' | awk -F ' ' '{print $2}' | python -c "import sys; print ','.join([l for l in sys.stdin.read().split()])"
}

case $1 in
    "create-cluster")
        create_cluster
        ;;
    "get-cluster-url")
        get_cluster_url
        ;;
    "lookup-redis")
        lookup_redis
        ;;
esac
