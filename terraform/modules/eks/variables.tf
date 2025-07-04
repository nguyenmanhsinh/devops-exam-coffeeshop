variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of the EKS cluster role"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the EKS node role"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS cluster"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for node groups"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "instance_type" {
  description = "Instance type for nodes"
  type        = string
  default     = "t3.micro"
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "eks_addons" {
  description = "EKS add-ons"
  type = list(object({
    name    = string
    version = string
  }))
  default = [
    {
      name    = "vpc-cni"
      version = "v1.15.3-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.10.1-eksbuild.5"
    },
    {
      name    = "kube-proxy"
      version = "v1.28.2-eksbuild.2"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.26.0-eksbuild.1"
    }
  ]
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