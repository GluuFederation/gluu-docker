# Amazon Web Services (AWS) - Classic Load Balancer

!!!Note: Following this example guide will install a classic load balancer with an `IP` that is not static. Do not worry about the `IP` changing as all pods will be updated automatically when a change in the `IP` of the load balancer occurs.

## Setup Cluster

-  Follow this [guide](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
 to install a cluster with worker nodes.

## Requirements

-   The above guide should also walk you through installing `kubectl` , `aws-iam-authenticator` and `aws cli` on the VM you will be managing your cluster and nodes from. Check to make sure.

        aws-iam-authenticator help
        aws-cli
        kubectl version

-   Get the source code:

        wget -q https://github.com/GluuFederation/gluu-docker/archive/3.1.6.zip
        unzip 3.1.6.zip
        cd gluu-docker-3.1.6/examples/kubernetes/aws/clb

## Deploying Containers

### Config

1.  Go to `config` directory:

        cd config

1.  Prepare roles for config:

        kubectl apply -f config-roles.yaml

1.  Prepare volumes for config:

        kubectl apply -f config-volumes.yaml

1.  Generate configuration:

        kubectl apply -f generate-config.yaml

### Redis (optional)

Note: this pod is optional and used only when `GLUU_CACHE_TYPE` is set to `REDIS`. If `REDIS` is selected, make sure to change the `ldap/opendj-init.yaml` file:

```
containers:
  - name: opendj
    env:
      # - name: GLUU_CACHE_TYPE
      #   value: "NATIVE_PERSISTENCE"
      - name: GLUU_CACHE_TYPE
        value: "REDIS"
      - name: GLUU_REDIS_TYPE
        value: "STANDALONE"
      - name: GLUU_REDIS_URL
        value: "redis:6379"
```

Deploy Redis pod:

    cd ../redis
    kubectl apply -f redis.yaml

### OpenDJ (LDAP)

1.  Go to `ldap` directory:

        cd ../ldap

1.  Prepare volumes for ldap:

        kubectl apply -f opendj-volumes.yaml

1.  Create constraints to assign container to specific nodes:

        kubectl get node

1.  Pick one of the nodes, get the name, and attach a label to the node:

        kubectl label node NODE_NAME opendj-init=true

1.  Pick other nodes and attach a label for each node:

        kubectl label node NODE_NAME opendj-init=false

1.  Deploy OpenDJ pod that generates initial data:

        kubectl apply -f opendj-init.yaml

    Please wait until pod is completed. Check the logs using `kubectl logs -f POD_NAME`

1.  Deploy additional OpenDJ pod:

        kubectl apply -f opendj-repl.yaml

### Nginx Ingress

1.  To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller.

        cd ../nginx
        kubectl apply -f mandatory.yaml
        kubectl apply -f cloud-generic.yaml

1.  The commands above will deploy a `LoadBalancer` service in the `ingress-nginx` namespace. Run `kubectl get svc -n ingress-nginx`:

        NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP                                                        PORT(S)                      AGE
        ingress-nginx          LoadBalancer   10.11.254.183   a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com              80:30306/TCP,443:30247/TCP   50s

1.  Create secrets to store TLS cert and key:

        sh tls-secrets.sh

1.  Adjust all references to the hostname `kube.gluu.local` in `nginx.yaml` to the hostname you applied earlier while generating the configuration. Afterwards deploy the custom Ingress for Gluu Server routes.

        kubectl apply -f nginx.yaml

    You can see the host and IP after with `kubectl get ing`

### Update scripts folder

1.  Create configmap for the update clb ip script.
        
        cd ../update-clb-ip
        
        kubectl create -f update-clb-configmap.yaml

### oxAuth

1. Get the current IP of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to the `oxauth` directory:

        cd ../oxauth

1.  Prepare volumes for oxAuth:

        kubectl apply -f oxauth-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

          - name: LB_ADDR
            value: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
          - name: DOMAIN
            value: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxauth.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxauth`.

        NGINX_IP=35.240.221.38 sh deploy-pod.sh

### Shared Shibboleth IDP Files

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster.

1.  Go to `shared-shib` directory:

        cd ../shared-shib

1.  Prepare volumes for shared Shibboleth files:

        kubectl apply -f shared-shib-volumes.yaml

### oxTrust

1. Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to `oxtrust` directory:

        cd ../oxtrust

1.  Prepare volumes for oxTrust:

        kubectl apply -f oxtrust-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        - name: LB_ADDR
          value: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        - name: DOMAIN
          value: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxtrust.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxtrust`.

        NGINX_IP=35.240.221.38 sh deploy-pod.sh

### oxShibboleth

1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        - name: LB_ADDR
          value: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        - name: DOMAIN
          value: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxshibboleth.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxShibboleth pod:

        cd ../oxshibboleth
        NGINX_IP=35.240.221.38P sh deploy-pod.sh

### oxPassport

1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        - name: LB_ADDR
          value: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        - name: DOMAIN
          value: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxpassport.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxPassport pod:

       cd ../oxpassport
       NGINX_IP=35.240.221.38 sh deploy-pod.sh

1.  Enable Passport support by following the official docs [here](https://gluu.org/docs/ce/authn-guide/passport/#setup-passportjs-with-gluu).

### key-rotation (OPTIONAL)

Deploy key-rotation pod:

    cd ../key-rotation
    kubectl apply -f key-rotation.yaml

### cr-rotate (OPTIONAL)

Deploy cr-rotate pod:

    cd ../cr-rotate
    kubectl apply -f cr-rotate-roles.yaml
    kubectl apply -f cr-rotate.yaml
