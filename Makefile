.DEFAULT_GOAL:=help
# image settings for the docker image name, tags and
# container name while running
IMAGE_NAME?=gcr.io/ci-30-162810/weblogic
TAGS?=latest
NAME=ci-weblogic

# parent image name
FROM=$(shell head -n1 Dockerfile | cut -d " " -f 2)
# the first tag and the remaining tags split up
FIRST_TAG=$(firstword $(TAGS))
ADDITIONAL_TAGS=$(wordlist 2, $(words $(TAGS)), $(TAGS))
# the image name which will be build
IMAGE=$(IMAGE_NAME):$(FIRST_TAG)
# options to use for running the image, can be extended by FLAGS variable
OPTS=--name $(NAME) -t -p 7001:7001 $(FLAGS)
# the docker command which can be configured by the DOCKER_OPTS variable
DOCKER=docker $(DOCKER_OPTS)

# default build settings
REMOVE=true
FORCE_RM=true
NO_CACHE=false

.PHONY: build
build: pull-from pull build-image test ## build the image for the first tag and tag it for additional tags

.PHONY: build-image
build-image: ## build the image
	$(DOCKER) build --rm=$(REMOVE) --force-rm=$(FORCE_RM) --no-cache=$(NO_CACHE) --build-arg TAG_NAME=$(TAGS) -t $(IMAGE) .
	@for tag in $(ADDITIONAL_TAGS); do \
		$(DOCKER) tag $(FORCE_FLAG) $(IMAGE) $(IMAGE_NAME):$$tag; \
	done

.PHONY: pull
pull: ## pull image from registry
	-$(DOCKER) pull $(IMAGE)

.PHONY: pull-from
pull-from: ## pull parent image
	$(DOCKER) pull $(FROM)

.PHONY: push
push: ## push container to registry
	@for tag in $(TAGS); do \
		$(DOCKER) push $(IMAGE_NAME):$$tag; \
	done

.PHONY: publish
publish: build-image push ## pull parent image, pull image, build image and push to repository

.PHONY: run
run: ## run container
	$(DOCKER) run --rm $(OPTS) $(IMAGE)

.PHONY: daemon
daemon: ## start container as daemon
	$(DOCKER) run -d $(OPTS) $(IMAGE)

.PHONY: shell
shell: ## start interactive container with bash
	$(DOCKER) run --rm -i --entrypoint=/bin/bash $(OPTS) $(IMAGE) --

.PHONY: test
test: daemon ## test if image starts and weblogic becomes ready afterwards
	$(DOCKER) exec -t $(NAME) supervisorctl start weblogic
	sleep 30
	$(DOCKER) exec -t $(NAME) curl -vvv localhost:7001/console
	-$(DOCKER) rm -f $(NAME)

.PHONY: rmf
rmf: ## remove container by name
	-$(DOCKER) rm -f $(NAME)

.PHONY: rmi
rmi: ## remove image with all tags
	@for tag in $(TAGS); do \
		$(DOCKER) rmi $(IMAGE_NAME):$$tag; \
	done

.PHONY: help
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

