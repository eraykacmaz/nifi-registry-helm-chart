# NiFi Registry Helm Chart Testing Guide

This document provides comprehensive testing procedures for the NiFi Registry Helm chart, covering different deployment scenarios and access methods.

## Prerequisites

Before testing, ensure you have:

- Kubernetes cluster (tested with kind, minikube, or any K8s cluster)
- Helm 3.x installed
- kubectl configured to access your cluster
- curl for API testing

## Quick Start Testing

### 1. Basic H2 Database Test (Recommended for initial testing)

This test uses the default H2 embedded database and requires no external dependencies.

```bash
# Create namespace
kubectl create namespace nifi-registry

# Deploy with minimal configuration
helm install nifi-registry . --namespace nifi-registry --values test-values-simple.yaml

# Wait for pod to be ready (usually takes 30-60 seconds)
kubectl get pods -n nifi-registry -w

# Once pod shows 1/1 Ready, proceed to access methods below
```

### 2. Access the NiFi Registry UI

Due to networking variations in different Kubernetes setups, we provide multiple access methods:

#### Method A: kubectl proxy (Recommended - works in most environments)

```bash
# Start kubectl proxy
kubectl proxy --port=8080 &

# Access the UI in your browser:
# http://localhost:8080/api/v1/namespaces/nifi-registry/services/nifi-registry:18080/proxy/nifi-registry/

# Test API access:
curl "http://localhost:8080/api/v1/namespaces/nifi-registry/services/nifi-registry:18080/proxy/nifi-registry-api/buckets"
```

#### Method B: Port forwarding (Alternative method)

```bash
# Set up port forwarding
kubectl port-forward -n nifi-registry svc/nifi-registry 18080:18080 &

# Access the UI in your browser:
# http://localhost:18080/nifi-registry/

# Test API access:
curl http://localhost:18080/nifi-registry-api/buckets
```

#### Method C: NodePort service (For kind/minikube clusters)

```bash
# Convert service to NodePort
kubectl patch svc nifi-registry -n nifi-registry -p '{"spec":{"type":"NodePort"}}'

# Get the assigned port
kubectl get svc nifi-registry -n nifi-registry

# For kind clusters, you may need additional port mapping configuration
```

### 3. Verify Deployment

Once you have UI access, verify the deployment:

1. **UI Verification**: Open the NiFi Registry web interface - you should see the main dashboard
2. **API Verification**: The API should return an empty array `[]` for buckets (expected for new installation)
3. **Pod Logs**: Check for successful startup messages:

```bash
kubectl logs nifi-registry-0 -n nifi-registry | grep "Started Application"
```

Expected output: `Started Application in X.XXX seconds`

## Advanced Testing Scenarios

### PostgreSQL Database Testing

For testing with external PostgreSQL database:

```bash
# 1. Deploy PostgreSQL for testing
kubectl create namespace postgres-test
kubectl run postgres --image=postgres:15 \
  --env="POSTGRES_PASSWORD=nifiregistry" \
  --env="POSTGRES_USER=nifiregistry" \
  --env="POSTGRES_DB=nifiregistry" \
  --port=5432 --namespace=postgres-test
kubectl expose pod postgres --port=5432 --namespace=postgres-test

# 2. Wait for PostgreSQL to be ready
kubectl get pods -n postgres-test -w

# 3. Deploy NiFi Registry with PostgreSQL
helm install nifi-registry-postgres . --namespace nifi-registry \
  --values test-values-postgres.yaml

# 4. Verify connection and functionality using the same access methods above
```

### SSL/TLS Testing

For testing with SSL/TLS enabled:

