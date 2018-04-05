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
        case $1 in
            virtualbox)
                docker-machine create \
                    --driver virtualbox \
                    manager-1
                ;;
            digitalocean)
                docker-machine create \
                    --driver=digitalocean \
                    --digitalocean-access-token=$DO_TOKEN \
                    --digitalocean-region=sgp1 \
                    --digitalocean-private-networking="true" \
                    --digitalocean-size=4gb \
                    manager-1
                ;;
        esac

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
        case $1 in
            virtualbox)
                docker-machine create \
                    --driver virtualbox \
                    worker-1
                ;;
            digitalocean)
                docker-machine create \
                    --driver=digitalocean \
                    --digitalocean-access-token=$DO_TOKEN \
                    --digitalocean-region=sgp1 \
                    --digitalocean-private-networking="true" \
                    --digitalocean-size=4gb \
                    worker-1
                ;;
        esac

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
        echo "[I] Creating network for swarm"
        docker network create -d overlay --attachable gluu
    else
        echo "[I] $net network is available"
    fi
    eval $(docker-machine env -u)
}

setup() {
    echo "[I] Setup the cluster nodes"
    load_manager $1
    load_worker $1
    create_network
}

teardown() {
    echo "[I] Teardown the cluster nodes"

    for node in manager-1 worker-1; do
        if [[ ! -z $(docker-machine ls --filter name=$node -q) ]]; then
            echo "[I] Removing $node node"
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
        "up")
            driver=$2
            case $driver in
                digitalocean)
                    DO_TOKEN_FILE=$PWD/volumes/digitalocean-access-token

                    if [[ ! -f $DO_TOKEN_FILE ]]; then
                        echo "[E] Requires DigitalOcean token saved in $DO_TOKEN_FILE file"
                        exit 1
                    fi

                    DO_TOKEN=$(cat $DO_TOKEN_FILE)
                    if [[ -z $DO_TOKEN ]]; then
                        echo "[E] DigitalOcean token cannot be empty"
                        exit 1
                    fi
                    ;;
                virtualbox)
                    # checks virtualbox
                    if [[ -z $(which virtualbox) ]]; then
                        echo "[E] Please install virtualbox (https://www.virtualbox.org/wiki/Downloads) first."
                        exit 1
                    fi
                    ;;
                *)
                    echo "[E] Unsupported driver (please choose either virtualbox or digitalocean)."
                    exit 1
                    ;;
            esac
            setup $driver
            ;;
        "down")
            teardown
            ;;
        *)
            echo "[E] Incorrect usage; please run 'up' or 'down' sub-command"
            exit 1
            ;;
    esac
}

main $@
