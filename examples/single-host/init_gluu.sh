#!/bin/dash

set -e

# Input parameters for Configuration to run.

echo "=============================================="
echo
echo "Please input the following parameters:"
echo

read -p "Enter Domain:                 " domain
read -p "Enter Country:                " countryCode
read -p "Enter State:                  " state
read -p "Enter City:                   " city
read -p "Enter Email:                  " email
read -p "Enter Organization:           " orgName
read -p "Enter Admin Password:         " adminPw

echo
echo "=============================================="
echo

echo
echo "Domain:                       " $domain
echo "Country:                      " $countryCode
echo "State:                        " $state
echo "City:                         " $city
echo "Email:                        " $email
echo "Organization:                 " $orgName
echo "Password:                     " $adminPw
echo
read -p "Continue with these settings? [Y/n]" choice

case "$choice" in 
  y|Y ) continue;;
  n|N ) exit 1 ;;
  * ) echo "invalid";;
esac

echo "Starting consul.."
docker-compose up -d consul

CONSUL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' consul`
GLUU_KV_HOST=${GLUU_KV_HOST:-$CONSUL_IP}
GLUU_KV_PORT=${GLUU_KV_PORT:-8500}
GLUU_LDAP_TYPE=opendj

# This URL will return the ip address and "leader", which in our case is an indicator that consul has successfully started.

url="http://$CONSUL_IP:8500/v1/status/leader"

while true; do
if curl -s $url | grep $CONSUL_IP; then
  echo "consul has finished starting.."
  echo
  break ;
else
  echo "..." ;
  sleep 5
fi
done

echo 
echo "=============================================="
echo "Configuring Gluu Docker Edition!"
echo "=============================================="
echo "This may take a moment.."

# Docker-compose automatically builds a default network, if not assigned. With the following command, this will assign that same network default
# name, which is just the current directory + _default. printf '%s\n' "${PWD##*/}" will automatically give the current directory.

net=$(printf '%s\n' "${PWD##*/}")
docker run --rm \
    --network "${net}_default" \
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

docker-compose up -d ldap

echo
echo "Configuration done!"
echo
echo "Starting OpenDJ"
echo
echo "Waiting for OpenDJ to finish starting. This can take a couple minutes."

# Check the logs for OpenDJ starting successfully.

while true; do
if docker logs ldap | grep "The Directory Server has started successfully"; then
  echo
  echo "OpenDJ has finished starting.."
  break ;
else
  echo "..." ;
  sleep 5
fi
done


# Launch the rest of the services
echo "OpenDJ started successfully!"
echo
echo
sleep 1
echo
echo
echo "Starting Gluu Docker Edition!"

# I could use an IF AND command here to check that oxAuth and oxTrust have finished starting.

DOMAIN=$domain HOST_IP=$(ip route get 1 | awk '{print $NF;exit}') docker-compose up nginx oxauth oxtrust
