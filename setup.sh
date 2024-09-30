#!/bin/bash

# Check if domain is passed as an argument
if [ -z "$1" ]; then
    echo "Error: No domain provided."
    echo "Usage: $0 domain.com"
    exit 1
fi

DOMAIN=$1

# Check if SSL certificate files exist
if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" && -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]]; then
    echo "SSL certificate files exist. Skipping installation of npm packages and Python environment setup."
else
    # Update package list and install Certbot and Nginx plugin
    echo "Installing Certbot and Nginx plugin..."
    apt update
    apt install certbot python3-certbot-nginx -y

    # Remove the default Nginx configuration if it exists
    echo "Removing default Nginx configuration..."
    rm /etc/nginx/sites-available/default 2>/dev/null
    rm /etc/nginx/sites-enabled/default 2>/dev/null

    # Create a new Nginx configuration file for the domain (port 80 HTTP)
    echo "Creating new Nginx configuration..."
    cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    listen [::]:80;
    server_name _;

    location / {
        # First attempt to serve request as file, then as directory,
        # then fall back to displaying a 404.
        try_files \$uri \$uri/ =404;
    }
}
EOL

    # Enable the new configuration by creating a symbolic link
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

    # Test Nginx configuration
    nginx -t || { echo "Nginx configuration test failed. Exiting."; exit 1; }

    # Restart Nginx to apply the changes
    systemctl restart nginx

    # Obtain SSL certificate using Certbot
    echo "Obtaining SSL certificate using Certbot..."
    certbot --nginx -d $DOMAIN

    # After Certbot is successful, overwrite the Nginx configuration to force HTTPS
    echo "Updating Nginx configuration to force HTTPS..."
    cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
    
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Reverse proxy for /recorder/
    location /recorder/ {
        proxy_pass http://localhost:5050/;
        proxy_http_version 1.1;  # Use HTTP/1.1 for WebSocket support
        proxy_set_header Upgrade \$http_upgrade;  # Handle WebSocket upgrade
        proxy_set_header Connection "upgrade";    # Handle WebSocket connection upgrade
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        rewrite ^/recorder/(.*)$ \$1 break;  # Fix rewrite rule for correct routing
    }

    # Reverse proxy for /transcriber/
    location /transcriber/ {
        proxy_pass http://localhost:5555/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        rewrite ^/transcriber(.*)\$ \$1 break;
    }

    # Reverse proxy for everything else
    location / {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

    # Test Nginx configuration again after SSL setup
    nginx -t || { echo "Nginx configuration test failed after SSL setup. Exiting."; exit 1; }

    # Restart Nginx to apply the updated SSL configuration
    systemctl restart nginx
fi

# Install global npm packages
echo "Installing global npm packages..."
npm install -g pnpm pm2 npx
apt instal python3.12-venv

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv myenv
source myenv/bin/activate

echo "Setup complete!"
