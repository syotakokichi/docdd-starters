variable "project_name" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "aws_account_id" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
