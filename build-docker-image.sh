#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

IMAGE_NAME="image-plus-audio"
IMAGE_TAG="latest"

echo "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}..."

# Ensure we are in the script's directory or Dockerfile is accessible
cd "$(dirname "$0")" || exit

docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "✅ Docker image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
