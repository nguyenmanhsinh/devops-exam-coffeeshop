variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev-exam-snguyen"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["172.16.10.0/24", "172.16.20.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "key_name" {
  description = "EC2 Key pair name"
  type        = string
}

variable "owner_name" {
  description = "Owner name for resource tagging"
  type        = string
  default     = "snguyen"
}

variable "expiry_date" {
  description = "Expiry date for temporary resources"
  type        = string
  default     = "2025-07-15"
} 