#!/bin/bash
# Pull latest changes
git pull

# Build the site locally
hugo --minify

# Restart Caddy to pick up changes
docker-compose restart caddy

echo "Wiki has been updated!"
