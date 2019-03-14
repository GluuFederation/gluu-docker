#!/bin/sh

if [ ! -f dhparam.pem ]; then
    openssl dhparam -out dhparam.pem 2048
fi

kubectl create secret generic tls-dhparam --from-file=dhparam.pem

if [ ! -f ingress.crt ]; then
    kubectl get cm gluu -o jsonpath='{.data.ssl_cert}' > ingress.crt
fi

if [ ! -f ingress.key ]; then
    kubectl get cm gluu -o jsonpath='{.data.ssl_key}' > ingress.key
fi

kubectl create secret tls tls-certificate --key ingress.key --cert ingress.crt
