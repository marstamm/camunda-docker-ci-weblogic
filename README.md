camunda-docker-ci-websphere
===========================

Camunda BPM platform - IBM WebSphere Docker image for development purposes.

# Requires

In order to run this image you need to:  
* Start it in privileged mode
* Have devicemapper as docker storage driver (Add `--storage-driver=devicemapper` to your DOCKER_OPTS)

# Usage

When starting the `camunda-docker-ci-websphere` image through `docker run`, you should do the following to ease your development process.
* Link your `camunda-bpm-platform` and `camunda-bpm-platform-ee` directories into the container.
* Link your Maven user home directory (eg. `~/.m2`) into the container to `/root/.m2` so you have access to your local maven repositories and settings.
* Map the exposed ports to your localhost (9080, 9060, 7777, 5900)


## Usage Examples

### Without database

```
$ docker run -it -p 9060:9060 -p 9080:9080 -p 7777:7777 -p 5900:5900 -v <MY_CAMUNDA_BPM_PLATFORM_DIR>:/camunda-bpm-platform \
-v <MY_CAMUNDA_BPM_PLATFORM_EE_DIR>:/camunda-bpm-platform-ee -v <MY_MAVEN_USER_HOME_DIR>:/root/.m2 camunda/camunda-docker-ci-websphere /bin/bash -l
```


### With Oracle 11g Express as linked docker container

Start Oracle 11g Express through Docker (User:system / Password: oracle) and give it a name, `oracle` in this case:
```
$ docker run -d -p 1521:1521 --name oracle wnameless/oracle-xe-11g
```

Start the WebSphere Container and link the database into it by referencing the name of the database container:
```
$ docker run -it -p 9060:9060 -p 9080:9080 -p 7777:7777 -v <MY_CAMUNDA_BPM_PLATFORM_DIR>:/camunda-bpm-platform \
-v <MY_CAMUNDA_BPM_PLATFORM_EE_DIR>:/camunda-bpm-platform-ee -v <MY_MAVEN_USER_HOME_DIR>:/root/.m2 \
--link oracle:oracle camunda/camunda-docker-ci-websphere /bin/bash -l
```


### Execute maven build

Start and enter the `camunda-docker-ci-websphere` container using one of the usage examples. Then go to your linked `<CAMUNDA_BPM_PLATFORM_EE>` directory in the docker container (eg `/camunda-bpm-platform-ee/qa`) and execute following statement to run the camunda BPM platform EE IBM WebSphere QA test suite:

```
$ cd /camunda-bpm-platform-ee/qa
$ mvn clean verify -Pwas85,oracle-xa -Dwas.home=${WAS_HOME} -Dwas.profile=${WAS_PROFILE} -Ddatabase.name=xe -Ddatabase.host=${ORACLE_PORT_1521_TCP_ADDR} -Ddatabase.port=${ORACLE_PORT_1521_TCP_PORT} -Ddatabase.user=system -Ddatabase.password=oracle
```


# Ports

* 22   - SSH access
* 5900 - VNC for chrome
* 7777 - Java remote debug port for IDEs
* 9060 - `http://localhost:9060/ibm/console` to access the IBM WebSphere administration console
* 9080 - Http connection for web applications, eg. camunda-webapp

# Packages

  - IBM WebSphere Application Server for Developers 8.0.0.0
  - Apache Maven 3.2.3
  - Google Chrome

# Users

## User: camunda

  - username: camunda
  - groups:   camunda, sudo
  - password: camunda

## User: jenkins

  - username: jenkins
  - groups:   jenkins
  - password: jenkins

# SSH

The keys inside the `keys` directory can be used to login without password.

For example start the docker image

```
docker run -p 2000:22 -d --name ci-base camunda/camunda-docker-ci-base
```

copy the key files to your local `~/.ssh/` directory and login with the key file

```
ssh -p 2000 -i ~/.ssh/camunda-developer-insecure camunda@localhost
```

or add following lines to your `~/.ssh/config`

```
Host ci-base
  Hostname localhost
  Port 2000
  User camunda
  IdentityFile ~/.ssh/camunda-developer-insecure
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
```

and login with ssh

```
ssh ci-base
```
