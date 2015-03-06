RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)

.PHONY: run

build:
	@docker build -t $(RUN_ARGS) $(RUN_ARGS)

run:
	@docker run -e SALT_MASTER_IPADDR=${SALT_MASTER_IPADDR} -it $(RUN_ARGS)

main:
	@docker run -it saltminion /usr/bin/docker-entrypoint.sh
