# GKE (Google Kubernetes Engine)

## Setup Cluster

1.  Install [gcloud](https://cloud.google.com/sdk/docs/quickstarts)

1.  Install kubectl using `gcloud components install kubectl` command

1.  Create cluster:

        gcloud container clusters create CLUSTER_NAME --zone ZONE_NAME

    where `CLUSTER_NAME` is the name you choose for the cluster and `ZONE_NAME` is the name of [zone](https://cloud.google.com/compute/docs/regions-zones/) where the cluster resources live in.

1.  Configure `kubectl` to use the cluster:

        gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE_NAME

    where `CLUSTER_NAME` is the name you choose for the cluster and `ZONE_NAME` is the name of [zone](https://cloud.google.com/compute/docs/regions-zones/) where the cluster resources live in.

    Afterwards run `kubectl cluster-info` to check whether `kubectl` is ready to interact with the cluster.

## Deploying Containers

### Config

1.  Go to `config` directory:

        cd config

1.  Prepare roles for config:

    -   Get the email of Google Cloud account:

            gcloud info | grep Account # example => Account: [johndoe@example.com]

    -   Pass the email address as environment variable:

            ACCOUNT=EMAIL sh prepare-roles.sh

    - Please note that if you get the error below, look closley at the `user=` section. The email is case sensitive based on how Google stores it. I received this error because my email address returned from the `gcloud info | grep Account` email was lower case, but Google has it saved in the backend as case sensitive for some reason. I changed the `ACCOUNT=` variable from `ACCOUNT=myadminemail@gmail.com` to `ACCOUNT=MyAdminEmail@gmail.com`


            PS C:\Users\User\Documents\Gluu_Kubernetes\GKE\gluu-docker\examples\kubernetes\gke\config> kubectl apply -f .\config-roles.yaml
            clusterrolebinding.rbac.authorization.k8s.io "cluster-admin-binding" configured
            rolebinding.rbac.authorization.k8s.io "gluu-rolebinding" unchanged
            Error from server (Forbidden): error when creating ".\\config-roles.yaml": roles.rbac.authorization.k8s.io "gluu-role" is forbidden: attempt to grant extra privileges: [PolicyRule{Resources:["services"], APIGroups:[""], Verbs:["get"]} PolicyRule{Resources:["services"], APIGroups:[""], Verbs:["list"]} PolicyRule{Resources:["services"], APIGroups:[""], Verbs:["watch"]} PolicyRule{Resources:["services"], APIGroups:[""], Verbs:["create"]} PolicyRule{Resources:["services"], APIGroups:[""], Verbs:["update"]} PolicyRule{Resources:["services"], APIGroups:[""], Verbs:["patch"]} PolicyRule{Resources:["services"], APIGroups:[""], Verbs:["delete"]} PolicyRule{Resources:["endpoints"], APIGroups:[""], Verbs:["get"]} PolicyRule{Resources:["endpoints"], APIGroups:[""], Verbs:["list"]} PolicyRule{Resources:["endpoints"], APIGroups:[""], Verbs:["watch"]} PolicyRule{Resources:["endpoints"], APIGroups:[""], Verbs:["create"]} PolicyRule{Resources:["endpoints"], APIGroups:[""], Verbs:["update"]} PolicyRule{Resources:["endpoints"], APIGroups:[""], Verbs:["patch"]} PolicyRule{Resources:["endpoints"], APIGroups:[""], Verbs:["delete"]} PolicyRule{Resources:["configmaps"], APIGroups:[""], Verbs:["get"]} PolicyRule{Resources:["configmaps"], APIGroups:[""], Verbs:["list"]} PolicyRule{Resources:["configmaps"], APIGroups:[""], Verbs:["watch"]} PolicyRule{Resources:["configmaps"], APIGroups:[""], Verbs:["create"]} PolicyRule{Resources:["configmaps"], APIGroups:[""], Verbs:["update"]} PolicyRule{Resources:["configmaps"], APIGroups:[""], Verbs:["patch"]} PolicyRule{Resources:["configmaps"], APIGroups:[""], Verbs:["delete"]}] user=&{MyAdminEmail@gmail.com  [system:authenticated] map[]} ownerrules=[PolicyRule{Resources:["selfsubjectaccessreviews" "selfsubjectrulesreviews"], APIGroups:["authorization.k8s.io"], Verbs:["create"]} PolicyRule{NonResourceURLs:["/api" "/api/*" "/apis" "/apis/*" "/healthz" "/swagger-2.0.0.pb-v1" "/swagger.json" "/swaggerapi" "/swaggerapi/*" "/version"], Verbs:["get"]}] ruleResolutionErrors=[]


1.  Prepare volumes for config:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

1.  Modify the `generate-config.yaml` environment variables to match your desired parameters, i.e. domain name, email, org, password, etc. Then run the following command to generate configuration:

        kubectl apply -f generate-config.yaml

### Redis

Deploy Redis pod:

    cd ../redis
    kubectl apply -f redis.yaml

### OpenDJ (LDAP)

1.  Go to `ldap` directory:

        cd ../ldap

1.  Prepare volumes for ldap:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

1.  Create constraints to assign container to specific nodes:

        kubectl get node

1. Pick one of the nodes, get the name, and attach a label to the node:

        kubectl label node NODE_NAME opendj-init=true

1. Pick other nodes and attach a label for each node:

        kubectl label node NODE_NAME opendj-init=false

1.  Deploy OpenDJ pod that generates initial data:

        kubectl apply -f opendj-init.yaml

    Please wait until pod is completed. Check the logs using `kubectl logs -f POD_NAME`

1.  Deploy additional OpenDJ pod:

        kubectl apply -f opendj-repl.yaml

### Nginx Ingress

1. To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller.

    cd ../nginx
    kubectl apply -f mandatory.yaml
    kubectl apply -f cloud-generic.yaml

1. The commands above will deploy a `LoadBalancer` service in the `ingress-nginx` namespace. Run `kubectl get svc -n ingress-nginx`:

    NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx          LoadBalancer   10.11.254.183   <pending>     80:30306/TCP,443:30247/TCP   50s

1. Create secrets to store TLS cert and key:

    sh tls-secrets.sh

1. Adjust all references to the hostname `kube.gluu.local` in `nginx.yaml` to the hostname you applied earlier while generating the configuration. Afterwards deploy the custom Ingress for Gluu Server routes.

    kubectl apply -f nginx.yaml
    
    - You can see the host and ip after with `kubectl get ing`
    
### oxAuth

1.  Go to the `oxauth` directory:

        cd ../oxauth

1.  Prepare volumes for oxAuth:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

1.  Deploy oxAuth pod:

    -   Get `EXTERNAL-IP` of `ingress-nginx` with `kubectl get svc -n ingress-nginx`:

            NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
            ingress-nginx          LoadBalancer   10.11.254.183   35.240.221.38   80:30306/TCP,443:30247/TCP   1m

1. In the example above, the external IP is set to `35.240.221.38`. Adjust the hostname from `kube.gluu.local` in `oxauth.yaml` to the hostname you applied earlier while generating the configuration. Pass the value as seen below to deploy oxAuth:

            NGINX_IP=NGINX_EXTERNAL_IP sh deploy-pod.sh

### NFS (Optional)

**This step is only required if you're utilizing Shibboleth, otherwise it's not necessary**

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster. For simplicity, we're going to use NFS volume for Kubernetes.

1.  Go to `nfs` directory:

        cd ../nfs

1.  Create GCE Persistent Disk:

        kubectl apply -f nfs-gce-pv.yaml

1.  Deploy RC and SVC:

        kubectl apply -f nfs.yaml

1.  Prepare volumes for NFS:

    Get the Cluster IP of NFS with `kubectl get svc`:

        NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                               AGE
        nfs-server   ClusterIP   10.11.240.76    <none>        2049/TCP,20048/TCP,111/TCP            10s

    Note the `CLUSTER-IP` for `nfs-server`. In this example, the IP is `10.11.240.76`.
    Use the value as environment variable as seen below:

        NFS_IP=NFS_CLUSTER_IP sh prepare-volumes.sh

1.  Create required directory inside NFS pod:

        kubectl exec -ti NFS_POD_ID sh
        mkdir -p /exports/opt/shared-shibboleth-idp

### oxTrust

1.  Go to `oxtrust` directory:

        cd ../oxtrust

1.  Prepare volumes for oxTrust:

        ZONE=ZONE_NAME sh prepare-volumes.sh

    where `ZONE_NAME` is the name of zone used when creating cluster

1.  Adjust the hostname from `kube.gluu.local` in `oxtrust.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxTrust pod:

    -   Get the `EXTERNAL-IP` of `ingress-nginx` with `kubectl get svc -n ingress-nginx`:

            NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
            ingress-nginx          LoadBalancer   10.11.254.183   35.240.221.38   80:30306/TCP,443:30247/TCP   1m

        In the example above, the external IP is set to `35.240.221.38`. Pass the value as seen below:

            NGINX_IP=NGINX_EXTERNAL_IP sh deploy-pod.sh

### oxShibboleth

1. Adjust the hostname from `kube.gluu.local` in `oxshibboleth.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxShibboleth pod:

    cd ../oxshibboleth
    NGINX_IP=NGINX_CLUSTER_IP sh deploy-pod.sh

### oxPassport

1. Adjust the hostname from `kube.gluu.local` in `oxpassport.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxPassport pod:

    cd ../oxpassport
    NGINX_IP=NGINX_CLUSTER_IP sh deploy-pod.sh

1. Enable Passport support by following the official docs [here](https://gluu.org/docs/ce/authn-guide/passport/#setup-passportjs-with-gluu).

1. Afterwards, run the following commands to _restart_ oxPassport:

    - this will force oxpassport to reload all of its containers in order to load strategies properly
    
            kubectl scale deployment --replicas=0 oxpassport
            kubectl scale deployment --replicas=1 oxpassport
