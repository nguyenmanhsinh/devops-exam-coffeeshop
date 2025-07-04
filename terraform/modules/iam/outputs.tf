output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node role"
  value       = aws_iam_role.eks_node.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key for EKS"
  value       = aws_kms_key.eks.arn
}

output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = { for repo in aws_ecr_repository.app_repos : repo.name => repo.repository_url }
} 