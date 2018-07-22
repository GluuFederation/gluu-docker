#!/bin/sh

if [ -z $ACCOUNT ]; then
    echo "[E] Requires valid email as Google Cloud account"
    exit 1
fi

cat config-roles.yaml | sed "s#ACCOUNT#$ACCOUNT#g" | kubectl apply -f -
