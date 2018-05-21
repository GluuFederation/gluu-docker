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
        # required for config-init
        docker-machine ssh manager-1 mkdir -p /root/config-init/db
        # required for ldap_init service
        docker-machine ssh manager-1 mkdir -p /flag /opt/opendj/config /opt/opendj/db /opt/opendj/ldif /opt/opendj/logs
    else
        node_up manager-1
    fi
}

load_worker() {
    if [[ -z $(docker-machine ls --filter name=worker-1 -q) ]]; then
        echo "[I] Creating worker-1 node as Swarm worker"
        case $1 in
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
        # required for ldap_peer service
        docker-machine ssh worker-1 mkdir -p /opt/opendj/config /opt/opendj/db /opt/opendj/ldif /opt/opendj/logs
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
        csync2_repl
    else
        echo "[I] $net network is available"
    fi
    eval $(docker-machine env -u)
}

csync2_repl() {
    echo "[I] Installing and configuring csync2 in manager-1 node"
    docker-machine ssh manager-1 apt-get install -y csync2
    echo $(docker-machine ip manager-1) manager-1.gluu > volumes/manager-1.gluu
    echo $(docker-machine ip worker-1) worker-1.gluu > volumes/worker-1.gluu
    docker-machine scp volumes/manager-1.gluu manager-1:/etc/
    docker-machine scp volumes/worker-1.gluu manager-1:/etc/
    docker-machine scp extra-hosts.sh manager-1:/root/
    docker-machine ssh manager-1 bash /root/extra-hosts.sh
    docker-machine scp csync2.cfg manager-1:/etc/
    docker-machine ssh manager-1 mkdir -p /opt/shared-shibboleth-idp
    docker-machine ssh manager-1 csync2 -k /etc/csync2.key
    docker-machine ssh manager-1 openssl genrsa -out /etc/csync2_ssl_key.pem 1024
    docker-machine ssh manager-1 openssl req -batch -new -key /etc/csync2_ssl_key.pem -out /etc/csync2_ssl_cert.csr
    docker-machine ssh manager-1 openssl x509 -req -days 3600 -in /etc/csync2_ssl_cert.csr -signkey /etc/csync2_ssl_key.pem -out /etc/csync2_ssl_cert.pem
    docker-machine scp manager-1:/etc/csync2.key volumes/
    docker-machine scp manager-1:/etc/csync2_ssl_key.pem volumes/
    docker-machine scp manager-1:/etc/csync2_ssl_cert.pem volumes/
    docker-machine scp manager-1:/etc/csync2_ssl_cert.csr volumes/
    docker-machine scp inetd-manager.conf manager-1:/etc/inetd.conf
    docker-machine ssh manager-1 /etc/init.d/openbsd-inetd restart
    docker-machine scp csync2-manager.cron manager-1:/etc/cron.d/csync2
    docker-machine ssh manager-1 service cron reload

    echo "[I] Installing and configuring csync2 in worker-1 node"
    docker-machine ssh worker-1 apt-get install -y csync2
    docker-machine scp volumes/manager-1.gluu worker-1:/etc/
    docker-machine scp volumes/worker-1.gluu worker-1:/etc/
    docker-machine scp extra-hosts.sh worker-1:/root/
    docker-machine ssh worker-1 bash /root/extra-hosts.sh
    docker-machine scp csync2.cfg worker-1:/etc/
    docker-machine ssh worker-1 mkdir -p /opt/shared-shibboleth-idp
    docker-machine scp volumes/csync2.key worker-1:/etc/
    docker-machine scp volumes/csync2_ssl_key.pem worker-1:/etc/
    docker-machine scp volumes/csync2_ssl_cert.pem worker-1:/etc/
    docker-machine scp volumes/csync2_ssl_cert.csr worker-1:/etc/
    docker-machine scp inetd-worker.conf worker-1:/etc/inetd.conf
    docker-machine ssh worker-1 /etc/init.d/openbsd-inetd restart
    docker-machine scp csync2-worker.cron worker-1:/etc/cron.d/csync2
    docker-machine ssh worker-1 service cron reload
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
            driver=digitalocean
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
