#!/bin/bash

echo "Generating CA private key"
openssl genrsa -out ca.key 4096

echo "Generating CA certificate"
openssl req -x509 -new -nodes -key ca.key -sha256 -days 10000 -out ca.crt -config ca.cnf -reqexts req_ext

echo "Generating container image registry private key"
openssl genrsa -out container-image-registry.key 2048

echo "Generating container image registry certificate"
openssl req -new -sha256 -key container-image-registry.key \
    -reqexts req_ext \
	-config container-image-registry.cnf \
	-out container-image-registry.csr

echo "Signing container image registry certificate with CA"
openssl x509 -req -in container-image-registry.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out container-image-registry.crt -days 10000 -sha256 -extfile container-image-registry.cnf -extensions req_ext

