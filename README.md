# Apache NiFi Registry Helm Chart

A production-ready Helm chart for deploying Apache NiFi Registry 2.4.0 on Kubernetes.

## Features

- ✅ **StatefulSet deployment** with persistent storage
- ✅ **Configurable database backends** (H2, PostgreSQL, MySQL)
- ✅ **SSL/TLS support** with keystore and truststore configuration
- ✅ **Security contexts** and pod security policies
- ✅ **Health checks** (readiness and liveness probes)
- ✅ **Service Account** with configurable RBAC
- ✅ **Ingress support** with TLS termination
- ✅ **Flexible configuration** via ConfigMap
- ✅ **Production-ready defaults** with resource limits

## Quick Start

### Prerequisites

- Kubernetes 1.19+
- Helm 3.x
- Persistent Volume provisioner support in the underlying infrastructure

### Installation

```bash
# Add the repository (if published to a Helm repository)
# helm repo add nifi-registry https://your-repo-url
# helm repo update

# Install with default configuration (H2 database)
helm install my-nifi-registry . --namespace nifi-registry --create-namespace

# Install with custom values
helm install my-nifi-registry . --namespace nifi-registry --create-namespace -f my-values.yaml
```

### Access the Application

```bash
# Using kubectl proxy (recommended)
kubectl proxy --port=8080 &
# Open: http://localhost:8080/api/v1/namespaces/nifi-registry/services/my-nifi-registry:18080/proxy/nifi-registry/

# Using port forwarding
kubectl port-forward -n nifi-registry svc/my-nifi-registry 18080:18080
# Open: http://localhost:18080/nifi-registry/
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `apache/nifi-registry` |
| `image.tag` | Image tag | `2.4.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `18080` |
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.size` | Storage size | `5Gi` |

### Database Configuration

#### Default H2 Database
```yaml
# No additional configuration needed - works out of the box
```

#### PostgreSQL Database
```yaml
nifiRegistry:
  properties:
    "nifi.registry.db.url": "jdbc:postgresql://postgres:5432/nifiregistry"
    "nifi.registry.db.driver.class": "org.postgresql.Driver"
    "nifi.registry.db.username": "nifiregistry"
    "nifi.registry.db.password": "password"
```

### SSL/TLS Configuration

```yaml
security:
  enabled: true
  keystore:
    secretName: "nifi-registry-keystore"
    keystoreKey: "keystore.jks"
    type: "JKS"
  truststore:
    secretName: "nifi-registry-truststore"
    truststoreKey: "truststore.jks"
    type: "JKS"
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: nifi-registry.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: nifi-registry-tls
      hosts:
        - nifi-registry.example.com
```

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing procedures including:
- Basic H2 deployment testing
- PostgreSQL integration testing
- SSL/TLS configuration testing
- Automated testing scripts

## Examples

Example configuration files are provided in the repository:

- `test-values-simple.yaml` - Basic H2 configuration
- `test-values-postgres.yaml` - PostgreSQL configuration
- `test-values-minimal.yaml` - Minimal configuration

## SSL Certificate Generation

Generate self-signed certificates for testing:

```bash
cd ssl-certs
./create-ssl-certs.sh
```

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│     Ingress     │────│     Service      │────│   StatefulSet   │
│  (optional)     │    │   (ClusterIP)    │    │  (nifi-registry)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                       ┌──────────────────┐            │
                       │   ConfigMap      │────────────┘
                       │ (configuration)  │
                       └──────────────────┘
                                                        │
                       ┌──────────────────┐            │
                       │ PersistentVolume │────────────┘
                       │   (database)     │
                       └──────────────────┘
```

## Production Considerations

1. **Database**: Use external PostgreSQL/MySQL for production
2. **SSL/TLS**: Use proper certificates from a Certificate Authority
3. **Storage**: Configure appropriate storage class and size
4. **Resources**: Adjust CPU/memory based on workload
5. **Ingress**: Configure ingress for external access
6. **Monitoring**: Add monitoring and logging
7. **Backup**: Implement database backup strategy
8. **High Availability**: Consider multiple replicas with shared storage

## Troubleshooting

### Common Issues

1. **Pod not starting**: Check logs with `kubectl logs <pod-name>`
2. **Database connection**: Verify database connectivity and credentials
3. **SSL issues**: Ensure certificates are valid and properly mounted
4. **Storage issues**: Check PVC status and storage class

### Debug Commands

```bash
# Check pod status
kubectl get pods -n nifi-registry

# View pod logs
kubectl logs -n nifi-registry <pod-name>

# Describe pod for events
kubectl describe pod -n nifi-registry <pod-name>

# Test internal connectivity
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never \
  --namespace=nifi-registry -- curl http://my-nifi-registry:18080/nifi-registry/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly using the provided testing procedures
5. Submit a pull request

## License

This Helm chart is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

Apache NiFi Registry is licensed under the Apache License 2.0.

## Support

For issues related to:
- **This Helm chart**: Open an issue in this repository
- **Apache NiFi Registry**: Visit the [official Apache NiFi documentation](https://nifi.apache.org/docs.html)

## Changelog

### v1.0.0
- Initial release
- Support for Apache NiFi Registry 2.4.0
- H2 and PostgreSQL database support
- SSL/TLS configuration
- Ingress support
- Production-ready defaults 