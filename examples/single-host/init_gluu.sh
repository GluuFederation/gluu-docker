#!/bin/bash

set -e

# Input parameters for Configuration to run.

echo "=============================================="
echo
echo "Please input the following parameters:"
echo
read -p "Enter Domain:                 " domain
read -p "Enter Country Code:                " countryCode
read -p "Enter State:                  " state
read -p "Enter City:                   " city
read -p "Enter Email:                  " email
read -p "Enter Organization:           " orgName
read -p "Enter Admin/LDAP Password:         " adminPw
echo
echo "=============================================="
echo

read -p "Continue with the above settings? [Y/n]" choice

case "$choice" in 
  y|Y ) ;;
  n|N ) exit 1 ;;
  * )   ;;
esac
echo
echo "=============================================="
echo "Starting consul.."
echo "=============================================="
echo

docker-compose up -d consul > /dev/null 2>&1

CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul`
GLUU_KV_HOST=${GLUU_KV_HOST:-$CONSUL_IP}
GLUU_KV_PORT=${GLUU_KV_PORT:-8500}
GLUU_LDAP_TYPE=opendj

# This URL will return the ip address and "leader", which in our case is an indicator that consul has successfully started.

url="http://$CONSUL_IP:8500/v1/status/leader"
status="curl -s ${url}"

while true; do
if [[ $(eval $status) = *"$CONSUL_IP"* ]]
then
  break
else
  echo "..."
  sleep 8
fi
done

echo "=============================================="
echo "consul has finished starting"
echo "=============================================="

echo 
echo "=============================================="
echo "Loading Gluu Docker Edition Configuration.."
echo "=============================================="
echo "This may take a moment.."
echo

# Docker-compose automatically builds a default network, if not assigned. With the following command, this will assign that same network default
# name, which is just the current directory + _default. printf '%s\n' "${PWD##*/}" will automatically give the current directory.

# Prompt the user here if they want to use a custom network.
# If yes, prompt the user for the network name and use that version of docker run
# Else, run the default compose network naming convention. They would have had to identify that custom network in their docker-compose file

net=$(printf '%s\n' "${PWD##*/}")

docker run --rm \
    --network "${net//-}_default" \
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
    --save 

echo "=============================================="
echo "Configuration Loaded!"
echo "=============================================="
echo

DOMAIN=$domain 
HOST_IP=$(ip route get 1 | awk '{print $NF;exit}')

echo "=============================================="
echo "Starting OpenDJ.."
echo "=============================================="
docker-compose up -d ldap > /dev/null 2>&1
echo
echo "Waiting for OpenDJ to finish starting. This can take a couple minutes.."

# Here I check that the port is active, but also check the docker logs to show me that the server is fully ready to start.
# This is because the installation process of OpenDJ starts and stops several times.
# Need to find a better way to minimize the output

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

echo
echo "=============================================="
echo "OpenDJ started successfully!"
echo "=============================================="
echo

echo "=============================================="
echo "Starting Gluu Server Docker Edition.."
echo "=============================================="
echo

startServices="DOMAIN=$domain HOST_IP=$(ip route get 1 | awk '{print $NF;exit}') docker-compose up -d nginx oxauth oxtrust > /dev/null 2>&1"

eval $startServices

echo "=============================================="
echo "Starting oxAuth.."
echo "=============================================="

# cURL and only get the HTTP response code. Good for standalone instance or health checks.
# curl -m 2 -skL -o /dev/null -w "%{http_code}" https://dev.dock.com/oxauth/ 

oxAuthCheck="curl -m 2 -skL -o /dev/null -w '%{http_code}' https://${domain}/oxauth/"
while true; do
if [[ $(eval $oxAuthCheck) = *"200"* ]]
then
  break
else
  echo "..."
  sleep 10
fi
done

echo
echo "=============================================="
echo "oxAuth started successfully!"
echo "=============================================="
echo

echo "=============================================="
echo "Starting oxTrust.."
echo "=============================================="

while true; do
oxTrustCheck="curl -m 2 -skL -o /dev/null -w '%{http_code}' https://${domain}/identity/"
if [[ $(eval $oxTrustCheck) = *"200"* ]]
then
  break
else
  echo "..."
  sleep 2
fi
done

echo
echo "=============================================="
echo "oxTrust started successfully!"
echo "=============================================="
echo

echo "=============================================="
echo "Gluu Server Docker Edition is Ready! Please navigate to ${domain}"
echo "=============================================="
echo

echo "Exiting.."
exit 1
