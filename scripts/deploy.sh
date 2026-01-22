#!/bin/bash

set -e

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
ECR_REPOSITORY=${ECR_REPOSITORY:-"ehes-dashboard"}
EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME:-"ehes-cluster"}
K8S_NAMESPACE=${K8S_NAMESPACE:-"ehes-app"}

echo "🚀 Starting deployment process..."

# Check if required tools are installed
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm is not installed. Aborting." >&2; exit 1; }

# Build and push Docker image
echo "📦 Building Docker image..."
docker build -t $ECR_REPOSITORY:latest .

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Tag and push image
IMAGE_TAG=$(git rev-parse --short HEAD)
echo "🏷️  Tagging image as $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
docker tag $ECR_REPOSITORY:latest $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

# Update kubeconfig
echo "⚙️  Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Create namespace if it doesn't exist
echo "📋 Creating namespace..."
kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Verify database secrets exist
echo "🔍 Checking database secrets..."
if ! kubectl get secret ehes-secrets -n $K8S_NAMESPACE >/dev/null 2>&1; then
    echo "❌ Database secrets not found. Please create k8s/secrets.yaml first."
    echo "💡 Run: kubectl apply -f k8s/secrets.yaml"
    exit 1
fi

# Deploy using Helm
echo "🎯 Deploying application with Helm..."
helm upgrade --install ehes-dashboard ./k8s/helm-chart \
  --namespace $K8S_NAMESPACE \
  --set image.repository=$ECR_REGISTRY/$ECR_REPOSITORY \
  --set image.tag=$IMAGE_TAG \
  --set ingress.host=your-domain.com \
  --wait \
  --timeout=10m

# Health check
echo "🏥 Running health check..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ehes-dashboard -n $K8S_NAMESPACE --timeout=300s

# Get deployment status
echo "📊 Deployment status:"
kubectl get pods -n $K8S_NAMESPACE -l app.kubernetes.io/name=ehes-dashboard

# Get the load balancer URL
echo "🌐 Getting service URL..."
SERVICE_URL=$(kubectl get service ehes-dashboard-service -n $K8S_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -n "$SERVICE_URL" ]; then
    echo "✅ Deployment successful!"
    echo "📡 Application is available at: http://$SERVICE_URL"
else
    echo "⏳ Waiting for LoadBalancer to be provisioned..."
    echo "Run 'kubectl get service ehes-dashboard-service -n $K8S_NAMESPACE' to check status"
fi

echo "🎉 Deployment completed!"
