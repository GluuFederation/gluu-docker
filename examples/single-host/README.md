1.  Deploy Consul container:

    ```
    docker-compose up consul
    ```

2.  Initialize cluster-wide config:

    ```
    sh init-config.sh
    ```

    This will prompts for various config.

3.  Deploy LDAP container:

    ```
    docker-compose up ldap
    ```

4.  Deploy nginx, oxAuth, and oxTrust containers:

    ```
    DOMAIN=<hostname-used-in-step2> HOST_IP=<host-ip-addr> docker-compose up nginx oxauth oxtrust
    ```
