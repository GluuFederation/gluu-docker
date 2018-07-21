#!/bin/sh
NODE=$(kubectl get no -o go-template='{{range .items}}{{.metadata.name}} {{end}}' | awk -F " " '{print $1}')

HOME_DIR=$(gcloud compute ssh $NODE --zone asia-southeast1-a --command='echo $HOME')

cat oxauth-volumes.yaml | sed -s "s@HOME_DIR@$HOME_DIR@g" | kubectl apply -f -
