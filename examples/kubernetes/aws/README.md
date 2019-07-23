# Amazon Web Services (AWS)

## Installation using different load balancers

This document includes installation instructions for AWS, with specific commands for the following types of Load Balancers:

- Classic Load Balancer - ![CDNJS](https://img.shields.io/badge/CLB--green.svg)

- Application Load Balancer (Beta) - ![CDNJS](https://img.shields.io/badge/ALB--red.svg) ** Coming soon

- Network Load Balancer (Alpha)- ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

The labels displayed above are used throughout the docs to indicate certain commands that only apply to a specific type of load balancer. **If no tag is specified, the command is applicable for all load balancers.** 

> **_NOTE:_** These are example deployments. We highly recommend using your own custom DNS entries. This is especially important with an ALB or NLB load balancer.

> **_NOTE:_**  ![CDNJS](https://img.shields.io/badge/CLB--green.svg) Following the CLB example guide will install a classic load balancer with an `IP` that is not static. Don't worry about the `IP` changing. All pods will be updated automatically with our script when a change in the `IP` of the load balancer occurs. However, when deploying in production, **DO NOT** use our script. Instead, assign a CNAME record for the LoadBalancer DNS name, or use Amazon Route 53 to create a hosted zone. More details in this [AWS guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/using-domain-names-with-elb.html?icmpid=docs_elb_console).


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

-  Please follow this [guide](https://kubernetes-sigs.github.io/aws-alb-ingress-controller/guide/controller/setup/) to install the `aws-alb-ingress-controller` ![CDNJS](https://img.shields.io/badge/ALB--red.svg)

-  Go to the IAM Console, create a policy with the contents in the [iam-policy.json](https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.0.0/docs/examples/iam-policy.json) file and save it as `ingressController-iam-policy`. This policy must be attached to all your `EKS Nodes`. ![CDNJS](https://img.shields.io/badge/ALB--red.svg)
		

# Deployment strategies

1. [Deploying containers with volumes on host](#deploying-containers-with-volumes-on-host) ![CDNJS](https://img.shields.io/badge/Host--blue.svg)

1. [Deploying containers with dynamically provisioned EBS volumes](#deploying-containers-with-dynamically-provisioned-ebs-volumes) ![CDNJS](https://img.shields.io/badge/EBS-dynamic-yellowgreen.svg)

1. [Deploying container with statically provisioned EBS volumes](#deploying-containers-with-statically-provisioned-ebs-volumes) ![CDNJS](https://img.shields.io/badge/EBS-static-yellow.svg)

   This strategy is mostly used when your EBS volumes for  all services exist already.

## Deploying containers with dynamically provisioned EBS volumes

Please follow the  notes in this section while  [Deploying containers with volumes on host](#deploying-containers-with-volumes-on-host) to deploy with dynamically provisioned EBS volumes :
 
- To add a deployment of gluu with automatically provisioned EBS volumes you must adjust the zones in all your storage classes where your volumes will be automattically provisioned in all the `*-volumes.yaml` files encountered during setup. The following is an example.

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
- Use the manifests  inside the `folder/dynamic-ebs` while following this guide.

### Example : Config

In this guide you will be asked to `cd` into `config`. Instead you will 

        cd config/dynamic-ebs

### Shared Shibboleth IDP Files

> **_Warning:_**  Multi-Attach is not supported by EBS as this volume is shared with oxTrust and oxShibboleth . The current deployment is using the host. If you feel it is necessary use EFS on AWS for deploying this volume.

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster.

## Deploying containers with statically provisioned EBS volumes

Please follow the  notes in this section while  [Deploying containers with volumes on host](#deploying-containers-with-volumes-on-host) to deploy with statically provisioned EBS volumes :

- In this section a deployment of gluu with statically provisioned EBS volumes will be created. You must have all your volumes available. Please note down all your EBS `volume-ids`.

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

- Note down which zone your volumes are created in you must deploy the services in the matching zones.

### Example: Changing the zone to match zone of the volume created

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

## Notes on using loadbalancers

- All service definitions for `oxTrust` , `oxAuth`, `oxPassport`, and `oxShibboleth` must be changed from `type : ClusterIP` to `type: NodePort`. ![CDNJS](https://img.shields.io/badge/ALB--red.svg)

### Example: Changing service type for oxAuth 

Before:

		apiVersion: v1
		kind: Service
		metadata:
		  name: oxauth
		  labels:
			app: oxauth
		spec:
		  ports:
		  - port: 8080
			name: oxauth
		  selector:
			app: oxauth
After:

		apiVersion: v1
		kind: Service
		metadata:
		  name: oxauth
		  labels:
			app: oxauth
		spec:
		  ports:
		  - port: 8080
			name: oxauth
			protocol: TCP
			targetPort: 8080
			nodePort: 30100 <--- This number must be different for each service
		  selector:
			app: oxauth
		  type: NodePort
		  
- It is highly recommended to assign a DNS stable name to your loadbalancer. Ignoring this note espicially when moving with `NLB` or `ALB` might hinder your deployment.  ![CDNJS](https://img.shields.io/badge/ALB--red.svg) ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

- Remove all occurences of `hostAliases` : ![CDNJS](https://img.shields.io/badge/ALB--red.svg)

        hostAliases:
        - ip: NGINX_IP
          hostnames:
          - demoexample.gluu.org
  
  This also applies to `CLB` and `NLB` if a DNS name is clearly assigned. ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)
  
# How-to

1. [How to expand EBS volumes](#how-to-expand-ebs-volumes)

## Deploying Containers with volumes on host

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

### OpenDJ
 
1.  Go to `ldap` directory:

        cd ../ldap
		
1.  Prepare volumes for ldap:


        kubectl apply -f opendj-volumes.yaml


1.  Create constraints to assign container to specific nodes:

        kubectl get node


1. Pick one of the nodes, get the name, and attach a label to the node:


        kubectl label node NODE_NAME opendj-init=true


1.  Pick other nodes and attach a label for each node:

        kubectl label node NODE_NAME opendj-init=false


1.  Deploy OpenDJ pod that generates initial data:

        kubectl apply -f opendj-init.yaml

    Please wait until pod is completed. Check the logs using `kubectl logs -f POD_NAME`


1.  Deploy additional OpenDJ pod:

        kubectl apply -f opendj-repl.yaml


### ALB Ingress ![CDNJS](https://img.shields.io/badge/ALB--red.svg)

        cd ../alb-ingress
		kubectl apply -f ingress.yaml


### Nginx Ingress ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

1.  To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller. ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        cd ../nginx
        kubectl apply -f mandatory.yaml
        kubectl apply -f cloud-generic.yaml
		
    To allow external traffic to the cluster, we need to deploy nginx Ingress and its controller but for NLB we must add an annotation `service.beta.kubernetes.io/aws-load-balancer-type: nlb` along with other annotations for using the right certificate when deploying nginx. These annotaions are added to the `cloud-generic.yaml`. ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)
        
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
		  ...
		  ...
		  
        kubectl apply -f mandatory.yaml
        kubectl apply -f cloud-generic.yaml
		
1.  The commands above will deploy a `LoadBalancer` service in the `ingress-nginx` namespace. Run `kubectl get svc -n ingress-nginx`: ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP                                                        PORT(S)                      AGE
        ingress-nginx          LoadBalancer   10.11.254.183   a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com              80:30306/TCP,443:30247/TCP   50s

1.  Create secrets to store TLS cert and key: ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        sh tls-secrets.sh
		
	An option to generate an ACM certificate and load it in nginx is available. This would require to insert the `.crt` and `key` in the `tls-certificate` secret

1.  Adjust all references to the hostname `demoexample.gluu.org` in `nginx.yaml` to the hostname you applied earlier while generating the configuration. Afterwards deploy the custom Ingress for Gluu Server routes. ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)
		
        kubectl apply -f nginx.yaml
    
    You can see the host and IP after with `kubectl get ing`

### Update scripts folder

> **_Warning:_**  If you are deploying in production please assign a CNAME record for the LoadBalancer DNS name, or use Amazon Route 53 to create a hosted  and do not use the following script. However, the following files need to be modified `oxauth.yaml`, `oxpassport.yaml`, `oxshibboleth.yaml`, and `oxtrust.yaml` to comment out the `updateclbip` as following : ![CDNJS](https://img.shields.io/badge/ALB--red.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)
       
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

1.  Create configmap for the update clb ip script. ![CDNJS](https://img.shields.io/badge/CLB--green.svg)
        
        cd ../update-clb-ip
        
        kubectl create -f update-clb-configmap.yaml

### oxAuth

1. Get the current IP of the load balancer ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to the `oxauth` directory:

        cd ../oxauth

1.  Prepare volumes for oxAuth:
        kubectl apply -f oxauth-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com` ![CDNJS](https://img.shields.io/badge/CLB--green.svg)

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `demoexample.gluu.org`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "demoexample.gluu.org"

1.  Adjust the hostname from `demoexample.gluu.org` in `oxauth.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxauth`.

    ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)
	
        NGINX_IP=35.240.221.38 sh deploy-pod.sh 
	
	![CDNJS](https://img.shields.io/badge/ALB--red.svg)
	
		kubectl apply -f oxauth.yaml 
		

### Shared Shibboleth IDP Files

As oxTrust and oxShibboleth shares Shibboleth configuration files, we need to have volumes that shared across all nodes in the cluster.

1.  Go to `shared-shib` directory: ![CDNJS](https://img.shields.io/badge/CLB--green.svg)

        cd ../shared-shib

1.  Prepare volumes for shared Shibboleth files:

        kubectl apply -f shared-shib-volumes.yaml

### oxTrust

1. Get the current ip of the load balancer ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Go to `oxtrust` directory:

        cd ../oxtrust

1.  Prepare volumes for oxTrust: 

        kubectl apply -f oxtrust-volumes.yaml

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com` ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `demoexample.gluu.org`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "demoexample.gluu.org"

1.  Adjust the hostname from `demoexample.gluu.org` in `oxtrust.yaml` to the hostname you applied earlier while generating the configuration and deploy `oxtrust`.

    ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        NGINX_IP=35.240.221.38 sh deploy-pod.sh 
		
	![CDNJS](https://img.shields.io/badge/ALB--red.svg)
	
		kubectl apply -f oxauth.yaml 

### oxShibboleth


1.  Get the current ip of the load balancer ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)


        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com` ![CDNJS](https://img.shields.io/badge/CLB--green.svg)

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `demoexample.gluu.org`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "demoexample.gluu.org"

1.  Adjust the hostname from `demoexample.gluu.org` in `oxshibboleth.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxShibboleth pod:

        cd ../oxshibboleth

    ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        NGINX_IP=35.240.221.38 sh deploy-pod.sh 
		
	![CDNJS](https://img.shields.io/badge/ALB--red.svg)
	
		kubectl apply -f oxauth.yaml 

### oxPassport


1.  Get the current ip of the load balancer ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        nslookup a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com

        Name : a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com
        Address : 35.240.221.38

1.  Modify the env  entry `LB_ADDR` to your LB address which in our case is `a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com` ![CDNJS](https://img.shields.io/badge/CLB--green.svg)

1.  Modify the env `DOMAIN` to the domain you chose at installation which in our case is `demoexample.gluu.org`

        LB_ADDR: "a73fkddo22203aom22-899102.eu-west-1.elb.amazonaws.com"
        DOMAIN: "demoexample.gluu.org"

1.  Adjust the hostname from `demoexample.gluu.org` in `oxpassport.yaml` to the hostname you applied earlier while generating the configuration. Deploy oxPassport pod:

        cd ../oxpassport
		
    ![CDNJS](https://img.shields.io/badge/CLB--green.svg) ![CDNJS](https://img.shields.io/badge/NLB--orange.svg)

        NGINX_IP=35.240.221.38 sh deploy-pod.sh 
		
	![CDNJS](https://img.shields.io/badge/ALB--red.svg)
	
		kubectl apply -f oxauth.yaml 
		
        

1.  Enable Passport support by following the official docs [here](https://gluu.org/docs/ce/authn-guide/passport/#setup-passportjs-with-gluu).

### key-rotation

Deploy key-rotation pod:

    cd ../key-rotation
    kubectl apply -f key-rotation.yaml

### cr-rotate

Deploy cr-rotate pod:

    cd ../cr-rotate
    kubectl apply -f cr-rotate-roles.yaml
    kubectl apply -f cr-rotate.yaml

## How to expand EBS volumes

1. Make sure the `StorageClass` used in your deployment has the `allowVolumeExpansion` set to true. If you have used our EBS volume deployment strategy then you will find that this property has already been set for you.

1. Edit your persistent volume claim using `kubectl edit pvc <claim-name> -n <namespace> ` and increase the value found for `storage:` to the value needed. Make sure the volumes expand by checking the `kubectl get pvc <claim-name> -n <namespace> `.

1. Restart the associated services
