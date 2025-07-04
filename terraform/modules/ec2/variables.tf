variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-05f991c49d264708f" # Ubuntu 24.04 LTS in us-west-2 (updated)
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
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