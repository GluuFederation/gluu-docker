RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)

.PHONY: run

build:
	@docker build -t $(RUN_ARGS) $(RUN_ARGS)

run:
	@docker run -e DOCKER_SOCKET=${DOCKER_SOCKET} -e SALT_MASTER_IPADDR=${SALT_MASTER_IPADDR} -it $(RUN_ARGS)

run-privileged:
	@docker run --privileged -e DOCKER_SOCKET=${DOCKER_SOCKET} -e SALT_MASTER_IPADDR=${SALT_MASTER_IPADDR} -it $(RUN_ARGS)

main:
	@docker run -it saltminion

exec:
	@docker exec -it `docker ps -q -n 1` bash
