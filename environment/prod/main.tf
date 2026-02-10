provider "aws" {
  region = "ap-northeast-1"
}

module "prod_s3" {
  source      = "../../modules/s3_bucket"
  
  bucket_name = "s3-z2220011-prod-20251229"
  env_name    = "prod"
}