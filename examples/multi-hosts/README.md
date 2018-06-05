# Multi-hosts Deployment using Docker Swarm

This is an example on how to deploy Gluu Server Docker Edition on multi-hosts setup.

## Requirements

-   [Docker](https://docs.docker.com/install/)

-   [Docker Machine](https://docs.docker.com/machine/install-machine/)

-   [DigitalOcean access token](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2)

-   Get the source code:

        wget -q https://github.com/GluuFederation/gluu-docker/archive/3.1.3.zip
        unzip 3.1.3.zip
        cd gluu-docker-3.1.3/examples/multi-hosts/

## Provisioning Cluster Nodes

Nodes are divided into 2 roles:

- Swarm manager, consists of `manager` node
- Swarm worker, consists of `worker-1` and `worker-2` node

These nodes are created/destroyed using `docker-machine`.
Nodes are deployed as DigitalOcean droplets.

Refer to https://docs.docker.com/engine/swarm/key-concepts/#nodes for an overview of each role.

### Setup Nodes

__Note__, we need to create a file contains DigitalOcean access token:

    echo $DO_TOKEN > $PWD/volumes/digital-access-token

To setup nodes, execute the command below:

    ./nodes.sh up

This command will create `manager`, `worker-1`, and `worker-2` nodes and setup the Swarm cluster.

Wait until all processes completed, and then we can execute this command to check nodes status:

    docker-machine ssh manager 'docker node ls'

which will return output similar to example below:

    ID                          HOSTNAME    STATUS  AVAILABILITY    MANAGER STATUS  ENGINE VERSION
    hylmq7086sr1oxmac6k8mjtcr * manager     Ready   Active          Leader          18.03.0-ce
    hdvgmuvwm9z5p4u4740ichd77   worker-1    Ready   Active                          18.03.0-ce
    hdvgmuvwm9z5p4u4740ichd88   worker-2    Ready   Active                          18.03.0-ce

After Swarm cluster created, we also create a custom network called `gluu`. To inspect the network, run the following command:

    docker-machine ssh manager 'docker network inspect gluu'

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

In this example, the following services/containers are used to deploy Gluu stack:

- Consul service
- config-init container
- Redis as caching service
- OpenDJ container
- oxAuth service
- oxTrust service
- oxShibboleth service
- oxPassport service
- NGINX service

### 1 - Deploying Consul

Consul service divided into 2 parts to achieve HA/cluster setup:

- `consul_manager` deployed to `manager` node
- `consul_worker` deployed to `worker-1` and `worker-2` node

To deploy the service:

    # connect to remote docker engine in manager node
    eval $(docker-machine env manager)
    docker stack deploy -c consul.yml gluu

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

    docker stack deploy -c cache.yml gluu

### 4 - Deploy LDAP

LDAP containers are divided into 2 roles:

1.  LDAP that has initial data.

    Run this command to deploy the container:

        ./ldap-manager.sh

    The process of initializing data will take some time.

2.  LDAP that has no initial data (data will be replicated from existing LDAP if any)

    Before deploying this service (and other services that need to run after LDAP is ready),
    we need to check if existing LDAP server in `manager` node has been fully ready:

        docker-machine ssh manager 'docker logs $(docker ps --filter name=gluu_ldap_init -q) 2>&1' | grep 'The Directory Server has started successfully'

    If we see the output similar to this one:

        [05/Apr/2018:19:59:27 +0000] category=CORE severity=NOTICE msgID=org.opends.messages.core.135 msg=The Directory Server has started successfully

    then we can proceed to deploy the next LDAP container:

        ./ldap-worker-1.sh

    The process will also take some time, but it's safe to proceed to deploy next services/containers.

    Repeat for third LDAP server by running this command:

        ./ldap-worker-2.sh

__NOTE__: OpenDJ containers are not deployed as service task because each of these containers require a reachable unique address for establishing replication.
Due to how Docker service works, there's no guarantee that the address will still be unique after restart, hence OpenDJ containers are deployed via plain `docker run` command.

### 5 - Deploy Registrator

[Registrator](https://gliderlabs.com/registrator/) acts a service registry bridge to watch oxAuth/oxTrust/oxShibboleth/oxPassport container events. The event will be watched and data will be saved into Consul.
This is needed because nginx container need to reconfigure its config whenever those containers are added or removed into/from the cluster.

Run the following command to deploy `registrator` service:

    docker stack deploy -c registrator.yml gluu

### 6 - Deploy oxAuth, oxTrust, oxShibboleth, and nginx

Run the following commands to deploy oxAuth, oxTrust, oxShibboleth, and nginx:

    # $DOMAIN is the domain value that's entered when running `./config.sh`
    DOMAIN=$DOMAIN docker stack deploy -c web.yml gluu

### 7 - Enabling oxPassport

Enable Passport support by doing steps below:

1. Login to oxTrust GUI.
2. Click *Configuration > Organization Configuration* sidebar menu.
3. On *System Configuration* tab, make sure *Passport Support* is enabled, then click *Update* button.
4. Click *Configuration > Manage Custom Scripts* sidebar menu.
5. On *Person Authentication* tab, make sure `passport_social` script is enabled, then click the *Update* button.
6. On *UMA RPT Policies* tab, make sure `uma_rpt_policy` and `uma_client_authz_rpt_policy` scripts are enabled, then click the *Update* button.

Afterwards, run the following commands to deploy restart oxPassport:

    # this will force gluu_oxpassport to reload all of its containers
    # in order to load strategies properly
    docker service update --force gluu_oxpassport

    # disconnect from remote docker engine in manager node
    eval $(docker-machine env -u)
