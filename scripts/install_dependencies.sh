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

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 270514764245.dkr.ecr.us-east-1.amazonaws.com

IMAGE_TAG=$(aws ssm get-parameter --name "database-image-tag" --region ap-south-1 --query "Parameter.Value" --output text)

sudo rm -rf /home/ubuntu/aura-db || true

sudo docker rm -f 270514764245.dkr.ecr.us-east-1.amazonaws.com/aura-postgres:latest || true 

docker pull 270514764245.dkr.ecr.us-east-1.amazonaws.com/aura-postgres:latest
