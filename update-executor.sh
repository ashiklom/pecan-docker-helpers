#!/bin/bash
set -e

PACKAGE=$1

if [ -z "${PACKAGE}" ]; then
    echo "Please specify a package to update"
    exit 1
fi
CONTAINER=$(docker container ls --filter name=executor --format '{{.ID}}')
SERVICE=$(docker service ls --format '{{.ID}}\t{{.Name}}' | awk '/executor/ {print $1}')

# Copy package into running container
echo "Copying ${PACKAGE} to container ${CONTAINER}"
docker exec -it ${CONTAINER} rm -rf /tmp/package
docker cp ${PACKAGE} ${CONTAINER}:/tmp/package

# Install the package
echo "Installing ${PACKAGE}"
docker exec -it ${CONTAINER} Rscript -e "devtools::install('/tmp/package')"

echo "Removing package from container"
docker exec -it ${CONTAINER} rm -rf /tmp/package

echo "Done!"
