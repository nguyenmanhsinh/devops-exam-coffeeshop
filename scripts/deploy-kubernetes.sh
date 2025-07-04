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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install it first."
    exit 1
fi

# Get cluster name
CLUSTER_NAME=${1:-prod-exam-snguyen-eks-cluster}
REGION=${2:-us-west-2}

print_info "Deploying to EKS cluster: $CLUSTER_NAME"

# Update kubeconfig
print_info "Updating kubeconfig..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# Verify connection
print_info "Verifying cluster connection..."
kubectl cluster-info

# Install AWS Load Balancer Controller
print_info "Installing AWS Load Balancer Controller..."
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Install External Secrets Operator
print_info "Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace \
  --set installCRDs=true

# Wait for External Secrets to be ready
kubectl wait --for=condition=available --timeout=300s deployment/external-secrets-webhook -n external-secrets-system

# Deploy application
print_info "Deploying application to Kubernetes..."

# Create namespace
kubectl apply -f kubernetes/base/namespace.yaml

# Create secrets
kubectl apply -f kubernetes/base/secrets.yaml

# Deploy RabbitMQ
kubectl apply -f kubernetes/base/rabbitmq.yaml

# Wait for RabbitMQ to be ready
print_info "Waiting for RabbitMQ to be ready..."
kubectl wait --for=condition=ready pod -l app=rabbitmq -n coffeeshop --timeout=300s

# Deploy services in order
print_info "Deploying Product service..."
kubectl apply -f kubernetes/base/product-service.yaml

print_info "Deploying Counter service..."
kubectl apply -f kubernetes/base/counter-service.yaml

# Wait for Product and Counter to be ready
kubectl wait --for=condition=available deployment/product -n coffeeshop --timeout=300s
kubectl wait --for=condition=available deployment/counter -n coffeeshop --timeout=300s

# Deploy remaining services
print_info "Deploying remaining services..."
kubectl apply -f kubernetes/base/barista-service.yaml
kubectl apply -f kubernetes/base/kitchen-service.yaml
kubectl apply -f kubernetes/base/proxy-service.yaml
kubectl apply -f kubernetes/base/web-service.yaml

# Apply HPA
print_info "Applying Horizontal Pod Autoscaling..."
kubectl apply -f kubernetes/base/hpa.yaml

# Apply Network Policies
print_info "Applying Network Policies..."
kubectl apply -f kubernetes/base/network-policy.yaml

# Apply Ingress
print_info "Applying Ingress..."
kubectl apply -f kubernetes/base/ingress.yaml

# Install Prometheus and Grafana
print_info "Installing Prometheus and Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f monitoring/prometheus-values.yaml

# Apply custom alerts
kubectl apply -f monitoring/custom-alerts.yaml

# Wait for all deployments to be ready
print_info "Waiting for all deployments to be ready..."
kubectl wait --for=condition=available deployment --all -n coffeeshop --timeout=600s

# Get Load Balancer URL
print_info "Getting application URL..."
INGRESS_URL=$(kubectl get ingress coffeeshop-ingress -n coffeeshop -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

if [[ "$INGRESS_URL" == "pending" ]]; then
    print_warning "Ingress URL is not ready yet. Check again with:"
    print_warning "kubectl get ingress coffeeshop-ingress -n coffeeshop"
else
    print_info "Application URL: http://$INGRESS_URL"
fi

# Get Grafana URL
GRAFANA_URL=$(kubectl get svc kube-prometheus-stack-grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

if [[ "$GRAFANA_URL" != "pending" ]]; then
    print_info "Grafana URL: http://$GRAFANA_URL"
    print_info "Grafana credentials - Username: admin, Password: admin123"
fi

print_info "Kubernetes deployment completed successfully!" 