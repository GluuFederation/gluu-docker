#!/bin/bash

set -e

node_up() {
    node=$1
    status=$(docker-machine ls --filter "name=${node}" --format '{{ .State }}')
    case $status in
    "Running")
        echo "[I] Node ${node} is running"
        ;;
    "Stopped")
        echo "[W] Node ${node} is stopped"
        echo "[I] Restarting ${node} node"
        docker-machine restart $node
        ;;
    esac
}

load_manager() {
    if [[ -z $(docker-machine ls --filter name=manager-1 -q) ]]; then
        echo "[I] Creating manager-1 node as Swarm manager"

        docker-machine create \
            --driver=digitalocean \
            --digitalocean-access-token=$DO_TOKEN \
            --digitalocean-region=sgp1 \
            --digitalocean-private-networking="true" \
            --digitalocean-size=4gb \
            manager-1

        echo "[I] Initializing Swarm"
        eval $(docker-machine env manager-1)
        docker swarm init --advertise-addr $(docker-machine ip manager-1)
        eval $(docker-machine env -u)
    else
        node_up manager-1
    fi
}

load_worker() {
    if [[ -z $(docker-machine ls --filter name=worker-1 -q) ]]; then
        echo "[I] Creating worker-1 node as Swarm worker"
        docker-machine create \
            --driver=digitalocean \
            --digitalocean-access-token=$DO_TOKEN \
            --digitalocean-region=sgp1 \
            --digitalocean-private-networking="true" \
            --digitalocean-size=4gb \
            worker-1

        echo "[I] Joining Swarm"
        docker-machine ssh manager-1 docker swarm join-token worker -q > /tmp/join-token-worker
        eval $(docker-machine env worker-1)
        docker swarm join --token $(cat /tmp/join-token-worker) $(docker-machine ip manager-1):2377
        eval $(docker-machine env -u)
        rm /tmp/join-token-worker
    else
        node_up worker-1
    fi
}

create_network() {
    eval $(docker-machine env manager-1)
    net=$(docker network ls -f name=gluu --format '{{ .Name }}')
    if [[ -z $net ]]; then
        docker network create -d overlay gluu
    fi
    eval $(docker-machine env -u)
}

deploy_consul() {
    echo "[I] Deploying consul stack"
    eval $(docker-machine env manager-1)

    if [[ -z $(docker service ls --filter name=consul_server -q) ]]; then
        echo "[I] Deploying consul_server to manager-1 node."
        docker service create \
            --name=consul_server \
            --env=CONSUL_BIND_INTERFACE=eth0 \
            --env='CONSUL_LOCAL_CONFIG={
            "leave_on_terminate": true,
            "skip_leave_on_interrupt": true,
            "autopilot": {
                "cleanup_dead_servers": true
            },
            "disable_update_check": true,
            "bootstrap_expect": 2
            }' \
            --network=gluu \
            --mode=global \
            --constraint=node.role==manager \
            --hostname="{{.Node.ID}}-{{.Service.Name}}" \
            --publish=mode=host,target=8500,published=8500 \
            --update-parallelism=1 \
            --update-failure-action=rollback \
            --update-delay=30s \
            --restart-window=120s \
            consul agent -server -ui -retry-join consul_server -client 0.0.0.0
    else
        echo "[I] consul_server is running"
    fi

    if [[ -z $(docker service ls --filter name=consul_agent -q) ]]; then
        echo "[I] Deploying consul_agent to worker-1 node."
        docker service create \
            --name=consul_agent \
            --env=CONSUL_BIND_INTERFACE=eth0 \
            --env=CONSUL_CLIENT_INTERFACE=eth0 \
            --env='CONSUL_LOCAL_CONFIG={
            "leave_on_terminate": true,
            "skip_leave_on_interrupt" : false,
            "disable_update_check": true,
            "bootstrap_expect": 2
            }' \
            --network=gluu \
            --mode=global \
            --publish=mode=host,target=8500,published=8500 \
            --constraint=node.role==worker \
            --hostname="{{.Node.ID}}-{{.Service.Name}}" \
            --update-parallelism=1 \
            --update-failure-action=rollback \
            --update-delay=30s \
            --restart-window=120s \
            consul agent -server -retry-join consul_server
    else
        echo "[I] consul_agent is running"
    fi

    eval $(docker-machine env -u)
}

setup() {
    echo "[I] Setup the cluster"
    load_manager
    load_worker
    create_network
    deploy_consul
}

teardown() {
    echo "[I] Teardown the cluster"

    for node in manager-1 worker-1; do
        if [[ ! -z $(docker-machine ls --filter name=$node -q) ]]; then
            docker-machine rm $node
        fi
    done
}

main() {
    # checks docker engine
    if [[ -z $(which docker) ]]; then
        echo "[E] Please install docker (https://docs.docker.com/install/) first."
        exit 1
    fi

    # checks docker-machine
    if [[ -z $(which docker-machine) ]]; then
        echo "[E] Please install docker-machine (https://docs.docker.com/machine/install-machine/) first."
        exit 1
    fi

    case $1 in
        "setup")
            DO_TOKEN=$(cat $HOME/.do-token)

            if [[ -z $DO_TOKEN ]]; then
                echo "[E] Requires DigitalOcean token saved in ${HOME}/.do-token file."
                exit 1
            fi
            setup
            ;;
        "teardown")
            teardown
            ;;
        *)
            echo "[E] Incorrect usage; please run 'setup' or 'teardown' sub-command"
            exit 1
            ;;
    esac
}

main $@
