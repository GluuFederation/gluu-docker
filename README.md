# Gluu Server Docker Edition

Currently in development.

## Code Repositories

Repositories for supported images are shown below (Under 3.1.2 branch):

- [config-init](http://github.com/GluuFederation/docker-config-init)
- [openldap](http://github.com/GluuFederation/docker-openldap)
- [opendj](http://github.com/GluuFederation/docker-opendj)
- [oxauth](http://github.com/GluuFederation/docker-oxauth)
- [oxtrust](http://github.com/GluuFederation/docker-oxtrust)
- [nginx](http://github.com/GluuFederation/docker-nginx)
- [key-rotation](https://github.com/GluuFederation/docker-key-rotation)
- [oxshibboleth](https://github.com/GluuFederation/docker-oxshibboleth)
- [oxpassport](https://github.com/GluuFederation/docker-oxPassport)

## Image Repositories

Images are hosted at Docker Hub:

`<image>:3.1.2_dev` are the latest builds currently.

- [config-init](https://hub.docker.com/r/gluufederation/config-init)
- [openldap](https://hub.docker.com/r/gluufederation/openldap)
- [opendj](https://hub.docker.com/r/gluufederation/opendj)
- [oxauth](https://hub.docker.com/r/gluufederation/oxauth)
- [oxtrust](https://hub.docker.com/r/gluufederation/oxtrust)
- [nginx](https://hub.docker.com/r/gluufederation/nginx)
- [key-rotation](https://hub.docker.com/r/gluufederation/key-rotation)
- [oxshibboleth](https://hub.docker.com/r/gluufederation/oxshibboleth)
- [oxpassport](https://hub.docker.com/r/gluufederation/oxpassport)

## Examples

[Single Host](./examples/single-host/)

- Please note that `docker-compose up` on this `docker-compose.yaml` does not work due to the nature of docker-compose and how it doesn't wait for containers to truly "finish" starting/exiting. There are required steps necessary. [A pull request is currently in the works to rectify this issue](https://github.com/GluuFederation/docker-oxtrust/pull/2)

[Swarm](./examples/multi-host/)

- The directory contains `README.md` as a guide to deploy basic multi-hosts Gluu server stack.

Kubernetes - TBD