```bash
# 1. Generate SSL certificates (if not already done)
./ssl-certs/create-ssl-certs.sh

# 2. Create Kubernetes secrets for certificates
kubectl create secret generic nifi-registry-keystore \
  --from-file=keystore.jks=ssl-certs/keystore.jks \
  --namespace nifi-registry

kubectl create secret generic nifi-registry-truststore \
  --from-file=truststore.jks=ssl-certs/truststore.jks \
  --namespace nifi-registry

# 3. Deploy with SSL enabled
helm install nifi-registry-ssl . --namespace nifi-registry \
  --set security.enabled=true \
  --set security.keystore.secretName=nifi-registry-keystore \
  --set security.truststore.secretName=nifi-registry-truststore

# 4. Access via HTTPS (port 18443)
kubectl proxy --port=8080 &
# https://localhost:8080/api/v1/namespaces/nifi-registry/services/nifi-registry:18443/proxy/nifi-registry/
```

## Automated Testing Script

Use the provided automated testing script for comprehensive validation:

```bash
# Make the script executable
chmod +x test-deployment.sh

# Run automated tests
./test-deployment.sh

# The script will:
# - Check prerequisites
# - Deploy with H2 database
# - Verify pod startup
# - Test API endpoints
# - Clean up resources
```

## Troubleshooting

### Common Issues and Solutions

#### Pod not starting (CrashLoopBackOff)

```bash
# Check pod logs for errors
kubectl logs nifi-registry-0 -n nifi-registry

# Common causes:
# 1. Port conflicts - ensure both HTTP and HTTPS ports aren't specified
# 2. Configuration errors - verify values.yaml syntax
# 3. Resource constraints - check cluster resources
```

#### UI not accessible

```bash
# Verify pod is running
kubectl get pods -n nifi-registry

# Check service configuration
kubectl get svc -n nifi-registry

# Test internal connectivity
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never \
  --namespace=nifi-registry -- curl http://nifi-registry:18080/nifi-registry/
```

#### Database connection issues

```bash
# For PostgreSQL testing, verify database is accessible
kubectl run pg-test --image=postgres:15 --rm -it --restart=Never \
  --namespace=postgres-test -- psql -h postgres -U nifiregistry -d nifiregistry -c "SELECT 1;"

# Check NiFi Registry logs for database errors
kubectl logs nifi-registry-0 -n nifi-registry | grep -i database
```

## Testing Checklist

- [ ] **Basic Deployment**: H2 database deployment successful
- [ ] **Pod Status**: Pod reaches Running and Ready state
- [ ] **UI Access**: Web interface accessible via kubectl proxy
- [ ] **API Access**: REST API returns expected responses
- [ ] **Logs**: No error messages in application logs
- [ ] **PostgreSQL**: External database integration working (if tested)
- [ ] **SSL/TLS**: HTTPS access working (if tested)
- [ ] **Persistence**: Data persists across pod restarts (if enabled)

## Cleanup

After testing, clean up resources:

```bash
# Remove Helm releases
helm uninstall nifi-registry -n nifi-registry
helm uninstall nifi-registry-postgres -n nifi-registry  # if deployed

# Remove namespaces
kubectl delete namespace nifi-registry
kubectl delete namespace postgres-test  # if created

# Stop kubectl proxy
pkill -f "kubectl proxy"
```

## Configuration Files Reference

- `test-values-simple.yaml`: Basic H2 configuration for simple testing
- `test-values-postgres.yaml`: PostgreSQL database configuration
- `test-values-minimal.yaml`: Minimal configuration with no custom properties
- `ssl-certs/create-ssl-certs.sh`: SSL certificate generation script

## Expected Results

### Successful H2 Deployment
- Pod status: `1/1 Running`
- UI accessible at proxy URL
- API returns `[]` for empty buckets list
- Logs show: `Started Application in X.XXX seconds`

### Successful PostgreSQL Deployment
- Same as H2 deployment
- Additional verification: Database tables created in PostgreSQL
- Logs show successful database connection

### Successful SSL Deployment
- Pod status: `1/1 Running`
- HTTPS UI accessible on port 18443
- Certificate validation working
- HTTP redirects to HTTPS (if configured)

This testing guide ensures comprehensive validation of the NiFi Registry Helm chart across different deployment scenarios and environments. 