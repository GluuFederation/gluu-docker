# Gluu Server Docker Edition Single-host Setup

This is an example of running Gluu Server Docker Edition on a single VM.

## Requirements:

1)  Follow the [Docker installation instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository) or use the [convenience installation script](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-convenience-script)

1)  [docker-compose](https://docs.docker.com/compose/install/#install-compose).

1)  Obtain Google Cloud Platform KMS credentials JSON file, save it as `gcp_kms_creds.json`.

1)  Create `gcp_kms_stanza.hcl`:

        seal "gcpckms" {
            credentials = "/vault/config/creds.json"
            project     = "<PROJECT_NAME>"
            region      = "<REGION_NAME>"
            key_ring    = "<KEYRING_NAME>"
            crypto_key  = "<KEY_NAME>"
        }

1)  Obtain files for deployment:

        mkdir docker-gluu-server
        cd docker-gluu-server
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/3.1.5/examples/single-host/run_all.sh
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/3.1.5/examples/single-host/docker-compose.yml
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/3.1.5/examples/single-host/vault_gluu_policy.hcl
        chmod +x run_all.sh

1)  Run the following command inside the `/path/to/docker-gluu-server/` directory and follow the prompts:

        ./run_all.sh

    The startup process may take some time. You can keep track of the deployment by using the following command:

        docker-compose logs -f

1)  On initial deployment, since Vault has not been configured yet, each service (other than Consul, Vault, and Registrator) will wait for Vault readiness.

    -   Initialize Vault:

            docker exec vault vault operator init -key-shares=1 -key-threshold=1 -recovery-shares=1 -recovery-threshold=1 > vault_key_token.txt

        The output of this command is redirected to a file `vault_key_token.txt`. Secure this file as it contains recovery key and root token.

    -   Login to Vault using root token:

            docker exec -ti vault vault login -no-print

        A prompt will appear to enter the root token.

    -   Write policy to access Vault's secrets:

            docker exec vault vault policy write gluu /vault/config/policy.hcl

    -   Enable Vault AppRole for containers:

            docker exec vault vault auth enable approle
            docker exec vault vault write auth/approle/role/gluu policies=gluu
            docker exec vault vault write auth/approle/role/gluu \
                secret_id_ttl=0 \
                token_num_uses=0 \
                token_ttl=20m \
                token_max_ttl=30m \
                secret_id_num_uses=0

    -   Generate RoleID and SecretID for containers:

            docker exec vault vault read -field=role_id auth/approle/role/gluu/role-id > vault_role_id.txt
            docker exec vault vault write -f -field=secret_id auth/approle/role/gluu/secret-id > vault_secret_id.txt

    Afterwards, check the logs to see the progress of deployment after Vault has been initialized and configured properly.

## FAQ

1) What network is Gluu Server Docker Edition running on?

    In this script, it launches consul using the `docker-compose up consul` command, where docker-compose creates a custom bridge network, based on the name of your current directory. So, for example, the network would be named `dockergluuserver_bridge`. You can assign a custom network in the `docker-compose.yaml`. Please see [the Docker-compose official documentation](https://docs.docker.com/compose/networking/#specify-custom-networks) for further understanding.

    All other containers in the docker-compose file are connected to that same network as well. The only container not included in the `docker-compose.yaml` file is the `config-init`. We left them disconnected as it must finish loading the necessary configuration files into consul before any other container can launch. As can be seen in the following `docker run` command, it connects to the same network as consul with the `--network container:consul` option.

        docker run --rm \
            --network container:consul \
            -e GLUU_CONFIG_ADAPTER=consul \
            -e GLUU_CONSUL_HOST=consul \
            gluufederation/config-init:3.1.5_dev \
            generate \
            --ldap-type "${GLUU_LDAP_TYPE}" \
            --domain $domain \
            --admin-pw $adminPw \
            --org-name "$orgName" \
            --email $email \
            --country-code $countryCode \
            --state $state \
            --city $city
    - Note this command is to create the initial configuration and is slightly different than the `load` or `dump` option of config-init.

1) What is the launch process for the containers?

    There are a couple containers which have to be launched first to successfully launch the dependent Gluu Server containers.

    Firstly, [consul](https://www.consul.io/), which is our key value store, as well as service discovery container.

    Secondly, [config-init](https://github.com/GluuFederation/docker-config-init/tree/3.1.5), which will load all of the necessary keys, configuration settings, templates and other requirements, into consul. This container will run to completion and then exit and remove itself. All services hereinafter will use consul to pull their necessary configuration.

    Next is our OpenDJ container. OpenDJ will install and configure itself inside the container as well as create volumes inside of the current directory as `/volumes/` for necessary persistent data, like db, schema, etc..

    After that oxAuth, NGINX, then oxTrust, which relies on the `/.well-known/openid-configuration/` to properly set it's own configuration. These containers can be restarted at any time from that point on.

    Currently all of the images, with the exception of the `consul` and `registrator` containers, have wait-for-it scripts designed to prevent them from trying to start, before the necessary launch procedure is accomplished. This mitigates failure during the build process.

## Documentation

Please refer to the [Gluu Server Docker Edition Documentation](https://gluu.org/docs/ce/3.1.5/docker/intro/) for further reading on Docker image implementations.
