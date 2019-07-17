#!/bin/sh

cat oxshibboleth.yaml | sed -s "s@NGINX_IP@$NGINX_IP@g" | kubectl apply -f -
