#!/bin/bash

set -e

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME:-"ehes-cluster"}
ECR_REPOSITORY=${ECR_REPOSITORY:-"ehes-dashboard"}

echo "🔧 Setting up AWS infrastructure..."

# Check if AWS CLI is installed
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is not installed. Aborting." >&2; exit 1; }

# Create ECR repository
echo "📦 Creating ECR repository..."
aws ecr create-repository \
    --repository-name $ECR_REPOSITORY \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --image-tag-mutability MUTABLE || echo "ECR repository already exists"

# Create EKS cluster (if it doesn't exist)
echo "☸️  Creating EKS cluster..."
if ! aws eks describe-cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION >/dev/null 2>&1; then
    aws eks create-cluster \
        --name $EKS_CLUSTER_NAME \
        --region $AWS_REGION \
        --kubernetes-version 1.28 \
        --nodegroup-name standard-workers \
        --node-type t3.medium \
        --nodes 2 \
        --nodes-min 1 \
        --nodes-max 4 \
        --managed \
        --with-oidc \
        --alb-ingress-mode \
        --logging clusterApi,audit,authenticator,controllerManager,scheduler || echo "EKS cluster creation initiated"
    
    echo "⏳ Waiting for EKS cluster to be ready..."
    aws eks wait cluster-active --name $EKS_CLUSTER_NAME --region $AWS_REGION
else
    echo "EKS cluster already exists"
fi

# Update kubeconfig
echo "⚙️  Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Install required addons
echo "🔌 Installing EKS addons..."
aws eks create-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --addon-name vpc-cni \
    --addon-version v1.14.1-eksbuild.1 \
    --region $AWS_REGION || echo "VPC CNI addon already exists"

aws eks create-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --addon-name coredns \
    --addon-version v1.10.1-eksbuild.5 \
    --region $AWS_REGION || echo "CoreDNS addon already exists"

aws eks create-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --addon-name kube-proxy \
    --addon-version v1.28.2-eksbuild.1 \
    --region $AWS_REGION || echo "Kube-proxy addon already exists"

# Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.publishService.enabled=true

# Install cert-manager for SSL certificates
echo "🔒 Installing cert-manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.13.2 \
    --set installCRDs=true

# Create IAM OIDC provider (if not exists)
echo "🔑 Setting up IAM OIDC provider..."
aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text
OIDC_PROVIDER=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

if ! aws iam list-open-id-connect-providers | grep -q $OIDC_PROVIDER; then
    aws iam create-open-id-connect-provider \
        --url https://$OIDC_PROVIDER \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 9e99a48a9960b14926bb7f3b02e22da2b0ab7280
fi

echo "✅ AWS infrastructure setup completed!"
echo "📋 Next steps:"
echo "1. Update your domain DNS to point to the LoadBalancer"
echo "2. Update secrets in k8s/secrets.yaml"
echo "3. Run ./scripts/deploy.sh to deploy your application"
