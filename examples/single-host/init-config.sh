#!/bin/sh

set -e

CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' singlehost_consul_1`
GLUU_KV_HOST=${GLUU_KV_HOST:-$CONSUL_IP}
GLUU_KV_PORT=${GLUU_KV_PORT:-8500}
GLUU_LDAP_TYPE=openldap

docker run --rm \
    --network singlehost-default \
    gluufederation/config-init:3.1.2_dev \
    --kv-host "${GLUU_KV_HOST}" \
    --kv-port "${GLUU_KV_PORT}" \
    --ldap-type "${GLUU_LDAP_TYPE}" \
    --domain singlehost.gluu.local \
    --admin-pw secret \
    --org-name "Gluu Inc." \
    --email 'support@gluu.local' \
    --country-code US \
    --state TX \
    --city Austin \
    --save
