# DevOps Final Examination - Coffee Shop Application

- **Student**: Sinh Nguyen
- **Email**: snguyen@opswat.com
- **Github**: https://github.com/nguyenmanhsinh/devops-exam-coffeeshop

## Summary

This project implements a complete DevOps solution for a microservices-based coffee shop application. The solution includes:

- **Infrastructure as Code (IaC)** using Terraform for AWS resource provisioning
- **Containerization** with Docker and Docker Compose for the development environment
- **Kubernetes deployment** on Amazon EKS for the production environment
- **CI/CD pipeline** using GitHub Actions with security scanning
- **Monitoring and alerting** using Prometheus and Grafana
- **Security best practices** including secrets management, network policies, and encryption

## Architecture

### Overview
The coffee shop application consists of six microservices:
- **Web Service**: Frontend application serving the user interface
- **Proxy Service**: API gateway handling requests between frontend and backend services
- **Product Service**: Manages product catalog
- **Counter Service**: Handles order processing
- **Barista Service**: Manages coffee preparation workflow
- **Kitchen Service**: Handles food preparation workflow

### Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐         ┌──────────────────────┐     │
│  │    Dev Environment   │         │   Prod Environment   │     │
│  │                      │         │                      │     │
│  │  ┌────────────────┐  │         │  ┌────────────────┐  │     │
│  │  │      EC2       │  │         │  │      EKS       │  │     │
│  │  │                │  │         │  │                │  │     │
│  │  │ Docker Compose │  │         │  │  Kubernetes    │  │     │
│  │  │                │  │         │  │                │  │     │
│  │  └────────────────┘  │         │  └────────────────┘  │     │
│  │                      │         │                      │     │
│  └──────────────────────┘         └──────────────────────┘     │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Shared Resources                       │  │
│  │                                                           │  │
│  │  ┌─────────┐  ┌─────────────┐  ┌────────────────────┐  │  │
│  │  │   RDS   │  │   Secrets   │  │       ECR         │  │  │
│  │  │ (PostgreSQL)│  │  Manager  │  │ (Docker Registry) │  │  │
│  │  └─────────┘  └─────────────┘  └────────────────────┘  │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Description

### Infrastructure Components

#### VPC and Networking
- **VPC**: Isolated network for each environment (dev/prod)
- **Subnets**: Public and private subnets across multiple availability zones
- **NAT Gateways**: For outbound internet access from private subnets
- **Security Groups**: Firewall rules for each service

#### Compute Resources
- **Dev Environment**: Single EC2 instance running Docker Compose
- **Prod Environment**: EKS cluster with auto-scaling node groups

#### Data Storage
- **RDS PostgreSQL**: Managed database service with automated backups
- **EBS Volumes**: Persistent storage for Kubernetes stateful sets

#### Security and Secrets
- **AWS Secrets Manager**: Stores database credentials and sensitive data
- **KMS**: Encryption keys for EKS and RDS
- **IAM Roles**: Service-specific permissions following least privilege principle

### Application Components

Each microservice is containerized and follows these patterns:
- Health check endpoints for monitoring
- Environment-based configuration
- Graceful shutdown handling
- Resource limits and requests

## Prerequisites

Before starting the deployment, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Terraform** (version 1.5.0 or higher)
4. **kubectl** (for Kubernetes management)
5. **Helm** (version 3.x)
6. **Docker** and **Docker Compose** (for local testing)
7. **Git** for version control

## User Guidelines

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd devops-exam
```

### Step 2: Set Up AWS Credentials

Configure your AWS credentials:

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region: us-west-2
# Enter default output format: json
```

### Step 3: Create EC2 Key Pair

Create an EC2 key pair for SSH access:

```bash
aws ec2 create-key-pair --key-name devops-exam-keypair-snguyen --query 'KeyMaterial' --output text > devops-exam-keypair-snguyen.pem
chmod 400 devops-exam-keypair-snguyen.pem
```

