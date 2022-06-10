#!/bin/bash

# Install CA certificate on a machine which will push from outside the cluster with docker push
# sudo cp ca.crt /usr/local/share/ca-certificates/extra/container-image-registry-ca.crt
# sudo update-ca-certificates

# Install container image registry certificates on the machine which will push from outside the cluster with docker push
# sudo cp container-image-registry.crt /etc/docker/certs.d/container-image-registry:31000/
# Not sure if this one is really needed - double check
# sudo cp ca.crt /etc/docker/certs.d/container-image-registry:31000/ca.crt
# sudo cp ca.crt /etc/docker/certs.d/container-image-registry:31000/ca.cert
# sudo cp ca.key /etc/docker/certs.d/container-image-registry:31000/

# sudo systemctl restart docker

# Install certificates and container image registry private key on the cluster
for i in {5..1}; do ssh -i ~/.ssh/hackbook_id_rsa root@10.27.27.1${i} mkdir -p /usr/local/share/ca-certificates/container-image-registry/; done
for i in {5..1}; do scp -i ~/.ssh/hackbook_id_rsa ca.crt root@10.27.27.1${i}:/usr/local/share/ca-certificates/container-image-registry/ca.crt; done
for i in {5..1}; do scp -i ~/.ssh/hackbook_id_rsa container-image-registry.crt root@10.27.27.1${i}:/usr/local/share/ca-certificates/container-image-registry/container-image-registry.crt; done
for i in {5..1}; do scp -i ~/.ssh/hackbook_id_rsa container-image-registry.key root@10.27.27.1${i}:/usr/local/share/ca-certificates/container-image-registry/container-image-registry.key; done
for i in {1..5}; do ssh -i ~/.ssh/hackbook_id_rsa root@10.27.27.1${i} mkdir -p /etc/rancher/k3s/; done
for i in {1..5}; do scp -i ~/.ssh/hackbook_id_rsa registries.yaml root@10.27.27.1${i}:/etc/rancher/k3s/registries.yaml; done

# update container-image-registry-certs secrets on the cluster
kubectl delete secret container-image-registry-certs -n container-image-registry
kubectl create secret -n container-image-registry tls container-image-registry-certs --key="container-image-registry.key" --cert="container-image-registry.crt"

# restart cluster
ssh -i ~/.ssh/hackbook_id_rsa root@leader-1 systemctl restart k3s
