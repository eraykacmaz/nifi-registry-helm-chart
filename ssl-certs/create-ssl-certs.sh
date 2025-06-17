#!/bin/bash

# Create a self-signed certificate and keystore for testing
echo "Creating self-signed certificates for NiFi Registry testing..."

# Generate private key
openssl genrsa -out nifi-registry-key.pem 2048

# Generate certificate signing request
openssl req -new -key nifi-registry-key.pem -out nifi-registry.csr -subj "/C=US/ST=Test/L=Test/O=Test/OU=Test/CN=localhost"

# Generate self-signed certificate
openssl x509 -req -in nifi-registry.csr -signkey nifi-registry-key.pem -out nifi-registry-cert.pem -days 365

# Create PKCS12 keystore
openssl pkcs12 -export -in nifi-registry-cert.pem -inkey nifi-registry-key.pem -out nifi-registry.p12 -name nifi-registry -passout pass:changeit

# Convert to JKS keystore
keytool -importkeystore -srckeystore nifi-registry.p12 -srcstoretype PKCS12 -destkeystore keystore.jks -deststoretype JKS -srcstorepass changeit -deststorepass changeit -noprompt

# Create truststore with the same certificate
keytool -import -alias nifi-registry -file nifi-registry-cert.pem -keystore truststore.jks -storepass changeit -noprompt

echo "SSL certificates created:"
echo "- keystore.jks (password: changeit)"
echo "- truststore.jks (password: changeit)"

# Clean up temporary files
rm nifi-registry.csr nifi-registry.p12 