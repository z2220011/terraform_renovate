variable "bucket_name" {
  description = "S3バケットの一意の名前"
  type        = string
}

variable "env_name" {
  description = "環境名 (dev, prodなど)"
  default = "dev"
  type        = string
}