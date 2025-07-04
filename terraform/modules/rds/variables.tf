variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "coffeeshop"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "owner_name" {
  description = "Owner name for resource tagging"
  type        = string
}

variable "expiry_date" {
  description = "Expiry date for temporary resources"
  type        = string
  default     = "2025-07-15"
} 