#!/bin/sh

REDIS_CLUSTER_URL=$(sh ../redis/redis-cluster.sh get-cluster-url)
cat opendj.yaml | sed -s "s@REDIS_CLUSTER_URL@$REDIS_CLUSTER_URL@g" | kubectl apply -f -
