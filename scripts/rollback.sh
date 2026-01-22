#!/bin/bash

set -e

# Configuration
K8S_NAMESPACE=${K8S_NAMESPACE:-"ehes-app"}

echo "🔄 Rolling back deployment..."

# Check if required tools are installed
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm is not installed. Aborting." >&2; exit 1; }

# Get deployment history
echo "📜 Deployment history:"
helm history ehes-dashboard -n $K8S_NAMESPACE

# Ask for revision to rollback to
echo "Enter revision number to rollback to (or press Enter for previous revision):"
read REVISION

if [ -z "$REVISION" ]; then
    # Rollback to previous revision
    echo "🔄 Rolling back to previous revision..."
    helm rollback ehes-dashboard -n $K8S_NAMESPACE
else
    # Rollback to specific revision
    echo "🔄 Rolling back to revision $REVISION..."
    helm rollback ehes-dashboard $REVISION -n $K8S_NAMESPACE
fi

# Wait for rollout to complete
echo "⏳ Waiting for rollback to complete..."
kubectl rollout status deployment/ehes-dashboard -n $K8S_NAMESPACE --timeout=300s

# Get pod status
echo "📊 Pod status after rollback:"
kubectl get pods -n $K8S_NAMESPACE -l app.kubernetes.io/name=ehes-dashboard

echo "✅ Rollback completed!"
