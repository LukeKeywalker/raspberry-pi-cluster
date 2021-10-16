#!/bin/bash

# Install CA certificate on a machine which will push from outside the cluster with docker push
sudo cp ca.crt /usr/local/share/ca-certificates/extra/container-image-registry-ca.crt
sudo update-ca-certificates

# Install container image registry certificates on the machine which will push from outside the cluster with docker push
sudo cp container-image-registry.crt /etc/docker/certs.d/container-image-registry:31000/
# Not sure if this one is really needed - double check
sudo cp ca.crt /etc/docker/certs.d/container-image-registry:31000/
sudo cp ca.key /etc/docker/certs.d/container-image-registry:31000/

# Install certificates and container image registry private key on the cluster
for i in {5..1}; do scp ~/projects/raspberry-pi-cluster/certs/ca.crt root@192.168.1.1${i}:/usr/local/share/ca-certificates/container-image-registry/ca.crt; done

for i in {5..1}; do scp ~/projects/raspberry-pi-cluster/certs/container-image-registry.crt root@192.168.1.1${i}:/usr/local/share/ca-certificates/container-image-registry/container-image-registry.crt; done

for i in {5..1}; do scp ~/projects/raspberry-pi-cluster/certs/container-image-registry.key root@192.168.1.1${i}:/usr/local/share/ca-certificates/container-image-registry/container-image-registry.key; done

# update container-image-registry-certs secrets on the cluster
kubectl delete secret container-image-registry-certs -n container-image-registry
kubectl create secret tls container-image-registry-certs --key="container-image-registry.key" --cert="container-image-registry.crt" -n container-image-registry

# restart cluster
ansible -i ../../node-inventory all_nodes -a "/sbin/shutdown -r now"
