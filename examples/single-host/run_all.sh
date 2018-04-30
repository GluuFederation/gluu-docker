#!/bin/bash

set -e

CONFIG_DIR=$PWD/volumes/config-init/db
HOST_IP=$(ip route get 1 | awk '{print $NF;exit}')
GLUU_VERSION=3.1.2_dev
INIT_CONFIG_CMD=""

DOMAIN=""
ADMIN_PW=""
EMAIL=""
ORG_NAME=""
COUNTRY_CODE=""
STATE=""
CITY=""

mkdir -p $CONFIG_DIR

# deploy service defined in docker-compose.yml
load_services() {
    echo "[I] Deploying containers"
    DOMAIN=$DOMAIN HOST_IP=$HOST_IP docker-compose up -d > /dev/null 2>&1
}

prepare_config() {
    echo "[I] Preparing cluster-wide configuration"

    # guess if config already in Consul
    if [[ ! -z $(docker ps --filter name=consul -q) ]]; then
        consul_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul)
        DOMAIN=$(curl $consul_ip:8500/v1/kv/gluu/config/hostname?raw -s)
    fi

    # if there's no config in Consul, ask users whether they want to load from previously saved config
    if [[ -z $DOMAIN ]]; then
        echo "[W] Configuration not found in Consul"

        if [[ -f $CONFIG_DIR/config.json ]]; then
            read -p "[I] Load previously saved configuration in local disk? [y/n]" load_choice
            if [[ $load_choice = "y" ]]; then
                DOMAIN=$(cat $CONFIG_DIR/config.json |  awk ' /'hostname'/ {print $2} ' | sed 's/[",]//g')
                INIT_CONFIG_CMD="load"
            fi
        fi
    fi

    # config is not loaded from previously saved configuration
    if [[ -z $DOMAIN ]]; then
        echo "[I] Creating new configuration, please input the following parameters"
        read -p "Enter Domain:                 " DOMAIN
        read -p "Enter Country Code:           " COUNTRY_CODE
        read -p "Enter State:                  " STATE
        read -p "Enter City:                   " CITY
        read -p "Enter Email:                  " EMAIL
        read -p "Enter Organization:           " ORG_NAME
        read -p "Enter Admin/LDAP Password:    " ADMIN_PW

        case "$ADMIN_PW" in
            * ) ;;
            "") echo "Password cannot be empty"; exit 1;
        esac

        read -p "Continue with the above settings? [Y/n]" choiceCont

        case "$choiceCont" in
            y|Y ) ;;
            n|N ) exit 1 ;;
            * )   ;;
        esac

        INIT_CONFIG_CMD="generate"
    fi
}

load_config() {
    echo "[I] Loading existing config."
    docker run \
        --rm \
        --network container:consul \
        -v $CONFIG_DIR:/opt/config-init/db/ \
        gluufederation/config-init:$GLUU_VERSION \
        load \
        --kv-host consul
}

generate_config() {
    echo "[I] Generating configuration for the first time; this may take a moment"
    docker run \
        --rm \
        --network container:consul \
        gluufederation/config-init:$GLUU_VERSION \
        generate \
        --admin-pw $ADMIN_PW \
        --email $EMAIL \
        --domain $DOMAIN \
        --org-name "$ORG_NAME" \
        --country-code $COUNTRY_CODE \
        --state $STATE \
        --city $CITY \
        --kv-host consul \
        --ldap-type opendj

    echo "[I] Saving configuration to local disk for later use"
    docker run \
        --rm \
        --network container:consul \
        gluufederation/config-init:$GLUU_VERSION \
        dump \
        --kv-host consul > $CONFIG_DIR/config.json
}

# ==========
# entrypoint
# ==========
prepare_config
load_services

case $INIT_CONFIG_CMD in
    "load")
        load_config
        ;;
    "generate")
        generate_config
        ;;
esac
