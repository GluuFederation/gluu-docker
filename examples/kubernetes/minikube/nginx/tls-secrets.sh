#!/bin/sh

if [ ! -f dhparam.pem ]; then
    openssl dhparam -out dhparam.pem 2048
fi

kubectl create secret generic tls-dhparam --from-file=dhparam.pem

if [ ! -f ingress.crt ]; then
    kubectl get cm gluu -o json \
    | grep '\"ssl_cert' \
    | awk -F '"' '{print $4}' \
    | python -c 'import sys; crt = sys.stdin.read().split("\\n"); f = open("ingress.crt", "w"); f.write("\n".join(crt[:-1])); f.close()'
fi

if [ ! -f ingress.key ]; then
    kubectl get cm gluu -o json \
    | grep '\"ssl_key' \
    | awk -F '"' '{print $4}' \
    | python -c 'import sys; key = sys.stdin.read().split("\\n"); f = open("ingress.key", "w"); f.write("\n".join(key[:-1])); f.close()'
fi

kubectl create secret tls tls-certificate --key ingress.key --cert ingress.crt
