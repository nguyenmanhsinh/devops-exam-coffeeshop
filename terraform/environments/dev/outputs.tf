output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ec2_instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = module.rds.db_secret_arn
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.iam.ecr_repository_urls
}

output "db_connection_string" {
  description = "PostgreSQL connection string"
  value       = module.rds.db_connection_string
  sensitive   = true
}

output "db_dsn_string" {
  description = "PostgreSQL DSN string"
  value       = module.rds.db_dsn_string
  sensitive   = true
} 