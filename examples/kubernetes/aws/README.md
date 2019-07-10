# Amazon Web Services (AWS)

## Installation using different load balancers:


A label will be shown for the commands to follow for each load balancer. **Only follow instructions that include the applicable tag for the load balancer in use.**

- Classic Load Balancer - ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg)

- Application Load Balancer - ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg)

- Network Load Balancer (Alpha)- ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

> **_NOTE:_**  ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) Following the CLB example guide will install a classic load balancer with an `IP` that is not static. Do not worry about the `IP` changing as all pods will be updated automatically when a change in the `IP` of the load balancer occurs using a script. However, if you are deploying in production you **WILL NOT** use our script and instead assign a static `IP`  to your load balancer.


## Setup Cluster

-  Follow this [guide](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
 to install a cluster with worker nodes. Please make sure that you have all the `IAM` policies for the AWS user that will be creating the cluster and volumes.

## Requirements

-   The above guide should also walk you through installing `kubectl` , `aws-iam-authenticator` and `aws cli` on the VM you will be managing your cluster and nodes from. Check to make sure.

        aws-iam-authenticator help
        aws-cli
        kubectl version

-   Get the source code:

        wget -q https://github.com/GluuFederation/gluu-docker/archive/3.1.6.zip
        unzip 3.1.6.zip
        cd gluu-docker-3.1.6/examples/kubernetes/aws/clb

# Deployment stratigies

1. [Deploying containers with volumes on host](#deploying-containers-with-volumes-on-host)

1. [Deploying containers with dynamically provisioned EBS volumes](#deploying-containers-with-dynamically-provisioned-ebs-volumes)

1. [Deploying container with statically provisioned EBS volumes](#deploying-containers-with-statically-provisioned-ebs-volumes)

   This strategy is mostly used when your EBS volumes for  all services exist already.

# How-to

1. [How to expand EBS volumes](#how-to-expand-ebs-volumes)

## Deploying Containers with volumes on host

### Config ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

1.  Go to `config` directory: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        cd config


1.  Prepare roles for config: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f config-roles.yaml


1.  Prepare volumes for config: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f config-volumes.yaml


1.  Generate configuration: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f generate-config.yaml

### Redis (optional) ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

> **_NOTE:_** This pod is optional and used only when `GLUU_CACHE_TYPE` is set to `REDIS`. If `REDIS` is selected, make sure to change the `ConfigMap` definetion in the `ldap/opendj-init.yaml` file:

```
  #GLUU_CACHE_TYPE: "NATIVE_PERSISTENCE"
  GLUU_CACHE_TYPE: "REDIS"
  GLUU_REDIS_URL: "redis:6379"
  GLUU_REDIS_TYPE: "STANDALONE"
```

Deploy Redis pod:

    cd ../redis
    kubectl apply -f redis.yaml

### OpenDJ (LDAP) ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)
 
1.  Go to `ldap` directory: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        cd ../ldap
		
1.  Prepare volumes for ldap: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)


        kubectl apply -f opendj-volumes.yaml


1.  Create constraints to assign container to specific nodes: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl get node


1. Pick one of the nodes, get the name, and attach a label to the node: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)


        kubectl label node NODE_NAME opendj-init=true


1.  Pick other nodes and attach a label for each node: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl label node NODE_NAME opendj-init=false


1.  Deploy OpenDJ pod that generates initial data: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f opendj-init.yaml

    Please wait until pod is completed. Check the logs using `kubectl logs -f POD_NAME`


1.  Deploy additional OpenDJ pod: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f opendj-repl.yaml

### Nginx Ingress ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

1.  To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller. ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg)

        cd ../nginx
        kubectl apply -f mandatory.yaml
        kubectl apply -f cloud-generic.yaml
		
    To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller but for NLB we must add an annotation `service.beta.kubernetes.io/aws-load-balancer-type: nlb` along with other annotations for using the right certificate when deploying nginx. These annotaions are added to the `cloud-generic.yaml`. ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)
        
		cd ../nginx
		vi cloud-generic.yaml
		
		  ...
		  ...
		  metadata:
          name: ingress-nginx
          namespace: ingress-nginx
          labels:
            app: ingress-nginx
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: nlb
			service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags: "Name=example,Owner=ingress-nginx"
			service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS-..."
			service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-west-2:2222222:certificate/324234-1111-fsef-efsf-daskjA98209a
			service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
			service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
			service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
			service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"
			service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: true
		  ...
		  ...
		  
        kubectl apply -f mandatory.yaml
        kubectl apply -f cloud-generic.yaml
		
1.  The commands above will deploy a `LoadBalancer` service in the `ingress-nginx` namespace. Run `kubectl get svc -n ingress-nginx`: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP                                                        PORT(S)                      AGE
        ingress-nginx          LoadBalancer   10.11.254.183   a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com              80:30306/TCP,443:30247/TCP   50s

1.  Create secrets to store TLS cert and key: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg)

        sh tls-secrets.sh

