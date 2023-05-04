# devops-upskill

## Highly available AWS infrastructure described with Terraform to host two dummy apps, created to practice AWS and Terraform.

### Running apps locally/ manually:

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

`uvicorn src/app-db:app --port 8000 --reload`

`uvicorn src/app-s3:app --port 8001 --reload`

### Running with terraform:

Create an ssh key pair:

`ssh-keygen -t rsa -b 4096`

Export env vars for storing the state file:

`export TFSTATE_BUCKET=xxx && export TFSTATE_KEY=xxx && export TFSTATE_REGION=xxx`

Example `terraforms.tfvars` (alternatively export them as env vars too as `TFVAR_OWNER`, etc.)
```
owner       = "me"
region      = "us-west-2"
db_user     = "user"
db_password = "pass"
db_name     = "USERS"
public_key  = "PASTE_YOUR_PUBLIC_KEY_HERE"
```

Run with `./ci-terraform-apply.sh`
