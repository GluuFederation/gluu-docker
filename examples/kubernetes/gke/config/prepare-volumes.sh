#!/bin/sh

NODE=$(kubectl get no -o go-template='{{range .items}}{{.metadata.name}} {{end}}' | awk -F " " '{print $1}')

if [ -z $ZONE ]; then
    echo "[E] Requires Google Cloud zone name"
    exit 1
fi

HOME_DIR=$(gcloud compute ssh $NODE --zone $ZONE --command='echo $HOME')

cat config-volumes.yaml | sed -s "s@HOME_DIR@$HOME_DIR@g" | kubectl apply -f -
