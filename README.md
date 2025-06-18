# NiFi Registry Helm Chart

A production-ready Helm chart for Apache NiFi Registry with **HTTPS and OIDC authentication enabled by default**.

## ⚠️ Breaking Changes in v2.0.0

**This is a BREAKING CHANGE from previous versions:**

- **HTTPS is now enabled by default** (previously HTTP)
- **OIDC authentication is enabled by default** (previously no authentication)
- **Auto-generated certificates** are created automatically
- **Script-based configuration** replaces property file mounting

### Migration from v1.x

If you need HTTP access (not recommended), see [Legacy HTTP Configuration](#legacy-http-configuration).

## Features

✅ **Security by default**: HTTPS with auto-generated certificates  
✅ **OIDC authentication**: Enterprise-ready authentication  
✅ **Multiple certificate strategies**: Auto, cert-manager, or manual  
✅ **Script-based configuration**: Dynamic property management  
✅ **Multiple databases**: H2, PostgreSQL, MySQL support  
✅ **Production ready**: Health checks, security contexts, persistence  
✅ **Kubernetes native**: StatefulSet, Services, Ingress, RBAC  

## Quick Start

### 1. Basic Secure Deployment (HTTPS + Self-signed certificates)

```bash
helm install nifi-registry ./nifi-registry
```

This creates a secure deployment with:
- HTTPS enabled with auto-generated self-signed certificates
- OIDC authentication enabled (requires configuration)
- H2 database for data persistence

### 2. Configure OIDC Authentication

Update your values to add your OIDC provider:

```yaml
oidc:
  enabled: true
  discoveryUrl: "https://your-oidc-provider.com/.well-known/openid_configuration"
  clientId: "nifi-registry"
  clientSecret: "your-client-secret"
```

### 3. Access the Application

```bash
# Port forward to access the application
kubectl port-forward svc/nifi-registry 18443:18443

# Visit https://localhost:18443/nifi-registry
# Accept the self-signed certificate warning
```

## Configuration

### Certificate Management

The chart supports three certificate strategies:

#### 1. Auto-Generated Certificates (Default)

```yaml
security:
  enabled: true
  certificates:
    strategy: auto
```

Creates self-signed certificates automatically. Perfect for development and testing.

#### 2. Cert-Manager Integration

```yaml
security:
  enabled: true
  certificates:
    strategy: cert-manager
    certManager:
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
```

Requires [cert-manager](https://cert-manager.io/) to be installed. Best for production with proper CA.

#### 3. Manual Certificates

```yaml
security:
  enabled: true
  certificates:
    strategy: manual
    manual:
      keystoreSecret: "my-keystore-secret"
      truststoreSecret: "my-truststore-secret"
```

Use your own certificates stored in Kubernetes secrets.

### OIDC Authentication

Configure your OIDC provider:

```yaml
oidc:
  enabled: true
  discoveryUrl: "https://keycloak.example.com/realms/nifi/.well-known/openid_configuration"
  clientId: "nifi-registry"
  clientSecret: "your-secret"
  claimIdentifyingUser: "preferred_username"  # or "email"
  additionalScopes: "groups"
```

### Database Configuration

#### H2 Database (Default)

```yaml
database:
  type: h2
```

#### PostgreSQL

```yaml
database:
  type: postgresql
  postgresql:
    host: "postgres.example.com"
    port: 5432
    database: "nifi_registry"
    username: "nifi_user"
    password: "secure-password"
    maxConnections: 10
```

#### MySQL

```yaml
database:
  type: mysql
  mysql:
    host: "mysql.example.com"
    port: 3306
    database: "nifi_registry"
    username: "nifi_user"
    password: "secure-password"
    maxConnections: 10
```

### Legacy HTTP Configuration

**⚠️ Not recommended for production**

To disable HTTPS and use HTTP (legacy behavior):

```yaml
security:
  enabled: false

oidc:
  enabled: false

nifiRegistry:
  web:
    httpPort: 18080
    httpsPort: ""

service:
  port: 18080

environment:
  NIFI_REGISTRY_WEB_HTTP_PORT: "18080"
  NIFI_REGISTRY_WEB_HTTPS_PORT: ""
```

## Production Deployment Example

```yaml
# Production values
security:
  enabled: true
  certificates:
    strategy: cert-manager
    certManager:
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer

oidc:
  enabled: true
  discoveryUrl: "https://auth.company.com/.well-known/openid_configuration"
  clientId: "nifi-registry-prod"
  clientSecret: "production-secret"

database:
  type: postgresql
  postgresql:
    host: "postgres-prod.company.com"
    database: "nifi_registry_prod"
    username: "nifi_user"
    password: "production-password"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  hosts:
    - host: nifi-registry.company.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: nifi-registry-tls
      hosts:
        - nifi-registry.company.com

resources:
  limits:
    cpu: 2
    memory: 4Gi
  requests:
    cpu: 1
    memory: 2Gi

persistence:
  enabled: true
  size: 50Gi
  storageClass: "fast-ssd"

replicaCount: 3
```

## Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `security.enabled` | Enable HTTPS and SSL/TLS | `true` |
| `security.certificates.strategy` | Certificate management strategy: `auto`, `cert-manager`, `manual` | `auto` |
| `oidc.enabled` | Enable OIDC authentication | `true` |
| `oidc.discoveryUrl` | OIDC provider discovery URL | `""` |
| `oidc.clientId` | OIDC client ID | `"nifi-registry"` |
| `oidc.clientSecret` | OIDC client secret | `""` |
| `database.type` | Database type: `h2`, `postgresql`, `mysql` | `h2` |
| `service.port` | Service port | `18443` |
| `persistence.enabled` | Enable persistent volume | `true` |
| `persistence.size` | Persistent volume size | `8Gi` |

For a complete list of configuration options, see [values.yaml](values.yaml).

## Testing

Test different configurations:

```bash
# Test secure deployment with auto-generated certificates
helm install test-secure ./nifi-registry -f test-values-secure.yaml

# Test cert-manager integration
helm install test-certmgr ./nifi-registry -f test-values-cert-manager.yaml

# Test legacy HTTP (not recommended)
helm install test-http ./nifi-registry -f test-values-legacy-http.yaml
```

## Troubleshooting

### Certificate Issues

Check certificate generation:

```bash
# Check cert generation job
kubectl get jobs
kubectl logs job/nifi-registry-cert-gen

# Check certificate secret
kubectl get secret nifi-registry-certs -o yaml
```

### OIDC Authentication Issues

1. Verify OIDC discovery URL is accessible
2. Check client ID and secret configuration
3. Review application logs for authentication errors

```bash
kubectl logs statefulset/nifi-registry
```

### Health Check Failures

For HTTPS deployments, health checks use HTTPS scheme. If certificates are invalid, health checks may fail:

```bash
# Check pod status
kubectl get pods
kubectl describe pod nifi-registry-0

# Check application logs
kubectl logs nifi-registry-0
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test with `helm lint` and `helm template`
4. Submit a pull request

## License

This chart is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

Apache NiFi Registry is a trademark of The Apache Software Foundation. 