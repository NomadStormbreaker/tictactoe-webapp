#!/bin/bash
set -e

# This script builds the Docker image and pushes it to DockerHub.

# The arguments to this script are the image name and DockerHub username.
echo "Inside build_and_push.sh file"
DOCKER_IMAGE_NAME=$1
DOCKERHUB_USERNAME=$2

echo "Value of DOCKER_IMAGE_NAME is $DOCKER_IMAGE_NAME"
echo "Value of DOCKERHUB_USERNAME is $DOCKERHUB_USERNAME"

if [ -z "$DOCKER_IMAGE_NAME" ] || [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "Usage: $0 <image-name> <dockerhub-username>"
    exit 1
fi

src_dir=$CODEBUILD_SRC_DIR

# Fetch DockerHub credentials from AWS Secrets Manager
echo "Fetching DockerHub credentials from AWS Secrets Manager..."
aws secretsmanager get-secret-value --secret-id dockerhub_credentials --query SecretString --output text > dockerhub_credentials.json

DOCKERHUB_USERNAME=$(jq -r '.username' dockerhub_credentials.json)
DOCKERHUB_PASSWORD=$(jq -r '.password' dockerhub_credentials.json)

# Clean up credentials file after usage
trap "rm -f dockerhub_credentials.json" EXIT

# Log in to DockerHub
echo $DOCKERHUB_PASSWORD | docker login --username $DOCKERHUB_USERNAME --password-stdin

# Use the build number as the image tag
image_tag="$CODEBUILD_BUILD_NUMBER"

# Correctly format the full image name with the repository and tag
fullname="${DOCKERHUB_USERNAME}/${DOCKER_IMAGE_NAME}:${image_tag}"
echo "fullname is $fullname"

# Create and bootstrap a new buildx builder
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap

# Build the Docker image for multiple platforms and push it to DockerHub
echo "Building and pushing Docker image..."
docker buildx build --platform linux/amd64,linux/arm64 --tag "${fullname}" --push $CODEBUILD_SRC_DIR/

if [ $? -ne 0 ]; then
    echo "Docker Push Event did not succeed with Image ${fullname}"
    exit 1
else
    echo "Docker Push Event is successful with Image ${fullname}"
fi
