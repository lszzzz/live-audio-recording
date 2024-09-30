#!/bin/bash
cd frontend
pm2 serve build/ 3000 --name "frontend" --spa
cd ../
cd backend
pm2 start dist/main.js 
cd ..
sudo chmod -R 777 backend/public
sudo chmod -R 777 audio-transcription
cd audio-transcription
python3 -m venv myenv
source myenv/bin/activate
pip install -r requirements.txt
python app/server.py &