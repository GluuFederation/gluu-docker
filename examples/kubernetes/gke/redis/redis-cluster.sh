lookup_redis() {
    kubectl get endpoints redis -o json | python -c 'import sys, json; data = json.loads(sys.stdin.read())["subsets"][0]["addresses"]; endpoints = [item["ip"] for item in data]; print " ".join(endpoints)'
}

get_cluster_url() {
    kubectl get endpoints redis -o json | python -c 'import sys, json; data = json.loads(sys.stdin.read())["subsets"][0]["addresses"]; endpoints = ["{}:6379".format(item["ip"]) for item in data]; print ",".join(endpoints)'
}

create_cluster() {
    ip_list=$(lookup_redis)
    if [ ! -z "$ip_list" ]; then
        # if IP list is not empty, format them as white-space separated value in 'host:port' format,
        # for example `10.0.0.2:6379 10.0.0.3:6379`, to conform to redis-trib command
        REDIS_CLUSTER=$(echo $ip_list | python -c "import sys; print ' '.join(['{}:6379'.format(l) for l in sys.stdin.read().split()])")

        if [ ! -z "$REDIS_CLUSTER" ]; then
            # run a container with tty in order to allow typing 'yes' when prompted
            kubectl run redis-trib \
                --image=iromli/redis-trib:latest \
                --restart=Never \
                -i \
                --tty \
                --rm \
                -- create $REDIS_CLUSTER
        fi
    fi
}

case $1 in
    "create-cluster")
        create_cluster
        ;;
    "get-cluster-url")
        get_cluster_url
        ;;
    "lookup-redis")
        lookup_redis
        ;;
esac
