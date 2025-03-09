#!/bin/bash
# save as deploy.sh

# Pull latest changes
git pull

# Restart containers
docker-compose restart hugo
sleep 5
docker-compose restart caddy

echo "Wiki has been updated!"
