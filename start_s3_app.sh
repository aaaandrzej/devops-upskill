#!/bin/bash

source .env

sudo apt-get update
sudo apt-get -y install python3-pip uvicorn
pip3 install fastapi[all] boto3 python-dotenv aiohttp

uvicorn app-s3:app --host 0.0.0.0 --port 8000