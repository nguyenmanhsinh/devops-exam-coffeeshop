# Detailed Deployment Guide - Coffee Shop Application

This guide provides step-by-step instructions to deploy the Coffee Shop application for the DevOps final examination.

## Table of Contents
1. [Prerequisites Setup](#prerequisites-setup)
2. [AWS Account Preparation](#aws-account-preparation)
3. [Development Environment Deployment](#development-environment-deployment)
4. [Production Environment Deployment](#production-environment-deployment)
5. [CI/CD Pipeline Setup](#cicd-pipeline-setup)
6. [Monitoring Setup](#monitoring-setup)
7. [Verification Steps](#verification-steps)
8. [Clean Up](#clean-up)

## Prerequisites Setup

### 1. Install Required Tools

#### AWS CLI
```bash
# On Linux/Mac
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

#### Terraform
```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version
```

#### kubectl
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

#### Helm
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

### 2. Configure AWS Credentials

```bash
aws configure
# AWS Access Key ID [None]: YOUR_ACCESS_KEY
# AWS Secret Access Key [None]: YOUR_SECRET_KEY
# Default region name [None]: us-west-2
# Default output format [None]: json
```

## AWS Account Preparation

### 1. Create EC2 Key Pair

```bash
# Create key pair
aws ec2 create-key-pair --key-name devops-exam-keypair-snguyen --query 'KeyMaterial' --output text > devops-exam-keypair-snguyen.pem

# Set proper permissions
chmod 400 devops-exam-keypair-snguyen.pem
```

### 2. Verify AWS Permissions

Ensure your AWS user has the following permissions:
- EC2 Full Access
- VPC Full Access
- EKS Full Access
- RDS Full Access
- Secrets Manager Full Access
- IAM Create Roles
- S3 Bucket Creation
- DynamoDB Table Creation

## Development Environment Deployment

### Step 1: Deploy Infrastructure

```bash
# Navigate to project directory
cd devops-exam

# Run infrastructure deployment script
./scripts/deploy-infrastructure.sh dev
```

The script will:
1. Create S3 bucket for Terraform state
2. Create DynamoDB table for state locking
3. Initialize Terraform
4. Create a `terraform.tfvars` template (if not exists)

### Step 2: Configure Variables

Edit `terraform/environments/dev/terraform.tfvars`:
```hcl
aws_region = "us-west-2"
key_name = "devops-exam-keypair-snguyen"
environment = "dev-exam-snguyen"
owner_name = "snguyen"
```

### Step 3: Apply Infrastructure

```bash
# Re-run the deployment script
./scripts/deploy-infrastructure.sh dev

# When prompted, review the plan and type 'yes' to confirm
```

### Step 4: Note the Outputs

After successful deployment, note:
- EC2 Instance Public IP
- RDS Endpoint
- ECR Repository URLs

### Step 5: Deploy Application

```bash
# Get EC2 IP from Terraform output
EC2_IP=$(cd terraform/environments/dev && terraform output -raw ec2_instance_public_ip)

# Deploy application
./scripts/setup-dev.sh $EC2_IP devops-exam-keypair-snguyen.pem
```

### Step 6: Verify Deployment

Access the application:
- Web Application: `http://<EC2_IP>:8888`
- RabbitMQ Management: `http://<EC2_IP>:15672`
  - Username: `admin`
  - Password: `admin123`

## Production Environment Deployment

### Step 1: Deploy Infrastructure

```bash
# Deploy production infrastructure
./scripts/deploy-infrastructure.sh prod
```

### Step 2: Configure Variables

Edit `terraform/environments/prod/terraform.tfvars`:
```hcl
aws_region = "us-west-2"
environment = "prod-exam-snguyen"
owner_name = "snguyen"
```

### Step 3: Apply Infrastructure

```bash
# Re-run the deployment script
./scripts/deploy-infrastructure.sh prod

# Review and confirm the plan
```

### Step 4: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --name prod-exam-snguyen-eks-cluster --region us-west-2

# Verify connection
kubectl cluster-info
```

### Step 5: Deploy Kubernetes Resources

```bash
# Run Kubernetes deployment script
./scripts/deploy-kubernetes.sh prod-exam-snguyen-eks-cluster us-west-2
```

This will:
1. Install AWS Load Balancer Controller
2. Install External Secrets Operator
3. Deploy all application services
4. Configure Horizontal Pod Autoscaling
5. Set up Ingress
6. Install Prometheus and Grafana

### Step 6: Get Application URL

```bash
# Get Load Balancer URL (may take 5-10 minutes to provision)
kubectl get ingress coffeeshop-ingress -n coffeeshop

# Get Grafana URL
kubectl get svc kube-prometheus-stack-grafana -n monitoring
```

## CI/CD Pipeline Setup

### Step 1: Fork Repository

1. Fork this repository to your GitHub account
2. Clone your forked repository

### Step 2: Set GitHub Secrets

In your GitHub repository, go to Settings > Secrets and add:

```yaml
AWS_ACCESS_KEY_ID: <your-access-key>
AWS_SECRET_ACCESS_KEY: <your-secret-key>
AWS_ACCOUNT_ID: <your-account-id>
DEV_EC2_INSTANCE_ID: <from-terraform-output>
```

### Step 3: Create Branches

```bash
# Create develop branch
git checkout -b develop
git push origin develop
```

### Step 4: Test Pipeline

Make a small change and push:
```bash
# To dev
git checkout develop
echo "test" >> test.txt
git add . && git commit -m "Test CI/CD"
git push origin develop

# To prod
git checkout main
git merge develop
git push origin main
```

## Monitoring Setup

### Step 1: Access Grafana

```bash
# Get Grafana URL
GRAFANA_URL=$(kubectl get svc kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Grafana URL: http://$GRAFANA_URL"
# Username: admin
# Password: admin123
```

### Step 2: Import Dashboards

1. Log into Grafana
2. Go to Dashboards > Import
3. Import these dashboard IDs:
   - 15172 (Kubernetes cluster monitoring)
   - 12740 (Kubernetes pod metrics)
   - 11454 (Kubernetes resource usage)

### Step 3: Configure Alerts

Alerts are automatically configured for:
- HPA reaching maximum replicas
- High CPU/Memory usage (>90%)
- 5xx errors
- ELB request anomalies

## Verification Steps

### Development Environment

```bash
# SSH to EC2
ssh -i devops-exam-keypair-snguyen.pem ubuntu@<EC2_IP>

# Check Docker containers
docker-compose ps

# View logs
docker-compose logs -f

# Test application endpoints
curl http://localhost:8888/health
```

### Production Environment

```bash
# Check pods
kubectl get pods -n coffeeshop

# Check services
kubectl get svc -n coffeeshop

# Check HPA
kubectl get hpa -n coffeeshop

# View pod logs
kubectl logs -f deployment/web -n coffeeshop

# Check ingress
kubectl describe ingress coffeeshop-ingress -n coffeeshop
```

## Clean Up

### Development Environment

```bash
cd terraform/environments/dev
terraform destroy -auto-approve
```

### Production Environment

```bash
# Delete Kubernetes resources
kubectl delete namespace coffeeshop
kubectl delete namespace monitoring
kubectl delete namespace external-secrets-system

# Destroy infrastructure
cd terraform/environments/prod
terraform destroy -auto-approve
```

### Clean S3 and DynamoDB

```bash
# Delete S3 bucket
aws s3 rb s3://devops-exam-terraform-state --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-state-lock
```

## Troubleshooting

### Issue: Terraform state lock
```bash
# Force unlock
terraform force-unlock <LOCK_ID>
```

### Issue: EKS nodes not joining
```bash
# Check node logs
kubectl describe nodes
aws eks describe-nodegroup --cluster-name prod-exam-snguyen-eks-cluster --nodegroup-name prod-node-group
```

### Issue: Pods in CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n coffeeshop --previous

# Check events
kubectl get events -n coffeeshop --sort-by='.lastTimestamp'
```

### Issue: Load Balancer not accessible
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check target health
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

## Support

For additional help:
1. Check AWS CloudWatch logs
2. Review Terraform state: `terraform show`
3. Check Kubernetes events: `kubectl get events --all-namespaces`
4. Review pod descriptions: `kubectl describe pod <pod-name> -n coffeeshop` 