#!/bin/bash

VERSION=${1:-latest}

SWARM_REGISTRY=${SWARM_REGISTRY:-172.20.234.6:5000}

IMAGES=(base depends web docs monitor models thredds data executor
model-maespa-git model-ed2-git model-sipnet-136)

for image in ${IMAGES[@]}; do
    NEWIMAGE=${REGISTRY}/pecan/$image:${VERSION}
    echo "Processing image: ${NEWIMAGE}"
    docker image tag $image:${VERSION} ${NEWIMAGE}
    docker push ${NEWIMAGE}
done