### Step 4: Deploy Infrastructure

#### Deploy Dev Environment

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy dev infrastructure
./scripts/deploy-infrastructure.sh dev

# Get the EC2 instance IP from the output
# Then set up the dev environment
./scripts/setup-dev.sh <EC2_IP> devops-exam-keypair-snguyen.pem
```

#### Deploy Prod Environment

```bash
# Deploy prod infrastructure
./scripts/deploy-infrastructure.sh prod

# Deploy Kubernetes resources
./scripts/deploy-kubernetes.sh prod-exam-snguyen-eks-cluster us-west-2
```

### Step 5: Set Up CI/CD Pipeline

1. Fork this repository to your GitHub account
2. Add the following secrets to your GitHub repository:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_ACCOUNT_ID`
   - `DEV_EC2_INSTANCE_ID` (from Terraform output)

3. The pipeline will automatically trigger on:
   - Push to `main` branch (deploys to production)
   - Push to `develop` branch (deploys to dev)

### Step 6: Access the Application

#### Dev Environment
- Application: `http://<EC2_IP>:8888`
- RabbitMQ Management: `http://<EC2_IP>:15672`
  - Username: `admin`
  - Password: `admin123`

#### Prod Environment
- Application: Available via the AWS Load Balancer URL
- Grafana Dashboard: Available via the Grafana Load Balancer URL
  - Username: `admin`
  - Password: `admin123`

### Step 7: Monitor the Application

Access Grafana and import the following dashboards:
1. Kubernetes cluster monitoring
2. Application metrics
3. Custom alerts for:
   - HPA max replicas reached
   - High memory/CPU usage
   - 5xx errors
   - ELB request anomalies

## Deployment Commands Reference

### Terraform Commands

```bash
# Initialize Terraform
cd terraform/environments/<env>
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```

### Kubernetes Commands

```bash
# Get pods
kubectl get pods -n coffeeshop

# Get services
kubectl get svc -n coffeeshop

# View logs
kubectl logs -f <pod-name> -n coffeeshop

# Scale deployment
kubectl scale deployment/<app-name> --replicas=3 -n coffeeshop

# Check HPA status
kubectl get hpa -n coffeeshop
```

### Docker Commands (Dev Environment)

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f <service-name>

# Restart service
docker-compose restart <service-name>

# Stop all services
docker-compose down
```

## Troubleshooting

### Common Issues

1. **EKS Node Group not joining cluster**
   - Check IAM roles and policies
   - Verify subnet tags for EKS

2. **Database connection issues**
   - Check RDS security group rules
   - Verify secrets are properly created

3. **Load Balancer not accessible**
   - Wait for ALB provisioning (can take 5-10 minutes)
   - Check security group rules

4. **Pods stuck in Pending state**
   - Check node capacity
   - Verify PVC bindings

## Clean Up

To avoid unnecessary AWS charges, clean up resources when done:

```bash
# Remove Kubernetes resources
kubectl delete namespace coffeeshop
kubectl delete namespace monitoring

# Destroy infrastructure
cd terraform/environments/dev
terraform destroy

cd ../prod
terraform destroy
```

## Security Considerations

1. **Secrets Management**: All sensitive data stored in AWS Secrets Manager
2. **Network Security**: Network policies restrict pod-to-pod communication
3. **Encryption**: Data encrypted at rest (RDS, EBS) and in transit (TLS)
4. **IAM Roles**: Service-specific roles with minimal permissions
5. **Container Security**: Images scanned with Trivy in CI/CD pipeline

## Cost Optimization

- Use t3.micro for RDS (Free tier eligible)
- EKS nodes use t3.small for minimal cost
- Auto-scaling configured to scale down during low usage
- Lifecycle policies for ECR to remove old images

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS CloudWatch logs
3. Check Kubernetes events: `kubectl get events -n coffeeshop`
4. Review GitHub Actions logs for CI/CD issues 