# Multi-host Deployment using Docker Swarm

This is an example of how to deploy Gluu Server Docker Edition on multi-host setup.

For futher reading, please see the [Gluu Server Docker Edition Documentation](https://gluu.org/docs/de/3.1.6).

Are you using **Openstack** take a look at [these](https://github.com/GluuFederation/enterprise-edition/blob/4.0.0/examples/multi-hosts/README.md#notes-on-deploying-multi-hosts-gluu-example-on-openstack) notes before moving forward.

## Requirements

-   [Docker](https://docs.docker.com/install/)

-   [Docker Machine](https://docs.docker.com/machine/install-machine/)

-   [DigitalOcean access token](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2)

-   Get the source code:

        wget -q https://github.com/GluuFederation/gluu-docker/archive/3.1.6.zip
        unzip 3.1.6.zip
        cd gluu-docker-3.1.6/examples/multi-hosts/

## Provisioning Cluster Nodes

Nodes are divided into two roles:

- Swarm manager, consists of `manager` node
- Swarm worker, consists of `worker-1` and `worker-2` node

These nodes are created/destroyed using `docker-machine` and are deployed as DigitalOcean droplets.

Refer to https://docs.docker.com/engine/swarm/key-concepts/#nodes for an overview of each role.

### Set Up Nodes

We need to create a file containing DigitalOcean access token:

    echo $DO_TOKEN > digitalocean-access-token

To set up nodes, execute the command below:

    ./nodes.sh up

This command will create `manager`, `worker-1`, and `worker-2` nodes and set up the Swarm cluster.

Wait until all processes are completed, and then we can execute this command to check nodes status:

    docker-machine ssh manager 'docker node ls'

This will return an output similar to the example below:

    ID                          HOSTNAME    STATUS  AVAILABILITY    MANAGER STATUS  ENGINE VERSION
    hylmq7086sr1oxmac6k8mjtcr * manager     Ready   Active          Leader          18.03.0-ce
    hdvgmuvwm9z5p4u4740ichd77   worker-1    Ready   Active                          18.03.0-ce
    hdvgmuvwm9z5p4u4740ichd88   worker-2    Ready   Active                          18.03.0-ce

After the Swarm cluster is created, we also create a custom network called `gluu`. To inspect the network, run the following command:

    docker-machine ssh manager 'docker network inspect gluu'

This will return the network information:

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
            "Attachable": false,
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

### Tear Down Nodes

To destroy nodes, simply execute the command below (regardless of the nodes driver):

    ./nodes.sh down

This will prompt the user to destroy each node.

## Deploying Services

Basically, a service can be seen as tasks executed on a manager or worker node.
A service manages specific image tasks (such as create/destroy/scale/etc).

Refer to https://docs.docker.com/engine/swarm/key-concepts/#services-and-tasks for an overview of Swarm service.

In this example, the following services/containers are used to deploy the Gluu stack:

- Consul service
- Vault service
- Registrator service
- config-init container
- OpenDJ container
- oxAuth service
- oxTrust service
- oxShibboleth service
- oxPassport service
- NGINX service

### 1 - Deploying Consul

To deploy the service:

    # connect to remote docker engine in manager node
    eval $(docker-machine env manager)
    docker stack deploy -c consul.yml gluu

### 2 - Deploying Vault

The following files are required for Vault auto-unseal process using GCP KMS service:

- `gcp_kms_creds.json`
- `gcp_kms_stanza.hcl`

Obtain Google Cloud Platform KMS credentials JSON file, save it as `gcp_kms_creds.json`. Save the content as Docker secret.

    docker secret create gcp_kms_creds gcp_kms_creds.json

Create `gcp_kms_stanza.hcl`:

    seal "gcpckms" {
        credentials = "/vault/config/creds.json"
        project     = "<PROJECT_NAME>"
        region      = "<REGION_NAME>"
        key_ring    = "<KEYRING_NAME>"
        crypto_key  = "<KEY_NAME>"
    }

Make sure to adjust the values above, then save the content as Docker secret.

    docker secret create gcp_kms_stanza gcp_kms_stanza.hcl

Create Docker config for custom Vault policy:

    docker config create vault_gluu_policy vault_gluu_policy.hcl

To deploy the service:

    docker stack deploy -c vault.yml gluu

Vault must be initialized (once) and configured to allow containers accessing the secrets:

    export VAULT_MANAGER=$(docker ps --filter name=vault --format '{{.Names}}')

    # the output is redirected to a file; securet this file as it contains recovery key and root token
    docker exec $VAULT_MANAGER vault operator init \
        -key-shares=1 \
        -key-threshold=1 \
        -recovery-shares=1 \
        -recovery-threshold=1 > vault_key_token.txt

    # when prompted for token, enter the root token from file above
    docker exec -ti $VAULT_MANAGER vault login -no-print

    # custom policy
    docker exec $VAULT_MANAGER vault policy write gluu /vault/config/policy.hcl

    # enable approle
    docker exec $VAULT_MANAGER vault auth enable approle
    docker exec $VAULT_MANAGER vault write auth/approle/role/gluu policies=gluu
    docker exec $VAULT_MANAGER vault write auth/approle/role/gluu \
        secret_id_ttl=0 \
        token_num_uses=0 \
        token_ttl=20m \
        token_max_ttl=30m \
        secret_id_num_uses=0

    # generate RoleID
    docker exec $VAULT_MANAGER vault read -field=role_id auth/approle/role/gluu/role-id > vault_role_id.txt
    docker secret create vault_role_id vault_role_id.txt

    # generate SecretID
    docker exec $VAULT_MANAGER vault write -f -field=secret_id auth/approle/role/gluu/secret-id > vault_secret_id.txt
    docker secret create vault_secret_id vault_secret_id.txt

    # re-establish Vault cluster by restarting all Vault containers
    docker service update --force gluu_vault

### 3 - Prepare cluster-wide config and secret

Cluster-wide config are saved into Consul KV storage and secrets are saved into Vault. All Gluu containers pull these to self-configure themselves.

Run the following command to prepare the config and secrets:

    ./config.sh

**NOTE:** this process may take some time, please wait until the process completed.

### 4 - Deploy Cache Storage (OPTIONAL)

By default, the cache storage is set to `NATIVE_PERSISTENCE`. To use `REDIS`, deploy the service first:

    docker stack deploy -c redis.yml gluu

Make sure to change `ldap-manager.yml` file:

```
services:
  ldap_manager:
    environment:
      - GLUU_CACHE_TYPE=REDIS  # don't forget to enable redis service
      - GLUU_REDIS_URL=redis:6379
      - GLUU_REDIS_TYPE=STANDALONE
```

### 5 - Deploy LDAP

LDAP containers are divided into two roles:

1.  LDAP that has initial data

        docker stack deploy -c ldap-manager.yml gluu

    The process of initializing data will take some time.

2.  LDAP that has no initial data (data will be replicated from existing LDAP if any)

    Before deploying this service (and other services that need to run after LDAP is ready),
    we need to check if existing LDAP server in `manager` node has been fully ready:

        docker-machine ssh manager 'docker logs $(docker ps --filter name=gluu_ldap_init -q) 2>&1' | grep 'The Directory Server has started successfully'

    If we see the output similar to this one:

        [05/Apr/2018:19:59:27 +0000] category=CORE severity=NOTICE msgID=org.opends.messages.core.135 msg=The Directory Server has started successfully

    then we can proceed to deploy the next LDAP container:

        docker stack deploy -c ldap-worker-1.yml gluu

    The process will also take some time, but it's safe to proceed to deploy next services/containers.

    Repeat for third LDAP server by running this command:

        docker stack deploy -c ldap-worker-2.yml gluu

__NOTE__: OpenDJ containers are not deployed as service tasks because each of these containers requires a reachable unique address for establishing replication.
Due to how the Docker service works, there's no guarantee that the address will still be unique after restart, hence OpenDJ containers are deployed via a plain `docker run` command.

### 6 - Deploy Registrator

[Registrator](https://gliderlabs.com/registrator/) acts a service registry bridge to watch oxAuth/oxTrust/oxShibboleth/oxPassport container events. The event will be watched and data will be saved into Consul.
This is needed because the NGINX container needs to reconfigure its config whenever those containers are added or removed into/from the cluster.

Run the following command to deploy `registrator` service:

    docker stack deploy -c registrator.yml gluu

### 7 - Deploy oxAuth, oxTrust, oxShibboleth, and NGINX

Run the following commands to deploy oxAuth, oxTrust, oxShibboleth, and NGINX:

    # $DOMAIN is the domain value that's entered when running `./config.sh`
    DOMAIN=$DOMAIN docker stack deploy -c web.yml gluu

### 8 - Enabling oxPassport

Enable Passport support by following the official docs [here](https://gluu.org/docs/ce/authn-guide/passport/#setup-passportjs-with-gluu).

### 9 - Enabling key-rotation and cr-rotate (OPTIONAL)

To enable key rotation for oxAuth keys (useful when we have RP) and cr-rotate (to monitor cycled IP address of oxTrust container used for cache refresh), run the following command:

    docker stack deploy -c utils.yml gluu

# Notes on deploying multi-hosts gluu example on openstack

**By using this software you are automatically acknowledging that use of Gluu Server Enterprise Edition is subject to the Gluu Support License**

1) Ignore [Set up nodes](#set-up-nodes) and [Requirments](#requirements) section.

1) **Docker machine will not be used**

1) **Ignore using `./node.sh` for deploying**

1) Provision three VMs with at least 8GB RAM each with OS flavor of your choosing that being ubuntu 18, CentOS7 ...etc

1) Make sure the ports associated with installation are open. Including docker swarm ports. In CentOS that might mean adding the allowed VMs and their respective ports.

    ```bash
        iptables -N GLUU
        iptables -A GLUU -s 104.130.198.53 -j ACCEPT  # VM docker-swarm-node-1
        iptables -A GLUU -s 104.130.217.164 -j ACCEPT # VM docker-swarm node-2
        iptables -A GLUU -s 104.130.217.190 -j ACCEPT # VM docker-swarm-node-3
        # SWARM PORTS
        iptables -I INPUT -p tcp --dport 2376 -j GLUU
        iptables -I INPUT -p tcp --dport 2377 -j GLUU
        iptables -I INPUT -p tcp --dport 7946 -j GLUU
        iptables -I INPUT -p udp --dport 7946 -j GLUU
        iptables -I INPUT -p udp --dport 4789 -j GLUU
        # SSL PORT
         iptables -I INPUT -p tcp --dport 443 -j GLUU
         #or 
         iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT 
        ####
        iptables -A GLUU -j LOG --log-prefix "unauth-swarm-access"
   ```
   
1) Please note that networking is **key** for a successful installation. Before initializing the setup make sure your nodes can reach each other on the ports used for gluu i.e **attach the security policies that allow inner communications between the nodes**.

1) Install latest [Docker](https://docs.docker.com/install/) on each VM.

1) Initialize Docker swarm mode for your first VM here that would be `Node-1`

    ```bash
    
        docker swarm init --advertise-addr <ip-for-node-1>
        # docker swarm init --advertise-addr 104.130.198.53
    ```
    
