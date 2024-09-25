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
sed -i "s|http://localhost:5050/|http://$DOMAIN/recorder|g" .env
sed -i "s|http://localhost:5555/|http://$DOMAIN/transcriber|g" .env
pnpm build
pm2 serve build/ 3000 --name "frontend" --spa
cd ../

# backend
cd backend
mkdir public
mkdir -p public/audios
pnpm i
sudo chmod -R 777 dist
cp .env.example .env
pnpm build
pm2 node dist/index.js 
cd ../

# python server
cd audio-transcription
pip install -r requirements.txt
pm2 python app/server.py 

cd ../
