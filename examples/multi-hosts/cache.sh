#!/bin/bash

set -e

for node in manager worker-1 worker-2; do
    docker-machine scp nutcracker.yml $node:/root/
done

docker stack deploy -c redis.yml gluu
sleep 5
docker stack deploy -c twemproxy.yml gluu
