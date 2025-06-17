#!/bin/bash

set -e

echo "🚀 NiFi Registry Helm Chart Testing Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to Kubernetes
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Make sure kubectl is configured correctly."
    exit 1
fi

print_status "Prerequisites check passed"

# Function to test simple deployment (H2 database)
test_simple_deployment() {
    echo ""
    echo "🧪 Testing Simple Deployment (H2 Database)"
    echo "===========================================" 
    
    # Create namespace for testing
    kubectl create namespace nifi-registry-test --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy with simple configuration
    helm upgrade --install nifi-registry-simple . \
        --namespace nifi-registry-test \
        --values test-values-simple.yaml \
        --wait --timeout=10m
    
    if [ $? -eq 0 ]; then
        print_status "Simple deployment successful"
        
        # Get pod status
        echo "Pod status:"
        kubectl get pods -n nifi-registry-test
        
        # Get service info
        echo "Service info:"
        kubectl get svc -n nifi-registry-test
        
        # Port forward for testing
        print_warning "Setting up port forwarding for testing..."
        kubectl port-forward -n nifi-registry-test svc/nifi-registry-simple 18080:18080 &
        PF_PID=$!
        
        # Wait a moment for port forward to establish
        sleep 3
        
        # Test HTTP endpoint
        echo "Testing HTTP endpoint..."
        if curl -f http://localhost:18080/nifi-registry/ &> /dev/null; then
            print_status "NiFi Registry is responding on HTTP"
        else
            print_warning "NiFi Registry HTTP endpoint not yet ready (this is normal, it may take a few minutes to start)"
        fi
        
        # Kill port forward
        kill $PF_PID 2>/dev/null || true
        
    else
        print_error "Simple deployment failed"
        return 1
    fi
}

# Function to test PostgreSQL deployment
test_postgres_deployment() {
    echo ""
    echo "🐘 Testing PostgreSQL Deployment"
    echo "================================="
    
    print_warning "This test assumes you have PostgreSQL running locally with the database setup from setup-postgres.sql"
    read -p "Do you want to proceed with PostgreSQL test? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Deploy with PostgreSQL configuration
        helm upgrade --install nifi-registry-postgres . \
            --namespace nifi-registry-test \
            --values test-values-postgres.yaml \
            --wait --timeout=10m
        
        if [ $? -eq 0 ]; then
            print_status "PostgreSQL deployment successful"
            
            # Get pod status
            echo "Pod status:"
            kubectl get pods -n nifi-registry-test
            
            # Get service info
            echo "Service info:"
            kubectl get svc -n nifi-registry-test
            
        else
            print_error "PostgreSQL deployment failed"
            return 1
        fi
    else
        print_warning "Skipping PostgreSQL test"
    fi
}

# Function to cleanup
cleanup() {
    echo ""
    echo "🧹 Cleanup"
    echo "=========="
    
    read -p "Do you want to cleanup test deployments? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        helm uninstall nifi-registry-simple -n nifi-registry-test 2>/dev/null || true
        helm uninstall nifi-registry-postgres -n nifi-registry-test 2>/dev/null || true
        kubectl delete namespace nifi-registry-test 2>/dev/null || true
        print_status "Cleanup completed"
    else
        print_warning "Cleanup skipped. Remember to manually clean up test resources if needed."
    fi
}

# Main execution
echo "Starting tests..."

# Run tests
test_simple_deployment

# Test PostgreSQL if requested
test_postgres_deployment

# Cleanup
cleanup

echo ""
print_status "Testing completed!"
echo ""
echo "📋 Summary:"
echo "- Simple deployment test: Check the output above"
echo "- PostgreSQL deployment test: Check the output above" 
echo ""
echo "📖 Next steps:"
echo "1. If tests passed, your Helm chart is working correctly"
echo "2. For production use, configure proper SSL certificates"
echo "3. Set up your preferred database (PostgreSQL, MySQL, etc.)"
echo "4. Configure ingress for external access"
echo "5. Adjust resource limits based on your requirements" 