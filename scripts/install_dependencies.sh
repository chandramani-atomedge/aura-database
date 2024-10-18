#!/bin/bash
set -e

# Update package index and install docker.io
sudo apt-get update -y

yes | sudo apt-get install -y ca-certificates curl

yes | sudo install -m 0755 -d /etc/apt/keyrings

yes | curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null

yes | echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

yes | sudo apt-get update -y

yes | sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin


sudo systemctl enable docker
sudo systemctl start docker

# Log in to AWS ECR
TOKEN=$(aws ecr get-login-password --region us-east-1)
if [ -z "$TOKEN" ]; then
    echo "Failed to get ECR login token" >&2
    exit 1
fi
echo "$TOKEN" | sudo docker login --username AWS --password-stdin 270514764245.dkr.ecr.us-east-1.amazonaws.com

sudo rm -rf /home/ubuntu/aura-db || true

sudo docker rm -f aura-db || true 

#sudo docker network rm -f aura-network || true

docker pull 270514764245.dkr.ecr.us-east-1.amazonaws.com/aura-postgres:latest

NETWORK_NAME="aura-network"

# Check if the network already exists
if docker network ls --format '{{.Name}}' | grep -w "$NETWORK_NAME" > /dev/null; then
    echo "Network '$NETWORK_NAME' already exists."
else
    # Create the network if it doesn't exist
    docker network create "$NETWORK_NAME"
    echo "Network '$NETWORK_NAME' created."
fi


# docker run -d --name aura-app --hostname localhost -e "AWS_ACCESS_KEY_ID=AKIAT567PXHK6WVKNEOS3" -e "AWS_SECRET_ACCESS_KEY=9yZfLNgfLmMtIc+uERbDFw+jygll+MtjuX8rqWZKl" -e "OTP_API_KEY=5d7dbdd8-6498-11ef-8b60-0200cd936042" -p 80:80 -d 270514764245.dkr.ecr.us-east-1.amazonaws.com/static-website:latest
#docker run -d --name aura-db --hostname localhost -e "AWS_ACCESS_KEY_ID=AKIAT567PXHK6WVKNEOS3" -e "AWS_SECRET_ACCESS_KEY=9yZfLNgfLmMtIc+uERbDFw+jygll+MtjuX8rqWZKl" -e "OTP_API_KEY=5d7dbdd8-6498-11ef-8b60-0200cd936042" -p 5432:5432 -d 270514764245.dkr.ecr.us-east-1.amazonaws.com/aura-hrms-db:latest

docker run -d \
  --name aura-db \
  --network aura-network \
  --env POSTGRES_USER=postgres \
  --env POSTGRES_PASSWORD=password \
  --env POSTGRES_DB=hrms \
  --publish published=5432,target=5432 \
  270514764245.dkr.ecr.us-east-1.amazonaws.com/aura-postgres:latest
