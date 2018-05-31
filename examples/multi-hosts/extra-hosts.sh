#!/bin/bash
set -e

if [[ -z $(cat /etc/hosts|grep manager.gluu) ]]; then
    echo "[I] Adding extra host manager.gluu"
    cat /etc/manager.gluu >> /etc/hosts
fi

for node in worker-1 worker-2; do
    if [[ -z $(cat /etc/hosts|grep $node.gluu) ]]; then
        echo "[I] Adding extra host $node.gluu"
        cat /etc/$node.gluu >> /etc/hosts
    fi
done
