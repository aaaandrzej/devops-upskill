import os
from pathlib import Path

import aiohttp
from aiohttp.client_exceptions import ClientConnectorError
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse

load_dotenv()

APP_DB_URL = os.getenv("APP_DB_URL")
S3_PATH = os.getenv("S3_PATH", default=None)

app = FastAPI()


@app.post("/upload")
async def create_file(request: Request):
    form = await request.form()
    filename = form["upload_file"].filename
    contents = await form["upload_file"].read()
    with open(Path(S3_PATH) / filename, "wb") as f:
        f.write(contents)
    return HTMLResponse(f"'{filename}' file uploaded successfully")


@app.get("/")
async def root():
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(APP_DB_URL) as response:
                response_from_db = await response.text()
    except ClientConnectorError:
        response_from_db = None

    if not response_from_db or response_from_db == "Internal Server Error":
        db_response_message = "No connection to database"
    else:
        db_response_message = f"There are {response_from_db} entries in the database"

    content = f"""
    <body>
    <h2>{db_response_message}</h2>
    <h2>Use this form to upload files to S3 bucket</h2>
    <form action="/upload" enctype="multipart/form-data" method="post">
    <input name="upload_file" type="file">
    <input type="submit">
    </form>
    </body>
    """
    return HTMLResponse(content=content)
