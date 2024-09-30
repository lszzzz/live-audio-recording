#!/bin/bash

# Check if the domain is passed as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <Domain>"
  exit 1
fi

DOMAIN=$1



echo "Stopping all Node.js processes..."
pkill -f node

# Stop all running Python processes
echo "Stopping all Python processes..."
pkill -f python
pm2 stop all

# frontend
cd frontend 
cp .env.example .env
pnpm i
sed -i "s|http://localhost:5050/|https://$DOMAIN/recorder/|g" .env
sed -i "s|http://localhost:5555/|https://$DOMAIN/transcriber/|g" .env
pnpm build
chmod -R 777 build
cd ../

# backend
cd backend
mkdir public
mkdir -p public/audios
pnpm i
sudo chmod -R 777 dist
cp .env.example .env
pnpm build
chmod -R 777 build
cd ../

# python server
sudo apt install ffmpeg -y


