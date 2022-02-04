#!/bin/bash

# Install CA certificate on a machine which will push from outside the cluster with docker push
sudo cp ca.crt /usr/local/share/ca-certificates/extra/container-image-registry-ca.crt
sudo update-ca-certificates

# Install container image registry certificates on the machine which will push from outside the cluster with docker push
sudo cp container-image-registry.crt /etc/docker/certs.d/container-image-registry:31000/
# Not sure if this one is really needed - double check
sudo cp ca.crt /etc/docker/certs.d/container-image-registry:31000/ca.crt
sudo cp ca.crt /etc/docker/certs.d/container-image-registry:31000/ca.cert
sudo cp ca.key /etc/docker/certs.d/container-image-registry:31000/

sudo systemctl restart docker

# Install certificates and container image registry private key on the cluster
for i in {6..1}; do ssh root@192.168.1.1${i} mkdir -p /usr/local/share/ca-certificates/container-image-registry/; done
for i in {6..1}; do scp ca.crt root@192.168.1.1${i}:/usr/local/share/ca-certificates/container-image-registry/ca.crt; done
for i in {6..1}; do scp container-image-registry.crt root@192.168.1.1${i}:/usr/local/share/ca-certificates/container-image-registry/container-image-registry.crt; done
for i in {6..1}; do scp container-image-registry.key root@192.168.1.1${i}:/usr/local/share/ca-certificates/container-image-registry/container-image-registry.key; done
for i in {1..6}; do ssh root@192.168.1.1${i} mkdir -p /etc/rancher/k3s/; done
for i in {1..6}; do scp registries.yaml root@192.168.1.1${i}:/etc/rancher/k3s/registries.yaml; done

# update container-image-registry-certs secrets on the cluster
kubectl delete secret container-image-registry-certs
kubectl create secret tls container-image-registry-certs --key="container-image-registry.key" --cert="container-image-registry.crt"

# restart cluster
ssh root@master-1 systemctl restart k3s
