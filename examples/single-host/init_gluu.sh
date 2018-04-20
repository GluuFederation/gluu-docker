#!/bin/bash

set -e

CONFIG_DIR=$PWD/volumes/config-init/db

######################################################################
#FUNCTIONS
######################################################################
loadConfig () {
    CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul`

    loadingEcho Configuration

    docker run   --rm \
        --network container:consul \
        -v $CONFIG_DIR:/opt/config-init/db/ \
        gluufederation/config-init:3.1.2_dev \
        load \
        --kv-host ${CONSUL_IP}

    loadedEcho Configuration
}
######################################################################
dumpConfig () {
    CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul`
    GLUU_KV_HOST=${GLUU_KV_HOST:-$CONSUL_IP}

    echo "=============================================="
    echo "Saving configuration to disk.."
    echo "=============================================="
    echo
    echo "You can use this saved configuration later to reupload your configuration "
    echo "to a fresh/empty consul instance."

    docker run   --rm \
        --network container:consul \
        -v $CONFIG_DIR/:/opt/config-init/db/ \
        gluufederation/config-init:3.1.2_dev \
        dump \
        --kv-host "${GLUU_KV_HOST}" > /dev/null 2>&1

    echo "=============================================="
    echo "Configuration saved to ${CONFIG_DIR}/config.json"
    echo "=============================================="
}
######################################################################
generateConfig () {
    loadingEcho "New Gluu Docker Edition Configuration.."

    echo "This may take a moment.."
    echo

    CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul`
    GLUU_KV_HOST=${GLUU_KV_HOST:-$CONSUL_IP}
    GLUU_LDAP_TYPE=opendj

    docker run --rm \
        --network container:consul \
        gluufederation/config-init:3.1.2_dev \
        generate \
        --kv-host "${GLUU_KV_HOST}" \
        --ldap-type "${GLUU_LDAP_TYPE}" \
        --domain $domain \
        --admin-pw $adminPw \
        --org-name "$orgName" \
        --email $email \
        --country-code $countryCode \
        --state $state \
        --city $city

    loadedEcho Configuration
}
######################################################################
loadLdap () {
    loadingEcho OpenDJ

    docker-compose up -d ldap > /dev/null 2>&1

    echo
    echo "Waiting for OpenDJ to finish starting."
    echo "This can take a couple minutes if it's the first time configuring.."

    # Here I check that the port is active, but also check the docker logs to show me that the server is fully ready to start.
    # This is because the installation process of OpenDJ starts and stops several times.

    LDAP_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ldap`
    ldapCheckPort="docker exec -it ldap nc -vz ${LDAP_IP} 1636"
    ldapCheckLog="docker logs ldap 2>&1"
    ldapSuccess="The Directory Server has started successfully"

    while true; do
    if [[ $(eval $ldapCheckPort) = *"open"* ]] && [[ $(eval $ldapCheckLog | grep "${ldapSuccess}") = *"${ldapSuccess}"* ]]
        then
            echo $(eval $ldapCheckPort)
            break
        else
            echo "..."
            sleep 10
        fi
    done

    loadedEcho OpenDJ
}
######################################################################
loadGluu () {
    domain=$1
    loadingEcho "Gluu Server Docker Edition.."

    startServices="DOMAIN=$domain HOST_IP=$(ip route get 1 | awk '{print $NF;exit}') docker-compose up -d nginx oxauth oxtrust oxshibboleth oxpassport > /dev/null 2>&1"
    eval $startServices

    checkOxAuthStatus $domain
    checkOxTrustStatus $domain

    loadedEcho "Gluu Server Docker Edition"
}
######################################################################
loadConsul () {
    loadingEcho consul

    docker-compose up -d consul > /dev/null 2>&1

    while true; do
        if [[ checkConsulStatus -eq 0 ]]
        then
            break
        else
            echo "..."
            sleep 8
        fi
    done

    loadedEcho consul
}
######################################################################
checkConsulStatus () {
    CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul`
    GLUU_KV_HOST=${GLUU_KV_HOST:-$CONSUL_IP}
    url="http://$CONSUL_IP:8500/v1/status/leader"
    status="curl -s ${url}"

    if [[ $(eval $status) = *"$CONSUL_IP"* ]]
        then
            return 0
        else
            return 1
    fi
}
######################################################################
checkOxAuthStatus () {
    domain=$1
    loadingEcho oxAuth

    oxAuthCheck="curl -m 2 -skL -o /dev/null -w '%{http_code}' https://${domain}/oxauth/"
    while true; do
        if [ $(eval $oxAuthCheck) == "200" ]
            then
                break
            else
                echo "..."
                sleep 10
        fi
    done

    loadedEcho oxAuth
}
######################################################################
checkOxTrustStatus () {
    domain=$1

    loadingEcho oxTrust

    while true; do
    oxTrustCheck="curl -m 2 -skL -o /dev/null -w '%{http_code}' https://${domain}/identity/"
    if  [ $(eval $oxTrustCheck) == "200" ]
        then
            break
        else
            echo "..."
            sleep 2
    fi
    done

    loadedEcho oxTrust
}
######################################################################
loadingEcho () {
    echo
    echo "=============================================="
    echo "Loading ${1}.."
    echo "=============================================="
    echo
}
######################################################################
loadedEcho () {
    echo
    echo "=============================================="
    echo "${1} Successfully Loaded!"
    echo "=============================================="
    echo
}
######################################################################
#/FUNCTIONS
######################################################################
if [[ -f $CONFIG_DIR/config.json ]]; then
    echo "=============================================="
    echo
    read -p "Do you want to load a previously saved Gluu Server Docker Edition Configuration? [N/y]" choiceConfig
fi

if [[ $choiceConfig = "y" ]]
then
    if [[ checkConsulStatus = true ]]
    then
        loadConfig
    else
        loadConsul
        sleep 2
        loadConfig
    fi
else
    echo "=============================================="
    echo
    echo "Please input the following parameters:"
    echo
    read -p "Enter Domain:                 " domain
    read -p "Enter Country Code:           " countryCode
    read -p "Enter State:                  " state
    read -p "Enter City:                   " city
    read -p "Enter Email:                  " email
    read -p "Enter Organization:           " orgName
    read -p "Enter Admin/LDAP Password:    " adminPw

    case "$adminPW" in
        * ) ;;
        "") echo "Cannot be empty"; exit 1;
    esac

    echo
    echo "=============================================="
    echo

    read -p "Continue with the above settings? [Y/n]" choiceCont

    case "$choiceCont" in
        y|Y ) ;;
        n|N ) exit 1 ;;
        * )   ;;
    esac

    loadConsul
    generateConfig
    dumpConfig
fi

if [ -z "$domain" ]
then
    domain=$(cat $CONFIG_DIR/config.json |  awk ' /'hostname'/ {print $2} ' | sed 's/[",]//g')
fi

loadLdap
loadGluu $domain

echo "=============================================="
echo "Gluu Server Docker Edition is Ready! Please navigate to ${domain}"
echo "=============================================="
echo

echo "Exiting.."
exit 1
