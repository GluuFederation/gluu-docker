# Deploying NFS Volume

1.  Create GCE Persistent Disk:

        kubectl apply -f nfs-server-gce-pv.yaml

2.  Deploy RC and SVC:

        kubectl apply -f nfs-server-rc.yaml
        kubectl apply -f nfs-server-service.yaml

3.  Add PV and PVC:

        kubectl apply -f nfs-pv.yaml
        kubectl apply -f nfs-pvc.yaml
