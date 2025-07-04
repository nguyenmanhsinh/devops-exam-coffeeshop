variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecr_repositories" {
  description = "List of ECR repository names"
  type        = list(string)
  default = [
    "coffeeshop-web",
    "coffeeshop-proxy",
    "coffeeshop-barista",
    "coffeeshop-kitchen",
    "coffeeshop-counter",
    "coffeeshop-product"
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