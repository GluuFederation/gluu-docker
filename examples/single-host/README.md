1.  Deploy Consul container:

    ```
    docker-compose up consul
    ```

2.  Initialize cluster-wide config:

    ```
    sh init-config.sh
    ```

3.  Deploy LDAP container:

    ```
    docker-compose up ldap
    ```

4.  Deploy nginx, oxAuth, and oxTrust containers:

    ```
    HOST_IP=$(ip route get 1 | awk '{print $NF;exit}') docker-compose nginx oxauth oxtrust
    ```
