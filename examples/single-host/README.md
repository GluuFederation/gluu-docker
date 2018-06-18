# Gluu Server Docker Edition Single-host Setup

This id an example of running Gluu Server Docker edition on a single VM.

#### Requirements:

1) Follow the [Docker installation instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository) or use the [convenience installation script](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-convenience-script)

1) [Docker-compose](https://docs.docker.com/compose/install/#install-compose)

1) `run_all.sh` setup file and docker-compose.yaml

        mkdir docker-gluu-server
        cd docker-gluu-server
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/master/examples/single-host/run_all.sh
        wget https://raw.githubusercontent.com/GluuFederation/gluu-docker/master/examples/single-host/docker-compose.yml
        chmod +x run_all.sh

Run the following command inside the `/path/to/docker-gluu-server/` directory and follow the prompts:

```
./run_all.sh
```

The startup process takes roughly 5-10 minutes depending. The longest is usually OpenDJ. You can keep track of that process by using the following command:

```
docker logs -f ldap
```

The same for all the other services after as well.

FAQ:

1) What network is Gluu Server Docker Edition running on?

    In this script, it launches consul using the `docker-compose up consul` command, where docker-compose creates a custom bridge network, based on the name of your current directory. So, for example, the network would be named `dockergluuserver_bridge`. You can assign a custom network in the `docker-compose.yaml`. Please see [the Docker-compose official documentation](https://docs.docker.com/compose/networking/#specify-custom-networks) for further understanding.

    All other containers in the docker-compose file are connected to that same network as well. The only container not included in the `docker-compose.yaml` file is the `config-init`. We left them disconnected as it must finish loading the necessary configuration files into consul before any other container can launch. As can be seen in the following `docker run` command, it connects to the same network as consul with the `--network container:consul` option.

        docker run --rm \
            --network container:consul \
            gluufederation/config-init:latest \
            generate \
            --kv-host "${GLUU_KV_HOST}" \
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

    Secondly, [config-init](https://github.com/GluuFederation/docker-config-init/tree/3.1.3), which will load all of the necessary keys, configuration settings, templates and other requirements, into consul. This container will run to completion and then exit and remove itself. All services hereinafter will use consul to pull their necessary configuration.

    Next is our OpenDJ container. OpenDJ will install and configure itself inside the container as well as create volumes inside of the current directory as `/volumes/` for necessary persistent data, like db, schema, etc..

    After that oxAuth, NGINX, then oxTrust, which relies on the `/.well-known/openid-configuration/` to properly set it's own configuration. These containers can be restarted at any time from that point on.

    Currently all of the images, with the exception of the `consul` and `registrator` containers, have wait-for-it scripts designed to prevent them from trying to start, before the necessary launch procedure is accomplished. This mitigates failure during the build process.

## Documentation

Please refer to the [Gluu Server Docker Edition Documentation](https://gluu.org/docs/ce/3.1.3/docker/intro/) for further reading on Docker image implementations.
