# Multi-hosts Deployment using Docker Swarm

This is an example on how to deploy Gluu Server Docker Edition on multi-hosts setup.

## Pre-requisites

- [Docker](https://docs.docker.com/install/)
- [Docker Machine](https://docs.docker.com/machine/install-machine/)
- [Virtualbox](https://www.virtualbox.org/wiki/Downloads); required only if nodes are provisioned using VirtualBox VM
- [DigitalOcean access token](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2); required only if nodes are provisioned using DigitalOcean droplet

## Provisioning Cluster Nodes

Nodes are divided into 2 roles, __manager__ and __worker__.
These nodes are created/destroyed using `docker-machine`.
Nodes can be placed inside VirtualBox VM or DigitalOcean droplet.

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

This command will create `manager-1` and `worker-1` nodes and setup the swarm cluster (including its custom network called `gluu`).

Wait until all processes completed, and then we can execute this command to check nodes status:

    docker-machine ssh manager-1 'docker node ls'

and `gluu` custom network:

    docker-machine ssh manager-1 'docker network inspect gluu'

Here's an example of successful nodes creation:

```
ID                          HOSTNAME    STATUS  AVAILABILITY    MANAGER STATUS  ENGINE VERSION
hylmq7086sr1oxmac6k8mjtcr * manager-1   Ready   Active          Leader          18.03.0-ce
hdvgmuvwm9z5p4u4740ichd77   worker-1    Ready   Active                          18.03.0-ce
```

### Teardown Nodes

To destroy nodes, simply execute command below (regardless of nodes driver):

    ./nodes.sh down

This will prompt user to destroy the each node.


## Deploying Services

### 1 - Deploying Consul

Consul service divided into 2 parts to achieve HA/cluster setup:

- `consul_server` deployed to `manager-1` node
- `consul_agent` deployed to `worker-1` node

Ideally at least 3 nodes are needed, but for example 2 instances of Consul are sufficient.

To deploy the service:

    eval $(docker-machine env manager-1)
    docker stack deploy -c consul.yml gluu
    eval $(docker-machine env -u)

Once the processes completed, we need to check whether a `consul` leader has been established or not, using this command:

    docker-machine ssh manager-1 'curl 0.0.0.0:8500/v1/status/leader'

If the command returns host and port of consul server, we're safe to proceed to next service.

### 2 - Prepare cluster-wide configuration

### 3 - Deploy Cache Storage

### 4 - Deploy LDAP

### 5 - Deploy Proxy for oxAuth and oxTrust

### 6 - Deploy oxAuth and oxTrust

### 7 - Deploy nginx
