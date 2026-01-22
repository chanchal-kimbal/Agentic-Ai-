# EHES Dashboard - CI/CD Deployment Guide

This guide covers the complete CI/CD pipeline setup for deploying the EHES Dashboard to AWS using Kubernetes.

## 🏗️ Architecture Overview

- **Application**: Streamlit dashboard with PostgreSQL database
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes on AWS EKS
- **CI/CD**: GitHub Actions for automated testing and deployment
- **Ingress**: NGINX Ingress Controller with SSL termination
- **Monitoring**: Built-in health checks and logging

## 📋 Prerequisites

### Required Tools
- AWS CLI (configured with credentials)
- kubectl
- Helm 3.x
- Docker
- Git

### AWS Requirements
- AWS account with appropriate permissions
- IAM user with EKS, ECR, and Route53 permissions
- Domain name (optional, for SSL)

## 🚀 Quick Start

### 1. Local Development

```bash
# Clone the repository
git clone <your-repo-url>
cd Project

# Start local development environment
docker-compose -f docker-compose.dev.yml up -d

# View the application
open http://localhost:8501
```

### 2. AWS Infrastructure Setup

```bash
# Set up AWS infrastructure
./scripts/setup-aws.sh

# Configure environment variables
export AWS_REGION="us-east-1"
export EKS_CLUSTER_NAME="ehes-cluster"
export ECR_REPOSITORY="ehes-dashboard"
export K8S_NAMESPACE="ehes-app"
```

### 3. Deploy to Production

```bash
# Deploy the application
./scripts/deploy.sh

# Check deployment status
kubectl get pods -n ehes-app
kubectl get services -n ehes-app
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file for local development:

```bash
DATABASE_URL=postgresql://postgres:password@localhost:5432/ehes_db
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
```

### Kubernetes Secrets

Update `k8s/secrets.yaml` with your actual secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ehes-secrets
  namespace: ehes-app
type: Opaque
data:
  # Base64 encoded values
  database-url: <base64-encoded-database-url>
  api-key: <base64-encoded-api-key>
```

### GitHub Secrets

Configure these secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EKS_CLUSTER_NAME`
- `APP_DOMAIN` (your domain name)

## 🔄 CI/CD Pipeline

### Workflow Triggers

- **Push to `main`**: Runs tests, builds image, deploys to production
- **Push to `develop`**: Runs tests, builds image, deploys to staging
- **Pull requests**: Runs tests only

### Pipeline Stages

1. **Test**: Linting, unit tests, code coverage
2. **Build**: Docker image build and push to ECR
3. **Deploy**: Helm deployment to Kubernetes

### Manual Deployment

```bash
# Run tests locally
./scripts/test.sh

# Deploy manually
./scripts/deploy.sh
```

## 🌐 Accessing the Application

### Production

After deployment, get the LoadBalancer URL:

```bash
kubectl get service ehes-dashboard-service -n ehes-app
```

### With Custom Domain

1. Update your DNS A record to point to the LoadBalancer IP
2. Configure `k8s/helm-chart/values.yaml` with your domain
3. SSL certificates will be automatically provisioned by cert-manager

## 📊 Monitoring and Logging

### Health Checks

The application includes built-in health checks:

- **Liveness Probe**: `/` endpoint every 10 seconds
- **Readiness Probe**: `/` endpoint every 5 seconds

### Logs

View application logs:

```bash
kubectl logs -f deployment/ehes-dashboard -n ehes-app
```

### Monitoring

Monitor resource usage:

```bash
kubectl top pods -n ehes-app
kubectl describe nodes
```

## 🔒 Security Considerations

- Database credentials stored in Kubernetes secrets
- SSL/TLS encryption for all external traffic
- Network policies for pod-to-pod communication
- Regular security scanning of Docker images
- IAM roles with least privilege principle

## 🧪 Testing

### Local Testing

```bash
# Run all tests
./scripts/test.sh

# Run specific test file
pytest test_file.py

# Run with coverage
pytest --cov=. --cov-report=html
```

### Integration Testing

```bash
# Test database connectivity
docker-compose run -e DATABASE_URL=postgresql://postgres:password@db:5432/ehes_db python -c "from store_data_in_db import *; print('Database connection successful')"
```

## 🚨 Troubleshooting

### Common Issues

1. **Pod Pending**: Check resource limits and node availability
2. **Image Pull Error**: Verify ECR permissions and image tags
3. **Database Connection**: Check secrets and network policies
4. **Ingress Issues**: Verify NGINX controller and DNS configuration

### Debug Commands

```bash
# Check pod status
kubectl get pods -n ehes-app -o wide

# Describe pod
kubectl describe pod <pod-name> -n ehes-app

# Check events
kubectl get events -n ehes-app --sort-by=.metadata.creationTimestamp

# Port forward for debugging
kubectl port-forward deployment/ehes-dashboard 8501:8501 -n ehes-app
```

## 📈 Scaling

### Horizontal Scaling

Update replica count in `k8s/helm-chart/values.yaml`:

```yaml
replicaCount: 5
```

### Auto-scaling

Enable HPA in values:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## 🧹 Cleanup

Remove all resources:

```bash
./scripts/cleanup.sh
```

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Streamlit Documentation](https://docs.streamlit.io/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./scripts/test.sh`
5. Submit a pull request

## 📞 Support

For deployment issues, check the troubleshooting section or create an issue in the repository.
