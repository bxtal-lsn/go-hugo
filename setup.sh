#!/bin/bash
# save as setup.sh

# Ensure the Caddyfile exists
if [ ! -f "Caddyfile" ]; then
  echo "Creating Caddyfile..."
  cat > Caddyfile << EOF
# Replace with your actual server IP
{$SERVER_IP} {
    root * /usr/share/caddy
    file_server
    encode gzip
    tls internal
}
EOF
fi

# Create public directory if it doesn't exist
mkdir -p public

# Start containers
echo "Starting containers..."
docker-compose up -d hugo

# Give Hugo a moment to generate site
echo "Waiting for Hugo to generate site..."
sleep 5

# Start Caddy after Hugo has generated the site
docker-compose up -d caddy

echo "Setup complete! Access your wiki at:"
echo "- Development (with live reload): http://localhost:1313"
echo "- Production (with HTTPS): https://$SERVER_IP"
