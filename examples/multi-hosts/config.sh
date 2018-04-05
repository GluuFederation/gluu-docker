#!/bin/bash

set -e

bootstrap_config() {
    echo "[I] Prepare cluster-wide configuration"

    # naive check to test whether config is in Consul
    domain=$(docker-machine ssh manager-1 curl 0.0.0.0:8500/v1/kv/gluu/config/hostname?raw -s)

    if [[ -z $domain ]]; then
        echo "[W] Unable to find configuration in Consul"

        saved_config=$PWD/volumes/config.json
        load_choice=""

        if [[ -f $saved_config ]]; then
            read -p "[I] Load previously saved configuration? [y/n]" load_choice
        fi

        if [[ $load_choice = "y" ]]; then
            docker-machine scp $saved_config manager-1:/root/config.json
            docker run \
                --rm \
                --network gluu \
                -v /root/config.json:/opt/config-init/db/config.json \
                gluufederation/config-init:3.1.2_dev \
                load \
                --kv-host $(docker-machine ip manager-1)
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

bootstrap_config