1.  Adjust all references to the hostname `kube.gluu.local` in `nginx.yaml` to the hostname you applied earlier while generating the configuration. Afterwards deploy the custom Ingress for Gluu Server routes. ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

    Remove `secretName: tls-certificate` in `nginx.yaml` . ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)
		
        kubectl apply -f nginx.yaml
    
    You can see the host and IP after with `kubectl get ing`

### Update scripts folder  ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

> **_Warning:_**  If you are deploying in production please assign a static IP to your Loadbalancer and skip this section.However, the following files need to be modified `oxauth.yaml`, `oxpassport.yaml`, `oxshibboleth.yaml`, and `oxtrust.yaml` to comment out the `updateclbip` as following : ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)
       
       volumeMounts:
         ...
         ...
         #- mountPath: /scripts
         #  name: update-clb-ip
       ..
       ..
     volumes:
     ...
     ...
     #- name: update-clb-ip
     #  configMap:
     #    name: updateclbip
 
---

1.  Create configmap for the update clb ip script. ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg)
        
        cd ../update-clb-ip
        
        kubectl create -f update-clb-configmap.yaml

### oxAuth ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

1. Get the current IP of the load balancer ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to the `oxauth` directory: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        cd ../oxauth

1.  Prepare volumes for oxAuth: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f oxauth-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com` ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg)

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local` ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxauth.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxauth`. ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)
 
        NGINX_IP=35.240.221.38 sh deploy-pod.sh ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)
		

### Shared Shibboleth IDP Files ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster.

1.  Go to `shared-shib` directory: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        cd ../shared-shib

1.  Prepare volumes for shared Shibboleth files: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f shared-shib-volumes.yaml

### oxTrust ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

1. Get the current ip of the load balancer ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to `oxtrust` directory: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        cd ../oxtrust

1.  Prepare volumes for oxTrust: ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        kubectl apply -f oxtrust-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com` ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local` ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxtrust.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxtrust`. ![CDNJS](https://img.shields.io/badge/CLB-passed-green.svg) ![CDNJS](https://img.shields.io/badge/ALB-underconstruction-red.svg) ![CDNJS](https://img.shields.io/badge/NLB-alpha-orange.svg)

        NGINX_IP=35.240.221.38 sh deploy-pod.sh

### oxShibboleth

> **_Warning:_**  If you are deploying in production please skip the second point on assiginnig your `LB_ADDR` env.

1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxshibboleth.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxShibboleth pod:

        cd ../oxshibboleth
        NGINX_IP=35.240.221.38P sh deploy-pod.sh

### oxPassport

> **_Warning:_**  If you are deploying in production please skip the second point on assiginnig your `LB_ADDR` env.


1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

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

## Deploying containers with dynamically provisioned EBS volumes

In this section a deployment of gluu with automatically provisioned EBS volumes will be created. You must adjust the zones in all your storage classes where your volumes will be automattically provisioned in all the `*-volumes.yaml` files encountered during setup. The following is an example.

### Example : Changing the oxauth storage class zone
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: oxauth-gluu
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/aws-ebs
allowVolumeExpansion: true
parameters:
  type: gp2
  encrypted: "true"
  zones: us-west-2a <---------- adjust this to the zone where you want the volumes associated to be provisioned
reclaimPolicy: Retain
mountOptions:
- debug 
```

### Config

1.  Go to `config/dynamic-ebs` directory:

        cd config/dynamic-ebs

1.  Prepare roles for config:

        kubectl apply -f config-roles.yaml

1.  Prepare volumes for config:

        kubectl apply -f config-volumes.yaml

1.  Generate configuration:

        kubectl apply -f generate-config.yaml

### Redis (optional)

Note: this pod is optional and used only when `GLUU_CACHE_TYPE` is set to `REDIS`. If `REDIS` is selected, make sure to change the `ldap/opendj-init.yaml` file:

```
  #GLUU_CACHE_TYPE: "NATIVE_PERSISTENCE"
  GLUU_CACHE_TYPE: "REDIS"
  GLUU_REDIS_URL: "redis:6379"
  GLUU_REDIS_TYPE: "STANDALONE"
```

Deploy Redis pod:

    cd ../redis
    kubectl apply -f redis.yaml

### OpenDJ (LDAP)

1.  Go to `ldap/dynamic-ebs` directory:

        cd ../ldap/dynamic-ebs

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

> **_Warning:_**  If you are deploying in production please assign a static IP to your Loadbalancer and skip this section. The following files need to be modified `oxauth.yaml`, `oxpassport.yaml`, `oxshibboleth.yaml`, and `oxtrust.yaml` to comment out the `updateclbip` as following :
       
       volumeMounts:
         ...
         ...
         #- mountPath: /scripts
         #  name: update-clb-ip
       ..
       ..
     volumes:
     ...
     ...
     #- name: update-clb-ip
     #  configMap:
     #    name: updateclbip
 
---

1.  Create configmap for the update clb ip script.
        
        cd ../update-clb-ip
        
        kubectl create -f update-clb-configmap.yaml

### oxAuth

> **_Warning:_**  If you are deploying in production please skip the forth point on assiginnig your `LB_ADDR` env.

1. Get the current IP of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to the `oxauth/dynamic-ebs` directory:

        cd ../oxauth/dynamic-ebs

1.  Prepare volumes for oxAuth:

        kubectl apply -f oxauth-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxauth.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxauth`.

        NGINX_IP=35.240.221.38 sh deploy-pod.sh
		
		
### Shared Shibboleth IDP Files

> **_Warning:_**  Multi-Attach is not supported by EBS as this volume is shared with oxTrust and oxShibboleth . The current deployment is using the host. If you feel it is necessary use EFS on AWS for deploying this volume.

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster.

1.  Go to `shared-shib` directory:

        cd ../shared-shib

1.  Prepare volumes for shared Shibboleth files:

        kubectl apply -f shared-shib-volumes.yaml

### oxTrust

> **_Warning:_**  If you are deploying in production please skip the forth point on assiginnig your `LB_ADDR` env.


1. Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to `oxtrust` directory:

        cd ../oxtrust/dynamic-ebs

1.  Prepare volumes for oxTrust:

        kubectl apply -f oxtrust-volumes.yaml


1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxtrust.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxtrust`.

        NGINX_IP=35.240.221.38 sh deploy-pod.sh

### oxShibboleth

> **_Warning:_**  If you are deploying in production please skip the second point on assiginnig your `LB_ADDR` env.


1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxshibboleth.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxShibboleth pod:

        cd ../oxshibboleth
        NGINX_IP=35.240.221.38P sh deploy-pod.sh

### oxPassport

> **_Warning:_**  If you are deploying in production please skip the second point on assiginnig your `LB_ADDR` env.


1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

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


## Deploying containers with statically provisioned EBS volumes

In this section a deployment of gluu with statically provisioned EBS volumes will be created. You must have all your volumes available. Please note down all your EBS `volume-ids`.

### Example : Changing the config volumeID

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: config
  labels:
      config-init: config
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  awsElasticBlockStore:
    volumeID: vol-9aiiiwa9hdfh0dfre0w <-- Place your volumeID associated with config here
    fsType ext4
```

### Example: Changing the zone to match zone of the volume created

Note down which zone your volumes are created in you must deploy the services in the matching zones.

```
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: failure-domain.beta.kubernetes.io/zone
                operator: In
                values:
                # change this to same zone your volume was created at
                - us-west-2a
```

### Config

1.  Go to `config/static-ebs` directory:

        cd config/static-ebs

1.  Prepare roles for config:

        kubectl apply -f config-roles.yaml

1.  Prepare volumes for config:

        kubectl apply -f config-volumes.yaml

1.  Generate configuration:

        kubectl apply -f generate-config.yaml

### Redis (optional)

Note: this pod is optional and used only when `GLUU_CACHE_TYPE` is set to `REDIS`. If `REDIS` is selected, make sure to change the `ldap/opendj-init.yaml` file:

```
  #GLUU_CACHE_TYPE: "NATIVE_PERSISTENCE"
  GLUU_CACHE_TYPE: "REDIS"
  GLUU_REDIS_URL: "redis:6379"
  GLUU_REDIS_TYPE: "STANDALONE"
```

Deploy Redis pod:

    cd ../redis
    kubectl apply -f redis.yaml

### OpenDJ (LDAP)

1.  Go to `ldap/static-ebs` directory:

        cd ../ldap/static-ebs

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

> **_Warning:_**  If you are deploying in production please assign a static IP to your Loadbalancer and skip this section. The following files need to be modified `oxauth.yaml`, `oxpassport.yaml`, `oxshibboleth.yaml`, and `oxtrust.yaml` to comment out the `updateclbip` as following :
       
       volumeMounts:
         ...
         ...
         #- mountPath: /scripts
         #  name: update-clb-ip
       ..
       ..
     volumes:
     ...
     ...
     #- name: update-clb-ip
     #  configMap:
     #    name: updateclbip
 
---

1.  Create configmap for the update clb ip script.
        
        cd ../update-clb-ip
        
        kubectl create -f update-clb-configmap.yaml

### oxAuth

> **_Warning:_**  If you are deploying in production please skip the forth point on assiginnig your `LB_ADDR` env.

1. Get the current IP of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to the `oxauth/static-ebs` directory:

        cd ../oxauth/static-ebs

1.  Prepare volumes for oxAuth:

        kubectl apply -f oxauth-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxauth.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxauth`.

        NGINX_IP=35.240.221.38 sh deploy-pod.sh


### Shared Shibboleth IDP Files

> **_Warning:_**  Multi-Attach is not supported by EBS as this volume is shared with oxTrust and oxShibboleth . The current deployment is using the host. If you feel it is necessary use EFS on AWS for deploying this volume.

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster.

1.  Go to `shared-shib` directory:

        cd ../shared-shib

1.  Prepare volumes for shared Shibboleth files:

        kubectl apply -f shared-shib-volumes.yaml


### oxTrust

> **_Warning:_**  If you are deploying in production please skip the forth point on assiginnig your `LB_ADDR` env.


1. Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to `oxtrust` directory:

        cd ../oxtrust/static-ebs

1.  Prepare volumes for oxTrust:

        kubectl apply -f oxtrust-volumes.yaml
        
1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxtrust.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxtrust`.

        NGINX_IP=35.240.221.38 sh deploy-pod.sh

### oxShibboleth

> **_Warning:_**  If you are deploying in production please skip the second point on assiginnig your `LB_ADDR` env.


1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

1.  Adjust the hostname from `kube.gluu.local` in `oxshibboleth.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxShibboleth pod:

        cd ../oxshibboleth
        NGINX_IP=35.240.221.38P sh deploy-pod.sh

### oxPassport

> **_Warning:_**  If you are deploying in production please skip the second point on assiginnig your `LB_ADDR` env.


1.  Get the current ip of the load balancer

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com`

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `kube.gluu.local`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "kube.gluu.local"

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
    
## How to expand EBS volumes

1. Make sure the `StorageClass` used in your deployment has the `allowVolumeExpansion` set to true. If you have used our EBS volume deployment strategy then you will find that this property has already been set for you.

1. Edit your persistent volume claim using `kubectl edit pvc <claim-name> -n <namespace> ` and increase the value found for `storage:` to the value needed. Make sure the volumes expand by checking the `kubectl get pvc <claim-name> -n <namespace> `.

1. Restart the associated services
