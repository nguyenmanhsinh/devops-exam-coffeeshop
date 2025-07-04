terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"
  
  environment          = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  owner_name          = var.owner_name
  expiry_date         = var.expiry_date
}

module "iam" {
  source = "../../modules/iam"
  
  environment = var.environment
  owner_name  = var.owner_name
  expiry_date = var.expiry_date
}

module "eks" {
  source = "../../modules/eks"
  
  environment        = var.environment
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_node_role_arn
  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids
  kms_key_arn        = module.iam.kms_key_arn
  owner_name         = var.owner_name
  expiry_date        = var.expiry_date
}

module "rds" {
  source = "../../modules/rds"
  
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  vpc_cidr_block = module.vpc.vpc_cidr_block
  owner_name     = var.owner_name
  expiry_date    = var.expiry_date
} 