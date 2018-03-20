#!/bin/dash

set -e

CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul`
GLUU_KV_HOST=${GLUU_KV_HOST:-$CONSUL_IP}
GLUU_KV_PORT=${GLUU_KV_PORT:-8500}
GLUU_LDAP_TYPE=opendj

echo "Please input the following parameters:"
# domain="USER INPUT"
read -p "Enter Domain: " domain
# countryCode="USER INPUT"
read -p "Enter Country: " countryCode
# state="USER INPUT"
read -p "Enter State: " state
# city="USER INPUT"
read -p "Enter City: " city
# email="USER INPUT"
read -p "Enter Email: " email
# orgName="USER INPUT"
read -p "Enter Organization: " orgName
# adminPw
read -p "Enter Admin Password: " adminPw
echo
echo "================================"
echo "Loading Configuration for Gluu Docker Edition!"
echo "================================"

docker run --rm \
    --network root_tulip \
    gluufederation/config-init:3.1.2_dev \
    --kv-host "${GLUU_KV_HOST}" \
    --kv-port "${GLUU_KV_PORT}" \
    --ldap-type "${GLUU_LDAP_TYPE}" \
    --domain $domain \
    --admin-pw $adminPw \
    --org-name "$orgName" \
    --email $email \
    --country-code $countryCode \
    --state $state \
    --city $city \
    --save \
    --view
