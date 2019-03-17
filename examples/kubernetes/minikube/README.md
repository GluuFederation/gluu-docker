# Minikube

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

4.  Generate configuration:

        kubectl apply -f generate-config.yaml

### Redis (optional)

Note: this pod is optional and used only when `GLUU_CACHE_TYPE` is set to `REDIS`.

Deploy Redis pod:

    cd ../redis
    kubectl apply -f redis.yaml

### Logging

The logging services will collect all containers log, parse and save them into Elasticsearch. The captured logs can be viewed on Kibana UI.

1.  Go to `logging` directory:

        cd ../logging

2.  Deploy Filebeat:

    ```
    kubectl create cm filebeat-config --from-file=filebeat.yml
    kubectl apply -f filebeat-ds.yaml
    ```

3.  Set `vm.max_map_count` kernel setting to at least 262144 for production use. Refer to the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode).

4.  Deploy Elasticsearch:

        kubectl apply -f elasticsearch.yaml

5.  Deploy Kibana:

        kubectl apply -f kibana.yaml

    Note: Kibana is not exposed to public. To access the UI, use `kubectl port-forward $KIBANA_POD_NAME --address $ADDRESS_OR_IP 5601:5601`

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
