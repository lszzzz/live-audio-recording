#!/bin/bash

# Check if domain is passed as an argument
if [ -z "$1" ]; then
    echo "Error: No domain provided."
    echo "Usage: $0 domain.com"
    exit 1
fi

DOMAIN=$1
WWW_DOMAIN="www.$DOMAIN"

# Install Certbot and Nginx plugin
apt update
apt install certbot python3-certbot-nginx -y

# Obtain SSL certificate using Certbot for the domain
certbot --nginx -d $DOMAIN -d $WWW_DOMAIN

# Remove the default Nginx configuration
rm /etc/nginx/sites-available/default

# Create a new Nginx configuration file for the domain
cat > /etc/nginx/sites-available/$DOMAIN <<EOL
server {
    listen 80;
    server_name $DOMAIN $WWW_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN $WWW_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Reverse proxy for /recorder/
    location /recorder/ {
        proxy_pass http://localhost:5050/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        rewrite ^/recorder(.*)\$ \$1 break;
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

    # Reverse proxy for everything else (general traffic)
    location / {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Enable the new configuration by creating a symbolic link
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Test Nginx configuration for syntax errors
nginx -t

# Restart Nginx to apply the changes
systemctl restart nginx



npm install -g pnpm
npm install -g pm2
npm install -g npx
python3 -m venv myenv
source myenv/bin/activate