1) The above command will initialize Docker swarm and output a command that will be used to add workers to this manager node.

    ```bash
    
        To add a worker to this swarm, run the following command:

        docker swarm join \
        --token SWMTKN-1-3pu6hszjassdfsdfknkj234u2938u4jksdfnl-1awxwuwd3z9j1z3puu7rcgdbx \
        104.130.198.53:2377
        
    ```
    
1) Execute the output command on the other nodes here `Node-2` and `Node-3`.

    ```bash
    
        docker swarm join \
        --token SWMTKN-1-3pu6hszjassdfsdfknkj234u2938u4jksdfnl-1awxwuwd3z9j1z3puu7rcgdbx \
        104.130.198.53:2377
        
    ```
    
1) **Optional** If you want all of the nodes to be managers promote them using the following command:

    ```bash
    
    docker node promote node1 node2
    
    ```
    
1) Create the network.

    ```bash
    
        docker network create -d overlay gluu
        
    ```
    
1) Create volumes for `Node-1`

    ```bash
        mkdir -p /opt/config-init/db \
        /opt/opendj/config /opt/opendj/db /opt/opendj/ldif /opt/opendj/logs /opt/opendj/backup /opt/opendj/flag \
        /opt/consul \
        /opt/vault/config /opt/vault/data /opt/vault/logs \
        /opt/shared-shibboleth-idp
    ```

1) Create volumes for `Node-2` and `Node-3`

    ```bash
    
        mkdir -p /opt/opendj/config /opt/opendj/db /opt/opendj/ldif /opt/opendj/logs /opt/opendj/backup \
            /opt/consul \
            /opt/vault/config /opt/vault/data /opt/vault/logs \
            /opt/shared-shibboleth-idp
            
    ```
   
1) Continue [deploying services](#deploying-services). But note that you will not use any `docker-machine` commands, but instead execute the commands directly on the respective node here `Node-1` is the manager.
