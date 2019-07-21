# Minikube ![CDNJS](https://img.shields.io/badge/UNDERCONSTRUCTION-red.svg?style=for-the-badge)

## Setup Cluster

1.  Install [minikube](https://github.com/kubernetes/minikube/releases).

2.  Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

3.  Create cluster:

        minikube start

4.  Configure `kubectl` to use the cluster:

        kubectl config use-context minikube

## Deploying Containers

### Config

1.  Go to `config` directory:

        cd config

2.  Prepare roles for config:

        kubectl apply -f config-roles.yaml

3.  Prepare volumes for config:

        kubectl apply -f config-volumes.yaml

4.  Create `generate.json` to define parameters for generating new config and secret:

    Example:

        {
            "hostname": "kube.gluu.local",
            "country_code": "US",
            "state": "TX",
            "city": "Austin",
            "admin_pw": "S3cr3t+pass",
            "email": "s@gluu.local",
            "org_name": "Gluu Inc."
        }

    Afterwards, save this file into ConfigMaps:

        kubectl create cm config-generate-params --from-file=generate.json

5.  Load config and secret:

        kubectl apply -f load-config.yaml

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

2.  Prepare volumes for ldap:

        kubectl apply -f opendj-volumes.yaml

3.  Deploy OpenDJ pod that generates initial data:

        kubectl apply -f opendj-init.yaml

    Please wait until pod is completed. Check the logs using `kubectl logs -f POD_NAME`

### nginx Ingress

To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller.

    cd ../nginx
    minikube addons enable ingress

Create secrets to store TLS cert and key:

    sh tls-secrets.sh

Afterwards deploy the custom Ingress for Gluu Server routes.

    kubectl apply -f nginx.yaml

### oxAuth

1.  Go to `oxauth` directory:

        cd ../oxauth

2.  Prepare volumes for oxAuth:

        kubectl apply -f oxauth-volumes.yaml

3.  Deploy oxAuth pod:

        NGINX_IP=$(minikube ip) sh deploy-pod.sh

### Shared Shibboleth IDP Files

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster.

1.  Go to `shared-shib` directory:

        cd ../shared-shib

2.  Prepare volumes for shared Shibboleth files:

        kubectl apply -f shared-shib-volumes.yaml

### oxTrust

1.  Go to `oxtrust` directory:

        cd ../oxtrust

2.  Prepare volumes for oxTrust:

        kubectl apply -f oxtrust-volumes.yaml

3.  Deploy oxTrust pod:

        NGINX_IP=$(minikube ip) sh deploy-pod.sh

### oxShibboleth

Deploy oxShibboleth pod:

    cd ../oxshibboleth
    NGINX_IP=$(minikube ip) sh deploy-pod.sh

### oxPassport

Enable Passport support by following the official docs [here](https://gluu.org/docs/ce/authn-guide/passport/#setup-passportjs-with-gluu).
Afterwards, deploy oxPassport pod:

    cd ../oxpassport
    NGINX_IP=$(minikube ip) sh deploy-pod.sh

### key-rotation (OPTIONAL)

Deploy key-rotation pod:

    cd ../key-rotation
    kubectl apply -f key-rotation.yaml

### cr-rotate (OPTIONAL)

Deploy cr-rotate pod:

    cd ../cr-rotate
    kubectl apply -f cr-rotate-roles.yaml
    kubectl apply -f cr-rotate.yaml

## Scaling Containers

To scale containers, run the following command:

```
kubectl scale --replicas=<number> <resource> <name>
```

In this case, `<resource>` could be Deployment or Statefulset and `<name>` is the resource name.

Examples:

-   Scaling oxAuth:

    ```
    kubectl scale --replicas=2 deployment oxauth
    ```

-   Scaling oxTrust:

    ```
    kubectl scale --replicas=2 statefulset oxtrust
    ```
