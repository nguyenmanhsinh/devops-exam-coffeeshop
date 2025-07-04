#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get EC2 instance details
EC2_IP=$1
KEY_PATH=$2

if [[ -z "$EC2_IP" || -z "$KEY_PATH" ]]; then
    print_error "Usage: $0 <EC2_IP> <PATH_TO_KEY>"
    print_error "Example: $0 52.x.x.x devops-exam-keypair-john.pem"
    exit 1
fi

print_info "Setting up dev environment on EC2 instance: $EC2_IP"

# Copy docker-compose file to EC2
print_info "Copying docker-compose.yml to EC2 instance..."
scp -i "$KEY_PATH" -o StrictHostKeyChecking=no docker/docker-compose.yml ubuntu@"$EC2_IP":/home/ubuntu/coffee-shop/

# Copy deployment script
print_info "Creating deployment script on EC2..."
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@"$EC2_IP" << 'EOF'
cd /home/ubuntu/coffee-shop

# Create .env file for environment variables
cat > .env << 'ENVFILE'
POSTGRES_PASSWORD=coffeeshop_pass123
RABBITMQ_DEFAULT_PASS=coffeeshop_pass123
ENVFILE

# Pull latest images
echo "Pulling Docker images..."
docker-compose pull

# Start services
echo "Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
sleep 30

# Check service status
docker-compose ps

# Show logs
echo "Showing recent logs..."
docker-compose logs

echo "Dev environment setup completed!"
echo "Application URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8888"
echo "RabbitMQ Management: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):15672"
echo "RabbitMQ credentials - Username: coffeeshop_user, Password: coffeeshop_pass123"
EOF

print_info "Dev environment setup completed!"
print_info "Application URL: http://$EC2_IP:8888"
print_info "RabbitMQ Management: http://$EC2_IP:15672" 