camunda-docker-ci-weblogic
===========================

Camunda BPM platform - Oracle WebLogic Docker image for development purposes.

# Usage

When starting the `camunda-docker-ci-weblogic` image through `docker run`, you should do the following to ease your development process.
* Link your `camunda-bpm-platform` and `camunda-bpm-platform-ee` directories into the container.
* Link your Maven user home directory (eg. `~/.m2`) into the container to `/home/camunda/.m2` so you have access to your local maven repository and `settings.xml`.
* Map the exposed ports to your localhost.
* Start Oracle WebLogic adminisration server either using `startWebLogic.sh`, which is in PATH or by `sudo supervisorctl start weblogic`
* Username and password can be lookuped in Dockerfile.

# Ports

* 22   - SSH access
* 5900 - VNC for chrome
* 8787 - Java remote debug port for IDEs
* 7001 - HTTP connection for web applications. Connect to Oracle WebLogic administration console using http://...:7001/console
* 7002 - HTTPS connection for web applications, eg. camunda-webapp

# Packages

  - Oracle WebLogic Application Server for Developers 12R2
  - Apache Maven 3.2.3
  - Google Chrome

# Users

## SSH User: camunda

  - username: camunda
  - groups:   camunda, sudo
  - password: camunda

## SSH User: jenkins

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
