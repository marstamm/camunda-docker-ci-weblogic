# image settings for the docker image name, tags and
# container name while running
WLS_VERSION=12R2
IMAGE_NAME=registry.camunda.com/camunda-ci-weblogic

# parent image name
PARENT_IMAGE=$(shell head -n1 Dockerfile | cut -d " " -f 2)
TAGS=latest $(WLS_VERSION)
CONTAINER_NAME=weblogic
CENTOS_IMAGE=camunda-ci-base-centos:latest
# the database image to inherit from, eg. camunda-ci-db2:9.7
DB_IMAGE?=$(CENTOS_IMAGE)

ifneq ($(DB_IMAGE),$(CENTOS_IMAGE))
	DB:=$(shell echo $(DB_IMAGE) | cut -d ':' -f 1 | cut -d '-' -f 3)
	DB_VERSION:=$(shell echo $(DB_IMAGE) | cut -d ':' -f 2)
	PARENT_IMAGE=registry.camunda.com/$(DB_IMAGE)
	TAGS=$(WLS_VERSION)-$(DB)-$(DB_VERSION)
	CONTAINER_NAME=weblogic_$(DB)
endif

# the first tag and the remaining tags split up
FIRST_TAG=$(firstword $(TAGS))
ADDITIONAL_TAGS=$(wordlist 2, $(words $(TAGS)), $(TAGS))
# the image name which will be build
IMAGE=$(IMAGE_NAME):$(FIRST_TAG)
# options to use for running the image, can be extended by FLAGS variable
OPTS=--name $(CONTAINER_NAME) -t $(FLAGS)
FORCE_FLAG:=$(shell if [ `docker version -f '{{.Client.Version}}' | cut -f2 -d.` -lt 10   ]; then echo -f; fi)
# the docker command which can be configured by the DOCKER_OPTS variable
DOCKER=docker $(DOCKER_OPTS)
# the temporary Dockerfile name with replaced parent image
DOCKERFILE_TMP=Dockerfile.tmp

# default build settings
REMOVE=true
FORCE_RM=true
NO_CACHE=false

# build the image for the first tag and tag it for additional tags
build:
	$(shell sed '1s!.*!FROM $(PARENT_IMAGE)!' Dockerfile > $(DOCKERFILE_TMP))
	$(DOCKER) build -f $(DOCKERFILE_TMP) --rm=$(REMOVE) --force-rm=$(FORCE_RM) --no-cache=$(NO_CACHE) -t $(IMAGE) .
	for tag in $(ADDITIONAL_TAGS); do \
		$(DOCKER) tag $(FORCE_FLAG) $(IMAGE) $(IMAGE_NAME):$$tag; \
	done

# pull image from registry
pull:
	-$(DOCKER) pull $(IMAGE)

# pull parent image
pull-from:
	$(DOCKER) pull $(PARENT_IMAGE)

# push container to registry
push:
	for tag in $(TAGS); do \
		$(DOCKER) push $(IMAGE_NAME):$$tag; \
	done

# pull parent image, pull image, build image and push to repository
publish: pull-from pull build push

# run container
run:
	$(DOCKER) run --rm $(OPTS) $(IMAGE)

# start container as daemon
daemon:
	$(DOCKER) run -d $(OPTS) $(IMAGE)

# start container with port mapping
stage: rmf
	$(DOCKER) run -d $(OPTS) -p 5900:5900 -p 8787:8787 -p 7001:7001 -p 7002:7002 $(IMAGE)

# start interactive container with bash
bash:
	$(DOCKER) run --rm -i $(OPTS) $(IMAGE) /bin/bash

# remove container by name
rmf:
	-$(DOCKER) rm -f $(CONTAINER_NAME)

# remove image with all tags
rmi:
	@for tag in $(TAGS); do \
		$(DOCKER) rmi $(IMAGE_NAME):$$tag; \
	done

.PHONY: build pull pull-from push publish run daemon stage bash rmf rmi
