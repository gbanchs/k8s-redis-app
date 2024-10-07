#!/bin/bash
export APP_NAME=$APP_NAME
export VERSION="${BITBUCKET_BUILD_NUMBER}"
export IMAGE_TAG="${BITBUCKET_BUILD_NUMBER}"
export NODE_ENV=$NODE_ENV
export ENV="${ENV}"
export NAMESPACE="${NAMESPACE}"

export APP_NAME="bluecore"
export IMAGE_TAG="v11"

export ENV="demo"
export NAMESPACE="default"

if [ "$ENV" = "prod" ]; then
    export DOMAIN="${APP_NAME}.gbanchs.com"

else
   export DOMAIN="${ENV}.${APP_NAME}.gbanchs.com"
fi



printf "APP_NAME: $APP_NAME\n"
printf "VERSION: $VERSION\n"
printf "IMAGE_TAG: $IMAGE_TAG\n"
printf "ENV: $ENV\n"
printf "DOMAIN_PREFIX: $DOMAIN_PREFIX\n"


for file in *.yaml; do
  envsubst < "$file" > temp.yaml && mv temp.yaml "$file"
  echo "\n After substitution $file:"
  cat "$file"
done