# GKE (Google Kubernetes Engine)

## Setup Cluster

1.  Install [gcloud](https://cloud.google.com/sdk/docs/quickstarts)

2.  Install kubectl using `gcloud components install kubectl` command

3.  Create cluster:

        gcloud container clusters create CLUSTER_NAME --zone ZONE_NAME

    where `CLUSTER_NAME` is the name you choose for the cluster and `ZONE_NAME` is the name of [zone](https://cloud.google.com/compute/docs/regions-zones/) where the cluster resources live in.

4.  Configure `kubectl` to use the cluster:

        gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE_NAME

    where `CLUSTER_NAME` is the name you choose for the cluster and `ZONE_NAME` is the name of [zone](https://cloud.google.com/compute/docs/regions-zones/) where the cluster resources live in.

    Afterwards run `kubectl cluster-info` to check whether `kubectl` is ready to interact with the cluster.

## Deploying Containers

### Config

1.  Go to `config` directory:

        cd config

2.  Prepare roles for config:

    -   Get the email of Google Cloud account:

            gcloud info | grep Account # example => Account: [johndoe@example.com]

    -   Pass the email address as environment variable:

            ACCOUNT=EMAIL sh prepare-roles.yaml

3.  Prepare volumes for config:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

4.  Generate configuration:

        kubectl apply -f generate-config.yaml

### Redis

1.  Deploy a set of Redis pods:

        cd ../redis
        kubectl apply -f redis.yaml

2.  Run redis-trib to create Redis cluster:

        sh redis-cluster.sh create-cluster

    Type `yes` after seeing this output:

        If you don't see a command prompt, try pressing enter.

### OpenDJ (LDAP)

1.  Go to `ldap` directory:

        cd ../ldap

2.  Prepare volumes for ldap:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

3.  Create constraints to assign container to specific nodes:

        kubectl get node

    Pick one of the nodes, get the name, and attach a label to the node:

        kubectl label node NODE_NAME opendj-init=true

    Pick other nodes and attach a label for each node:

        kubectl label node NODE_NAME opendj-init=false

4.  Deploy OpenDJ pod that generates initial data:

        sh deploy-pod.sh

    Please wait until pod is completed. Check the logs using `kubectl logs -f POD_NAME`

5.  Deploy additional OpenDJ pod:

        kubectl apply -f opendj-repl.yaml

### nginx Ingress

To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller.

    cd ../nginx
    kubectl apply -f mandatory.yaml
    kubectl apply -f cloud-generic.yaml

The commands above will deploy `LoadBalancer` service in `ingress-nginx` namespace. Run `kubectl get svc -n ingress-nginx`:

    NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx          LoadBalancer   10.11.254.183   <pending>     80:30306/TCP,443:30247/TCP   50s

Create secrets to store TLS cert and key:

    sh tls-secrets.sh

Afterwards deploy the custom Ingress for Gluu Server routes.

    kubectl apply -f nginx.yaml

### oxAuth

1.  Go to `oxauth` directory:

        cd ../oxauth

2.  Prepare volumes for oxAuth:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

3.  Deploy oxAuth pod:

        kubectl apply -f oxauth.yaml

### NFS

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster. For simplicity, we're going to use NFS volume for Kubernetes.

1.  Go to `nfs` directory:

        cd ../nfs

2.  Create GCE Persistent Disk:

        kubectl apply -f nfs-gce-pv.yaml

3.  Deploy RC and SVC:

        kubectl apply -f nfs.yaml

4.  Prepare volumes for NFS:

    Get the Service IP of NFS:

        kubectl get svc
        NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                               AGE
        nfs-server   ClusterIP   10.11.240.76    <none>        2049/TCP,20048/TCP,111/TCP            10s

    Note the `CLUSTER-IP` for `nfs-server`. In this example, the IP is `10.11.240.76`.
    Use the value as environment variable as seen below:

        NFS_IP=NFS_CLUSTER_IP sh prepare-volumes.yaml

5.  Create required directory inside NFS pod:

        kubectl exec -ti NFS_POD_ID sh
        mkdir -p /exports/opt/shared-shibboleth-idp

### oxTrust

1.  Go to `oxtrust` directory:

        cd ../oxtrust

2.  Prepare volumes for oxTrust:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

3.  Deploy oxTrust pod:

    -   Get `EXTERNAL-IP` of `ingress-nginx`:

            NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
            ingress-nginx          LoadBalancer   10.11.254.183   35.240.221.38   80:30306/TCP,443:30247/TCP   1m

        In the example above, the external IP is set to `35.240.221.38`. Pass the value as seen below:

            NGINX_IP=NGINX_CLUSTER_IP sh deploy-pod.sh

### oxShibboleth

Deploy oxShibboleth pod:

    cd ../oxshibboleth
    NGINX_IP=NGINX_CLUSTER_IP sh deploy-pod.sh

### oxPassport

Deploy oxPassport pod:

    cd ../oxpassport
    NGINX_IP=NGINX_CLUSTER_IP sh deploy-pod.sh
