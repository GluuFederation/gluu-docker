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
    if [[ -z $(docker-machine ls --filter name=manager -q) ]]; then
        echo "[I] Creating manager node as Swarm manager"
        case $1 in
            digitalocean)
                docker-machine create \
                    --driver=digitalocean \
                    --digitalocean-access-token=$DO_TOKEN \
                    --digitalocean-region=sgp1 \
                    --digitalocean-private-networking="true" \
                    --digitalocean-size=8gb \
                    manager
                ;;
        esac

        echo "[I] Initializing Swarm"
        eval $(docker-machine env manager)
        docker swarm init --advertise-addr $(docker-machine ip manager)
        eval $(docker-machine env -u)
    else
        node_up manager
    fi
}

load_worker() {
    for node in worker-1 worker-2; do
        if [[ -z $(docker-machine ls --filter name=$node -q) ]]; then
            echo "[I] Creating $node node as Swarm worker"
            case $1 in
                digitalocean)
                    docker-machine create \
                        --driver=digitalocean \
                        --digitalocean-access-token=$DO_TOKEN \
                        --digitalocean-region=sgp1 \
                        --digitalocean-private-networking="true" \
                        --digitalocean-size=8gb \
                        $node
            esac

            echo "[I] Joining Swarm"
            docker-machine ssh manager docker swarm join-token worker -q > volumes/join-token-worker
            eval $(docker-machine env $node)
            docker swarm join --token $(cat volumes/join-token-worker) $(docker-machine ip manager):2377
            eval $(docker-machine env -u)
        else
            node_up $node
        fi
    done
}

create_network() {
    eval $(docker-machine env manager)
    net=$(docker network ls -f name=gluu --format '{{ .Name }}')
    if [[ -z $net ]]; then
        echo "[I] Creating network for swarm"
        docker network create -d overlay gluu
    else
        echo "[I] $net network is available"
    fi
    eval $(docker-machine env -u)
}

csync2_repl() {
    for node in manager worker-1 worker-2; do
        echo "$(docker-machine ip $node) $node.gluu" > volumes/$node.gluu
    done

    docker-machine ssh manager dpkg -l > volumes/dpkg_manager_list
    if [ ! -z "$(cat volumes/dpkg_manager_list | grep 'csync2')" ]; then
        echo "[I] csync2 in manager node has been installed"
    else
        echo "[I] Installing and configuring csync2 in manager node"
        docker-machine ssh manager apt-get install -y csync2

        docker-machine scp volumes/manager.gluu manager:/etc/
        docker-machine scp volumes/worker-1.gluu manager:/etc/
        docker-machine scp volumes/worker-2.gluu manager:/etc/

        docker-machine scp extra-hosts.sh manager:/root/
        docker-machine ssh manager bash /root/extra-hosts.sh
        docker-machine scp csync2.cfg manager:/etc/

        docker-machine ssh manager csync2 -k /etc/csync2.key
        docker-machine ssh manager openssl genrsa -out /etc/csync2_ssl_key.pem 1024
        docker-machine ssh manager openssl req -batch -new -key /etc/csync2_ssl_key.pem -out /etc/csync2_ssl_cert.csr
        docker-machine ssh manager openssl x509 -req -days 3600 -in /etc/csync2_ssl_cert.csr -signkey /etc/csync2_ssl_key.pem -out /etc/csync2_ssl_cert.pem
        docker-machine scp manager:/etc/csync2.key volumes/
        docker-machine scp manager:/etc/csync2_ssl_key.pem volumes/
        docker-machine scp manager:/etc/csync2_ssl_cert.pem volumes/
        docker-machine scp manager:/etc/csync2_ssl_cert.csr volumes/
        sed -e "s@NODE@manager@" inetd.conf.tmpl > volumes/inetd-manager.conf
        docker-machine scp volumes/inetd-manager.conf manager:/etc/inetd.conf
        docker-machine ssh manager /etc/init.d/openbsd-inetd restart
        sed -e "s@NODE@manager@" csync2.cron.tmpl > volumes/csync2-manager.cron
        docker-machine scp volumes/csync2-manager.cron manager:/etc/cron.d/csync2
        docker-machine ssh manager service cron reload
    fi

    for node in worker-1 worker-2; do
        docker-machine ssh $node dpkg -l > volumes/dpkg_${node}_list
        if [ ! -z "$(cat volumes/dpkg_${node}_list | grep 'csync2')" ]; then
            echo "[I] csync2 in $node node has been installed"
        else
            echo "[I] Installing and configuring csync2 in $node node"
            docker-machine ssh $node apt-get install -y csync2

            docker-machine scp volumes/manager.gluu $node:/etc/
            docker-machine scp volumes/worker-1.gluu $node:/etc/
            docker-machine scp volumes/worker-2.gluu $node:/etc/

            docker-machine scp extra-hosts.sh $node:/root/
            docker-machine ssh $node bash /root/extra-hosts.sh
            docker-machine scp csync2.cfg $node:/etc/
            docker-machine scp volumes/csync2.key $node:/etc/
            docker-machine scp volumes/csync2_ssl_key.pem $node:/etc/
            docker-machine scp volumes/csync2_ssl_cert.pem $node:/etc/
            docker-machine scp volumes/csync2_ssl_cert.csr $node:/etc/
            sed -e "s@NODE@$node@" inetd.conf.tmpl > volumes/inetd-${node}.conf
            docker-machine scp volumes/inetd-$node.conf $node:/etc/inetd.conf
            docker-machine ssh $node /etc/init.d/openbsd-inetd restart
            sed -e "s@NODE@$node@" csync2.cron.tmpl > volumes/csync2-${node}.cron
            docker-machine scp volumes/csync2-$node.cron $node:/etc/cron.d/csync2
            docker-machine ssh $node service cron reload
        fi
    done
}

prepare_volumes() {
    echo "[I] Creating directories for mounted volumes in manager node"
    docker-machine ssh manager mkdir -p /opt/config-init/db \
        /opt/opendj/config /opt/opendj/db /opt/opendj/ldif /opt/opendj/logs /opt/opendj/backup /opt/opendj/flag \
        /opt/consul \
        /opt/vault/config /opt/vault/data /opt/vault/logs \
        /opt/shared-shibboleth-idp

    for node in worker-1 worker-2; do
        echo "[I] Creating directories for mounted volumes in $node node"
        docker-machine ssh $node mkdir -p /opt/opendj/config /opt/opendj/db /opt/opendj/ldif /opt/opendj/logs /opt/opendj/backup \
            /opt/consul \
            /opt/vault/config /opt/vault/data /opt/vault/logs \
            /opt/shared-shibboleth-idp
    done
}

setup() {
    echo "[I] Setup the cluster nodes"
    load_manager $1
    load_worker $1
    create_network
    prepare_volumes
    csync2_repl
}

teardown() {
    echo "[I] Teardown the cluster nodes"

    for node in manager worker-1 worker-2; do
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
            DO_TOKEN_FILE=$PWD/digitalocean-access-token

            if [[ -f $PWD/volumes/digitalocean-access-token ]]; then
                mv $PWD/volumes/digitalocean-access-token .
            fi

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

main "$@"
