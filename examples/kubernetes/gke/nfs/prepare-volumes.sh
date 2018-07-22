#!/bin/sh

cat nfs-volumes.yaml | sed -s "s@NFS_IP@$NFS_IP@g" | kubectl apply -f -
