# Multi-host Deployment using Docker Swarm ![CDNJS](https://img.shields.io/badge/UNDERCONSTRUCTION-red.svg?style=for-the-badge)

This is an example of how to deploy Gluu Server Docker Edition on multi-host setup.

For futher reading, please see the [Gluu Server Docker Edition Documentation](https://gluu.org/docs/de/4.0.0).

## Requirements

-   [Docker](https://docs.docker.com/install/)

-   [Docker Machine](https://docs.docker.com/machine/install-machine/)

-   [DigitalOcean access token](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2)

-   Get the source code:

        wget -q https://github.com/GluuFederation/gluu-docker/archive/4.0.0.zip
        unzip 4.0.0.zip
        cd gluu-docker-4.0.0/examples/multi-hosts/

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
