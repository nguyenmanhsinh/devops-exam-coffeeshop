resource "aws_security_group" "dev_instance" {
  name        = "${var.environment}-dev-instance-sg"
  description = "Security group for dev instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Web"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RabbitMQ Management"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-dev-instance-sg"
    Environment = var.environment
    Owner       = var.owner_name
    Temporary   = "true"
    ExpiryDate  = var.expiry_date
  }
}

resource "aws_instance" "dev" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name              = var.key_name
  vpc_security_group_ids = [aws_security_group.dev_instance.id]
  subnet_id              = var.subnet_id

  user_data = templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.environment}-dev-instance"
    Environment = var.environment
    Owner       = var.owner_name
    Temporary   = "true"
    ExpiryDate  = var.expiry_date
  }
} 