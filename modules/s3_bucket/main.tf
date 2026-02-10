resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name # 環境ごとに名前を変えられるように変数にする

  tags = {
    Environment = var.env_name
  }
}

# バケットの所有権設定（セキュリティの基本）
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 公開アクセスのブロック（実務で必須の設定）
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}