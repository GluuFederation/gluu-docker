#!/bin/bash

set -e

get_consul_name() {
    docker ps --filter name=consul --format '{{.Names}}'
}

bootstrap_config() {
    echo "[I] Prepare cluster-wide configuration"

    # guess if config already in Consul
    # consul_name=$(docker ps --filter name=consul --format '{{.Names}}')
    consul_name=$(get_consul_name)
    if [[ ! -z $consul_name ]]; then
        consul_ip=$(docker exec $consul_name ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
        domain=$(docker-machine ssh manager curl $consul_ip:8500/v1/kv/gluu/config/hostname?raw -s)
    fi

    if [[ -z $domain ]]; then
        echo "[W] Unable to find configuration in Consul"

        saved_config=$PWD/volumes/config.json
        load_choice=""

        if [[ -f $saved_config ]]; then
            read -p "[I] Load previously saved configuration? [y/n]" load_choice
        fi

        if [[ $load_choice = "y" ]]; then
            docker-machine scp $saved_config manager:/opt/config-init/db/config.json
            docker run \
                --rm \
                --network container:$(get_consul_name) \
                -v /opt/config-init/db:/opt/config-init/db/ \
                -e GLUU_CONFIG_ADAPTER=consul \
                -e GLUU_CONSUL_HOST=consul.server \
                gluufederation/config-init:3.1.4_03 \
                load
        else
            generate_config
        fi
    fi
}

generate_config() {
    saved_config=$PWD/volumes/config.json

    echo "[I] Creating new configuration, please input the following parameters"
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
        --network container:$(get_consul_name) \
        -v /opt/config-init/db:/opt/config-init/db/ \
        -e GLUU_CONFIG_ADAPTER=consul \
        -e GLUU_CONSUL_HOST=consul.server \
        gluufederation/config-init:3.1.4_03 \
        generate \
        --admin-pw secret \
        --email $email \
        --domain $domain \
        --org-name "$orgName" \
        --country-code $countryCode \
        --state $state \
        --city $city \
        --ldap-type opendj
    docker-machine scp manager:/opt/config-init/db/config.json $saved_config
}

bootstrap_config
