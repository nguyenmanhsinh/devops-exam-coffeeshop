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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# All placeholders have been replaced with snguyen

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Get environment parameter
ENVIRONMENT=${1:-dev}
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment. Use 'dev' or 'prod'"
    exit 1
fi

print_info "Deploying infrastructure for $ENVIRONMENT environment"

# Change to terraform directory
cd terraform

# Create S3 bucket for Terraform state if it doesn't exist
BUCKET_NAME="devops-exam-terraform-state-snguyen"
REGION="us-west-2"

if ! aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    print_info "Creating S3 bucket for Terraform state..."
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled --region "$REGION"
    aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' --region "$REGION"
fi

# Create DynamoDB table for state locking if it doesn't exist
TABLE_NAME="terraform-state-lock-snguyen"

if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
    print_info "Creating DynamoDB table for state locking..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION"
fi

# Initialize Terraform with backend configuration
print_info "Initializing Terraform..."
terraform init -backend-config="bucket=$BUCKET_NAME" \
               -backend-config="key=$ENVIRONMENT/terraform.tfstate" \
               -backend-config="region=$REGION" \
               -backend-config="dynamodb_table=$TABLE_NAME"

# Change to environment directory
cd environments/$ENVIRONMENT

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    print_warning "terraform.tfvars not found. Creating template..."
    cat > terraform.tfvars <<EOF
# AWS Configuration
aws_region = "us-west-2"

# EC2 Key Pair Name (create this in AWS Console first)
key_name = "devops-exam-keypair-snguyen"

# Environment
environment = "$ENVIRONMENT-exam-snguyen"

# Owner name for tagging
owner_name = "snguyen"

# Expiry date for resources
expiry_date = "2024-12-31"
EOF
    print_info "terraform.tfvars created. Please review before proceeding."
    exit 0
fi

# Initialize environment
print_info "Initializing $ENVIRONMENT environment..."
terraform init

# Create workspace if it doesn't exist
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    print_info "Creating workspace $ENVIRONMENT..."
    terraform workspace new "$ENVIRONMENT"
else
    print_info "Selecting workspace $ENVIRONMENT..."
    terraform workspace select "$ENVIRONMENT"
fi

# Plan the deployment
print_info "Planning Terraform deployment..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "Do you want to apply this plan? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Apply the deployment
print_info "Applying Terraform deployment..."
terraform apply tfplan

# Save outputs
print_info "Saving outputs..."
terraform output -json > outputs.json

print_info "Infrastructure deployment completed successfully!"

# Print important outputs
if [[ "$ENVIRONMENT" == "dev" ]]; then
    EC2_IP=$(terraform output -raw ec2_instance_public_ip 2>/dev/null || echo "N/A")
    print_info "Dev EC2 Instance IP: $EC2_IP"
    print_info "You can SSH using: ssh -i your-key.pem ubuntu@$EC2_IP"
else
    EKS_CLUSTER=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "N/A")
    print_info "EKS Cluster Name: $EKS_CLUSTER"
    print_info "Update kubeconfig: aws eks update-kubeconfig --name $EKS_CLUSTER --region $REGION"
fi 