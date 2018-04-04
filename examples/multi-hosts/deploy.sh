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
    fi
    eval $(docker-machine env -u)
}

bootstrap_config() {
    echo "[I] Prepare cluster-wide configuration"

    # naive check to test whether config is in Consul
    domain=$(docker-machine ssh manager-1 curl 0.0.0.0:8500/v1/kv/gluu/config/hostname?raw -s)

    saved_config=$PWD/volumes/config.json

    if [[ -z $domain ]]; then
        echo "[W] Unable to find configuration in Consul"

        if [[ -f $saved_config ]]; then
            read -p "[I] Load previously saved configuration? [y/n]" load_choice
            if [[ $load_choice = "y" ]]; then
                docker-machine scp $saved_config manager-1:/root/config.json
                docker run \
                    --rm \
                    --network gluu \
                    -v /root/config.json:/opt/config-init/db/config.json \
                    gluufederation/config-init:3.1.2_dev \
                    load \
                    --kv-host $(docker-machine ip manager-1)
            fi
        else
            generate_config
        fi
    fi
}

generate_config() {
    saved_config=$PWD/volumes/config.json

    echo "[I] Please input the following parameters"
    read -p "Enter Domain:                 " domain
    read -p "Enter Country Code:           " countryCode
    read -p "Enter State:                  " state
    read -p "Enter City:                   " city
    read -p "Enter Email:                  " email
    read -p "Enter Organization:           " orgName
    read -p "Enter Admin/LDAP Password:    " adminPw

    case "$adminPW" in
        * ) ;;
        "") echo "Password cannot be empty"; exit 1;
    esac

    read -p "Continue with the above settings? [Y/n]" choiceCont

    case "$choiceCont" in
        y|Y ) ;;
        n|N ) exit 1 ;;
        * )   ;;
    esac

    echo "[I] Generating configuration for the first time; this may take a moment"
    docker run \
        --rm \
        --network gluu \
        gluufederation/config-init:3.1.2_dev \
        generate \
        --admin-pw secret \
        --email $email \
        --domain $domain \
        --org-name "$orgName" \
        --country-code $countryCode \
        --state $state \
        --city $city \
        --kv-host $(docker-machine ip manager-1) \
        --ldap-type opendj

    echo "[I] Saving configuration to local disk for later use"
    docker run \
        --rm \
        --network gluu \
        gluufederation/config-init:3.1.2_dev \
        dump \
        --kv-host $(docker-machine ip manager-1) > $saved_config
}

deploy_stack() {
    eval $(docker-machine env manager-1)
    # if [[ -z $(docker stack ls --format '{{ .Name }}' | grep -i gluu) ]]; then
        docker stack deploy -c consul.yml gluu

        docker stack deploy -c cache.yml gluu
        # @TODO: wait for consul
        bootstrap_config

        # @TODO: wait for consul
        # docker stack deploy -c proxy.yml gluu

        # @TODO: wait for consul
        # docker stack deploy -c ldap.yml gluu

        # # @TODO: wait for consul and ldap
        # docker stack deploy -c ox.yml gluu
        # domain=$(docker-machine ssh manager-1 curl 0.0.0.0:8500/v1/kv/gluu/config/hostname?raw -s)
        # DOMAIN=$domain docker stack deploy -c nginx.yml gluu
    # fi
    eval $(docker-machine env -u)
}

setup() {
    echo "[I] Setup the cluster"
    load_manager $1
    load_worker $1
    create_network
    deploy_stack
}

teardown() {
    echo "[I] Teardown the cluster"

    if [[ ! -z $(docker-machine ls --filter name=manager-1 -q) ]]; then
        eval $(docker-machine env manager-1)
        if [[ ! -z $(docker stack ls --format '{{ .Name }}' | grep -i gluu) ]]; then
            read -p "Do you want to remove gluu stack? [y/n] " rm_choice

            if [[ $rm_choice = "y"  ]]; then
                echo "[I] Removing gluu stack"
                docker stack rm gluu
            fi
        fi
        eval $(docker-machine env -u)
    fi

    for node in manager-1 worker-1; do
        if [[ ! -z $(docker-machine ls --filter name=$node -q) ]]; then
            echo "[I] Removing $node node"
            docker-machine rm $node
        fi
    done

    rm -f $PWD/volumes/config.json
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
                *)
                    driver=virtualbox
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
