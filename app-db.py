import os

import mysql.connector
from dotenv import load_dotenv
from fastapi import FastAPI

load_dotenv()

DB_SETTINGS = {
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
    "database": os.getenv("DB_NAME"),
}

DB_QUERY = "SELECT * FROM Users"

app = FastAPI()


def get_users():
    cnx = mysql.connector.connect(**DB_SETTINGS)
    cursor = cnx.cursor(dictionary=True)
    cursor.execute(DB_QUERY)
    result = cursor.fetchall()
    cnx.close()
    return result


@app.get("/")
async def root():
    return get_users()


@app.get("/getNoOfRecs")
async def get_no_of_recs():
    return len(get_users())
