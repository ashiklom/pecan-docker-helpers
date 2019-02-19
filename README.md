# Helper files for PEcAn swarm deployment

This repo contains tools to facilitate deploying PEcAn across multiple VMs using Docker Swarm.
The files are as follows:

- `production.yml` -- A `docker-compose.yml` file modified as follows:
   - All services that should run on the `manager` node have the appropriate deployment constraint
   - The `pecan` volume, which has to be shared across nodes, is deployed via NFS at `/publish/shared-docker-volumes/pecan_data`. It is also given the `nocopy` option everywhere.
   - All pecan images are prefixed with my local registry's IP address.
- `tag-images.sh` -- A helper script to quickly tag existing PEcAn images of a given version with the registry IP address and push them to the registry.
- `deploy.sh` -- A helper script that reads environment variables from the `.env` file and then deploys a Docker stack from the `production.yml` Compose file.

# Setup PEcAn stack on Docker Swarm

## Configure NFS storage

On the manager node, install the NFS kernel (`apt` package `nfs-kernel-server`).
On each worker node, install the NFS utilities (`nfs-common`).
(One or both may already be available -- they are pretty common).

Create a directory to be shared over NFS.
Here, I use `/public/shared-docker-volumes`.

On the manager node, open the `/etc/exports` file (as root) and add the following line:

```
/public/shared-docker-volumes *(rw,sync)
```

(You may place additional restrictions on this volume if you wish -- see the NFS documentation for more details).

You may also need to change the group ownership of this directory to the `nogroup` group (to allow Docker's `nobody` user to edit it).

```
sudo chgrp nogroup /public/shared-docker-volumes
```

## Set up Docker Swarm

Initialize the Docker Swarm on your local (static) IP address (you can look up possible IP addresses with shell command `ip address`):

```
docker swarm init --advertise-addr XXX.XXX.XXX.XXX
```

This will output a command to run on "worker" nodes to add them to the Swarm.
Run that command on all worker nodes you want to add to the Swarm.

You can check the status of the stack with the following command:

```
docker node ls
```

## Set up local image registry (if using local images) 

Create a Docker registry on the manager node.

```
docker service create --name registry --publish published=5000,target=5000 registry:2
```

You may need to also configure the manager and all worker nodes to allow this as an insecure (HTTP, as opposed to HTTPS) registry.
To do this, edit the `/etc/docker/daemon.json` file (as root) to include the following:

```
{"insecure-registries": ["XXX.XXX.XXX.XXX:5000"]
```

...and then restart the Docker service.

```
# On Ubuntu
sudo service docker restart
# On systemctl-based systems
sudo systemctl restart docker
```

## Create images for Swarm

Clone this repositry into the `helpers` subdirectory of the PEcAn root directory.

```
# (From the PEcAn root directory)
git clone https://github.com/ashiklom/pecan-docker-helpers helpers
```

Pick an image tag to use for the stack and make sure you have all the required images available locally. The following steps assume you are using `develop`.

```
docker image ls | grep pecan/.*:develop
```

Select the tag (e.g. `latest`, `develop`, `testing`, or something custom) of the images you want to run on the stack.
This will be the value of `PECAN_VERSION` in the next step.

Note that because worker nodes do not have access to your local images, they will have to pull them from somewhere.
By default, they pull the images from Docker Hub.
If you want to use custom images, you will need to upload them to a local registry.
The `tag-images.sh` script is a helper script that tags appropriately and pushes them to the local registry auotmatically.
For instance, to tag and push images with the `custom` tag (e.g. `pecan/executor:custom`), run (from the PEcAn root directory):

```
helpers/tag-images.sh custom
```

## Initialize PEcAn data volumes

These are basically the same steps as for standard Docker deployment, _except_ that they use a slightly different compose file and different project name.
Below, we assume you are using the `custom` tag and are creating a swarm called `pecanswarm` (you can change these if you wish, but they _must_ be consistent with earlier and later steps).

```
PECAN_VERSION=custom docker-compose -f helpers/production.yml -p pecanswarm up -d postgres
docker run -it --rm --network pecanswarm_pecan pecan/bety:latest initialize
docker run -it --rm --network pecanswarm_pecan --volume pecanswarm_pecan:/data --env FQDN=docker pecan/data:develop
```

Assuming these commands run successfully, you can then remove this temporary stack (the volumes should be preserved).

```
PECAN_VERSION=custom docker-compose -f helpers/production.yml -p pecanswarm down
```

## Deploy the PEcAn stack

Create or modify the `.env` (in the PEcAn root directory) to set relevant variables for the Docker Compose file.
In particular, make sure to set `PECAN_VERSION` to whatever tag you selected in the previous step.

Then, from the PEcAn root directory, run the `helpers/deploy.sh` script to deploy the stack.
The first argument gives the name of the stack, which defaults to `pecanswarm` if omitted.

You can view the status of your stack with either of the following commands:

```
docker service ls
docker stack ps pecanswarm
```

