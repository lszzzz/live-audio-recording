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
pm2 start dist/main.js 
cd ../

# python server
sudo apt install ffmpeg -y
cd audio-transcription
python3 -m venv myenv
source myenv/bin/activate
pip install -r requirements.txt
python app/server.py &

