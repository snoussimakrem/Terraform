# LocalStack S3 backend. `use_lockfile` = native S3 locking (Terraform >= 1.10): a <key>.tflock
# object is created with a conditional write, so no DynamoDB table is needed any more.
bucket                      = "tfstate-platform-local"
region                      = "us-east-1"
encrypt                     = true
use_lockfile                = true
use_path_style              = true
skip_credentials_validation = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
skip_region_validation      = true
endpoints                   = { s3 = "http://localhost:4566" }
