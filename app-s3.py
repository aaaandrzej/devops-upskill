import os

from dotenv import load_dotenv
from fastapi import FastAPI
from requests import get

load_dotenv()

APP_DB_URL = os.getenv("APP_DB_URL")

app = FastAPI()


@app.get("/")
async def root():
    return get(url=APP_DB_URL).text
