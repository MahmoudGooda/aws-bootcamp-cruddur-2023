#!/bin/bash

echo setting env. variables
export BACKEND_URL="*"
export FRONTEND_URL="*"
echo Done
echo Installing requirements
pip install flask
pip install flask-cors
echo Done
echo run backend-flask
python3 -m flask run --host=0.0.0.0 --port=4567