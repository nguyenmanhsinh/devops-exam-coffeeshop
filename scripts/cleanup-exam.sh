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

# Confirmation
print_warning "This script will destroy ALL exam resources in AWS!"
print_warning "This includes EC2 instances, EKS clusters, RDS databases, and more."
read -p "Are you sure you want to continue? Type 'yes' to confirm: " confirm

if [[ "$confirm" != "yes" ]]; then
    print_info "Cleanup cancelled."
    exit 0
fi

# Second confirmation for safety
read -p "This action is IRREVERSIBLE. Type 'DELETE' to proceed: " confirm2

if [[ "$confirm2" != "DELETE" ]]; then
    print_info "Cleanup cancelled."
    exit 0
fi

print_info "Starting cleanup process..."

# Set variables
REGION="us-west-2"
BUCKET_NAME="devops-exam-terraform-state-snguyen"
TABLE_NAME="terraform-state-lock-snguyen"

# Destroy Kubernetes resources if kubectl is configured
if command -v kubectl &> /dev/null; then
    print_info "Removing Kubernetes resources..."
    kubectl delete namespace coffeeshop --ignore-not-found=true
    kubectl delete namespace monitoring --ignore-not-found=true
    kubectl delete namespace external-secrets-system --ignore-not-found=true
else
    print_warning "kubectl not found, skipping Kubernetes cleanup"
fi

# Destroy Terraform resources
if command -v terraform &> /dev/null; then
    # Destroy production environment
    if [ -d "terraform/environments/prod" ]; then
        print_info "Destroying production environment..."
        cd terraform/environments/prod
        terraform init -backend-config="bucket=$BUCKET_NAME" \
                      -backend-config="key=prod/terraform.tfstate" \
                      -backend-config="region=$REGION" \
                      -backend-config="dynamodb_table=$TABLE_NAME" || true
        terraform workspace select prod || true
        terraform destroy -auto-approve || true
        cd ../../..
    fi

    # Destroy development environment
    if [ -d "terraform/environments/dev" ]; then
        print_info "Destroying development environment..."
        cd terraform/environments/dev
        terraform init -backend-config="bucket=$BUCKET_NAME" \
                      -backend-config="key=dev/terraform.tfstate" \
                      -backend-config="region=$REGION" \
                      -backend-config="dynamodb_table=$TABLE_NAME" || true
        terraform workspace select dev || true
        terraform destroy -auto-approve || true
        cd ../../..
    fi
else
    print_error "Terraform not found! Manual cleanup required."
fi

# Clean up S3 bucket
print_info "Cleaning up S3 bucket..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    aws s3 rm s3://$BUCKET_NAME --recursive --region "$REGION"
    aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    print_info "S3 bucket deleted"
else
    print_warning "S3 bucket not found or already deleted"
fi

# Clean up DynamoDB table
print_info "Cleaning up DynamoDB table..."
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
    aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$REGION"
    print_info "DynamoDB table deleted"
else
    print_warning "DynamoDB table not found or already deleted"
fi

# Clean up key pair
KEY_NAME="devops-exam-keypair-snguyen"
print_info "Cleaning up EC2 key pair..."
aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$REGION" || true

# List any remaining resources with our tags
print_info "Checking for remaining resources..."
print_info "EC2 instances with our tags:"
aws ec2 describe-instances --filters "Name=tag:Temporary,Values=true" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table --region "$REGION"

print_info "VPCs with our tags:"
aws ec2 describe-vpcs --filters "Name=tag:Temporary,Values=true" --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table --region "$REGION"

print_success() {
    echo -e "${GREEN}✅ Cleanup completed!${NC}"
}

print_success
print_info "Please verify in the AWS Console that all resources have been removed."
print_info "Check especially for:"
print_info "  - EC2 instances"
print_info "  - EKS clusters"
print_info "  - RDS databases"
print_info "  - VPCs and subnets"
print_info "  - Security groups"
print_info "  - IAM roles (may need manual cleanup)"
print_info "  - ECR repositories (may need manual cleanup)"

# Remove local files
print_info "Removing local state files..."
rm -f terraform/environments/*/outputs.json
rm -f terraform/environments/*/.terraform.lock.hcl
rm -rf terraform/environments/*/.terraform
rm -f devops-exam-keypair-*.pem

print_info "All done! 🎉" 