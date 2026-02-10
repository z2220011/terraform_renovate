provider "aws" {
  region = "ap-northeast-1"
}

module "dev_s3" {
  source      = "../../modules/s3_bucket"

  bucket_name = "s3-z2220011-dev-20251229"
  env_name    = "dev"
}
