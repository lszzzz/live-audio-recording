#!/bin/bash
cd frontend 
pnpm i
cp .env.example .env
sed -i "s|http://localhost:5050/|http://$(curl -s ifconfig.me)/recorder|g" .env
sed -i "s|http://localhost:5555/|http://$(curl -s ifconfig.me)/transcriber|g" .env
pnpm build
cd ../
cd backend
pnpm i
pnpm build
cp .env.example .env
cd ../
pm2 stop all
pm2 serve apps/frontend/build/ 3000 --name "frontend" --spa
cd backend
pm2  node  dist/index.js --name "server"
cd ../


