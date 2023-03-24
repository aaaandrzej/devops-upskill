# devops-upskill

## Two dummy APIs to practice AWS cloud services.

### Running locally/ manually:

Example `.env` contents:
```
DB_USER=user
DB_PASSWORD=pass
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=USERS

APP_DB_HOST=127.0.0.1
APP_DB_PORT=8000
APP_DB_URL=http://${APP_DB_HOST}:${APP_DB_PORT}/getNoOfRecs
S3_BUCKET_NAME=mybucket
```

`uvicorn app-db:app --port 8000 --reload`

`uvicorn app-s3:app --port 8001 --reload`

### Running with terraform:

Example `terraforms.tfvars`:
```
owner              = "me"
region             = "us-west-2"
availability_zones = ["us-west-2a", "us-west-2b"]
db_user     = "user"
db_password = "pass"
db_name     = "USERS"
```

`cd terraform`

`terraform apply`
