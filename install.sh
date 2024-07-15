#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Docker on Debian-based systems (like Ubuntu)
install_docker_debian() {
    echo "Updating package database..."
    sudo apt-get update -y

    echo "Installing prerequisites..."
    sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y

    echo "Adding Docker's official GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    echo "Adding Docker APT repository..."
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    echo "Updating package database with Docker packages..."
    sudo apt-get update -y

    echo "Installing Docker..."
    sudo apt-get install docker-ce -y
}

# Function to install Docker on RHEL-based systems (like CentOS)
install_docker_rhel() {
    echo "Updating package database..."
    sudo yum update -y

    echo "Installing prerequisites..."
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2

    echo "Adding Docker's official GPG key..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    echo "Installing Docker..."
    sudo yum install docker-ce -y
}

# Check if necessary environment variables are set
if [ -z "$COLLECTION_ID" ]; then
    echo "Error: COLLECTION_ID."
    exit 1
fi

echo "COLLECTION_ID: $COLLECTION_ID"

# Install Docker if not already installed
if ! command_exists docker; then
    if command_exists apt-get; then
        install_docker_debian
    elif command_exists yum; then
        install_docker_rhel
    else
        echo "Unsupported package manager. Please install Docker manually."
        exit 1
    fi
else
    echo "Docker is already installed."
fi

# Start Docker service if not running
if ! sudo systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Verify Docker installation
echo "Verifying Docker installation..."
docker --version
if [ $? -ne 0 ]; then
    echo "Docker installation failed."
    exit 1
fi
echo "Docker installed successfully."

# Set environment variables
export AWS_PUBLIC_REPO_IMAGE="public.ecr.aws/f9i4e9b2/apisentry_waf:latest"

# Pull Docker image from AWS public repository
echo "Pulling Docker image from AWS public repository..."
sudo docker pull $AWS_PUBLIC_REPO_IMAGE
if [ $? -ne 0 ]; then
    echo "Failed to pull Docker image."
    exit 1
fi
echo "Docker image pulled successfully."

# Run Docker container
echo "Running Docker container..."
sudo docker run -d --name my-container $AWS_PUBLIC_REPO_IMAGE
if [ $? -ne 0 ]; then
    echo "Failed to run Docker container."
    exit 1
fi
echo "Docker container running successfully."

# Check if Docker container is running
sudo docker ps | grep my-container
if [ $? -ne 0 ]; then
    echo "Docker container is not running."
    exit 1
fi
echo "Docker container is confirmed running."

# Generate UUID
UUID=$(uuidgen)
echo "Generated UUID: $UUID"

# Get server information
SERVER_INFO=$(uname -a)
echo "Server information: $SERVER_INFO"


# Confirm environment variables
echo "Environment variables set:"
echo "COLLECTION_ID: $COLLECTION_ID"
