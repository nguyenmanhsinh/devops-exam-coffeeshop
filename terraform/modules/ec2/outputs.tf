output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.dev.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.dev.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.dev.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.dev_instance.id
} 