#!/bin/bash
# This script shows how to build the Docker image and push it to Docker Hub.

echo "Inside build_and_push.sh file"
DOCKERHUB_USERNAME=$1

echo "Value of DOCKERHUB_USERNAME is $DOCKERHUB_USERNAME"

if [ "$DOCKERHUB_USERNAME" == "" ]
then
    echo "Usage: $0 <dockerhub-username>"
    exit 1
fi

src_dir=$CODEBUILD_SRC_DIR

# Fetch DockerHub credentials from AWS Secrets Manager
echo "Fetching DockerHub credentials from AWS Secrets Manager..."
aws secretsmanager get-secret-value --secret-id dockerhub_credentials --query SecretString --output text > dockerhub_credentials.json

DOCKERHUB_USERNAME=$(jq -r '.username' dockerhub_credentials.json)
DOCKERHUB_PASSWORD=$(jq -r '.password' dockerhub_credentials.json)

echo "Logging in to DockerHub..."
echo $DOCKERHUB_PASSWORD | docker login --username $DOCKERHUB_USERNAME --password-stdin

# Get the region defined in the current configuration (default to us-east-1 if none defined)
region=$AWS_REGION
if [ -z "$region" ]; then
    region="us-east-1"
fi
echo "Region value is: $region"

# Set up Docker Buildx
docker buildx create --use --name mybuilder
docker buildx inspect mybuilder --bootstrap

# Build and push WebApp image
WEBAPP_IMAGE="${DOCKERHUB_USERNAME}/webapp"
webapp_fullname="${WEBAPP_IMAGE}:latest"

echo "Building and pushing WebApp image..."
docker buildx build --platform linux/amd64,linux/arm64 -t ${webapp_fullname} -f ${src_dir}/Dockerfile ${src_dir} --push

# Logout from Docker Hub
docker logout

if [ $? -ne 0 ]
then
    echo "Docker Push Event did not Succeed"
    exit 1
else
    echo "Docker Push Event is Successful"
fi
