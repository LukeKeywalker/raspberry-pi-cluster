# raspberry-pi-cluster

Raspberry Pi mac addresses start with [`dc:a6:32`](https://maclookup.app/macaddress/DCA632)

command for getting ip addresses for all rpis on the network:
```
arp -e | grep "dc:a6:32" | awk '{ print $3 }'
```

## cgroup memory settings
add this at the end of `/boot/cmdline.txt`

```
sed '$s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/cmdline.txt > cmdline.tmp
mv cmdline.tmp /boot/cmdline.txt
```

## set hostnames

### master nodes
```
hostnamectl set-hostname master-node-n
```

### worker nodes
```
hostnamectl set-hostname worker-node-n
```

### all the nodes
```
echo '192.168.1.11   		master-{i}.k3s.local		master-node-1'	 >> /etc/hosts
...
echo '192.168.1.{n} 		master-{i}.k3s.local 		master-node-{n}' >> /etc/hosts
echo '192.168.1.{n + 1} 	worker-{n + 1}.k3s.local 	worker-node-1' 	 >> /etc/hosts
...
echo '192.168.1.{n + k}		worker-{n + k}.k3s.local	worker-node-{k}' >> /etc/hosts
```

## firewall setup

### master nodes
for some reason first firewall-cmd is not applied and has to be re-applied manually after the k3sup had beed installed
```
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload
```

### worker nodes
```
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload
```

## update iptables settings (all nodes)
```
echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.d/k8s.conf
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.d/k8s.conf
sysctl --system
```

## disable swap memory (all nodes)
```
sed -i '/swap/d' /etc/fstab
swapoff -a
```

## disable SELinux (all nodes)
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

## disable WIFI adapter

```
nmcli radio wifi off
```

## disable firewalld

systemctl disable firewalld --now

## Creating K3S cluster with K3Sup

see `setup-k3s.sh`

## WireGuard

`yum update -y` is needed before WireGuard can be compiled from sources (there will be compilation errors otherwise)

wireguard needs to be installed from source on raspberry pi CentOS 7 (arm build not available in ElRepo)

installing proper kernel development package:

```
yum install "kernel-devel-uname-r == $(uname -r)" -y
```
rest of dependencies:
```
yum install elfutils-libelf-devel kernel-devel pkgconfig "@Development Tools" -y
```

install git
```
yum install git -y
```
grab the code
```
git clone https://git.zx2c4.com/wireguard-linux-compat
git clone https://git.zx2c4.com/wireguard-tools
```
compile and install kernel module:
```
make -C wireguard-linux-compat/src -j$(nproc)
sudo make -C wireguard-linux-compat/src install
```
compile and install wg tool:
```
make -C wireguard-tools/src -j$(nproc)
sudo make -C wireguard-tools/src install
```


Create client configuration file:
```
sudo mkdir -p /etc/wireguard/
cd /etc/wireguard
wg genkey | sudo tee /etc/wireguard/client_private.key | wg pubkey | sudo tee /etc/wireguard/client_public.key
```

Client config file content:
```
vim /etc/wireguard/wg-client0.conf
```

```
[Interface]
Address = 10.10.10.2/24
DNS = 10.10.10.1
PrivateKey = private-key-of-your-client

[Peer]
PublicKey = public-key-of-your-server
AllowedIPs = 0.0.0.0/0 # to allow untunneled traffic, use `0.0.0.0/1, 128.0.0.0/1` instead
Endpoint = public-ip-of-your-server:51820
PersistentKeepalive = 25
```
Starting wg interface on the client:
```
systemctl start wg-quick@wg-client0.service
```

## Disabling Traefik ingress

Preferably install server with `--disable traefik` flag. If installed with it then do this on master nodes:
Remove traefik helm chart resource
```
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik
```

Stop the k3s service
```
service k3s stop
```
    
Edit service file `/etc/systemd/system/k3s.service` and add this line to ExecStart:
```
    --no-deploy traefik \
```
* Reload the service file
```
systemctl daemon-reload
```
* Remove the manifest file from auto-deploy folder
```
rm /var/lib/rancher/k3s/server/manifests/traefik.yaml
```
* Start the k3s service:
```
service k3s start
```

## Running private docker image registry in the k8s pod

[instructions](https://medium.com/swlh/deploy-your-private-docker-registry-as-a-pod-in-kubernetes-f6a489bf0180)

## Installing nginx ingress controller

[installation guide](https://kubernetes.github.io/ingress-nginx/deploy/)
[k8s documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)

create namespace for Nginx Ingress Controller and install Nginx Ingress Controller with helm:
```
kubectl create namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx
```

After installing NGINX Ingress Controller following error appear when trying to log into the docker image repository pod:
```
$ docker login container-registry -u 'container-repository-user' -p 'K9MTmQ2Y54D6CvoX'
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Error response from daemon: Get "https://container-registry/v2/": x509: certificate is valid for ingress.local, not container-registry
```
[troubleshooting tls problem](https://github.com/kubernetes/ingress-nginx/issues/4644)

Solving this TLS issue would be required in order to push images to the pod docker image registry. But this may not be necessary, and not allowing ingress into a docker registry is more secure. Solution would be to build the docker images inside another pod, and pushing it to the registry from inside the cluster. Then, only ingress to the CI/CD like Jenkins would be needed, and the image build process will be controlled by it.

[Kaniko - docker image builder](https://devopscube.com/build-docker-image-kubernetes-pod/)
[Kaniko - github](https://github.com/GoogleContainerTools/kaniko)

## Private Container Image Registry

K3s allows for configuration of Containerd that works with self signed certificates. What is needed though is adding a self-generated CA certificate. This configuration needs to be copied into the following path for all the nodes that pull from the private registry:
```
/etc/rancher/k3s/registries.yaml
```

registries.yaml:
```
mirrors:
  docker.io:
    endpoint:
      - "https://container-image-registry:31000"
configs:
  "container-image-registry:31000":
    auth:
      username: registrar 
      password: <<registry password>>
    tls:
      cert_file: /usr/local/share/ca-certificates/container-image-registry/container-image-registry.crt
      key_file:  /usr/local/share/ca-certificates/container-image-registry/container-image-registry.key
      ca_file:  /usr/local/share/ca-certificates/container-image-registry/ca.crt
```
[source](https://rancher.com/docs/k3s/latest/en/installation/private-registry/)

also, `container-image-registry.crt`, `container-image-registry.key` and `ca.crt` need to be present on all the nodes using the private image registry.

### Installing self signed certificate on Ubuntu

Copy `ca.crt` into `/usr/local/share/ca-certificates/extra/` path:
```
sudo cp ca.crt /usr/local/share/ca-certificates/extra/ca.crt    
```
update ca certificates:
```
sudo update-ca-certificates
```

## Limiting number of SD card writes

source: [link](https://haydenjames.io/increase-performance-lifespan-ssds-sd-cards/)


