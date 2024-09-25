#!/bin/bash

npm install -g pnpm
npm install -g pm2
npm install -g npx



if ! grep -q "location /backend/" /etc/nginx/sites-available/default; then
    sudo sed -i '/server_name _;/a \
        location /recorder/ { \
            proxy_pass http://localhost:5050/; \
            proxy_set_header Host $host; \
            proxy_set_header X-Real-IP $remote_addr; \
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
            proxy_set_header X-Forwarded-Proto $scheme; \
            rewrite ^/recorder(.*)$ $1 break; \
        } \
        location /transcriber/ { \
            proxy_pass http://localhost:5555/; \
            proxy_set_header Host $host; \
            proxy_set_header X-Real-IP $remote_addr; \
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
            proxy_set_header X-Forwarded-Proto $scheme; \
            rewrite ^/transcriber(.*)$ $1 break; \
        } \
        location / { \
            proxy_pass http://localhost:3000/; \
            proxy_set_header Host $host; \
            proxy_set_header X-Real-IP $remote_addr; \
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
            proxy_set_header X-Forwarded-Proto $scheme; \
        }' /etc/nginx/sites-available/default
fi

service nginx restart
mkdir backend/public/uploads
chmod -R 777  backend/public/uploads