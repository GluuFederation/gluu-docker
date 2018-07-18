kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin \
    --user 'isman.firmansyah@gmail.com'

sleep 5

GLUU_CONFIG_ADAPTER=${GLUU_CONFIG_ADAPTER:-kubernetes}

echo "using $GLUU_CONFIG_ADAPTER as config adapter"

kubectl run config-init \
    --env=GLUU_CONFIG_ADAPTER="$GLUU_CONFIG_ADAPTER" \
    --image=gluufederation/config-init:3.1.3_wrapper \
    --restart=Never \
    -i \
    --tty \
    --rm \
    -- generate \
        --admin-pw secret \
        --email 'support@gluu.local' \
        --domain kube.gluu.local \
        --org-name Gluu \
        --country-code US \
        --state TX \
        --city Austin
