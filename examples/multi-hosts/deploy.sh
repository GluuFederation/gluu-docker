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
            --driver virtualbox \
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
            --driver virtualbox \
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
        echo "[I] Creating network for swarm"
        docker network create -d overlay --attachable gluu
    fi
    eval $(docker-machine env -u)
}

deploy_consul() {
    # @TODO: DONT expose client to public
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

bootstrap_config() {
    echo "[I] Prepare cluster-wide configuration"

    # naive check to test whether config is in Consul
    domain=$(docker-machine ssh manager-1 curl 0.0.0.0:8500/v1/kv/gluu/config/hostname?raw -s)

    saved_config=$PWD/volumes/config.json

    eval $(docker-machine env manager-1)

    if [[ -z $domain ]]; then
        echo "[W] Unable to find configuration in Consul"

        if [[ -f $saved_config ]]; then
            echo "[I] Found saved configuration in local disk"
            echo "[I] Loading previously saved configuration"
            docker-machine scp $saved_config manager-1:/root/config.json
            docker run \
                --rm \
                --network gluu \
                -v /root/config.json:/opt/config-init/db/config.json \
                gluufederation/config-init:3.1.2_dev \
                load \
                --kv-host $(docker-machine ip manager-1)
        else
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
        fi
    fi
    eval $(docker-machine env -u)
}

deploy_ldap() {
    eval $(docker-machine env manager-1)

    if [[ -z $(docker service ls --filter name=ldap_init -q) ]]; then
        docker-machine ssh manager-1 mkdir -p /root/opendj/db /root/opendj/logs /root/opendj/config /root/opendj/flag
        echo "[I] Deploying ldap_init to manager-1 node."
        docker service create \
            --name=ldap_init \
            --env=GLUU_LDAP_INIT=true \
            --env=GLUU_LDAP_INIT_HOST="{{.Service.Name}}" \
            --env=GLUU_KV_HOST=consul_server \
            --network=gluu \
            --replicas=1 \
            --constraint=node.role==manager \
            --update-parallelism=1 \
            --update-failure-action=rollback \
            --update-delay=30s \
            --restart-window=120s \
            --mount=type=bind,src=/root/opendj/db,target=/opt/opendj/db \
            --mount=type=bind,src=/root/opendj/config,target=/opt/opendj/config \
            --mount=type=bind,src=/root/opendj/logs,target=/opt/opendj/logs \
            --mount=type=bind,src=/root/opendj/flag,target=/flag \
            gluufederation/opendj:3.1.2_dev
    else
        echo "[I] ldap_init is running"
    fi
    eval $(docker-machine env -u)
}

deploy_oxauth() {
    eval $(docker-machine env manager-1)

    if [[ -z $(docker service ls --filter name=oxauth -q) ]]; then
        echo "[I] Deploying oxauth."
        docker service create \
            --name=oxauth \
            --env=GLUU_LDAP_URL=ldap_init:1636 \
            --env=GLUU_KV_HOST=consul_server \
            --network=gluu \
            --replicas=1 \
            --update-parallelism=1 \
            --update-failure-action=rollback \
            --update-delay=30s \
            --restart-window=120s \
            gluufederation/oxauth:3.1.2_dev
    else
        echo "[I] oxauth is running"
    fi
    eval $(docker-machine env -u)
}

deploy_oxtrust() {
    eval $(docker-machine env manager-1)
    domain=$(docker-machine ssh manager-1 curl 0.0.0.0:8500/v1/kv/gluu/config/hostname?raw -s)
    if [[ -z $(docker service ls --filter name=oxtrust -q) ]]; then
        echo "[I] Deploying oxtrust."
        docker service create \
            --name=oxtrust \
            --env=GLUU_LDAP_URL=ldap_init:1636 \
            --env=GLUU_KV_HOST=consul_server \
            --network=gluu \
            --replicas=1 \
            --update-parallelism=1 \
            --update-failure-action=rollback \
            --update-delay=30s \
            --restart-window=120s \
            --host=$domain:$(docker-machine ip manager-1) \
            gluufederation/oxtrust:3.1.2_dev
    else
        echo "[I] oxtrust is running"
    fi
    eval $(docker-machine env -u)
}

deploy_nginx() {
    eval $(docker-machine env manager-1)

    if [[ -z $(docker service ls --filter name=nginx -q) ]]; then
        echo "[I] Deploying nginx"
        docker service create \
            --name=nginx \
            --env=GLUU_KV_HOST=consul_server \
            --env=GLUU_OXAUTH_BACKEND=oxauth:8080 \
            --env=GLUU_OXTRUST_BACKEND=oxtrust:8080 \
            --publish=mode=host,target=80,published=80 \
            --publish=mode=host,target=443,published=443 \
            --network=gluu \
            --mode=global \
            --update-parallelism=1 \
            --update-failure-action=rollback \
            --update-delay=30s \
            --restart-window=120s \
            gluufederation/nginx:3.1.2_dev
    else
        echo "[I] nginx is running"
    fi
    eval $(docker-machine env -u)
}

setup() {
    echo "[I] Setup the cluster"
    load_manager
    load_worker
    create_network
    deploy_consul
    bootstrap_config
    deploy_ldap
    deploy_oxauth
    deploy_nginx
    deploy_oxtrust
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
        "up")
            setup
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
