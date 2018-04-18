#!/bin/bash
set -e

if [[ -z $(cat /etc/hosts|grep manager-1.gluu) ]]; then
    echo "[I] Adding extra host manager-1.gluu"
    cat /etc/manager-1.gluu >> /etc/hosts
fi

if [[ -z $(cat /etc/hosts|grep worker-1.gluu) ]]; then
    echo "[I] Adding extra host worker-1.gluu"
    cat /etc/worker-1.gluu >> /etc/hosts
fi
