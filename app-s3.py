import os

import aiohttp
from dotenv import load_dotenv
from fastapi import FastAPI

load_dotenv()

APP_DB_URL = os.getenv("APP_DB_URL")

app = FastAPI()


@app.get("/")
async def root():
    async with aiohttp.ClientSession() as session:
        async with session.get(APP_DB_URL) as response:
            return await response.text()
