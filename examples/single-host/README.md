# Gluu Server Docker Edition Single-host Setup

This is an example of running Gluu Server Docker Edition on a single VM.

## Requirements:

1)  Follow the [Docker installation instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository) or use the [convenient installation script](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-convenience-script)

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
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/4.0.0/examples/single-host/run_all.sh
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/4.0.0/examples/single-host/docker-compose.yml
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/4.0.0/examples/single-host/docker-compose.override.yml
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/4.0.0/examples/single-host/vault_gluu_policy.hcl
        chmod +x run_all.sh

1)  Run the following command inside the `/path/to/docker-gluu-server/` directory and follow the prompts:

        ./run_all.sh

    Do not be alarmed for the `warning` alerts that may show up. Wait until  it prompts you for information or loads the previous configuration found. In the case where this is a fresh install you may see something like this :

        ./run_all.sh
        [I] Determining OS Type and Attempting to Gather External IP Address
        Host is detected as Linux
        Is this the correct external IP Address: 172.189.222.111 [Y/n]? y
        [I] Preparing cluster-wide config and secrets
        WARNING: The DOMAIN variable is not set. Defaulting to a blank string.
        WARNING: The HOST_IP variable is not set. Defaulting to a blank string.
        Pulling consul (consul:)...
        latest: Pulling from library/consul
        bdf0201b3a05: Pull complete
        af3d1f90fc60: Pull complete
        d3a756372895: Pull complete
        54efc599d7c7: Pull complete
        73d2c234fe14: Pull complete
        cbf8018e609a: Pull complete
        Digest: sha256:bce60e9bf3e5bbbb943b13b87077635iisdksdf993579d8a6d05f2ea69bccd
        Status: Downloaded newer image for consul:latest
        Creating consul ... done
        [I] Checking existing config in Consul
        [W] Unable to get config in Consul; retrying ...
        [W] Unable to get config in Consul; retrying ...
        [W] Unable to get config in Consul; retrying ...
        [W] Configuration not found in Consul
        [I] Creating new configuration, please input the following parameters
        Enter Domain:                 yourdomain
        Enter Country Code:           US
        Enter State:                  TX
        Enter City:                   Austin
        Enter Email:                  email@example.com
        Enter Organization:           Gluu Inc
        Enter Admin/LDAP Password:
        Confirm Admin/LDAP Password:
        Continue with the above settings? [Y/n]y


    The startup process may take some time. You can keep track of the deployment by using the following command:

        docker-compose logs -f

1)  On initial deployment, since Vault has not been configured yet, the `run_all.sh` will generate root token and key to interact with Vault API, saved as `vault_key_token.txt`. Secure this file as it contains recovery key and root token.

## FAQ

1) What network is Gluu Server Docker Edition running on?

    In this script, it launches consul using the `docker-compose up consul` command, where docker-compose creates a custom bridge network, based on the name of your current directory. So, for example, the network would be named `dockergluuserver_bridge`. You can assign a custom network in the `docker-compose.yaml`. Please see [the Docker-compose official documentation](https://docs.docker.com/compose/networking/#specify-custom-networks) for further understanding.

    All other containers in the docker-compose file are connected to that same network as well. The only container not included in the `docker-compose.yaml` file is the `config-init`. We left them disconnected as it must finish loading the necessary configuration files into consul before any other container can launch. As can be seen in the following `docker run` command, it connects to the same network as consul with the `--network container:consul` option.

        docker run --rm \
            --network container:consul \
            -e GLUU_CONFIG_ADAPTER=consul \
            -e GLUU_CONSUL_HOST=consul \
            gluufederation/config-init:4.0.0_dev \
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

    Secondly, [config-init](https://github.com/GluuFederation/docker-config-init/tree/4.0.0), which will load all of the necessary keys, configuration settings, templates and other requirements, into consul. This container will run to completion and then exit and remove itself. All services hereinafter will use consul to pull their necessary configuration.

    Next is our OpenDJ container. OpenDJ will install and configure itself inside the container as well as create volumes inside of the current directory as `/volumes/` for necessary persistent data, like db, schema, etc..

    After that oxAuth, NGINX, then oxTrust, which relies on the `/.well-known/openid-configuration/` to properly set it's own configuration. These containers can be restarted at any time from that point on.

    Currently all of the images, with the exception of the `consul` and `registrator` containers, have wait-for-it scripts designed to prevent them from trying to start, before the necessary launch procedure is accomplished. This mitigates failure during the build process.

## Documentation

Please refer to the [Gluu Server Docker Edition Documentation](https://gluu.org/docs/de/4.0.0) for further reading on Docker image implementations.
