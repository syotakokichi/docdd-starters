# Production Environment

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "PROJECT_NAME-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "PROJECT_NAME-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

module "network" {
  source       = "../../modules/network"
  project_name = var.project_name
  environment  = "prod"
}

module "ecs" {
  source                  = "../../modules/ecs"
  project_name            = var.project_name
  environment             = "prod"
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  alb_security_group_id   = module.network.alb_security_group_id
  ecr_repository_backend  = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-backend"
  ecr_repository_frontend = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-frontend"
  backend_cpu             = 512
  backend_memory          = 1024
  frontend_cpu            = 512
  frontend_memory         = 1024
  backend_desired_count   = 2
  frontend_desired_count  = 2
}

module "rds" {
  source                  = "../../modules/rds"
  project_name            = var.project_name
  environment             = "prod"
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  ecs_security_group_id   = module.ecs.cluster_id
  instance_class          = "db.t3.small"
  allocated_storage       = 50
  backup_retention_period = 14
  db_password             = var.db_password
}

module "secrets" {
  source       = "../../modules/secrets"
  project_name = var.project_name
  environment  = "prod"
  db_password  = var.db_password
  db_host      = module.rds.endpoint
}

module "monitoring" {
  source       = "../../modules/monitoring"
  project_name = var.project_name
  environment  = "prod"
}

module "cloudfront" {
  source              = "../../modules/cloudfront"
  project_name        = var.project_name
  environment         = "prod"
  alb_dns_name        = module.network.alb_dns_name
  domain_aliases      = var.domain_aliases
  acm_certificate_arn = var.acm_certificate_arn
}
