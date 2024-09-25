#!/bin/bash
cd frontend 
pnpm i
cp .env.example .env
sed -i "s|http://localhost:5050/|http://$(curl -s ifconfig.me)/recorder|g" .env
sed -i "s|http://localhost:5555/|http://$(curl -s ifconfig.me)/transcriber|g" .env
pnpm start &
cd ../
cd backend
pnpm i
cp .env.example .env
pnpm start-dev &
cd ../


