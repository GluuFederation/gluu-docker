RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)

.PHONY: run

build:
	@docker build -t $(RUN_ARGS) $(RUN_ARGS)

run:
	@docker run -it $(RUN_ARGS)

main:
	@docker run -it saltminion /usr/bin/docker-entrypoint.sh
