#!/bin/bash

set -e

# Configuration
EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME:-"ehes-cluster"}
K8S_NAMESPACE=${K8S_NAMESPACE:-"ehes-app"}
ECR_REPOSITORY=${ECR_REPOSITORY:-"ehes-dashboard"}

echo "🧹 Cleaning up AWS resources..."

# Check if required tools are installed
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm is not installed. Aborting." >&2; exit 1; }

# Uninstall Helm chart
echo "🗑️  Uninstalling Helm chart..."
helm uninstall ehes-dashboard --namespace $K8S_NAMESPACE || echo "Helm release not found"

# Delete namespace
echo "📋 Deleting namespace..."
kubectl delete namespace $K8S_NAMESPACE || echo "Namespace not found"

# Delete EKS cluster
echo "☸️  Deleting EKS cluster..."
if aws eks describe-cluster --name $EKS_CLUSTER_NAME >/dev/null 2>&1; then
    aws eks delete-cluster --name $EKS_CLUSTER_NAME
    echo "⏳ Waiting for EKS cluster to be deleted..."
    aws eks wait cluster-deleted --name $EKS_CLUSTER_NAME
else
    echo "EKS cluster not found"
fi

# Delete ECR repository
echo "📦 Deleting ECR repository..."
aws ecr delete-repository --repository-name $ECR_REPOSITORY --force || echo "ECR repository not found"

# Uninstall NGINX Ingress Controller
echo "🌐 Uninstalling NGINX Ingress Controller..."
helm uninstall ingress-nginx --namespace ingress-nginx || echo "NGINX Ingress not found"

# Uninstall cert-manager
echo "🔒 Uninstalling cert-manager..."
helm uninstall cert-manager --namespace cert-manager || echo "cert-manager not found"

echo "✅ Cleanup completed!"
