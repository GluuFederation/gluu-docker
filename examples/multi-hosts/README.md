# Multi-hosts Deployment using Docker Swarm

This is an example on how to deploy Gluu Server Docker Edition on multi-hosts setup.

## Pre-requisites

- [Docker](https://docs.docker.com/install/)
- [Docker Machine](https://docs.docker.com/machine/install-machine/)
- [Virtualbox](https://www.virtualbox.org/wiki/Downloads); required only if nodes are provisioned using VirtualBox VM
- [DigitalOcean access token](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2); required only if nodes are provisioned using DigitalOcean droplet

## Provisioning Cluster Nodes

Nodes are divided into 2 roles:

- manager
- worker

These nodes are created/destroyed using `docker-machine`.
Nodes can be placed inside VirtualBox VM or DigitalOcean droplet.

Refer to https://docs.docker.com/engine/swarm/key-concepts/#nodes for an overview of each role.

### Setup Nodes

To setup nodes, execute the command below:

    ./nodes.sh up $driver

where `$driver` value can be `virtualbox` or `digitalocean`.
__Note__, for `digitalocean` driver, we need to create a file contains DigitalOcean access token:

    echo $DO_TOKEN > $PWD/volumes/digital-access-token

To setup nodes in `virtualbox` VM:

    ./nodes.sh up virtualbox

For `digitalocean` droplet:

    ./nodes.sh up digitalocean

This command will create `manager-1` and `worker-1` nodes and setup the Swarm cluster.

Wait until all processes completed, and then we can execute this command to check nodes status:

    docker-machine ssh manager-1 'docker node ls'

which will return output similar to example below:

    ID                          HOSTNAME    STATUS  AVAILABILITY    MANAGER STATUS  ENGINE VERSION
    hylmq7086sr1oxmac6k8mjtcr * manager-1   Ready   Active          Leader          18.03.0-ce
    hdvgmuvwm9z5p4u4740ichd77   worker-1    Ready   Active                          18.03.0-ce

After Swarm cluster created, we also create a custom network called `gluu`. To inspect the network, run the following command:

    docker-machine ssh manager-1 'docker network inspect gluu'

which will return the information of the network:

    [
        {
            "Name": "gluu",
            "Id": "j6gt3o0jrgyk5b10h1hf4gxh8",
            "Created": "2018-04-05T18:30:22.47872588Z",
            "Scope": "swarm",
            "Driver": "overlay",
            "EnableIPv6": false,
            "IPAM": {
                "Driver": "default",
                "Options": null,
                "Config": []
            },
            "Internal": false,
            "Attachable": true,
            "Ingress": false,
            "ConfigFrom": {
                "Network": ""
            },
            "ConfigOnly": false,
            "Containers": null,
            "Options": {
                "com.docker.network.driver.overlay.vxlanid_list": "4097"
            },
            "Labels": null
        }
    ]

The `gluu` network has `attachable` option set to `true`.
It means any container deployed outside the Swarm cluster can be _attached_ to `gluu` network.
For example, running `docker run --rm --network=gluu gluufederation/config-init`
will enable this container to talk to other containers within `gluu` network.

### Teardown Nodes

To destroy nodes, simply execute command below (regardless of nodes driver):

    ./nodes.sh down

This will prompt user to destroy each node.

## Deploying Services

Basically, a service can be seen as tasks definition that executed on manager or worker node.
A service manages a specific image tasks (create/destroy/scale/etc).

Refer to https://docs.docker.com/engine/swarm/key-concepts/#services-and-tasks for an overview of Swarm service.

In this example, the following services are used to deploy Gluu stack:

- Consul for storing cluster-wide configuration
- Redis for cache storage (required for oxAuth session)
- OpenDJ for LDAP storage
- Traefik for oxAuth and oxTrust proxy
- oxAuth, the OpenID Connect Provider (OP) & UMA Authorization Server (AS)
- oxTrust for managing authentication, authorization and users
- NGINX for public-facing web app

### 1 - Deploying Consul

Consul service divided into 2 parts to achieve HA/cluster setup:

- `consul_server` deployed to `manager-1` node
- `consul_agent` deployed to `worker-1` node

Ideally at least 3 nodes are needed, but for example 2 instances of Consul are sufficient.

To deploy the service:

    # connect to remote docker engine in manager-1 node
    eval $(docker-machine env manager-1)

    docker stack deploy -c consul.yml gluu

    # disconnect from remote docker engine in manager-1 node
    eval $(docker-machine env -u)

Once the processes completed, we need to check whether a `consul` leader has been established or not, using this command:

    docker-machine ssh manager-1 'curl -s 0.0.0.0:8500/v1/status/leader'

If the command returns host and port of consul server, we're safe to proceed to next service.

### 2 - Prepare cluster-wide configuration

Cluster-wide configuration are saved into Consul KV storage. All Gluu containers pull these config to self-configure themselves.

Run the following command to prepare the configuration:

    ./config.sh

If there's no configuration saved in Consul KV, the script will ask user whether to import configuration from backup file or generating new ones
(we only need to input required parameters and the configuration will be generated, saved to Consul, and export them to local file for backup purpose).

__NOTE__: this process may take some time, please wait until the process completed.

### 3 - Deploy Cache Storage

For Gluu cluster with multiple oxAuth instances, we need a cache storage as a single place to read and write sessions.
In this case, we're using Redis.

Run the following command to deploy cache service:

    eval $(docker-machine env manager-1)
    docker stack deploy -c cache.yml gluu
    eval $(docker-machine env -u)

### 4 - Deploy LDAP

LDAP services are divided into 2 roles:

1.  LDAP that has initial data.

    Run this command to deploy the service:

        eval $(docker-machine env manager-1)
        docker stack deploy -c ldap-init.yml gluu
        eval $(docker-machine env -u)

    The process of initializing data will take some time.

2.  LDAP that has no initial data (data will be replicated from existing LDAP if any)

    Before deploying this service (and other services that need to run after LDAP is ready),
    we need to check if existing LDAP server in `manager-1` node has been fully ready:

        docker-machine ssh manager-1 'docker logs $(docker ps --filter name=gluu_ldap_init -q) 2>&1' | grep 'The Directory Server has started successfully'

    If we see the output similar to this one:

        [05/Apr/2018:19:59:27 +0000] category=CORE severity=NOTICE msgID=org.opends.messages.core.135 msg=The Directory Server has started successfully

    then we can proceed to deploy the next LDAP service:

        eval $(docker-machine env manager-1)
        docker stack deploy -c ldap-peer.yml gluu
        eval $(docker-machine env -u)

    The process will also take some time, but it's safe to proceed to deploy next services.

### 5 - Deploy Proxy for oxAuth and oxTrust

TBA

### 6 - Deploy oxAuth and oxTrust

TBA

### 7 - Deploy nginx

TBA
